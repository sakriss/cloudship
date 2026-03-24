//
//  OpenRouterService.swift
//  Cloudship
//
//  Wraps the OpenRouter chat completions API (OpenAI-compatible).
//  Uses free models with automatic fallback chain — no cost, just rate-limited.
//  https://openrouter.ai/docs
//

import Foundation

// MARK: - Chat message model

struct ChatMessage {
    enum Role: String, Codable {
        case system
        case user
        case assistant
    }
    let role: Role
    let content: String
}

// MARK: - Service

final class OpenRouterService {

    static let shared = OpenRouterService()
    private init() {}

    // ─────────────────────────────────────────────────────────────────────────
    // 🔑 API key is read from Info.plist → Secrets.xcconfig (gitignored).
    // Copy Secrets.xcconfig.example → Secrets.xcconfig and add your key.
    // Free tier — no credit card required: https://openrouter.ai/keys
    // ─────────────────────────────────────────────────────────────────────────
    private let apiKey: String = {
        guard let key = Bundle.main.infoDictionary?["OpenRouterAPIKey"] as? String,
              !key.isEmpty,
              key != "your-openrouter-api-key-here" else {
            print("⚠️ OpenRouter API key not configured. See Secrets.xcconfig.example")
            return ""
        }
        return key
    }()

    /// Models to try in order — if the first provider errors, fall through to the next.
    /// Premium users get higher-quality paid models; free users get free-tier models.
    private let premiumModels = [
        "anthropic/claude-3-haiku",
        "openai/gpt-4o-mini"
    ]
    private let freeModels = [
        "google/gemma-3-27b-it:free",
        "google/gemma-3-12b-it:free",
        "nvidia/nemotron-3-super-120b-a12b:free",
        "meta-llama/llama-3.3-70b-instruct:free"
    ]
    private var models: [String] {
        if SubscriptionManager.shared.isPremiumCached {
            return premiumModels + freeModels
        }
        return freeModels
    }
    private let endpoint = URL(string: "https://openrouter.ai/api/v1/chat/completions")!

    // MARK: - System prompt

    /// Formats UnifiedWeatherData into a concise system prompt the model can reason about.
    func systemPrompt(from data: UnifiedWeatherData) -> String {
        let location = data.locationName ?? "your location"
        let c = data.current

        let dateStr: String = {
            let f = DateFormatter()
            f.dateFormat = "EEEE, MMMM d"
            return f.string(from: Date())
        }()

        let tempUnit = TemperatureFormatter.apiUnits == "imperial" ? "°F" : "°C"
        let speedUnit = TemperatureFormatter.apiUnits == "imperial" ? "mph" : "km/h"

        func fmt(_ v: Double?) -> String { v.map { String(format: "%.0f", $0) } ?? "—" }

        var prompt = """
        You are a helpful weather assistant for \(location). \
        Answer questions in 2–4 sentences using only the forecast data below. \
        Be specific about days, temperatures, and conditions. \
        Today is \(dateStr).

        CURRENT CONDITIONS:
        Temperature: \(fmt(c.temperature))\(tempUnit) (feels like \(fmt(c.feelsLike))\(tempUnit))
        Condition: \(c.condition.description)
        Humidity: \(fmt(c.humidity))%  |  Wind: \(fmt(c.windSpeed)) \(speedUnit) \
        |  UV Index: \(fmt(c.uvIndex))  |  Dew Point: \(fmt(c.dewPoint))\(tempUnit)

        7-DAY FORECAST:
        """

        let dayFmt = DateFormatter()
        dayFmt.dateFormat = "EEE MMM d"

        for entry in data.daily.prefix(7) {
            let day  = dayFmt.string(from: entry.time)
            let hi   = fmt(entry.tempMax)
            let lo   = fmt(entry.tempMin)
            let cond = entry.condition.description
            let rain = entry.precipChance.map { String(format: "%.0f", $0 * 100) + "%" } ?? "—"
            prompt += "\n• \(day) — High \(hi)\(tempUnit) / Low \(lo)\(tempUnit)  \(cond)  (\(rain) rain)"
        }

        return prompt
    }

    // MARK: - Brief

    /// Generate a concise 2-3 sentence daily weather brief.
    func sendBrief(weatherData: UnifiedWeatherData) async throws -> String {
        let location = weatherData.locationName ?? "your location"
        let unitSystem = TemperatureFormatter.apiUnits == "imperial" ? "imperial (°F, mph)" : "metric (°C, km/h)"

        let briefSystemPrompt = """
        You are a concise weather briefing assistant. Generate a 2-3 sentence weather brief \
        for today at \(location). Be specific about times and temperatures. Focus on what \
        matters most: precipitation timing, best time to go outside, what to wear. \
        Be conversational and helpful, not clinical. Use the \(unitSystem) system. \
        Do not use emojis.
        """

        let weatherContext = systemPrompt(from: weatherData)
        let messages = [
            ChatMessage(role: .system, content: briefSystemPrompt),
            ChatMessage(role: .user, content: weatherContext + "\n\nGenerate today's weather brief.")
        ]

        // Try each model with shorter output
        var lastError: Error?
        for model in models {
            do {
                let reply = try await callModel(model, messages: messages, maxTokens: 150)
                return reply
            } catch {
                print("OpenRouter brief: \(model) failed — \(error.localizedDescription). Trying next…")
                lastError = error
            }
        }

        throw lastError ?? NSError(domain: "OpenRouter", code: -1,
                                    userInfo: [NSLocalizedDescriptionKey: "All models unavailable"])
    }

    // MARK: - Send

    /// Send the full conversation history to OpenRouter and return the assistant's reply.
    /// - Parameters:
    ///   - messages: The full conversation so far (system message is prepended automatically).
    ///   - weatherData: Used to build the system prompt.
    func send(messages: [ChatMessage], weatherData: UnifiedWeatherData) async throws -> String {
        let systemMsg = ChatMessage(role: .system, content: systemPrompt(from: weatherData))
        let allMessages = [systemMsg] + messages

        // Try each model in order until one succeeds
        var lastError: Error?
        for model in models {
            do {
                let reply = try await callModel(model, messages: allMessages)
                return reply
            } catch {
                print("OpenRouter: \(model) failed — \(error.localizedDescription). Trying next…")
                lastError = error
            }
        }

        throw lastError ?? NSError(domain: "OpenRouter", code: -1,
                                    userInfo: [NSLocalizedDescriptionKey: "All models unavailable"])
    }

    private func callModel(_ model: String, messages: [ChatMessage], maxTokens: Int = 300) async throws -> String {
        let body: [String: Any] = [
            "model": model,
            "messages": messages.map { ["role": $0.role.rawValue, "content": $0.content] },
            "max_tokens": maxTokens,
            "temperature": 0.7,
            "provider": ["allow_fallbacks": true]   // let OpenRouter try alternate providers
        ]

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)",   forHTTPHeaderField: "Authorization")
        request.setValue("application/json",   forHTTPHeaderField: "Content-Type")
        request.setValue("https://cloudshipapp.com", forHTTPHeaderField: "HTTP-Referer")
        request.setValue("Cloudship iOS",      forHTTPHeaderField: "X-Title")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 30

        // Retry up to 2 times for transient provider errors
        var lastError: Error?
        for attempt in 0..<2 {
            if attempt > 0 {
                try await Task.sleep(nanoseconds: UInt64(attempt) * 1_500_000_000) // 1.5s backoff
            }

            let (data, response) = try await URLSession.shared.data(for: request)

            // Check HTTP status
            if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                var msg = "HTTP \(http.statusCode)"
                if let errorJSON = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
                   let errorDict = errorJSON["error"] as? [String: Any],
                   let errorMsg  = errorDict["message"] as? String {
                    msg = errorMsg
                }
                // 429/502/503 are transient — retry; others are fatal
                if http.statusCode == 429 || http.statusCode == 502 || http.statusCode == 503 {
                    lastError = NSError(domain: "OpenRouter", code: http.statusCode,
                                        userInfo: [NSLocalizedDescriptionKey: msg])
                    continue
                }
                throw NSError(domain: "OpenRouter", code: http.statusCode,
                              userInfo: [NSLocalizedDescriptionKey: msg])
            }

            // Parse JSON
            guard let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
                throw NSError(domain: "OpenRouter", code: -1,
                              userInfo: [NSLocalizedDescriptionKey: "Invalid JSON response"])
            }

            // OpenRouter can return HTTP 200 with an error body (e.g. provider failures)
            if let errorDict = json["error"] as? [String: Any],
               let errorMsg  = errorDict["message"] as? String {
                let code = errorDict["code"] as? Int ?? -1
                lastError = NSError(domain: "OpenRouter", code: code,
                                    userInfo: [NSLocalizedDescriptionKey: errorMsg])
                // Provider errors are transient — retry
                if errorMsg.lowercased().contains("provider") {
                    continue
                }
                throw lastError!
            }

            // Parse successful response
            guard let choices = json["choices"] as? [[String: Any]],
                  let first   = choices.first,
                  let msgDict = first["message"] as? [String: Any],
                  let content = msgDict["content"] as? String
            else {
                throw NSError(domain: "OpenRouter", code: -1,
                              userInfo: [NSLocalizedDescriptionKey: "Unexpected response format"])
            }

            return content.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }

        throw lastError ?? NSError(domain: "OpenRouter", code: -1,
                                    userInfo: [NSLocalizedDescriptionKey: "Request failed after retries"])
    }
}

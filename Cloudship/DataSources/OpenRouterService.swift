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
    // 🔑 API keys are read from Info.plist → Secrets.xcconfig (gitignored).
    // Copy Secrets.xcconfig.example → Secrets.xcconfig and add your keys.
    // ─────────────────────────────────────────────────────────────────────────

    /// Google AI Studio (Gemini) key — tried first because it's free & fast.
    /// https://aistudio.google.com/app/apikey
    private let geminiAPIKey: String =
        (Bundle.main.infoDictionary?["GeminiAPIKey"] as? String) ?? ""

    /// OpenRouter key — used as fallback when Gemini is unavailable.
    /// Free tier: https://openrouter.ai/keys
    private let openRouterAPIKey: String =
        (Bundle.main.infoDictionary?["OpenRouterAPIKey"] as? String) ?? ""

    // Gemini native generateContent API (v1beta).
    // gemini-2.0-flash: confirmed available on v1beta, 15 RPM / 1500 RPD free tier.
    // The retry logic below handles transient 429s — in normal app use (<1 req/min) this never triggers.
    private let geminiModels = ["gemini-2.5-flash-lite"]
    private func geminiURL(model: String) -> URL {
        URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(geminiAPIKey)")!
    }

    private let openRouterEndpoint = URL(string: "https://openrouter.ai/api/v1/chat/completions")!

    /// OpenRouter fallback models (tried if Gemini fails or is unconfigured).
    private let openRouterFreeModels = [
        "google/gemma-3-27b-it:free",
        "google/gemma-3-12b-it:free",
        "meta-llama/llama-3.3-70b-instruct:free"
    ]

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

        return try await callWithFallback(messages: messages, maxTokens: 150)
    }

    // MARK: - Send

    /// Send the full conversation history and return the assistant's reply.
    func send(messages: [ChatMessage], weatherData: UnifiedWeatherData) async throws -> String {
        let systemMsg = ChatMessage(role: .system, content: systemPrompt(from: weatherData))
        let allMessages = [systemMsg] + messages
        return try await callWithFallback(messages: allMessages, maxTokens: 300)
    }

    // MARK: - Routing

    /// Try each Gemini model in order, then fall back to OpenRouter free models.
    private func callWithFallback(messages: [ChatMessage], maxTokens: Int) async throws -> String {
        // 1. Try Gemini models in order (flash-lite → 1.5-flash → 2.0-flash)
        if !geminiAPIKey.isEmpty {
            for model in geminiModels {
                do {
                    let reply = try await callGemini(model: model, messages: messages, maxTokens: maxTokens)
                    print("✅ AI: Gemini/\(model) answered")
                    return reply
                } catch {
                    print("⚠️ Gemini/\(model) failed (\(error.localizedDescription))")
                }
            }
            print("⚠️ All Gemini models failed — falling back to OpenRouter")
        } else {
            print("⚠️ Gemini API key not configured — trying OpenRouter")
        }

        // 2. Fall back to OpenRouter free models
        var lastError: Error?
        for model in openRouterFreeModels {
            do {
                let reply = try await callOpenRouter(model: model, messages: messages, maxTokens: maxTokens)
                print("✅ AI: OpenRouter/\(model) answered")
                return reply
            } catch {
                print("⚠️ OpenRouter \(model) failed — \(error.localizedDescription)")
                lastError = error
            }
        }

        throw lastError ?? NSError(domain: "AIService", code: -1,
                                    userInfo: [NSLocalizedDescriptionKey: "All AI providers unavailable"])
    }

    // MARK: - Gemini (Google AI Studio — native generateContent API)

    private func callGemini(model: String, messages: [ChatMessage], maxTokens: Int) async throws -> String {
        // Split system messages out — native API takes them in `systemInstruction`.
        let systemText = messages.filter { $0.role == .system }.map(\.content).joined(separator: "\n")
        let userMessages = messages.filter { $0.role != .system }

        // Build `contents` array (user/model turns only)
        let contents: [[String: Any]] = userMessages.map { msg in
            let role = msg.role == .assistant ? "model" : "user"
            return ["role": role, "parts": [["text": msg.content]]]
        }

        var body: [String: Any] = [
            "contents": contents,
            "generationConfig": [
                "maxOutputTokens": maxTokens,
                "temperature": 0.7
            ]
        ]
        if !systemText.isEmpty {
            body["systemInstruction"] = ["parts": [["text": systemText]]]
        }

        var request = URLRequest(url: geminiURL(model: model))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 30

        // Retry once on 429 (rate limit) with a short backoff — common during dev but rare in production.
        var lastData = Data()
        var lastStatus = 0
        for attempt in 0..<2 {
            if attempt > 0 {
                print("⚠️ Gemini/\(model) rate-limited — retrying in 3s…")
                try await Task.sleep(nanoseconds: 3_000_000_000)
            }
            let (d, r) = try await URLSession.shared.data(for: request)
            lastData   = d
            lastStatus = (r as? HTTPURLResponse)?.statusCode ?? -1
            if lastStatus != 429 { break }
        }

        if lastStatus != 200 {
            let rawBody = String(data: lastData, encoding: .utf8) ?? "(unreadable)"
            var msg = "Gemini/\(model) HTTP \(lastStatus)"
            if let errorJSON = (try? JSONSerialization.jsonObject(with: lastData)) as? [String: Any],
               let errorDict = errorJSON["error"] as? [String: Any],
               let errorMsg  = errorDict["message"] as? String {
                msg = errorMsg
            }
            print("⚠️ Gemini/\(model) error body: \(rawBody)")
            throw NSError(domain: "Gemini", code: lastStatus,
                          userInfo: [NSLocalizedDescriptionKey: msg])
        }

        let data = lastData

        // Native response: candidates[0].content.parts[0].text
        guard let json        = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              let candidates  = json["candidates"] as? [[String: Any]],
              let first       = candidates.first,
              let content     = first["content"] as? [String: Any],
              let parts       = content["parts"] as? [[String: Any]],
              let text        = parts.first?["text"] as? String
        else {
            let rawBody = String(data: data, encoding: .utf8) ?? "(unreadable)"
            print("⚠️ Gemini/\(model) unexpected response: \(rawBody)")
            throw NSError(domain: "Gemini", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Unexpected Gemini response format"])
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - OpenRouter (fallback)

    private func callOpenRouter(model: String, messages: [ChatMessage], maxTokens: Int) async throws -> String {
        let body: [String: Any] = [
            "model": model,
            "messages": messages.map { ["role": $0.role.rawValue, "content": $0.content] },
            "max_tokens": maxTokens,
            "temperature": 0.7,
            "provider": ["allow_fallbacks": true]
        ]

        var request = URLRequest(url: openRouterEndpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(openRouterAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json",            forHTTPHeaderField: "Content-Type")
        request.setValue("https://cloudshipapp.com",    forHTTPHeaderField: "HTTP-Referer")
        request.setValue("Cloudship iOS",               forHTTPHeaderField: "X-Title")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 30

        // Retry once on transient errors
        var lastError: Error?
        for attempt in 0..<2 {
            if attempt > 0 {
                try await Task.sleep(nanoseconds: 1_500_000_000)
            }

            let (data, response) = try await URLSession.shared.data(for: request)

            if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                var msg = "HTTP \(http.statusCode)"
                if let errorJSON = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
                   let errorDict = errorJSON["error"] as? [String: Any],
                   let errorMsg  = errorDict["message"] as? String {
                    msg = errorMsg
                }
                if http.statusCode == 429 || http.statusCode == 502 || http.statusCode == 503 {
                    lastError = NSError(domain: "OpenRouter", code: http.statusCode,
                                        userInfo: [NSLocalizedDescriptionKey: msg])
                    continue
                }
                throw NSError(domain: "OpenRouter", code: http.statusCode,
                              userInfo: [NSLocalizedDescriptionKey: msg])
            }

            guard let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
                throw NSError(domain: "OpenRouter", code: -1,
                              userInfo: [NSLocalizedDescriptionKey: "Invalid JSON response"])
            }

            if let errorDict = json["error"] as? [String: Any],
               let errorMsg  = errorDict["message"] as? String {
                let code = errorDict["code"] as? Int ?? -1
                lastError = NSError(domain: "OpenRouter", code: code,
                                    userInfo: [NSLocalizedDescriptionKey: errorMsg])
                if errorMsg.lowercased().contains("provider") { continue }
                throw lastError!
            }

            guard let choices = json["choices"] as? [[String: Any]],
                  let first   = choices.first,
                  let msgDict = first["message"] as? [String: Any],
                  let content = msgDict["content"] as? String
            else {
                throw NSError(domain: "OpenRouter", code: -1,
                              userInfo: [NSLocalizedDescriptionKey: "Unexpected response format"])
            }

            return content.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        throw lastError ?? NSError(domain: "OpenRouter", code: -1,
                                    userInfo: [NSLocalizedDescriptionKey: "Request failed after retries"])
    }
}

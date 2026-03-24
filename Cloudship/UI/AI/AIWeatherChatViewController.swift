//
//  AIWeatherChatViewController.swift
//  Cloudship
//
//  Bottom-sheet AI chat interface. Presents via UISheetPresentationController
//  with .medium / .large detents. Sends questions to OpenRouterService with
//  the full UnifiedWeatherData context and shows multi-turn conversation bubbles.
//

import UIKit

class AIWeatherChatViewController: UIViewController {

    // MARK: - Properties

    private let weatherData: UnifiedWeatherData
    private var messages: [ChatMessage] = []
    private var isLoading = false

    // MARK: - Suggestion chips

    private let suggestions: [(emoji: String, text: String)] = [
        ("🏃", "Good for running?"),
        ("🚗", "How's the commute?"),
        ("🎨", "Can I paint outside?"),
        ("🌱", "Should I water plants?"),
        ("🎉", "Good for a BBQ?"),
        ("✈️", "Travel conditions?")
    ]

    // MARK: - UI

    private lazy var titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Ask about your weather"
        l.font = .systemFont(ofSize: 17, weight: .semibold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var dismissButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        b.tintColor = .tertiaryLabel
        b.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private lazy var chipsScrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsHorizontalScrollIndicator = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private lazy var chipsStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 8
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private lazy var messagesScrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = true
        sv.alwaysBounceVertical = true
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private lazy var messagesStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 12
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private lazy var inputContainerView: UIView = {
        let v = UIView()
        v.backgroundColor = .secondarySystemBackground
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private lazy var textField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Ask anything..."
        tf.font = .systemFont(ofSize: 15)
        tf.backgroundColor = .tertiarySystemBackground
        tf.layer.cornerRadius = 18
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))
        tf.leftViewMode = .always
        tf.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))
        tf.rightViewMode = .always
        tf.returnKeyType = .send
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private lazy var sendButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "arrow.up.circle.fill",
                               withConfiguration: UIImage.SymbolConfiguration(pointSize: 30))
        let b = UIButton(configuration: config)
        b.tintColor = .systemBlue
        b.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private var inputBottomConstraint: NSLayoutConstraint!

    // MARK: - Init

    init(weatherData: UnifiedWeatherData) {
        self.weatherData = weatherData
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupChips()
        setupKeyboard()
        textField.delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Show a welcome message if this is the first open
        if messages.isEmpty {
            addAIBubble("Hi! I can answer questions about your local weather. Try tapping a suggestion or type your own question.")
        }
    }

    // MARK: - Setup

    private func setupView() {
        view.backgroundColor = .systemBackground

        // Header
        view.addSubview(titleLabel)
        view.addSubview(dismissButton)

        // Chips
        chipsScrollView.addSubview(chipsStack)
        view.addSubview(chipsScrollView)

        // Separator
        let sep = UIView()
        sep.backgroundColor = .separator
        sep.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sep)

        // Messages
        messagesScrollView.addSubview(messagesStack)
        view.addSubview(messagesScrollView)

        // Input
        inputContainerView.addSubview(textField)
        inputContainerView.addSubview(sendButton)
        view.addSubview(inputContainerView)

        inputBottomConstraint = inputContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)

        NSLayoutConstraint.activate([
            // Header
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            dismissButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            dismissButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            dismissButton.widthAnchor.constraint(equalToConstant: 32),
            dismissButton.heightAnchor.constraint(equalToConstant: 32),

            // Chips
            chipsScrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 14),
            chipsScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            chipsScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            chipsScrollView.heightAnchor.constraint(equalToConstant: 36),

            chipsStack.topAnchor.constraint(equalTo: chipsScrollView.topAnchor),
            chipsStack.bottomAnchor.constraint(equalTo: chipsScrollView.bottomAnchor),
            chipsStack.leadingAnchor.constraint(equalTo: chipsScrollView.leadingAnchor, constant: 16),
            chipsStack.trailingAnchor.constraint(equalTo: chipsScrollView.trailingAnchor, constant: -16),
            chipsStack.heightAnchor.constraint(equalTo: chipsScrollView.heightAnchor),

            // Separator
            sep.topAnchor.constraint(equalTo: chipsScrollView.bottomAnchor, constant: 10),
            sep.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sep.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sep.heightAnchor.constraint(equalToConstant: 0.5),

            // Messages
            messagesScrollView.topAnchor.constraint(equalTo: sep.bottomAnchor),
            messagesScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            messagesScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            messagesScrollView.bottomAnchor.constraint(equalTo: inputContainerView.topAnchor),

            messagesStack.topAnchor.constraint(equalTo: messagesScrollView.contentLayoutGuide.topAnchor, constant: 12),
            messagesStack.leadingAnchor.constraint(equalTo: messagesScrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            messagesStack.trailingAnchor.constraint(equalTo: messagesScrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            messagesStack.bottomAnchor.constraint(equalTo: messagesScrollView.contentLayoutGuide.bottomAnchor, constant: -12),
            messagesStack.widthAnchor.constraint(equalTo: messagesScrollView.frameLayoutGuide.widthAnchor, constant: -32),

            // Input container
            inputContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputContainerView.heightAnchor.constraint(equalToConstant: 64),
            inputBottomConstraint,

            sendButton.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor, constant: -8),
            sendButton.centerYAnchor.constraint(equalTo: inputContainerView.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 44),
            sendButton.heightAnchor.constraint(equalToConstant: 44),

            textField.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor, constant: 12),
            textField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -4),
            textField.centerYAnchor.constraint(equalTo: inputContainerView.centerYAnchor),
            textField.heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    private func setupChips() {
        for suggestion in suggestions {
            let btn = UIButton(type: .system)
            btn.setTitle("\(suggestion.emoji) \(suggestion.text)", for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
            btn.backgroundColor = .secondarySystemBackground
            btn.tintColor = .label
            btn.layer.cornerRadius = 14
            btn.layer.cornerCurve = .continuous
            btn.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
            btn.addTarget(self, action: #selector(chipTapped(_:)), for: .touchUpInside)
            // Store the question text via accessibility
            btn.accessibilityLabel = suggestion.text
            chipsStack.addArrangedSubview(btn)
        }
    }

    private func setupKeyboard() {
        NotificationCenter.default.addObserver(self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    // MARK: - Actions

    @objc private func dismissSelf() {
        dismiss(animated: true)
    }

    @objc private func chipTapped(_ sender: UIButton) {
        let question = sender.accessibilityLabel ?? ""
        send(question: question)
    }

    @objc private func sendTapped() {
        guard let text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else { return }
        textField.text = ""
        send(question: text)
    }

    // MARK: - Messaging

    private static let freeDailyLimit = 3

    private func dailyMessageCount() -> Int {
        let key = "aiChatCount_\(Calendar.current.startOfDay(for: Date()).timeIntervalSince1970)"
        return UserDefaults.standard.integer(forKey: key)
    }

    private func incrementDailyMessageCount() {
        let key = "aiChatCount_\(Calendar.current.startOfDay(for: Date()).timeIntervalSince1970)"
        let count = UserDefaults.standard.integer(forKey: key)
        UserDefaults.standard.set(count + 1, forKey: key)
    }

    private func send(question: String) {
        guard !isLoading else { return }

        // Rate limit free users
        if !SubscriptionManager.shared.isPremiumCached
            && dailyMessageCount() >= Self.freeDailyLimit {
            let paywall = PaywallViewController()
            paywall.modalPresentationStyle = .pageSheet
            if let sheet = paywall.sheetPresentationController {
                sheet.detents = [.large()]
            }
            present(paywall, animated: true)
            return
        }

        incrementDailyMessageCount()
        addUserBubble(question)
        messages.append(ChatMessage(role: .user, content: question))
        textField.resignFirstResponder()

        let typingView = addTypingIndicator()
        isLoading = true
        updateSendButton()

        Task {
            do {
                let reply = try await OpenRouterService.shared.send(
                    messages: messages,
                    weatherData: weatherData
                )
                await MainActor.run {
                    typingView.removeFromSuperview()
                    addAIBubble(reply)
                    messages.append(ChatMessage(role: .assistant, content: reply))
                    isLoading = false
                    updateSendButton()
                }
            } catch {
                await MainActor.run {
                    typingView.removeFromSuperview()
                    addAIBubble("Sorry, I couldn't get a response. \(error.localizedDescription)")
                    isLoading = false
                    updateSendButton()
                }
            }
        }
    }

    private func updateSendButton() {
        sendButton.isEnabled = !isLoading
        sendButton.alpha = isLoading ? 0.4 : 1.0
    }

    // MARK: - Bubble builders

    private func addUserBubble(_ text: String) {
        let bubble = makeBubble(text: text, isUser: true)
        messagesStack.addArrangedSubview(bubble)
        scrollToBottom()
    }

    private func addAIBubble(_ text: String) {
        let bubble = makeBubble(text: text, isUser: false)
        messagesStack.addArrangedSubview(bubble)
        scrollToBottom()
    }

    @discardableResult
    private func addTypingIndicator() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let bubble = UIView()
        bubble.backgroundColor = .secondarySystemBackground
        bubble.layer.cornerRadius = 16
        bubble.layer.cornerCurve = .continuous
        bubble.translatesAutoresizingMaskIntoConstraints = false

        let dots = UILabel()
        dots.text = "···"
        dots.font = .systemFont(ofSize: 22, weight: .bold)
        dots.textColor = .tertiaryLabel
        dots.translatesAutoresizingMaskIntoConstraints = false

        bubble.addSubview(dots)
        container.addSubview(bubble)

        NSLayoutConstraint.activate([
            dots.topAnchor.constraint(equalTo: bubble.topAnchor, constant: 6),
            dots.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -6),
            dots.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: 14),
            dots.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -14),

            bubble.topAnchor.constraint(equalTo: container.topAnchor),
            bubble.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            bubble.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            bubble.widthAnchor.constraint(equalToConstant: 64),

            container.heightAnchor.constraint(greaterThanOrEqualToConstant: 36)
        ])

        // Pulse animation
        UIView.animate(withDuration: 0.6, delay: 0,
                       options: [.repeat, .autoreverse]) {
            dots.alpha = 0.3
        }

        messagesStack.addArrangedSubview(container)
        scrollToBottom()
        return container
    }

    private func makeBubble(text: String, isUser: Bool) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let bubble = UIView()
        bubble.backgroundColor = isUser ? .systemBlue : .secondarySystemBackground
        bubble.layer.cornerRadius = 16
        bubble.layer.cornerCurve = .continuous
        bubble.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 15)
        label.textColor = isUser ? .white : .label
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false

        bubble.addSubview(label)
        container.addSubview(bubble)

        let maxWidth = UIScreen.main.bounds.width * 0.75

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: bubble.topAnchor, constant: 10),
            label.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -10),
            label.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: 14),
            label.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -14),

            bubble.topAnchor.constraint(equalTo: container.topAnchor),
            bubble.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            bubble.widthAnchor.constraint(lessThanOrEqualToConstant: maxWidth)
        ])

        if isUser {
            NSLayoutConstraint.activate([
                bubble.trailingAnchor.constraint(equalTo: container.trailingAnchor)
            ])
        } else {
            NSLayoutConstraint.activate([
                bubble.leadingAnchor.constraint(equalTo: container.leadingAnchor)
            ])
        }

        return container
    }

    private func scrollToBottom() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            let bottom = self.messagesScrollView.contentSize.height
                - self.messagesScrollView.bounds.height
                + self.messagesScrollView.contentInset.bottom
            if bottom > 0 {
                self.messagesScrollView.setContentOffset(
                    CGPoint(x: 0, y: bottom), animated: true)
            }
        }
    }

    // MARK: - Keyboard

    @objc private func keyboardWillShow(_ n: Notification) {
        guard let info = n.userInfo,
              let frame = (info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
              let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
        else { return }

        let keyboardHeight = frame.height - view.safeAreaInsets.bottom
        inputBottomConstraint.constant = -keyboardHeight

        UIView.animate(withDuration: duration) { self.view.layoutIfNeeded() }
        scrollToBottom()
    }

    @objc private func keyboardWillHide(_ n: Notification) {
        guard let duration = n.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
        else { return }
        inputBottomConstraint.constant = 0
        UIView.animate(withDuration: duration) { self.view.layoutIfNeeded() }
    }
}

// MARK: - UITextFieldDelegate

extension AIWeatherChatViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendTapped()
        return false
    }
}

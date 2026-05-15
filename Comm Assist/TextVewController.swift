import UIKit
import AVFoundation

class TextViewController: UIViewController,
                          AVSpeechSynthesizerDelegate,
                          UITextViewDelegate {

    // MARK: - UI ELEMENTS

    let titleLabel = UILabel()
    let subtitleLabel = UILabel()

    let textView = UITextView()

    let speakButton = UIButton()
    let stopButton = UIButton()
    let pauseButton = UIButton()

    let statusLabel = UILabel()
    let tipLabel = UILabel()

    let speedSlider = UISlider()
    let buttonStack = UIStackView()

    let wordHighlightLabel = UILabel()
    let charCountLabel = UILabel()
    let speedTitleLabel = UILabel()

    // MARK: - SPEECH

    let synthesizer = AVSpeechSynthesizer()

    // MARK: - LAYERS

    private var backgroundGradient: CAGradientLayer?
    private var gradientsApplied = false

    // MARK: - STATES

    private var isSpeaking = false

    // MARK: - PLACEHOLDER

    private weak var placeholderLabel: UILabel?

    // MARK: - LIFECYCLE

    override func viewDidLoad() {
        super.viewDidLoad()

        synthesizer.delegate = self

        setupAudioSession()

        setupUI()
        setupConstraints()

        view.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 0,
            leading: 20,
            bottom: 0,
            trailing: 20
        )
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        applyBackgroundGradient()

        if !gradientsApplied {
            gradientsApplied = true
            applyButtonGradients()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        animateEntrance()
        startTextViewIdleAnimation()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        NotificationCenter.default.removeObserver(self)

        textView.layer.removeAnimation(forKey: "borderPulse")
        speakButton.layer.removeAnimation(forKey: "speakPulse")
    }

    // MARK: - UI SETUP

    func setupUI() {

        view.backgroundColor = .black

        // TITLE

        titleLabel.text = "Text to Speech"
        titleLabel.font = UIFont.systemFont(ofSize: 26, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center

        // SUBTITLE

        subtitleLabel.text = "Type and convert to voice"

        subtitleLabel.font = UIFont.systemFont(
            ofSize: 14,
            weight: .medium
        )

        subtitleLabel.textColor = UIColor(
            red: 180/255,
            green: 200/255,
            blue: 220/255,
            alpha: 1
        )

        subtitleLabel.textAlignment = .center

        // TEXT VIEW

        textView.backgroundColor =
            UIColor.white.withAlphaComponent(0.07)

        textView.layer.cornerRadius = 18
        textView.layer.borderWidth = 1.5

        textView.layer.borderColor =
            UIColor.white.withAlphaComponent(0.25).cgColor

        textView.textColor = .white
        textView.font = UIFont.systemFont(ofSize: 17)

        textView.delegate = self

        textView.textContainerInset = UIEdgeInsets(
            top: 18,
            left: 14,
            bottom: 18,
            right: 14
        )

        textView.keyboardAppearance = .dark

        textView.layer.shadowColor =
            UIColor.white.withAlphaComponent(0.08).cgColor

        textView.layer.shadowOpacity = 1
        textView.layer.shadowRadius = 10
        textView.layer.shadowOffset = .zero

        // OPTIONAL PERFORMANCE BOOST

        textView.layer.shouldRasterize = true
        textView.layer.rasterizationScale = UIScreen.main.scale

        // CHAR COUNT

        charCountLabel.text = "0 / 500"

        charCountLabel.font = UIFont.systemFont(
            ofSize: 12,
            weight: .medium
        )

        charCountLabel.textColor =
            UIColor.white.withAlphaComponent(0.45)

        charCountLabel.textAlignment = .right

        // WORD HIGHLIGHT

        wordHighlightLabel.text = ""

        wordHighlightLabel.font = UIFont.systemFont(
            ofSize: 15,
            weight: .semibold
        )

        wordHighlightLabel.textColor = UIColor(
            red: 140/255,
            green: 220/255,
            blue: 255/255,
            alpha: 1
        )

        wordHighlightLabel.textAlignment = .center
        wordHighlightLabel.alpha = 0

        // SPEED TITLE

        speedTitleLabel.text = "Speed: Normal 🎯"

        speedTitleLabel.font = UIFont.systemFont(
            ofSize: 13,
            weight: .medium
        )

        speedTitleLabel.textColor =
            UIColor.white.withAlphaComponent(0.7)

        speedTitleLabel.textAlignment = .center

        // SPEED SLIDER

        speedSlider.minimumValue = 0.3
        speedSlider.maximumValue = 0.7
        speedSlider.value = 0.5

        speedSlider.minimumTrackTintColor = .systemPurple

        speedSlider.maximumTrackTintColor =
            UIColor.white.withAlphaComponent(0.2)

        speedSlider.thumbTintColor = .white

        speedSlider.addTarget(
            self,
            action: #selector(sliderChanged),
            for: .valueChanged
        )

        // BUTTONS

        setupButton(
            speakButton,
            title: "▶ Speak",
            action: #selector(speakTapped)
        )

        setupButton(
            pauseButton,
            title: "⏸ Pause",
            action: #selector(pauseTapped)
        )

        setupButton(
            stopButton,
            title: "⏹ Stop",
            action: #selector(stopTapped)
        )

        // STACK

        buttonStack.axis = .horizontal
        buttonStack.spacing = 12
        buttonStack.distribution = .fillEqually

        buttonStack.addArrangedSubview(speakButton)
        buttonStack.addArrangedSubview(pauseButton)
        buttonStack.addArrangedSubview(stopButton)

        // STATUS

        statusLabel.text = "Status: Idle"

        statusLabel.textColor = .white
        statusLabel.textAlignment = .center

        statusLabel.font = UIFont.systemFont(
            ofSize: 14,
            weight: .medium
        )

        // TIP

        tipLabel.text =
            "💡 Enter a clear sentence for better voice quality"

        tipLabel.textColor = .lightGray

        tipLabel.font = UIFont.systemFont(ofSize: 13)

        tipLabel.textAlignment = .center
        tipLabel.numberOfLines = 2

        // PLACEHOLDER

        setupPlaceholder()

        // ADD SUBVIEWS

        [
            titleLabel,
            subtitleLabel,
            textView,
            charCountLabel,
            wordHighlightLabel,
            speedTitleLabel,
            speedSlider,
            buttonStack,
            statusLabel,
            tipLabel
        ].forEach {

            view.addSubview($0)

            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }

    // MARK: - BUTTON SETUP

    func setupButton(_ button: UIButton,
                     title: String,
                     action: Selector) {

        button.setTitle(title, for: .normal)

        button.titleLabel?.font = UIFont.systemFont(
            ofSize: 15,
            weight: .semibold
        )

        button.layer.cornerRadius = 20
        button.clipsToBounds = true

        button.addTarget(
            self,
            action: action,
            for: .touchUpInside
        )
    }

    // MARK: - PLACEHOLDER

    private func setupPlaceholder() {

        let label = UILabel()

        label.text = "Enter your text here..."

        label.font = UIFont.systemFont(ofSize: 17)

        label.textColor =
            UIColor.white.withAlphaComponent(0.28)

        label.numberOfLines = 0

        label.translatesAutoresizingMaskIntoConstraints = false

        textView.addSubview(label)

        NSLayoutConstraint.activate([

            label.topAnchor.constraint(
                equalTo: textView.topAnchor,
                constant: 18
            ),

            label.leadingAnchor.constraint(
                equalTo: textView.leadingAnchor,
                constant: 18
            ),

            label.trailingAnchor.constraint(
                equalTo: textView.trailingAnchor,
                constant: -18
            )
        ])

        placeholderLabel = label
    }

    // MARK: - CONSTRAINTS

    func setupConstraints() {

        NSLayoutConstraint.activate([

            titleLabel.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: 28
            ),

            titleLabel.leadingAnchor.constraint(
                equalTo: view.layoutMarginsGuide.leadingAnchor
            ),

            titleLabel.trailingAnchor.constraint(
                equalTo: view.layoutMarginsGuide.trailingAnchor
            ),

            subtitleLabel.topAnchor.constraint(
                equalTo: titleLabel.bottomAnchor,
                constant: 8
            ),

            subtitleLabel.leadingAnchor.constraint(
                equalTo: view.layoutMarginsGuide.leadingAnchor
            ),

            subtitleLabel.trailingAnchor.constraint(
                equalTo: view.layoutMarginsGuide.trailingAnchor
            ),

            textView.topAnchor.constraint(
                equalTo: subtitleLabel.bottomAnchor,
                constant: 36
            ),

            textView.leadingAnchor.constraint(
                equalTo: view.layoutMarginsGuide.leadingAnchor
            ),

            textView.trailingAnchor.constraint(
                equalTo: view.layoutMarginsGuide.trailingAnchor
            ),

            textView.heightAnchor.constraint(
                equalTo: view.heightAnchor,
                multiplier: 0.28
            ),

            charCountLabel.topAnchor.constraint(
                equalTo: textView.bottomAnchor,
                constant: 6
            ),

            charCountLabel.trailingAnchor.constraint(
                equalTo: view.layoutMarginsGuide.trailingAnchor
            ),

            wordHighlightLabel.topAnchor.constraint(
                equalTo: charCountLabel.bottomAnchor,
                constant: 10
            ),

            wordHighlightLabel.leadingAnchor.constraint(
                equalTo: view.layoutMarginsGuide.leadingAnchor
            ),

            wordHighlightLabel.trailingAnchor.constraint(
                equalTo: view.layoutMarginsGuide.trailingAnchor
            ),

            wordHighlightLabel.heightAnchor.constraint(
                equalToConstant: 24
            ),

            speedTitleLabel.topAnchor.constraint(
                equalTo: wordHighlightLabel.bottomAnchor,
                constant: 18
            ),

            speedTitleLabel.leadingAnchor.constraint(
                equalTo: view.layoutMarginsGuide.leadingAnchor
            ),

            speedTitleLabel.trailingAnchor.constraint(
                equalTo: view.layoutMarginsGuide.trailingAnchor
            ),

            speedSlider.topAnchor.constraint(
                equalTo: speedTitleLabel.bottomAnchor,
                constant: 10
            ),

            speedSlider.leadingAnchor.constraint(
                equalTo: view.layoutMarginsGuide.leadingAnchor
            ),

            speedSlider.trailingAnchor.constraint(
                equalTo: view.layoutMarginsGuide.trailingAnchor
            ),

            buttonStack.topAnchor.constraint(
                equalTo: speedSlider.bottomAnchor,
                constant: 28
            ),

            buttonStack.leadingAnchor.constraint(
                equalTo: view.layoutMarginsGuide.leadingAnchor
            ),

            buttonStack.trailingAnchor.constraint(
                equalTo: view.layoutMarginsGuide.trailingAnchor
            ),

            buttonStack.heightAnchor.constraint(
                equalToConstant: 52
            ),

            statusLabel.topAnchor.constraint(
                equalTo: buttonStack.bottomAnchor,
                constant: 16
            ),

            statusLabel.leadingAnchor.constraint(
                equalTo: view.layoutMarginsGuide.leadingAnchor
            ),

            statusLabel.trailingAnchor.constraint(
                equalTo: view.layoutMarginsGuide.trailingAnchor
            ),

            tipLabel.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -16
            ),

            tipLabel.leadingAnchor.constraint(
                equalTo: view.layoutMarginsGuide.leadingAnchor
            ),

            tipLabel.trailingAnchor.constraint(
                equalTo: view.layoutMarginsGuide.trailingAnchor
            )
        ])
    }

    // MARK: - ACTIONS

    @objc func speakTapped() {

        animateTap(speakButton)

        let text =
            textView.text.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !text.isEmpty else {

            shakeView(statusLabel)

            statusLabel.text =
                "⚠️ Please enter text first"

            return
        }

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)

        utterance.voice =
            AVSpeechSynthesisVoice(language: "en-US")

        utterance.rate = speedSlider.value

        synthesizer.speak(utterance)

        animateSpeakingPulse(true)
    }

    @objc func pauseTapped() {

        animateTap(pauseButton)

        if synthesizer.isSpeaking {

            synthesizer.pauseSpeaking(at: .word)

            animateSpeakingPulse(false)

        } else if synthesizer.isPaused {

            synthesizer.continueSpeaking()

            animateSpeakingPulse(true)
        }
    }

    @objc func stopTapped() {

        animateTap(stopButton)

        synthesizer.stopSpeaking(at: .immediate)

        animateSpeakingPulse(false)

        hideWordHighlight()

        statusLabel.text = "Status: Stopped ⏹"
    }

    @objc func sliderChanged() {

        let val = speedSlider.value

        switch val {

        case ..<0.38:
            speedTitleLabel.text = "Speed: Slow 🐢"

        case 0.38..<0.55:
            speedTitleLabel.text = "Speed: Normal 🎯"

        default:
            speedTitleLabel.text = "Speed: Fast ⚡️"
        }
    }

    // MARK: - SPEECH DELEGATES

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                           didStart utterance: AVSpeechUtterance) {

        DispatchQueue.main.async {

            self.statusLabel.text =
                "Status: Speaking... 🔊"

            self.animateStatusLabel()
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                           didFinish utterance: AVSpeechUtterance) {

        DispatchQueue.main.async {

            self.statusLabel.text =
                "Status: Finished ✅"

            self.animateSpeakingPulse(false)

            self.hideWordHighlight()
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                           willSpeakRangeOfSpeechString characterRange: NSRange,
                           utterance: AVSpeechUtterance) {

        let nsString =
            utterance.speechString as NSString

        if characterRange.location +
            characterRange.length <= nsString.length {

            let word =
                nsString.substring(with: characterRange)

            showWordHighlight(word)
        }
    }

    // MARK: - WORD HIGHLIGHT

    private func showWordHighlight(_ word: String) {

        wordHighlightLabel.text = "▶ \(word)"

        UIView.animate(withDuration: 0.12) {

            self.wordHighlightLabel.alpha = 1

            self.wordHighlightLabel.transform =
                CGAffineTransform(scaleX: 1.08, y: 1.08)

        } completion: { _ in

            UIView.animate(withDuration: 0.12) {

                self.wordHighlightLabel.transform =
                    .identity
            }
        }
    }

    private func hideWordHighlight() {

        UIView.animate(withDuration: 0.3) {

            self.wordHighlightLabel.alpha = 0

        } completion: { _ in

            self.wordHighlightLabel.text = ""
        }
    }

    // MARK: - TEXTVIEW DELEGATES

    func textViewDidBeginEditing(_ textView: UITextView) {

        UIView.animate(withDuration: 0.25) {

            textView.layer.borderColor =
                UIColor.systemPurple
                .withAlphaComponent(0.8).cgColor

            textView.layer.borderWidth = 2
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {

        placeholderLabel?.isHidden =
            !textView.text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty

        UIView.animate(withDuration: 0.25) {

            textView.layer.borderColor =
                UIColor.white
                .withAlphaComponent(0.25).cgColor

            textView.layer.borderWidth = 1.5
        }
    }

    func textViewDidChange(_ textView: UITextView) {

        placeholderLabel?.isHidden =
            !textView.text.isEmpty

        let length = textView.text.count

        charCountLabel.text =
            "\(min(length, 500)) / 500"

        if length > 500 {

            charCountLabel.textColor = .systemRed

        } else if length > 450 {

            charCountLabel.textColor = .systemOrange

        } else {

            charCountLabel.textColor =
                UIColor.white.withAlphaComponent(0.45)
        }
    }

    // MARK: - KEYBOARD

    @objc func keyboardShow(notification: Notification) {

        UIView.animate(withDuration: 0.3) {

            self.view.transform =
                CGAffineTransform(
                    translationX: 0,
                    y: -120
                )
        }
    }

    @objc func keyboardHide(notification: Notification) {

        UIView.animate(withDuration: 0.3) {

            self.view.transform = .identity
        }
    }

    // MARK: - GRADIENTS

    func applyButtonGradients() {

        [speakButton, pauseButton, stopButton].forEach {

            button in

            let gradient = CAGradientLayer()

            gradient.colors = [
                UIColor.systemPurple.cgColor,
                UIColor.systemBlue.cgColor
            ]

            gradient.frame = button.bounds

            gradient.cornerRadius = 20

            button.layer.insertSublayer(gradient, at: 0)

            button.setTitleColor(.white, for: .normal)
        }
    }

    func applyBackgroundGradient() {

        if backgroundGradient == nil {

            let gradient = CAGradientLayer()

            gradient.colors = [

                UIColor(
                    red: 15/255,
                    green: 32/255,
                    blue: 39/255,
                    alpha: 1
                ).cgColor,

                UIColor(
                    red: 32/255,
                    green: 58/255,
                    blue: 67/255,
                    alpha: 1
                ).cgColor,

                UIColor(
                    red: 44/255,
                    green: 83/255,
                    blue: 100/255,
                    alpha: 1
                ).cgColor
            ]

            gradient.frame = view.bounds

            view.layer.insertSublayer(gradient, at: 0)

            backgroundGradient = gradient
        }

        backgroundGradient?.frame = view.bounds
    }

    // MARK: - ANIMATIONS

    func animateEntrance() {

        let elements: [UIView] = [

            titleLabel,
            subtitleLabel,
            textView,
            charCountLabel,
            speedTitleLabel,
            speedSlider,
            buttonStack,
            statusLabel,
            tipLabel
        ]

        for (i, v) in elements.enumerated() {

            v.alpha = 0

            v.transform =
                CGAffineTransform(
                    translationX: 0,
                    y: 30
                )

            UIView.animate(
                withDuration: 0.7,
                delay: Double(i) * 0.08,
                usingSpringWithDamping: 0.8,
                initialSpringVelocity: 0.5
            ) {

                v.alpha = 1
                v.transform = .identity
            }
        }
    }

    func animateTap(_ button: UIButton) {

        UIView.animate(withDuration: 0.1) {

            button.transform =
                CGAffineTransform(scaleX: 0.92, y: 0.92)

        } completion: { _ in

            UIView.animate(withDuration: 0.15) {

                button.transform = .identity
            }
        }
    }

    func startTextViewIdleAnimation() {

        let pulse =
            CABasicAnimation(keyPath: "borderColor")

        pulse.fromValue =
            UIColor.white
            .withAlphaComponent(0.2).cgColor

        pulse.toValue =
            UIColor.systemPurple
            .withAlphaComponent(0.45).cgColor

        pulse.duration = 2.5
        pulse.autoreverses = true
        pulse.repeatCount = .infinity

        textView.layer.add(pulse, forKey: "borderPulse")
    }

    func animateSpeakingPulse(_ on: Bool) {

        if on {

            let pulse =
                CABasicAnimation(
                    keyPath: "transform.scale"
                )

            pulse.fromValue = 1.0
            pulse.toValue = 1.04

            pulse.duration = 0.6

            pulse.autoreverses = true
            pulse.repeatCount = .infinity

            speakButton.layer.add(
                pulse,
                forKey: "speakPulse"
            )

        } else {

            speakButton.layer.removeAnimation(
                forKey: "speakPulse"
            )
        }
    }

    func animateStatusLabel() {

        UIView.animate(withDuration: 0.2) {

            self.statusLabel.transform =
                CGAffineTransform(scaleX: 1.06, y: 1.06)

        } completion: { _ in

            UIView.animate(withDuration: 0.2) {

                self.statusLabel.transform = .identity
            }
        }
    }

    func shakeView(_ view: UIView) {

        let shake =
            CAKeyframeAnimation(
                keyPath: "transform.translation.x"
            )

        shake.duration = 0.4

        shake.values = [-10, 10, -8, 8, -4, 4, 0]

        view.layer.add(shake, forKey: "shake")
    }

    // MARK: - AUDIO SESSION

    func setupAudioSession() {

        let session =
            AVAudioSession.sharedInstance()

        do {

            try session.setCategory(
                .playback,
                mode: .spokenAudio,
                options: [.duckOthers]
            )

            try session.setActive(true)

        } catch {

            print("Audio session error:", error)
        }
    }
}

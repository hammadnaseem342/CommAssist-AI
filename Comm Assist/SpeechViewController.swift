import UIKit
import Speech
import AVFoundation

class SpeechViewController: UIViewController, SFSpeechRecognizerDelegate {

    // MARK: - UI Elements
    let titleLabel    = UILabel()
    let subtitleLabel = UILabel()
    let micButton     = UIButton()
    let textView      = UITextView()
    let resetButton   = UIButton()
    let tipLabel      = UILabel()

    // New UI additions
    let statusLabel      = UILabel()       // shows Listening / Idle
    let wordCountLabel   = UILabel()       // shows word count
    let micRingView      = UIView()        // animated ring around mic
    let micRingView2     = UIView()        // second ring for layered effect

    var waveLayers: [CALayer] = []

    // MARK: - Speech Properties
    var speechRecognizer    = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    let audioEngine         = AVAudioEngine()
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask:    SFSpeechRecognitionTask?

    private var backgroundGradient: CAGradientLayer?
    private var isRecording = false
    var textViewHeightConstraint: NSLayoutConstraint!

    // Particle layers for ambient animation
    private var particleLayers: [CAShapeLayer] = []

    // MARK: - LIFECYCLE

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        requestPermissions()
        addFloatingParticles()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        applyBackgroundGradient()
        applyButtonGradient()
        micRingView.layer.cornerRadius  = micRingView.bounds.width / 2
        micRingView2.layer.cornerRadius = micRingView2.bounds.width / 2
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateEntrance()
        startIdleRingPulse()
    }

    // MARK: - UI SETUP

    func setupUI() {

        // ── Title ─────────────────────────────────────────────
        titleLabel.text          = "Speech to Text"
        titleLabel.font          = UIFont.systemFont(ofSize: 26, weight: .bold)
        titleLabel.textColor     = .white
        titleLabel.textAlignment = .center

        // ── Subtitle ──────────────────────────────────────────
        subtitleLabel.text      = "Tap and start speaking"
        subtitleLabel.font      = UIFont.systemFont(ofSize: 14, weight: .medium)
        subtitleLabel.textColor = UIColor(red: 180/255, green: 200/255, blue: 220/255, alpha: 1)
        subtitleLabel.textAlignment = .center

        // ── Mic outer ring 2 (furthest) ───────────────────────
        micRingView2.backgroundColor  = .clear
        micRingView2.layer.borderColor = UIColor.systemPurple.withAlphaComponent(0.15).cgColor
        micRingView2.layer.borderWidth = 2
        micRingView2.alpha            = 0

        // ── Mic outer ring 1 ──────────────────────────────────
        micRingView.backgroundColor   = .clear
        micRingView.layer.borderColor = UIColor.systemPurple.withAlphaComponent(0.3).cgColor
        micRingView.layer.borderWidth = 2
        micRingView.alpha             = 0

        // ── Mic Button ────────────────────────────────────────
        micButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
        micButton.tintColor         = .white
        micButton.layer.cornerRadius = 40
        micButton.imageView?.contentMode = .scaleAspectFit
        micButton.addTarget(self, action: #selector(micTapped), for: .touchUpInside)

        // ── Status Label ──────────────────────────────────────
        statusLabel.text          = "● Idle"
        statusLabel.font          = UIFont.systemFont(ofSize: 14, weight: .semibold)
        statusLabel.textColor     = UIColor.white.withAlphaComponent(0.55)
        statusLabel.textAlignment = .center

        // ── Text View ─────────────────────────────────────────
        textView.backgroundColor    = UIColor.black.withAlphaComponent(0.3)
        textView.layer.cornerRadius = 15
        textView.layer.borderWidth  = 1.5
        textView.layer.borderColor  = UIColor.white.withAlphaComponent(0.15).cgColor
        textView.textColor          = .white
        textView.font               = UIFont.systemFont(ofSize: 16)
        textView.isEditable         = false
        textView.text               = "Your speech will appear here..."
        textView.textColor          = UIColor.white.withAlphaComponent(0.35)

        // ── Word Count ────────────────────────────────────────
        wordCountLabel.text          = "0 words"
        wordCountLabel.font          = UIFont.systemFont(ofSize: 12, weight: .medium)
        wordCountLabel.textColor     = UIColor.white.withAlphaComponent(0.4)
        wordCountLabel.textAlignment = .right

        // ── Reset Button ──────────────────────────────────────
        resetButton.setTitle("⟳  Reset", for: .normal)
        resetButton.titleLabel?.font    = UIFont.systemFont(ofSize: 15, weight: .medium)
        resetButton.layer.cornerRadius  = 18
        resetButton.layer.borderColor   = UIColor.white.withAlphaComponent(0.25).cgColor
        resetButton.layer.borderWidth   = 1
        resetButton.contentEdgeInsets   = UIEdgeInsets(top: 8, left: 22, bottom: 8, right: 22)
        resetButton.addTarget(self, action: #selector(resetTapped), for: .touchUpInside)

        // ── Tip Label ─────────────────────────────────────────
        tipLabel.text          = "💡 Speak clearly for better results"
        tipLabel.textColor     = .lightGray
        tipLabel.font          = UIFont.systemFont(ofSize: 13)
        tipLabel.textAlignment = .center

        // ── Add all views ─────────────────────────────────────
        [titleLabel, subtitleLabel,
         micRingView2, micRingView, micButton,
         statusLabel, textView, wordCountLabel,
         resetButton, tipLabel].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }

    // MARK: - CONSTRAINTS

    func setupConstraints() {

        textViewHeightConstraint = textView.heightAnchor.constraint(equalToConstant: 140)

        NSLayoutConstraint.activate([

            titleLabel.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 15),
            titleLabel.leadingAnchor.constraint(
                equalTo: view.layoutMarginsGuide.leadingAnchor),
            titleLabel.trailingAnchor.constraint(
                equalTo: view.layoutMarginsGuide.trailingAnchor),

            subtitleLabel.topAnchor.constraint(
                equalTo: titleLabel.bottomAnchor, constant: 6),
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            // Outer ring 2 — centred behind mic, 20pt larger on each side
            micRingView2.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            micRingView2.centerYAnchor.constraint(
                equalTo: micButton.centerYAnchor),
            micRingView2.widthAnchor.constraint(equalToConstant: 140),
            micRingView2.heightAnchor.constraint(equalToConstant: 140),

            // Outer ring 1
            micRingView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            micRingView.centerYAnchor.constraint(
                equalTo: micButton.centerYAnchor),
            micRingView.widthAnchor.constraint(equalToConstant: 110),
            micRingView.heightAnchor.constraint(equalToConstant: 110),

            // Mic button
            micButton.topAnchor.constraint(
                equalTo: subtitleLabel.bottomAnchor, constant: 30),
            micButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            micButton.widthAnchor.constraint(equalToConstant: 80),
            micButton.heightAnchor.constraint(equalToConstant: 80),

            // Status
            statusLabel.topAnchor.constraint(
                equalTo: micButton.bottomAnchor, constant: 14),
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            // Text view
            textView.topAnchor.constraint(
                equalTo: statusLabel.bottomAnchor, constant: 16),
            textView.leadingAnchor.constraint(
                equalTo: view.layoutMarginsGuide.leadingAnchor),
            textView.trailingAnchor.constraint(
                equalTo: view.layoutMarginsGuide.trailingAnchor),
            textViewHeightConstraint,

            // Word count
            wordCountLabel.topAnchor.constraint(
                equalTo: textView.bottomAnchor, constant: 5),
            wordCountLabel.trailingAnchor.constraint(
                equalTo: view.layoutMarginsGuide.trailingAnchor),

            // Reset
            resetButton.topAnchor.constraint(
                equalTo: wordCountLabel.bottomAnchor, constant: 14),
            resetButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            // Tip
            tipLabel.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            tipLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }

    // MARK: - MIC ACTION

    @objc func micTapped() {
        animateTap(micButton)

        if isRecording {
            stopRecording()
            setIdleState()
        } else {
            startRecording()
            setListeningState()
        }

        isRecording.toggle()
    }

    // MARK: - STATE CHANGES

    private func setListeningState() {
        // Button icon → stop
        micButton.setImage(UIImage(systemName: "stop.fill"), for: .normal)

        // Status label
        statusLabel.text      = "● Listening..."
        statusLabel.textColor = UIColor(red: 100/255, green: 220/255, blue: 150/255, alpha: 1)
        animateStatusPop()

        // textView placeholder disappears
        if textView.textColor == UIColor.white.withAlphaComponent(0.35) {
            textView.text      = ""
            textView.textColor = .white
        }

        // Border glows
        UIView.animate(withDuration: 0.3) {
            self.textView.layer.borderColor =
                UIColor.systemPurple.withAlphaComponent(0.6).cgColor
            self.textView.layer.borderWidth = 2
        }

        // Rings & pulse
        startListeningRingAnimation()
        startMicPulse()
        flashGlow()
    }

    private func setIdleState() {
        micButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)

        statusLabel.text      = "● Idle"
        statusLabel.textColor = UIColor.white.withAlphaComponent(0.55)
        animateStatusPop()

        UIView.animate(withDuration: 0.3) {
            self.textView.layer.borderColor =
                UIColor.white.withAlphaComponent(0.15).cgColor
            self.textView.layer.borderWidth = 1.5
        }

        stopListeningRingAnimation()
        stopMicPulse()
        startIdleRingPulse()
    }

    // MARK: - SPEECH LOGIC (unchanged)

    func startRecording() {
        recognitionTask?.cancel()
        recognitionTask = nil

        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.record, mode: .measurement,
                                      options: .duckOthers)
        try? audioSession.setActive(true,
                                    options: .notifyOthersOnDeactivation)

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }

        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)

        recognitionTask = speechRecognizer?.recognitionTask(
            with: recognitionRequest) { [weak self] result, error in
            guard let self else { return }
            if let result = result {
                DispatchQueue.main.async {
                    self.textView.text  = result.bestTranscription.formattedString
                    self.textView.textColor = .white
                    self.adjustTextView()
                    self.adjustFontSize()
                    self.updateWordCount()
                    self.animateNewWord()
                }
            }
            if error != nil { self.stopRecording() }
        }

        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) {
            buffer, _ in recognitionRequest.append(buffer)
        }

        audioEngine.prepare()
        try? audioEngine.start()
    }

    func stopRecording() {
        if audioEngine.isRunning { audioEngine.stop() }
        recognitionRequest?.endAudio()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionTask?.cancel()
        recognitionTask = nil
    }

    @objc func resetTapped() {
        animateTap(resetButton)
        flashResetGlow()

        UIView.animate(withDuration: 0.2, animations: {
            self.textView.alpha = 0
        }) { _ in
            self.textView.text      = "Your speech will appear here..."
            self.textView.textColor = UIColor.white.withAlphaComponent(0.35)
            self.adjustTextView()
            self.wordCountLabel.text = "0 words"
            UIView.animate(withDuration: 0.3) {
                self.textView.alpha = 1
            }
        }
    }

    func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { _ in }
        AVAudioApplication.requestRecordPermission { _ in }
    }

    // MARK: - GRADIENTS (unchanged)

    func applyBackgroundGradient() {
        backgroundGradient?.removeFromSuperlayer()
        let gradient    = CAGradientLayer()
        gradient.colors = [
            UIColor.black.cgColor,
            UIColor(red: 32/255, green: 58/255, blue: 67/255, alpha: 1).cgColor,
            UIColor(red: 44/255, green: 83/255, blue: 100/255, alpha: 1).cgColor
        ]
        gradient.frame = view.bounds
        view.layer.insertSublayer(gradient, at: 0)
        backgroundGradient = gradient
    }

    func applyButtonGradient() {
        micButton.layer.sublayers?.removeAll(where: { $0 is CAGradientLayer })
        let gradient          = CAGradientLayer()
        gradient.colors       = [UIColor.systemPurple.cgColor,
                                  UIColor.systemBlue.cgColor]
        gradient.frame        = micButton.bounds
        gradient.cornerRadius = 40
        micButton.layer.insertSublayer(gradient, at: 0)
    }

    // MARK: - HELPERS

    func adjustFontSize() {
        let count = textView.text.count
        textView.font = UIFont.systemFont(ofSize: count < 100 ? 18 : 14)
    }

    func adjustTextView() {
        let size      = CGSize(width: textView.frame.width, height: .infinity)
        let estimated = textView.sizeThatFits(size)
        textViewHeightConstraint.constant = min(estimated.height, 250)
        UIView.animate(withDuration: 0.2) { self.view.layoutIfNeeded() }
    }

    func updateWordCount() {
        let words = textView.text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: " ").count
        wordCountLabel.text = "\(words) word\(words == 1 ? "" : "s")"
        UIView.animate(withDuration: 0.15, animations: {
            self.wordCountLabel.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        }) { _ in
            UIView.animate(withDuration: 0.15) {
                self.wordCountLabel.transform = .identity
            }
        }
    }

    // MARK: - ANIMATIONS

    func animateEntrance() {
        let views: [UIView] = [titleLabel, subtitleLabel, micRingView,
                                micButton, statusLabel, textView,
                                wordCountLabel, resetButton, tipLabel]
        for (i, v) in views.enumerated() {
            v.alpha     = 0
            v.transform = CGAffineTransform(translationX: 0, y: 28)
            UIView.animate(withDuration: 0.7,
                           delay: Double(i) * 0.07,
                           usingSpringWithDamping: 0.8,
                           initialSpringVelocity: 0.4) {
                v.alpha     = 1
                v.transform = .identity
            }
        }
    }

    func animateTap(_ button: UIButton) {
        UIView.animate(withDuration: 0.1, animations: {
            button.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                button.transform = .identity
            }
        }
    }

    // Gentle idle ring pulse (both rings slowly appear/disappear)
    func startIdleRingPulse() {
        micRingView.layer.removeAnimation(forKey: "listeningPulse")
        micRingView2.layer.removeAnimation(forKey: "listeningPulse2")

        let pulse          = CABasicAnimation(keyPath: "opacity")
        pulse.fromValue    = 0.0
        pulse.toValue      = 0.6
        pulse.duration     = 2.2
        pulse.autoreverses = true
        pulse.repeatCount  = .infinity
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        micRingView.layer.add(pulse, forKey: "idlePulse")
        micRingView.alpha = 1

        let pulse2          = pulse.copy() as! CABasicAnimation
        pulse2.timeOffset   = 1.1
        micRingView2.layer.add(pulse2, forKey: "idlePulse2")
        micRingView2.alpha = 1
    }

    // Active listening: rings expand outward continuously
    func startListeningRingAnimation() {
        micRingView.layer.removeAnimation(forKey: "idlePulse")
        micRingView2.layer.removeAnimation(forKey: "idlePulse2")

        for (ring, delay) in [(micRingView, 0.0), (micRingView2, 0.35)] {
            let scale          = CABasicAnimation(keyPath: "transform.scale")
            scale.fromValue    = 1.0
            scale.toValue      = 1.25
            scale.duration     = 0.9
            scale.autoreverses = true
            scale.repeatCount  = .infinity
            scale.beginTime    = CACurrentMediaTime() + delay
            scale.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

            let opacity          = CABasicAnimation(keyPath: "opacity")
            opacity.fromValue    = 0.8
            opacity.toValue      = 0.2
            opacity.duration     = 0.9
            opacity.autoreverses = true
            opacity.repeatCount  = .infinity
            opacity.beginTime    = scale.beginTime
            opacity.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

            ring.layer.add(scale,   forKey: "listeningPulse")
            ring.layer.add(opacity, forKey: "listeningOpacity")
            ring.alpha = 1
        }
    }

    func stopListeningRingAnimation() {
        for ring in [micRingView, micRingView2] {
            ring.layer.removeAnimation(forKey: "listeningPulse")
            ring.layer.removeAnimation(forKey: "listeningOpacity")
        }
    }

    // Mic button heartbeat while listening
    func startMicPulse() {
        let pulse          = CABasicAnimation(keyPath: "transform.scale")
        pulse.fromValue    = 1.0
        pulse.toValue      = 1.06
        pulse.duration     = 0.55
        pulse.autoreverses = true
        pulse.repeatCount  = .infinity
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        micButton.layer.add(pulse, forKey: "micPulse")
    }

    func stopMicPulse() {
        micButton.layer.removeAnimation(forKey: "micPulse")
    }

    // Glow burst on mic button when recording starts
    func flashGlow() {
        let glow            = CALayer()
        glow.frame          = micButton.bounds.insetBy(dx: -12, dy: -12)
        glow.cornerRadius   = 52
        glow.backgroundColor = UIColor.clear.cgColor
        glow.shadowColor    = UIColor.systemPurple.cgColor
        glow.shadowOpacity  = 0.9
        glow.shadowRadius   = 22
        glow.shadowOffset   = .zero
        micButton.layer.insertSublayer(glow, below: micButton.imageView?.layer)

        let fade            = CABasicAnimation(keyPath: "shadowOpacity")
        fade.fromValue      = 0.9
        fade.toValue        = 0.0
        fade.duration       = 0.8
        fade.timingFunction = CAMediaTimingFunction(name: .easeOut)

        CATransaction.begin()
        CATransaction.setCompletionBlock { glow.removeFromSuperlayer() }
        glow.add(fade, forKey: "glowFade")
        CATransaction.commit()
    }

    // Glow on reset
    func flashResetGlow() {
        let glow            = CALayer()
        glow.frame          = resetButton.bounds.insetBy(dx: -6, dy: -6)
        glow.cornerRadius   = 22
        glow.backgroundColor = UIColor.clear.cgColor
        glow.shadowColor    = UIColor.systemBlue.cgColor
        glow.shadowOpacity  = 0.8
        glow.shadowRadius   = 14
        glow.shadowOffset   = .zero
        resetButton.layer.addSublayer(glow)

        let fade       = CABasicAnimation(keyPath: "shadowOpacity")
        fade.fromValue = 0.8
        fade.toValue   = 0.0
        fade.duration  = 0.6

        CATransaction.begin()
        CATransaction.setCompletionBlock { glow.removeFromSuperlayer() }
        glow.add(fade, forKey: "glowFade")
        CATransaction.commit()
    }

    // Status label pop
    func animateStatusPop() {
        UIView.animate(withDuration: 0.18, animations: {
            self.statusLabel.transform = CGAffineTransform(scaleX: 1.12, y: 1.12)
        }) { _ in
            UIView.animate(withDuration: 0.18) {
                self.statusLabel.transform = .identity
            }
        }
    }

    // New word pop — tiny scale bounce on textView
    func animateNewWord() {
        UIView.animate(withDuration: 0.1, animations: {
            self.textView.transform = CGAffineTransform(scaleX: 1.012, y: 1.012)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.textView.transform = .identity
            }
        }
    }

    // Floating ambient particles (subtle, same as main screen)
    func addFloatingParticles() {
        for _ in 0..<8 {
            let size  = CGFloat.random(in: 2...4)
            let layer = CAShapeLayer()
            layer.path = UIBezierPath(
                ovalIn: CGRect(x: 0, y: 0, width: size, height: size)).cgPath
            layer.fillColor = UIColor.white.withAlphaComponent(
                CGFloat.random(in: 0.04...0.10)).cgColor
            layer.position = CGPoint(
                x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                y: UIScreen.main.bounds.height + size)
            view.layer.addSublayer(layer)
            particleLayers.append(layer)
            animateParticle(layer)
        }
    }

    private func animateParticle(_ layer: CAShapeLayer) {
        let duration  = Double.random(in: 7...15)
        let delay     = Double.random(in: 0...6)
        let startX    = layer.position.x
        let endX      = startX + CGFloat.random(in: -40...40)
        let screenH   = UIScreen.main.bounds.height

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak layer, weak self] in
            guard let layer, let self else { return }

            let move         = CABasicAnimation(keyPath: "position")
            move.fromValue   = CGPoint(x: startX, y: screenH + 10)
            move.toValue     = CGPoint(x: endX, y: -20)
            move.duration    = duration

            let fade         = CABasicAnimation(keyPath: "opacity")
            fade.fromValue   = 0.1
            fade.toValue     = 0.0
            fade.duration    = duration

            let group        = CAAnimationGroup()
            group.animations = [move, fade]
            group.duration   = duration
            group.isRemovedOnCompletion = true

            CATransaction.begin()
            CATransaction.setCompletionBlock { [weak layer, weak self] in
                guard let layer, let self else { return }
                layer.position = CGPoint(
                    x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                    y: screenH + 10)
                self.animateParticle(layer)
            }
            layer.add(group, forKey: "float")
            CATransaction.commit()
        }
    }

    // Stubs kept for compatibility
    func setupWaveAnimation() {}
    func startWaveAnimation() {}
    func stopWaveAnimation() {}
}

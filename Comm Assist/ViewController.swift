import UIKit
import AVFoundation
import AVFAudio

class ViewController: UIViewController {

    // MARK: - OUTLETS

    @IBOutlet weak var textOutlet: UIButton!
    @IBOutlet weak var handOutlet: UIButton!
    @IBOutlet weak var commLabel: UILabel!
    @IBOutlet weak var speechOutlet: UIButton!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!

    // MARK: - PRIVATE PROPERTIES

    private var backgroundGradient: CAGradientLayer?
    private let synthesizer = AVSpeechSynthesizer()
    private var hasSpokenWelcome = false

    // Prevent duplicate layers/animations
    private var particlesAdded = false
    private var gradientsApplied = false

    // Floating particles
    private var particleLayers: [CAShapeLayer] = []

    // Speech completion
    private var speechCompletionHandler: (() -> Void)?

    // MARK: - LIFECYCLE

    override func viewDidLoad() {
        super.viewDidLoad()

        configureAudioSession()

        setupUI()
        addIcons()

        [commLabel, subtitleLabel, infoLabel,
         handOutlet, speechOutlet, textOutlet].forEach {
            $0?.translatesAutoresizingMaskIntoConstraints = false
        }

        setupConstraints()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        applyBackgroundGradient()

        if !gradientsApplied {
            gradientsApplied = true
            applyButtonGradients()
        }

        if !particlesAdded {
            particlesAdded = true
            addFloatingParticles()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        animateEntrance()
        addPulseAnimation(view: commLabel)
        animateSubtitle()
        animateFeaturesLabel()
        addIdleButtonAnimation()

        // Speak only once
        if !hasSpokenWelcome {
            hasSpokenWelcome = true
            speakWelcomeSequence()
        }
    }

    // MARK: - AUDIO SESSION

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()

            try session.setCategory(
                .playback,
                mode: .default,
                options: [.duckOthers]
            )

            try session.setActive(true)

        } catch {
            print("Audio session error:", error)
        }
    }

    // MARK: - WELCOME SPEECH

    private func speakWelcomeSequence() {

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {

            self.speak(
                "Welcome to A I Communication Assistant.",
                rate: 0.48,
                pitch: 1.1
            ) {

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {

                    self.speak(
                        "Breaking barriers between minds. Use hand gestures, your voice, or text and let A I turn every sign into spoken words.",
                        rate: 0.44,
                        pitch: 1.05,
                        completion: nil
                    )
                }
            }
        }
    }

    // MARK: - BUTTON SPEECH

    private func announceMode(_ message: String) {
        synthesizer.stopSpeaking(at: .immediate)
        speak(message, rate: 0.50, pitch: 1.1, completion: nil)
    }

    // MARK: - SPEECH HELPER

    private func speak(_ text: String,
                       rate: Float = 0.50,
                       pitch: Float = 1.0,
                       completion: (() -> Void)?) {

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = rate
        utterance.pitchMultiplier = pitch
        utterance.volume = 1.0
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")

        if let completion = completion {
            speechCompletionHandler = completion
            synthesizer.delegate = self
        }

        synthesizer.speak(utterance)
    }

    // MARK: - UI SETUP

    func setupUI() {
        styleTitle()
        styleSubtitle()
        styleButtons()
        styleBottomInfo()
    }

    func styleTitle() {
        commLabel.text = "COMM AI ASSISTANT"
        commLabel.textColor = .white
        commLabel.font = UIFont.systemFont(ofSize: 30, weight: .bold)
        commLabel.textAlignment = .center
        commLabel.alpha = 0
    }

    func styleSubtitle() {

        subtitleLabel.text = "Helping you communicate smarter"
        subtitleLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)

        subtitleLabel.textColor = UIColor(
            red: 180/255,
            green: 200/255,
            blue: 220/255,
            alpha: 1
        )

        subtitleLabel.textAlignment = .center
        subtitleLabel.alpha = 0

        let attributed = NSMutableAttributedString(
            string: subtitleLabel.text ?? ""
        )

        attributed.addAttribute(
            .kern,
            value: 0.8,
            range: NSRange(location: 0, length: attributed.length)
        )

        subtitleLabel.attributedText = attributed
    }

    func styleButtons() {

        for button in [handOutlet, speechOutlet, textOutlet] {

            guard let btn = button else { continue }

            btn.layer.cornerRadius = 20
            btn.clipsToBounds = true

            btn.setTitleColor(.white, for: .normal)

            btn.titleLabel?.font = UIFont.systemFont(
                ofSize: 16,
                weight: .semibold
            )

            btn.layer.shadowColor = UIColor.black.cgColor
            btn.layer.shadowOpacity = 0.3
            btn.layer.shadowOffset = CGSize(width: 0, height: 5)
            btn.layer.shadowRadius = 8

            btn.alpha = 0
        }
    }

    func applyButtonGradients() {

        for button in [handOutlet, speechOutlet, textOutlet] {

            guard let btn = button else { continue }

            btn.layer.sublayers?.removeAll(where: {
                $0 is CAGradientLayer
            })

            let gradient = CAGradientLayer()

            gradient.colors = [
                UIColor.systemPurple.cgColor,
                UIColor.systemBlue.cgColor
            ]

            gradient.startPoint = CGPoint(x: 0, y: 0)
            gradient.endPoint = CGPoint(x: 1, y: 1)

            gradient.frame = btn.bounds
            gradient.cornerRadius = 20

            btn.layer.insertSublayer(gradient, at: 0)
        }
    }

    func applyBackgroundGradient() {

        backgroundGradient?.removeFromSuperlayer()

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

        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)

        gradient.frame = view.bounds

        view.layer.insertSublayer(gradient, at: 0)

        backgroundGradient = gradient
    }

    func addIcons() {

        handOutlet.setImage(
            UIImage(systemName: "hand.raised.fill"),
            for: .normal
        )

        speechOutlet.setImage(
            UIImage(systemName: "mic.fill"),
            for: .normal
        )

        textOutlet.setImage(
            UIImage(systemName: "speaker.wave.2.fill"),
            for: .normal
        )

        [handOutlet, speechOutlet, textOutlet].forEach {
            $0?.tintColor = .white
        }

        handOutlet.imageEdgeInsets =
            UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)

        speechOutlet.imageEdgeInsets =
            UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)

        textOutlet.imageEdgeInsets =
            UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)
    }

    func styleBottomInfo() {

        let text = "FEATURES"

        let attributed = NSMutableAttributedString(string: text)

        let para = NSMutableParagraphStyle()
        para.alignment = .center
        para.lineSpacing = 2

        attributed.addAttributes([
            .paragraphStyle: para,
            .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
            .foregroundColor: UIColor(
                red: 140/255,
                green: 220/255,
                blue: 255/255,
                alpha: 0.95
            ),
            .kern: 2.2
        ], range: NSRange(location: 0, length: attributed.length))

        infoLabel.attributedText = attributed
        infoLabel.alpha = 0
    }

    // MARK: - CONSTRAINTS

    func setupConstraints() {

        NSLayoutConstraint.activate([

            commLabel.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: 5
            ),

            commLabel.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            ),

            infoLabel.topAnchor.constraint(
                equalTo: commLabel.bottomAnchor,
                constant: 60
            ),

            infoLabel.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            ),

            handOutlet.topAnchor.constraint(
                equalTo: infoLabel.bottomAnchor,
                constant: 70
            ),

            handOutlet.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            ),

            handOutlet.widthAnchor.constraint(
                equalTo: view.widthAnchor,
                multiplier: 0.85
            ),

            handOutlet.heightAnchor.constraint(equalToConstant: 50),

            speechOutlet.topAnchor.constraint(
                equalTo: handOutlet.bottomAnchor,
                constant: 40
            ),

            speechOutlet.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            ),

            speechOutlet.widthAnchor.constraint(
                equalTo: handOutlet.widthAnchor
            ),

            speechOutlet.heightAnchor.constraint(
                equalTo: handOutlet.heightAnchor
            ),

            textOutlet.topAnchor.constraint(
                equalTo: speechOutlet.bottomAnchor,
                constant: 40
            ),

            textOutlet.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            ),

            textOutlet.widthAnchor.constraint(
                equalTo: handOutlet.widthAnchor
            ),

            textOutlet.heightAnchor.constraint(
                equalTo: handOutlet.heightAnchor
            ),

            subtitleLabel.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -20
            ),

            subtitleLabel.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            )
        ])
    }

    // MARK: - ANIMATIONS

    func animateEntrance() {

        let elements = [
            commLabel,
            subtitleLabel,
            handOutlet,
            speechOutlet,
            textOutlet,
            infoLabel
        ]

        for (index, element) in elements.enumerated() {

            element?.transform =
                CGAffineTransform(translationX: 0, y: 30)

            UIView.animate(
                withDuration: 0.8,
                delay: Double(index) * 0.15,
                usingSpringWithDamping: 0.7,
                initialSpringVelocity: 0.5,
                options: [],
                animations: {

                    element?.alpha = 1
                    element?.transform = .identity
                }
            )
        }
    }

    func animateTap(_ button: UIButton) {

        UIView.animate(withDuration: 0.1, animations: {

            button.transform =
                CGAffineTransform(scaleX: 0.92, y: 0.92)

        }) { _ in

            UIView.animate(withDuration: 0.15) {
                button.transform = .identity
            }
        }
    }

    func addPulseAnimation(view: UIView) {

        let pulse = CABasicAnimation(keyPath: "transform.scale")

        pulse.duration = 1
        pulse.fromValue = 1
        pulse.toValue = 1.05

        pulse.autoreverses = true
        pulse.repeatCount = .infinity

        view.layer.add(pulse, forKey: "pulse")
    }

    func animateSubtitle() {

        subtitleLabel.alpha = 0

        subtitleLabel.transform =
            CGAffineTransform(translationX: 0, y: 10)

        UIView.animate(
            withDuration: 1.2,
            delay: 0.3,
            options: [.curveEaseInOut]
        ) {

            self.subtitleLabel.alpha = 1
            self.subtitleLabel.transform = .identity
        }

        let pulse = CABasicAnimation(keyPath: "opacity")

        pulse.fromValue = 0.7
        pulse.toValue = 1.0
        pulse.duration = 2.2

        pulse.autoreverses = true
        pulse.repeatCount = .infinity

        subtitleLabel.layer.add(pulse, forKey: "softPulse")
    }

    func animateFeaturesLabel() {

        infoLabel.alpha = 0

        infoLabel.transform =
            CGAffineTransform(translationX: 0, y: 8)

        UIView.animate(
            withDuration: 1.0,
            delay: 0.5,
            usingSpringWithDamping: 0.9,
            initialSpringVelocity: 0.4,
            options: []
        ) {

            self.infoLabel.alpha = 1
            self.infoLabel.transform = .identity
        }

        let glow = CABasicAnimation(keyPath: "opacity")

        glow.fromValue = 0.6
        glow.toValue = 1.0
        glow.duration = 2.5

        glow.autoreverses = true
        glow.repeatCount = .infinity

        infoLabel.layer.add(glow, forKey: "glowPulse")
    }

    func addIdleButtonAnimation() {

        for (index, button) in
            [handOutlet, speechOutlet, textOutlet].enumerated() {

            guard let btn = button else { continue }

            UIView.animate(
                withDuration: 2.5,
                delay: Double(index) * 0.2,
                options: [.autoreverse, .repeat, .allowUserInteraction]
            ) {

                btn.transform =
                    CGAffineTransform(scaleX: 1.03, y: 1.03)
            }
        }
    }

    // MARK: - FLOATING PARTICLES

    func addFloatingParticles() {

        for _ in 0..<12 {

            let size: CGFloat = CGFloat.random(in: 2...5)

            let x = CGFloat.random(
                in: 0...view.bounds.width
            )

            let layer = CAShapeLayer()

            layer.path = UIBezierPath(
                ovalIn: CGRect(
                    x: 0,
                    y: 0,
                    width: size,
                    height: size
                )
            ).cgPath

            layer.fillColor = UIColor.white
                .withAlphaComponent(
                    CGFloat.random(in: 0.04...0.12)
                ).cgColor

            layer.position = CGPoint(
                x: x,
                y: view.bounds.height + size
            )

            view.layer.addSublayer(layer)

            particleLayers.append(layer)

            animateParticle(layer)
        }
    }

    private func animateParticle(_ layer: CAShapeLayer) {

        let duration = Double.random(in: 6...14)
        let delay = Double.random(in: 0...8)

        let startX = layer.position.x

        let driftX = startX + CGFloat.random(in: -40...40)

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        layer.position = CGPoint(
            x: startX,
            y: view.bounds.height + 10
        )

        CATransaction.commit()

        DispatchQueue.main.asyncAfter(
            deadline: .now() + delay
        ) { [weak self, weak layer] in

            guard let self, let layer else { return }

            let move = CABasicAnimation(keyPath: "position")

            move.fromValue = CGPoint(
                x: startX,
                y: self.view.bounds.height + 10
            )

            move.toValue = CGPoint(
                x: driftX,
                y: -20
            )

            move.duration = duration

            move.timingFunction =
                CAMediaTimingFunction(name: .easeInEaseOut)

            let fade = CABasicAnimation(keyPath: "opacity")

            fade.fromValue = 0.1
            fade.toValue = 0.0
            fade.duration = duration

            let group = CAAnimationGroup()

            group.animations = [move, fade]
            group.duration = duration
            group.isRemovedOnCompletion = true

            CATransaction.begin()

            CATransaction.setCompletionBlock {

                layer.position = CGPoint(
                    x: CGFloat.random(
                        in: 0...self.view.bounds.width
                    ),
                    y: self.view.bounds.height + 10
                )

                self.animateParticle(layer)
            }

            layer.add(group, forKey: "float")

            CATransaction.commit()
        }
    }

    // MARK: - RIPPLE EFFECT

    private func addRipple(to button: UIButton) {

        let ripple = CAShapeLayer()

        let center = CGPoint(
            x: button.bounds.midX,
            y: button.bounds.midY
        )

        let startPath = UIBezierPath(
            ovalIn: CGRect(
                x: center.x - 5,
                y: center.y - 5,
                width: 10,
                height: 10
            )
        )

        let endPath = UIBezierPath(
            ovalIn: CGRect(
                x: center.x - 80,
                y: center.y - 80,
                width: 160,
                height: 160
            )
        )

        ripple.path = startPath.cgPath

        ripple.fillColor =
            UIColor.white.withAlphaComponent(0.25).cgColor

        ripple.strokeColor = UIColor.clear.cgColor

        button.layer.addSublayer(ripple)

        let pathAnim = CABasicAnimation(keyPath: "path")
        pathAnim.toValue = endPath.cgPath

        let opacityAnim = CABasicAnimation(keyPath: "opacity")
        opacityAnim.toValue = 0

        let group = CAAnimationGroup()

        group.animations = [pathAnim, opacityAnim]
        group.duration = 0.55

        group.timingFunction =
            CAMediaTimingFunction(name: .easeOut)

        group.isRemovedOnCompletion = true
        group.fillMode = .forwards

        CATransaction.begin()

        CATransaction.setCompletionBlock {
            ripple.removeFromSuperlayer()
        }

        ripple.add(group, forKey: "ripple")

        CATransaction.commit()
    }

    // MARK: - GLOW EFFECT

    private func flashGlow(on button: UIButton,
                           color: UIColor) {

        let glow = CALayer()

        glow.frame = button.bounds.insetBy(dx: -8, dy: -8)

        glow.cornerRadius = 24

        glow.backgroundColor = UIColor.clear.cgColor

        glow.shadowColor = color.cgColor
        glow.shadowOpacity = 0.9
        glow.shadowRadius = 18
        glow.shadowOffset = .zero

        button.layer.insertSublayer(glow, at: 0)

        let fade = CABasicAnimation(keyPath: "shadowOpacity")

        fade.fromValue = 0.9
        fade.toValue = 0.0

        fade.duration = 0.7

        fade.timingFunction =
            CAMediaTimingFunction(name: .easeOut)

        fade.isRemovedOnCompletion = true

        CATransaction.begin()

        CATransaction.setCompletionBlock {
            glow.removeFromSuperlayer()
        }

        glow.add(fade, forKey: "glowFade")

        CATransaction.commit()
    }

    // MARK: - ACTIONS

    @IBAction func handGesturePressed(_ sender: UIButton) {

        animateTap(sender)
        addRipple(to: sender)

        flashGlow(
            on: sender,
            color: UIColor.systemPurple
        )

        announceMode(
            "Hand Gesture Recogniser Mode Enabled."
        )
    }

    @IBAction func speechPressed(_ sender: UIButton) {

        animateTap(sender)
        addRipple(to: sender)

        flashGlow(
            on: sender,
            color: UIColor.systemBlue
        )

        announceMode(
            "Speech to Text Mode Enabled."
        )
    }

    @IBAction func textPressed(_ sender: UIButton) {

        animateTap(sender)
        addRipple(to: sender)

        flashGlow(
            on: sender,
            color: UIColor.cyan
        )

        announceMode(
            "Text to Speech Mode Enabled."
        )
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension ViewController: AVSpeechSynthesizerDelegate {

    func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didFinish utterance: AVSpeechUtterance
    ) {

        let handler = speechCompletionHandler

        speechCompletionHandler = nil

        handler?()
    }
}

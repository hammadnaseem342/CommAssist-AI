import UIKit

class ViewController: UIViewController {

    // MARK: - OUTLETS (MAKE SURE CONNECTED IN STORYBOARD)
    @IBOutlet weak var textOutlet: UIButton!
    @IBOutlet weak var handOutlet: UIButton!
    @IBOutlet weak var commLabel: UILabel!
    @IBOutlet weak var speechOutlet: UIButton!
    
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!

    private var backgroundGradient: CAGradientLayer?

    // MARK: - LIFE CYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        addIcons()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        applyBackgroundGradient()
        applyButtonGradients()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateEntrance()
        addPulseAnimation(view: commLabel)
        animateSubtitle()
        animateFeaturesLabel()
        addIdleButtonAnimation()
    }

    // MARK: - UI SETUP
    func setupUI() {
        styleTitle()
        styleSubtitle()
        styleButtons()
        styleBottomInfo()
    }

    // MARK: - TITLE
    func styleTitle() {
        commLabel.text = "COMM AI ASSISTANT"
        commLabel.textColor = .white
        commLabel.font = UIFont.systemFont(ofSize: 30, weight: .bold)
        commLabel.textAlignment = .center
        commLabel.alpha = 0
    }

    // MARK: - SUBTITLE
    func styleSubtitle() {
        subtitleLabel.text = "Helping you communicate smarter"
        subtitleLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        subtitleLabel.textColor = UIColor(red: 180/255, green: 200/255, blue: 220/255, alpha: 1)
        subtitleLabel.textAlignment = .center
        subtitleLabel.alpha = 0

        let attributedText = NSMutableAttributedString(string: subtitleLabel.text ?? "")
        attributedText.addAttribute(.kern, value: 0.8, range: NSRange(location: 0, length: attributedText.length))
        subtitleLabel.attributedText = attributedText
    }

    // MARK: - BUTTON STYLE
    func styleButtons() {
        let buttons = [handOutlet, speechOutlet, textOutlet]
        for button in buttons {
            guard let btn = button else { continue }
            btn.layer.cornerRadius = 20
            btn.clipsToBounds = true
            btn.setTitleColor(.white, for: .normal)
            btn.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
            btn.layer.shadowColor = UIColor.black.cgColor
            btn.layer.shadowOpacity = 0.3
            btn.layer.shadowOffset = CGSize(width: 0, height: 5)
            btn.layer.shadowRadius = 8
            btn.alpha = 0
        }
    }

    // MARK: - BUTTON GRADIENT
    func applyButtonGradients() {
        let buttons = [handOutlet, speechOutlet, textOutlet]

        for button in buttons {
            guard let btn = button else { continue }

            btn.layer.sublayers?.removeAll(where: { $0 is CAGradientLayer })

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

    // MARK: - BACKGROUND
    func applyBackgroundGradient() {
        backgroundGradient?.removeFromSuperlayer()

        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor(red: 15/255, green: 32/255, blue: 39/255, alpha: 1).cgColor,
            UIColor(red: 32/255, green: 58/255, blue: 67/255, alpha: 1).cgColor,
            UIColor(red: 44/255, green: 83/255, blue: 100/255, alpha: 1).cgColor
        ]

        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        gradient.frame = view.bounds

        view.layer.insertSublayer(gradient, at: 0)
        backgroundGradient = gradient
    }

    // MARK: - ICONS
    func addIcons() {
        handOutlet.setImage(UIImage(systemName: "hand.raised.fill"), for: .normal)
        speechOutlet.setImage(UIImage(systemName: "mic.fill"), for: .normal)
        textOutlet.setImage(UIImage(systemName: "speaker.wave.2.fill"), for: .normal)

        handOutlet.tintColor = .white
        speechOutlet.tintColor = .white
        textOutlet.tintColor = .white

        handOutlet.imageEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)
        speechOutlet.imageEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)
        textOutlet.imageEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)
    }

    // MARK: - FEATURES LABEL
    func styleBottomInfo() {
        let text = "FEATURES"

        let attributedText = NSMutableAttributedString(string: text)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineSpacing = 2

        attributedText.addAttribute(.paragraphStyle, value: paragraphStyle,
                                    range: NSRange(location: 0, length: attributedText.length))

        attributedText.addAttribute(.font,
                                    value: UIFont.systemFont(ofSize: 16, weight: .semibold),
                                    range: NSRange(location: 0, length: attributedText.length))

        attributedText.addAttribute(.foregroundColor,
                                    value: UIColor(red: 140/255, green: 220/255, blue: 255/255, alpha: 0.95),
                                    range: NSRange(location: 0, length: attributedText.length))

        attributedText.addAttribute(.kern, value: 2.2,
                                    range: NSRange(location: 0, length: attributedText.length))

        infoLabel.attributedText = attributedText
        infoLabel.alpha = 0
    }

    // MARK: - ANIMATIONS
    func animateEntrance() {
        let elements = [commLabel, subtitleLabel, handOutlet, speechOutlet, textOutlet, infoLabel]

        for (index, element) in elements.enumerated() {
            element?.transform = CGAffineTransform(translationX: 0, y: 30)

            UIView.animate(withDuration: 0.8,
                           delay: Double(index) * 0.15,
                           usingSpringWithDamping: 0.7,
                           initialSpringVelocity: 0.5,
                           options: [],
                           animations: {
                element?.alpha = 1
                element?.transform = .identity
            })
        }
    }

    func animateTap(_ button: UIButton) {
        UIView.animate(withDuration: 0.1, animations: {
            button.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
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

    // MARK: - NEW ANIMATIONS
    func animateSubtitle() {
        subtitleLabel.alpha = 0
        subtitleLabel.transform = CGAffineTransform(translationX: 0, y: 10)

        UIView.animate(withDuration: 1.2,
                       delay: 0.3,
                       options: [.curveEaseInOut],
                       animations: {
            self.subtitleLabel.alpha = 1
            self.subtitleLabel.transform = .identity
        })

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
        infoLabel.transform = CGAffineTransform(translationX: 0, y: 8)

        UIView.animate(withDuration: 1.0,
                       delay: 0.5,
                       usingSpringWithDamping: 0.9,
                       initialSpringVelocity: 0.4,
                       options: [],
                       animations: {
            self.infoLabel.alpha = 1
            self.infoLabel.transform = .identity
        })

        let glow = CABasicAnimation(keyPath: "opacity")
        glow.fromValue = 0.6
        glow.toValue = 1.0
        glow.duration = 2.5
        glow.autoreverses = true
        glow.repeatCount = .infinity

        infoLabel.layer.add(glow, forKey: "glowPulse")
    }

    func addIdleButtonAnimation() {
        let buttons = [handOutlet, speechOutlet, textOutlet]

        for (index, button) in buttons.enumerated() {
            guard let btn = button else { continue }
            let delay = Double(index) * 0.2

            UIView.animate(withDuration: 2.5,
                           delay: delay,
                           options: [.autoreverse, .repeat, .allowUserInteraction],
                           animations: {
                btn.transform = CGAffineTransform(scaleX: 1.03, y: 1.03)
            })
        }
    }

    // MARK: - ACTIONS
    @IBAction func handGesturePressed(_ sender: UIButton) {
        animateTap(sender)
    }

    @IBAction func speechPressed(_ sender: UIButton) {
        animateTap(sender)
    }

    @IBAction func textPressed(_ sender: UIButton) {
        animateTap(sender)
    }
}

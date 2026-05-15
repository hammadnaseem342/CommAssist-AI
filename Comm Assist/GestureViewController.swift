import UIKit
import AVFoundation

class GestureViewController: UIViewController {

    // MARK: - UI Elements
    let titleLabel = UILabel()
    let subtitleLabel = UILabel()
    let previewView = UIView()
    let detectButton = UIButton()
    let resultLabel = UILabel()
    let tipLabel = UILabel()

    // MARK: - Camera
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?

    private var backgroundGradient: CAGradientLayer?
    private var isDetecting = false

    // MARK: - LIFE CYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        applyConstraints()
        setupCamera()
        
        view.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 0, leading: 20, bottom: 0, trailing: 20
        )
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        applyBackgroundGradient()
        previewLayer?.frame = previewView.bounds
        applyButtonGradient()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateEntrance()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession?.stopRunning()
    }

    // MARK: - UI SETUP
    func setupUI() {
        
        // TITLE
        titleLabel.text = "Hand Gesture Recognition"
        titleLabel.font = UIFont.systemFont(ofSize: 26, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        
        // SUBTITLE
        subtitleLabel.text = "Show your hand to the camera"
        subtitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        subtitleLabel.textColor = UIColor(
            red: 180/255, green: 200/255, blue: 220/255, alpha: 1
        )
        subtitleLabel.textAlignment = .center
        
        // CAMERA PREVIEW
        previewView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        previewView.layer.cornerRadius = 20
        previewView.clipsToBounds = true
        
        // BUTTON
        detectButton.setTitle("Start Detection", for: .normal)
        detectButton.setTitleColor(.white, for: .normal)
        detectButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        detectButton.layer.cornerRadius = 20
        detectButton.addTarget(self, action: #selector(detectPressed), for: .touchUpInside)
        
        // RESULT
        resultLabel.text = "Detected: -"
        resultLabel.textColor = .white
        resultLabel.textAlignment = .center
        resultLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        
        // TIP
        tipLabel.text = "💡 Keep your hand clearly visible"
        tipLabel.textColor = .lightGray
        tipLabel.font = UIFont.systemFont(ofSize: 13)
        tipLabel.textAlignment = .center
        
        // ADD SUBVIEWS
        [titleLabel, subtitleLabel, previewView,
         detectButton, resultLabel, tipLabel].forEach {
            view.addSubview($0)
        }
    }

    // MARK: - RESPONSIVE CONSTRAINTS
    func applyConstraints() {
        
        [titleLabel, subtitleLabel, previewView,
         detectButton, resultLabel, tipLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            
            // TITLE
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 15),
            titleLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            
            // SUBTITLE
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            
            // CAMERA (🔥 BIG + RESPONSIVE)
            previewView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 20),
            previewView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            
            // Option 1: adaptive height
            previewView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.42),
            
            // BUTTON
            detectButton.topAnchor.constraint(equalTo: previewView.bottomAnchor, constant: 20),
            detectButton.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            detectButton.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            detectButton.heightAnchor.constraint(equalToConstant: 55),
            
            // RESULT
            resultLabel.topAnchor.constraint(equalTo: detectButton.bottomAnchor, constant: 15),
            resultLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            resultLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            
            // TIP
            tipLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            tipLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            tipLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor)
        ])
    }

    // MARK: - CAMERA SETUP
    func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .high

        guard let session = captureSession,
              let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device)
        else { return }

        if session.canAddInput(input) {
            session.addInput(input)
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer?.videoGravity = .resizeAspectFill
        previewLayer?.cornerRadius = 20

        if let previewLayer = previewLayer {
            previewView.layer.addSublayer(previewLayer)
        }
    }

    // MARK: - BUTTON ACTION
    @objc func detectPressed() {
        animateTap(detectButton)

        isDetecting.toggle()

        if isDetecting {
            detectButton.setTitle("Stop Detection", for: .normal)
            captureSession?.startRunning()
            resultLabel.text = "Detecting..."
        } else {
            detectButton.setTitle("Start Detection", for: .normal)
            captureSession?.stopRunning()
            resultLabel.text = "Detected: -"
        }
    }

    // MARK: - BUTTON GRADIENT
    func applyButtonGradient() {
        detectButton.layer.sublayers?.removeAll(where: { $0 is CAGradientLayer })

        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor.systemPurple.cgColor,
            UIColor.systemBlue.cgColor
        ]
        gradient.frame = detectButton.bounds
        gradient.cornerRadius = 20

        detectButton.layer.insertSublayer(gradient, at: 0)
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
        gradient.frame = view.bounds

        view.layer.insertSublayer(gradient, at: 0)
        backgroundGradient = gradient
    }

    // MARK: - ANIMATIONS
    func animateEntrance() {
        let elements = [titleLabel, subtitleLabel, previewView,
                        detectButton, resultLabel, tipLabel]

        for (i, element) in elements.enumerated() {
            element.alpha = 0
            element.transform = CGAffineTransform(translationX: 0, y: 30)

            UIView.animate(withDuration: 0.7,
                           delay: Double(i) * 0.08,
                           usingSpringWithDamping: 0.8,
                           initialSpringVelocity: 0.5) {
                element.alpha = 1
                element.transform = .identity
            }
        }
    }

    func animateTap(_ button: UIButton) {
        UIView.animate(withDuration: 0.1,
                       animations: {
            button.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                button.transform = .identity
            }
        }
    }
}

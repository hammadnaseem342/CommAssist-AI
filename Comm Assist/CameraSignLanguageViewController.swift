import AVFoundation
import UIKit
import Vision

final class CameraSignLanguageViewController: UIViewController {

    // MARK: - Camera
    private let captureSession = AVCaptureSession()
    private let videoOutput    = AVCaptureVideoDataOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let handRequest    = VNDetectHumanHandPoseRequest()

    // Track current camera position
    private var currentPosition: AVCaptureDevice.Position = .back

    // MARK: - API + helpers
    private let api           = SignLanguageAPIClient.shared
    private let segmenter     = GestureSegmenter()
    private let wordCorrector = WordLevelCorrector()
    private let speech        = SpeechManager()

    // Rate limiting
    private var requestInFlight = false
    private var lastTime        = Date()
    private let interval: TimeInterval = 0.15
    private var lastSpokenWord  = ""
    private var serverReachable = false

    // MARK: - UI

    private let gestureInfoLabel: UILabel = {
        let l = UILabel()
        l.text            = "X = SPACE  |  Z = QUIT"
        l.textColor       = .white
        l.font            = .systemFont(ofSize: 13, weight: .semibold)
        l.translatesAutoresizingMaskIntoConstraints = false
        l.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        l.layer.cornerRadius = 8
        l.clipsToBounds   = true
        l.textAlignment   = .center
        return l
    }()

    private let serverStatusLabel: UILabel = {
        let l = UILabel()
        l.text            = "● Connecting..."
        l.textColor       = .yellow
        l.font            = .systemFont(ofSize: 12, weight: .medium)
        l.translatesAutoresizingMaskIntoConstraints = false
        l.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        l.layer.cornerRadius = 8
        l.clipsToBounds   = true
        l.textAlignment   = .center
        return l
    }()

    private let liveDetectionLabel: UILabel = {
        let l = UILabel()
        l.text            = "Detecting: —"
        l.textColor       = .green
        l.font            = .systemFont(ofSize: 15, weight: .semibold)
        l.numberOfLines   = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        l.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        l.layer.cornerRadius = 8
        l.clipsToBounds   = true
        l.textAlignment   = .center
        return l
    }()

    private let sentenceLabel: UILabel = {
        let l = UILabel()
        l.textColor       = .white
        l.font            = .systemFont(ofSize: 19, weight: .bold)
        l.numberOfLines   = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        l.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        l.layer.cornerRadius = 12
        l.clipsToBounds   = true
        l.textAlignment   = .center
        return l
    }()

    // ── Camera Swap Button ────────────────────────────────────
    private let swapCameraButton: UIButton = {
        let btn = UIButton(type: .system)

        // Blurred circular background
        btn.backgroundColor = UIColor.white.withAlphaComponent(0.18)
        btn.layer.cornerRadius = 28
        btn.clipsToBounds      = true
        btn.translatesAutoresizingMaskIntoConstraints = false

        // SF Symbol icon
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        let icon   = UIImage(systemName: "arrow.triangle.2.circlepath.camera.fill",
                             withConfiguration: config)
        btn.setImage(icon, for: .normal)
        btn.tintColor = .white

        // Border
        btn.layer.borderColor = UIColor.white.withAlphaComponent(0.35).cgColor
        btn.layer.borderWidth = 1.5

        // Shadow
        btn.layer.shadowColor   = UIColor.black.cgColor
        btn.layer.shadowOpacity = 0.4
        btn.layer.shadowRadius  = 8
        btn.layer.shadowOffset  = CGSize(width: 0, height: 3)

        return btn
    }()

    // Camera label below swap button
    private let cameraLabel: UILabel = {
        let l = UILabel()
        l.text            = "REAR"
        l.textColor       = UIColor.white.withAlphaComponent(0.85)
        l.font            = .systemFont(ofSize: 11, weight: .bold)
        l.textAlignment   = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        l.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        l.layer.cornerRadius = 6
        l.clipsToBounds   = true
        return l
    }()

    private var overlayLayer = CAShapeLayer()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupUI()
        setupOverlay()
        configureCamera(position: .back)
        pingServer()

        Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.pingServer()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
        overlayLayer.frame  = view.bounds
    }

    // MARK: - Server ping

    private func pingServer() {
        api.checkHealth { [weak self] online in
            guard let self else { return }
            self.serverReachable = online
            DispatchQueue.main.async {
                self.serverStatusLabel.text      = online
                    ? "  ● Server: Connected ✓  "
                    : "  ● Offline — check IP & Wi-Fi  "
                self.serverStatusLabel.textColor = online ? .systemGreen : .systemRed
            }
        }
    }

    // MARK: - UI setup

    private func setupUI() {
        [gestureInfoLabel, serverStatusLabel,
         liveDetectionLabel, sentenceLabel,
         swapCameraButton, cameraLabel].forEach { view.addSubview($0) }

        swapCameraButton.addTarget(self, action: #selector(swapCameraTapped),
                                   for: .touchUpInside)

        NSLayoutConstraint.activate([

            // ── Top labels ────────────────────────────────────
            gestureInfoLabel.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            gestureInfoLabel.leadingAnchor.constraint(
                equalTo: view.leadingAnchor, constant: 12),
            gestureInfoLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: swapCameraButton.leadingAnchor, constant: -10),

            serverStatusLabel.topAnchor.constraint(
                equalTo: gestureInfoLabel.bottomAnchor, constant: 6),
            serverStatusLabel.leadingAnchor.constraint(
                equalTo: view.leadingAnchor, constant: 12),
            serverStatusLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: swapCameraButton.leadingAnchor, constant: -10),

            liveDetectionLabel.topAnchor.constraint(
                equalTo: serverStatusLabel.bottomAnchor, constant: 6),
            liveDetectionLabel.leadingAnchor.constraint(
                equalTo: view.leadingAnchor, constant: 12),
            liveDetectionLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: swapCameraButton.leadingAnchor, constant: -10),

            // ── Swap camera button (top-right) ────────────────
            swapCameraButton.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            swapCameraButton.trailingAnchor.constraint(
                equalTo: view.trailingAnchor, constant: -16),
            swapCameraButton.widthAnchor.constraint(equalToConstant: 56),
            swapCameraButton.heightAnchor.constraint(equalToConstant: 56),

            // ── Camera label (below swap button) ──────────────
            cameraLabel.topAnchor.constraint(
                equalTo: swapCameraButton.bottomAnchor, constant: 5),
            cameraLabel.centerXAnchor.constraint(
                equalTo: swapCameraButton.centerXAnchor),
            cameraLabel.widthAnchor.constraint(equalToConstant: 48),

            // ── Sentence label (bottom) ───────────────────────
            sentenceLabel.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            sentenceLabel.leadingAnchor.constraint(
                equalTo: view.leadingAnchor, constant: 12),
            sentenceLabel.trailingAnchor.constraint(
                equalTo: view.trailingAnchor, constant: -12),
        ])
    }

    private func setupOverlay() {
        overlayLayer.strokeColor = UIColor.systemGreen.cgColor
        overlayLayer.fillColor   = UIColor.clear.cgColor
        overlayLayer.lineWidth   = 2
        view.layer.addSublayer(overlayLayer)
    }

    // MARK: - Camera configuration

    private func configureCamera(position: AVCaptureDevice.Position) {
        DispatchQueue(label: "camera.setup", qos: .userInitiated).async {

            // Stop existing session
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }

            self.captureSession.beginConfiguration()

            // Remove existing inputs
            self.captureSession.inputs.forEach {
                self.captureSession.removeInput($0)
            }
            // Remove existing outputs
            self.captureSession.outputs.forEach {
                self.captureSession.removeOutput($0)
            }

            self.captureSession.sessionPreset = .hd1280x720

            guard
                let device = AVCaptureDevice.default(
                    .builtInWideAngleCamera, for: .video, position: position),
                let input  = try? AVCaptureDeviceInput(device: device)
            else {
                self.captureSession.commitConfiguration()
                return
            }

            self.captureSession.addInput(input)
            self.videoOutput.setSampleBufferDelegate(
                self, queue: DispatchQueue(label: "cam.queue"))

            if self.captureSession.canAddOutput(self.videoOutput) {
                self.captureSession.addOutput(self.videoOutput)
            }

            self.captureSession.commitConfiguration()

            // ── Update preview on main thread ─────────────────
            DispatchQueue.main.async {
                if self.previewLayer == nil {
                    let preview          = AVCaptureVideoPreviewLayer(
                        session: self.captureSession)
                    preview.videoGravity = .resizeAspectFill
                    preview.frame        = self.view.bounds
                    self.view.layer.insertSublayer(preview, at: 0)
                    self.previewLayer    = preview
                } else {
                    self.previewLayer?.session = self.captureSession
                }
            }

            self.captureSession.startRunning()
        }
    }

    // MARK: - Swap camera action

    @objc private func swapCameraTapped() {
        // Bounce animation on button
        UIView.animate(withDuration: 0.1, animations: {
            self.swapCameraButton.transform = CGAffineTransform(scaleX: 0.88, y: 0.88)
        }) { _ in
            UIView.animate(
                withDuration: 0.15,
                delay: 0,
                usingSpringWithDamping: 0.5,
                initialSpringVelocity: 0.8,
                options: []
            ) {
                self.swapCameraButton.transform = .identity
            }
        }
        // Rotate icon animation
        UIView.animate(withDuration: 0.45,
                       delay: 0,
                       usingSpringWithDamping: 0.7,
                       initialSpringVelocity: 0.5) {
            self.swapCameraButton.imageView?.transform =
                self.swapCameraButton.imageView?.transform
                    .rotated(by: .pi) ?? .identity
        }

        // Flip transition on preview
        let transition        = CATransition()
        transition.duration   = 0.35
        transition.type       = .fade
        view.layer.add(transition, forKey: nil)

        // Toggle position
        currentPosition = (currentPosition == .back) ? .front : .back
        configureCamera(position: currentPosition)

        // Update label
        DispatchQueue.main.async {
            let labelText = self.currentPosition == .back ? "REAR" : "FRONT"
            UIView.transition(with: self.cameraLabel,
                              duration: 0.25,
                              options: .transitionCrossDissolve) {
                self.cameraLabel.text = labelText
            }
        }

        // Glow flash
        flashSwapGlow()

        // Clear overlay (old hand position no longer valid)
        DispatchQueue.main.async {
            self.overlayLayer.path = nil
        }
    }

    private func flashSwapGlow() {
        let glow            = CALayer()
        glow.frame          = swapCameraButton.bounds.insetBy(dx: -10, dy: -10)
        glow.cornerRadius   = 38
        glow.backgroundColor = UIColor.clear.cgColor
        glow.shadowColor    = UIColor.white.cgColor
        glow.shadowOpacity  = 0.7
        glow.shadowRadius   = 18
        glow.shadowOffset   = .zero
        swapCameraButton.layer.insertSublayer(glow, at: 0)

        let fade            = CABasicAnimation(keyPath: "shadowOpacity")
        fade.fromValue      = 0.7
        fade.toValue        = 0.0
        fade.duration       = 0.6
        fade.timingFunction = CAMediaTimingFunction(name: .easeOut)

        CATransaction.begin()
        CATransaction.setCompletionBlock { glow.removeFromSuperlayer() }
        glow.add(fade, forKey: "glowFade")
        CATransaction.commit()
    }

    // MARK: - Stop camera (Z gesture)

    private func stopCamera() {
        DispatchQueue(label: "camera.stop", qos: .userInitiated).async {
            self.captureSession.stopRunning()
        }
        DispatchQueue.main.async {
            self.dismiss(animated: true)
        }
    }

    // MARK: - Frame processing (background thread)

    private func process(sampleBuffer: CMSampleBuffer) {
        guard Date().timeIntervalSince(lastTime) > interval else { return }
        guard !requestInFlight  else { return }
        guard serverReachable   else { return }
        lastTime = Date()

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        // Flip orientation for front camera
        let orientation: CGImagePropertyOrientation =
            currentPosition == .front ? .leftMirrored : .right

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                            orientation: orientation)
        try? handler.perform([handRequest])

        guard
            let obs       = handRequest.results?.first,
            let landmarks = extract(obs)
        else { return }

        drawHand(landmarks)

        requestInFlight = true

        api.predict(landmarks: landmarks) { [weak self] response in
            guard let self else { return }
            self.requestInFlight = false

            guard let response else {
                DispatchQueue.main.async {
                    self.liveDetectionLabel.text      = "  API: No response  "
                    self.liveDetectionLabel.textColor = .orange
                }
                return
            }

            let letter     = response.letter
            let confidence = response.confidence

            guard confidence >= 0.3 else {
                DispatchQueue.main.async {
                    self.liveDetectionLabel.text =
                        "  Raw: \(letter) | \(String(format: "%.0f", confidence*100))%  "
                    self.liveDetectionLabel.textColor = .orange
                }
                return
            }

            guard let stable = self.segmenter.update(label: letter) else { return }

            DispatchQueue.main.async {
                self.liveDetectionLabel.text =
                    "  \(stable)  |  \(String(format: "%.0f", confidence*100))%  "
                self.liveDetectionLabel.textColor = .systemGreen
                self.animateDetectionPop()
            }

            switch stable {
            case "X":
                self.wordCorrector.space()
            case "Z":
                self.stopCamera()
                return
            default:
                self.wordCorrector.add(letter: stable)
            }

            let text = self.wordCorrector.text()
            DispatchQueue.main.async {
                self.sentenceLabel.text = "  \(text)  "
            }

            if let lastWord = text.split(separator: " ").last?.description,
               lastWord != self.lastSpokenWord {
                self.speech.speak(word: lastWord)
                self.lastSpokenWord = lastWord
            }
        }
    }

    // Pop animation when a new letter is detected
    private func animateDetectionPop() {
        UIView.animate(withDuration: 0.1, animations: {
            self.liveDetectionLabel.transform = CGAffineTransform(scaleX: 1.08, y: 1.08)
        }) { _ in
            UIView.animate(withDuration: 0.12) {
                self.liveDetectionLabel.transform = .identity
            }
        }
    }

    // MARK: - Hand overlay (main thread)

    private func drawHand(_ points: [CGPoint]) {
        DispatchQueue.main.async {
            let w    = self.view.bounds.width
            let h    = self.view.bounds.height
            let path = UIBezierPath()
            for (i, p) in points.enumerated() {
                let pt = CGPoint(x: p.x * w, y: p.y * h)
                i == 0 ? path.move(to: pt) : path.addLine(to: pt)
            }
            self.overlayLayer.path = path.cgPath
        }
    }

    // MARK: - Landmark extraction

    private func extract(_ obs: VNHumanHandPoseObservation) -> [CGPoint]? {
        let order: [VNHumanHandPoseObservation.JointName] = [
            .wrist,
            .thumbCMC,  .thumbMP,   .thumbIP,   .thumbTip,
            .indexMCP,  .indexPIP,  .indexDIP,  .indexTip,
            .middleMCP, .middlePIP, .middleDIP, .middleTip,
            .ringMCP,   .ringPIP,   .ringDIP,   .ringTip,
            .littleMCP, .littlePIP, .littleDIP, .littleTip,
        ]
        guard let points = try? obs.recognizedPoints(.all) else { return nil }
        var result: [CGPoint] = []
        for joint in order {
            guard let p = points[joint], p.confidence > 0.3 else { return nil }
            result.append(CGPoint(x: p.location.x, y: 1.0 - p.location.y))
        }
        return result
    }
}

// MARK: - Delegate

extension CameraSignLanguageViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(_ output: AVCaptureOutput,
                                   didOutput sampleBuffer: CMSampleBuffer,
                                   from connection: AVCaptureConnection) {
        process(sampleBuffer: sampleBuffer)
    }
}

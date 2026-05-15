import Foundation
import CoreGraphics

// ─────────────────────────────────────────────────────────────
// COMM AI — Sign Language API Client
//
// ⚠️  Set baseURL to your Windows PC IP address.
//     Find it: open CMD → type ipconfig → copy IPv4 under Wi-Fi
//     Example: http://192.168.1.105:8000
// ─────────────────────────────────────────────────────────────

final class SignLanguageAPIClient {

    // ⚠️ CHANGE THIS TO YOUR WINDOWS PC IP
    private let baseURL = "http://192.168.18.15:8000"

    static let shared = SignLanguageAPIClient()
    private init() {}

    private let session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest  = 3.0
        cfg.timeoutIntervalForResource = 3.0
        return URLSession(configuration: cfg)
    }()

    // MARK: - Models

    private struct LandmarkPoint: Codable {
        let x: Double
        let y: Double
    }

    private struct PredictRequest: Codable {
        let landmarks: [LandmarkPoint]
    }

    struct PredictResponse: Codable {
        let letter: String
        let confidence: Double
        let all_probabilities: [String: Double]
    }

    // MARK: - Predict

    func predict(landmarks: [CGPoint],
                 completion: @escaping (PredictResponse?) -> Void) {

        guard let url = URL(string: "\(baseURL)/predict") else {
            completion(nil); return
        }

        let points  = landmarks.map { LandmarkPoint(x: Double($0.x), y: Double($0.y)) }
        let payload = PredictRequest(landmarks: points)

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONEncoder().encode(payload)

        session.dataTask(with: req) { data, _, error in
            guard error == nil,
                  let data = data,
                  let result = try? JSONDecoder().decode(PredictResponse.self, from: data)
            else { completion(nil); return }
            completion(result)
        }.resume()
    }

    // MARK: - Health check

    func checkHealth(completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(baseURL)/health") else {
            completion(false); return
        }
        session.dataTask(with: URLRequest(url: url)) { _, response, _ in
            completion((response as? HTTPURLResponse)?.statusCode == 200)
        }.resume()
    }
}

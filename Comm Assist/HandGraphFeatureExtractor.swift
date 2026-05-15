import CoreGraphics

enum HandGraphFeatureExtractor {

    static let jointCount = 21

    static func extract(_ points: [CGPoint]) -> [Double]? {

        guard points.count == jointCount else { return nil }

        let wrist = points[0]

        var features: [Double] = []

        // =================================================
        // 1. WRIST NORMALIZATION (MediaPipe style)
        // =================================================
        let normalized = points.map {
            CGPoint(x: $0.x - wrist.x,
                    y: $0.y - wrist.y)
        }

        // =================================================
        // 2. PAIRWISE DISTANCES (GRAPH EDGES)
        // =================================================
        func dist(_ a: CGPoint, _ b: CGPoint) -> Double {
            let dx = a.x - b.x
            let dy = a.y - b.y
            return sqrt(dx*dx + dy*dy)
        }

        // finger chains
        let edges: [(Int, Int)] = [
            (0,5),(5,6),(6,7),(7,8),     // index
            (0,9),(9,10),(10,11),(11,12), // middle
            (0,13),(13,14),(14,15),(15,16),
            (0,17),(17,18),(18,19),(19,20),
            (0,1),(1,2),(2,3),(3,4)      // thumb
        ]

        for (a,b) in edges {
            features.append(dist(normalized[a], normalized[b]))
        }

        // =================================================
        // 3. ANGLE FEATURES (key for M/S/R)
        // =================================================
        func angle(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint) -> Double {
            let ab = (a.x - b.x, a.y - b.y)
            let cb = (c.x - b.x, c.y - b.y)

            let dot = ab.0 * cb.0 + ab.1 * cb.1
            let mag1 = sqrt(ab.0*ab.0 + ab.1*ab.1)
            let mag2 = sqrt(cb.0*cb.0 + cb.1*cb.1)

            guard mag1 > 0 && mag2 > 0 else { return 0 }

            let cosv = dot / (mag1 * mag2)
            return acos(max(-1, min(1, cosv)))
        }

        features.append(angle(points[5], points[6], points[8]))
        features.append(angle(points[9], points[10], points[12]))
        features.append(angle(points[13], points[14], points[16]))
        features.append(angle(points[17], points[18], points[20]))

        return features
    }
}

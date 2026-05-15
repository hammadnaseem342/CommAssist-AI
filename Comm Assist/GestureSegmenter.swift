import Foundation

final class GestureSegmenter {

    private var buffer: [String] = []
    private let window    = 8
    private var lastStable = ""

    func update(label: String) -> String? {
        buffer.append(label)
        if buffer.count > window { buffer.removeFirst() }

        let counts = Dictionary(grouping: buffer, by: { $0 }).mapValues(\.count)
        guard let best = counts.max(by: { $0.value < $1.value }) else { return nil }

        // 5 of 8 frames must agree AND it must differ from last confirmed letter
        if best.value >= 5, best.key != lastStable {
            lastStable = best.key
            return best.key
        }
        return nil
    }
}

import Foundation

/// How close two frames must be, in time and in looks, to be one burst.
public struct BurstRules: Sendable {
    /// Frames further apart than this are never grouped.
    public var maxGap: TimeInterval
    /// Within this gap the camera was firing continuously, so looser looks count.
    public var burstGap: TimeInterval
    /// Highest look difference allowed inside a continuous burst.
    public var burstDistance: Float
    /// Highest look difference for frames a few seconds apart (re-takes of a pose).
    public var retakeDistance: Float

    /// Measured on a6400 portraits: re-takes of one pose were 0.21–0.49 apart (up to
    /// 45 s apart), different set-ups 0.56 and more.
    public static let standard = BurstRules(maxGap: 60, burstGap: 1.5, burstDistance: 0.6, retakeDistance: 0.5)
}

/// Splits a shoot into bursts: runs of frames taken close together that
/// look alike. Each frame is compared with the one before it, so a burst
/// can drift slowly (a runner crossing the frame) and still stay together.
///
/// The rule is separate from how looks are measured (Vision, in
/// `SimilarityPrints`), so it can be tested with made-up distances.
public enum BurstGrouper {
    public struct Frame: Sendable {
        public let id: URL
        public let time: Date

        public init(id: URL, time: Date) {
            self.id = id
            self.time = time
        }
    }

    /// `distance(i)` is how different frame `i` looks from frame `i - 1`; it
    /// is asked only when the two are close enough in time to matter.
    public static func group(
        _ frames: [Frame], rules: BurstRules = .standard, distance: (Int) -> Float?
    ) -> [[URL]] {
        var groups: [[URL]] = []
        for index in frames.indices {
            if index > 0, belongsWithPrevious(index, frames, rules, distance) {
                groups[groups.count - 1].append(frames[index].id)
            } else {
                groups.append([frames[index].id])
            }
        }
        return groups
    }

    private static func belongsWithPrevious(
        _ index: Int, _ frames: [Frame], _ rules: BurstRules, _ distance: (Int) -> Float?
    ) -> Bool {
        let gap = abs(frames[index].time.timeIntervalSince(frames[index - 1].time))
        guard gap <= rules.maxGap, let difference = distance(index) else { return false }
        return difference <= (gap <= rules.burstGap ? rules.burstDistance : rules.retakeDistance)
    }
}

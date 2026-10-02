import Foundation
import Testing

@testable import WinnowCore

@Suite struct BurstGrouperTests {
    private func frames(_ seconds: [TimeInterval]) -> [BurstGrouper.Frame] {
        seconds.enumerated().map { index, second in
            BurstGrouper.Frame(id: URL(fileURLWithPath: "/f/\(index).ARW"), time: Date(timeIntervalSince1970: second))
        }
    }

    @Test func groupsAContinuousBurst() {
        let groups = BurstGrouper.group(frames([0, 0.1, 0.2, 0.3])) { _ in 0.55 }
        #expect(groups.map(\.count) == [4])  // 0.55 is fine inside a burst (limit 0.6)
    }

    @Test func groupsRetakesOfAPoseButNotNewSetups() {
        // Re-take 12 s later (0.33), then a new set-up 30 s later (0.86).
        let distances: [Int: Float] = [1: 0.33, 2: 0.86]
        let groups = BurstGrouper.group(frames([0, 12, 42])) { distances[$0] }
        #expect(groups.map(\.count) == [2, 1])
    }

    @Test func neverGroupsAcrossALongGap() {
        var asked: [Int] = []
        let groups = BurstGrouper.group(frames([0, 600])) { index in
            asked.append(index)
            return 0.1
        }
        #expect(groups.map(\.count) == [1, 1])
        #expect(asked.isEmpty)  // too far apart in time to need comparing
    }
}

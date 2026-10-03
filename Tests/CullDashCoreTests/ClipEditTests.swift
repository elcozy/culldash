import Foundation
import Testing

@testable import CullDashCore

@Suite struct ClipEditTests {
    /// Shorthand so the expectations below read as spans, not constructors.
    private func spans(_ ranges: [ClipRange]) -> [[Double]] {
        ranges.map { [$0.start, $0.end] }
    }

    @Test func keepsTheWholeClipUntilSomethingIsCut() {
        let edit = ClipEdit(duration: 30)
        #expect(edit.isUnchanged)
        #expect(spans(edit.kept) == [[0, 30]])
        #expect(edit.keptDuration == 30)
    }

    @Test func cuttingTheMiddleLeavesTheTwoEnds() {
        var edit = ClipEdit(duration: 30)
        edit.cut(ClipRange(start: 10, end: 20))
        #expect(spans(edit.kept) == [[0, 10], [20, 30]])
        #expect(edit.keptDuration == 20)
        #expect(!edit.isUnchanged)
    }

    @Test func trimmingBothEndsIsTwoCuts() {
        var edit = ClipEdit(duration: 30)
        edit.keepOnly(from: 5, to: 25)
        #expect(spans(edit.kept) == [[5, 25]])
        #expect(edit.keptDuration == 20)
    }

    @Test func overlappingCutsMergeIntoOne() {
        var edit = ClipEdit(duration: 30)
        edit.cut(ClipRange(start: 0, end: 5))
        edit.cut(ClipRange(start: 3, end: 8))
        #expect(spans(edit.cuts) == [[0, 8]])
        #expect(spans(edit.kept) == [[8, 30]])
    }

    @Test func cutsThatMerelyTouchAlsoMerge() {
        var edit = ClipEdit(duration: 30)
        edit.cut(ClipRange(start: 10, end: 15))
        edit.cut(ClipRange(start: 15, end: 20))
        #expect(spans(edit.cuts) == [[10, 20]])
    }

    @Test func severalSeparateCutsStayInOrder() {
        var edit = ClipEdit(duration: 60)
        edit.cut(ClipRange(start: 40, end: 50))
        edit.cut(ClipRange(start: 10, end: 20))
        #expect(spans(edit.cuts) == [[10, 20], [40, 50]])
        #expect(spans(edit.kept) == [[0, 10], [20, 40], [50, 60]])
        #expect(edit.keptDuration == 40)
    }

    @Test func cutsAreHeldInsideTheClip() {
        var edit = ClipEdit(duration: 30)
        edit.cut(ClipRange(start: -10, end: 5))
        edit.cut(ClipRange(start: 25, end: 999))
        #expect(spans(edit.cuts) == [[0, 5], [25, 30]])
        #expect(spans(edit.kept) == [[5, 25]])
    }

    @Test func aBackwardsOrEmptyCutDoesNothing() {
        var edit = ClipEdit(duration: 30)
        edit.cut(ClipRange(start: 20, end: 10))  // reversed: same as 10-20
        #expect(spans(edit.cuts) == [[10, 20]])
        edit.restoreEverything()
        edit.cut(ClipRange(start: 7, end: 7))
        #expect(edit.isUnchanged)
    }

    @Test func cuttingEverythingIsCaughtRatherThanWritingAnEmptyClip() {
        var edit = ClipEdit(duration: 30)
        edit.cut(ClipRange(start: 0, end: 30))
        #expect(edit.isEverythingCut)
        #expect(edit.kept.isEmpty)
        #expect(edit.keptDuration == 0)
    }

    @Test func cuttingOneSectionTwiceChangesNothingTheSecondTime() {
        var edit = ClipEdit(duration: 30)
        edit.cut(ClipRange(start: 10, end: 20))
        let once = edit
        edit.cut(ClipRange(start: 12, end: 18))
        #expect(edit == once)
    }

    /// A trimmed copy is given its source's capture date so the two stay
    /// together when the shoot is sorted. Which of the pair comes first is
    /// decided by the name, so this pins down what that ordering actually is.
    @Test func aTrimmedCopySortsNextToTheClipItCameFrom() {
        let when = Date(timeIntervalSince1970: 1_800_000_000)
        let before = Photo(primary: URL(fileURLWithPath: "/c/C0006.MP4"), kind: .video, modified: when.addingTimeInterval(-10))
        let source = Photo(primary: URL(fileURLWithPath: "/c/C0007.MP4"), kind: .video, modified: when)
        let copy = Photo(primary: URL(fileURLWithPath: "/c/C0007-trimmed.MP4"), kind: .video, modified: when)
        let after = Photo(primary: URL(fileURLWithPath: "/c/C0008.MP4"), kind: .video, modified: when.addingTimeInterval(10))

        let order = [after, copy, before, source].sorted(by: FolderScanner.captureOrder).map(\.name)
        #expect(order.first == "C0006.MP4" && order.last == "C0008.MP4")
        // The pair lands together, whichever way round the name puts them.
        let pair = Set(order[1...2])
        #expect(pair == ["C0007.MP4", "C0007-trimmed.MP4"])
    }
}

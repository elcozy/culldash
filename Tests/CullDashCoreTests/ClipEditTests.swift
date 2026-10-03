import Foundation
import Testing

@testable import CullDashCore

@Suite struct ClipEditTests {
    /// Shorthand so the expectations below read as spans, not constructors.
    private func spans(_ ranges: [ClipRange]) -> [[Double]] {
        ranges.map { [$0.start, $0.end] }
    }

    @Test func startsAsOnePieceCoveringTheWholeClip() {
        let edit = ClipEdit(duration: 30)
        #expect(spans(edit.pieces) == [[0, 30]])
        #expect(edit.isUnchanged)
        #expect(edit.keptDuration == 30)
    }

    @Test func splittingDividesAPieceWithoutChangingTheLength() {
        var edit = ClipEdit(duration: 30)
        let didSplit = edit.split(atOutput: 10)
        #expect(didSplit)
        #expect(spans(edit.pieces) == [[0, 10], [10, 30]])
        // Nothing was dropped, so there is still nothing to export.
        #expect(edit.keptDuration == 30)
        #expect(edit.isUnchanged)
    }

    @Test func splittingOnAJoinOrAnEndDoesNothing() {
        var edit = ClipEdit(duration: 30)
        edit.split(atOutput: 10)
        let onAJoin = edit.split(atOutput: 10)
        let atTheStart = edit.split(atOutput: 0)
        let atTheEnd = edit.split(atOutput: 30)
        #expect(!onAJoin && !atTheStart && !atTheEnd)
        #expect(spans(edit.pieces) == [[0, 10], [10, 30]])
    }

    @Test func droppingAPieceClosesTheGap() {
        var edit = ClipEdit(duration: 30)
        edit.split(atOutput: 10)
        edit.split(atOutput: 20)
        #expect(spans(edit.pieces) == [[0, 10], [10, 20], [20, 30]])

        edit.remove(at: 1)
        // The row is shorter and the parts that remain are flush: no hole.
        #expect(spans(edit.pieces) == [[0, 10], [20, 30]])
        #expect(edit.keptDuration == 20)
        #expect(!edit.isUnchanged)
        // What used to be at source 20 is now at output 10.
        #expect(edit.outputStart(of: 1) == 10)
    }

    @Test func outputTimeMapsBackToTheRightMomentOfTheOriginal() {
        var edit = ClipEdit(duration: 30)
        edit.split(atOutput: 10)
        edit.split(atOutput: 20)
        edit.remove(at: 1)  // 10-20 of the original is gone

        // Before the cut, output and source agree.
        #expect(edit.locate(output: 5)?.source == 5)
        // After it, output 12 is source 22: the ten seconds removed are skipped.
        let after = edit.locate(output: 12)
        #expect(after?.index == 1 && after?.source == 22)
    }

    @Test func removingAnIndexThatIsNotThereIsIgnored() {
        var edit = ClipEdit(duration: 30)
        edit.remove(at: 7)
        edit.remove(at: -1)
        #expect(spans(edit.pieces) == [[0, 30]])
    }

    @Test func cuttingASpanOfTheOriginalLeavesTheTwoEnds() {
        var edit = ClipEdit(duration: 30)
        edit.cut(ClipRange(start: 10, end: 20))
        #expect(spans(edit.pieces) == [[0, 10], [20, 30]])
        #expect(edit.keptDuration == 20)
    }

    @Test func cuttingAcrossSeveralPiecesTakesOutOfEach() {
        var edit = ClipEdit(duration: 30)
        edit.split(atOutput: 10)
        edit.split(atOutput: 20)
        edit.cut(ClipRange(start: 5, end: 25))
        #expect(spans(edit.pieces) == [[0, 5], [25, 30]])
    }

    @Test func trimmingBothEndsKeepsOnlyTheMiddle() {
        var edit = ClipEdit(duration: 30)
        edit.keepOnly(from: 5, to: 25)
        #expect(spans(edit.pieces) == [[5, 25]])
        #expect(edit.keptDuration == 20)
    }

    @Test func cutsAreHeldInsideTheClip() {
        var edit = ClipEdit(duration: 30)
        edit.cut(ClipRange(start: -10, end: 5))
        edit.cut(ClipRange(start: 25, end: 999))
        #expect(spans(edit.pieces) == [[5, 25]])
    }

    @Test func aBackwardsOrEmptyCutDoesNothing() {
        var edit = ClipEdit(duration: 30)
        edit.cut(ClipRange(start: 20, end: 10))  // reversed: same as 10-20
        #expect(spans(edit.pieces) == [[0, 10], [20, 30]])
        edit.restoreEverything()
        edit.cut(ClipRange(start: 7, end: 7))
        #expect(edit.isUnchanged)
    }

    @Test func cuttingEverythingIsCaughtRatherThanWritingAnEmptyClip() {
        var edit = ClipEdit(duration: 30)
        edit.cut(ClipRange(start: 0, end: 30))
        #expect(edit.isEverythingCut)
        #expect(edit.pieces.isEmpty)
        #expect(edit.keptDuration == 0)
        #expect(edit.locate(output: 1) == nil)
    }

    @Test func restoringPutsTheClipBackInOnePiece() {
        var edit = ClipEdit(duration: 30)
        edit.split(atOutput: 10)
        edit.remove(at: 0)
        edit.restoreEverything()
        #expect(spans(edit.pieces) == [[0, 30]])
        #expect(edit.isUnchanged)
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
        #expect(Set(order[1...2]) == ["C0007.MP4", "C0007-trimmed.MP4"])
    }
}

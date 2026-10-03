import Foundation

/// A span of a clip, in seconds from its start.
public struct ClipRange: Hashable, Sendable {
    public var start: Double
    public var end: Double

    public init(start: Double, end: Double) {
        self.start = min(start, end)
        self.end = max(start, end)
    }

    public var duration: Double { end - start }
    public var isEmpty: Bool { duration <= 1e-6 }
}

/// The clip as a row of pieces, the way an editor works on one: split a piece
/// at the playhead, drop the pieces you do not want, and what is left closes
/// up behind them.
///
/// The pieces are the parts kept, not the parts cut, so there is no such thing
/// as a hole: dropping a piece shortens the row, and everything after it moves
/// left. That is why positions come in two flavours. A *source* time is a
/// moment in the original file. An *output* time is a moment in what is left,
/// which is what the strip draws and the playhead runs along.
public struct ClipEdit: Hashable, Sendable {
    /// The original clip's full length.
    public let duration: Double
    /// Source spans, in order, laid end to end when exported. The whole clip
    /// in one piece until something is split or cut.
    public private(set) var pieces: [ClipRange]

    public init(duration: Double) {
        self.duration = max(0, duration)
        pieces = self.duration > 0 ? [ClipRange(start: 0, end: self.duration)] : []
    }

    /// For rebuilding a known row, e.g. in a test.
    public init(duration: Double, pieces: [ClipRange]) {
        self.duration = max(0, duration)
        self.pieces = pieces.filter { !$0.isEmpty }
    }

    // MARK: Where things are

    /// Where a piece begins on the output timeline.
    public func outputStart(of index: Int) -> Double {
        pieces.prefix(max(0, index)).reduce(0) { $0 + $1.duration }
    }

    /// The piece an output time falls in, and how far into the original file
    /// that moment is. `nil` once every piece is gone.
    public func locate(output time: Double) -> (index: Int, source: Double)? {
        guard !pieces.isEmpty else { return nil }
        var remaining = min(max(time, 0), keptDuration)
        for (index, piece) in pieces.enumerated() {
            if remaining <= piece.duration || index == pieces.count - 1 {
                return (index, min(piece.start + remaining, piece.end))
            }
            remaining -= piece.duration
        }
        return nil
    }

    // MARK: Editing

    /// Splits the piece under `time` in two, so either half can be dropped.
    /// Landing on a join does nothing, there being nothing to divide.
    @discardableResult
    public mutating func split(atOutput time: Double) -> Bool {
        guard let (index, source) = locate(output: time) else { return false }
        let piece = pieces[index]
        let head = ClipRange(start: piece.start, end: source)
        let tail = ClipRange(start: source, end: piece.end)
        guard !head.isEmpty, !tail.isEmpty else { return false }
        pieces.replaceSubrange(index...index, with: [head, tail])
        return true
    }

    /// Drops one piece. What is left closes up.
    public mutating func remove(at index: Int) {
        guard pieces.indices.contains(index) else { return }
        pieces.remove(at: index)
    }

    /// Takes a span of the *original* out, wherever it still survives. The row
    /// closes up, as it does for any other removal.
    public mutating func cut(_ range: ClipRange) {
        let span = ClipRange(
            start: min(max(range.start, 0), duration),
            end: min(max(range.end, 0), duration))
        guard !span.isEmpty else { return }
        pieces = pieces.flatMap { piece -> [ClipRange] in
            guard piece.start < span.end, span.start < piece.end else { return [piece] }
            // Each end is built only when there is really something left of
            // it. ClipRange turns a reversed pair the right way round, so
            // handing it one would quietly invent a piece that was cut away.
            var remains: [ClipRange] = []
            if piece.start < span.start {
                remains.append(ClipRange(start: piece.start, end: min(piece.end, span.start)))
            }
            if piece.end > span.end {
                remains.append(ClipRange(start: max(piece.start, span.end), end: piece.end))
            }
            return remains.filter { !$0.isEmpty }
        }
    }

    /// Keeps only `from`–`to` of the original: both ends go.
    public mutating func keepOnly(from start: Double, to end: Double) {
        let keep = ClipRange(start: start, end: end)
        cut(ClipRange(start: 0, end: keep.start))
        cut(ClipRange(start: keep.end, end: duration))
    }

    public mutating func restoreEverything() {
        pieces = duration > 0 ? [ClipRange(start: 0, end: duration)] : []
    }

    // MARK: What is left

    /// The parts kept, in order, which is what gets exported.
    public var kept: [ClipRange] { pieces }

    public var keptDuration: Double { pieces.reduce(0) { $0 + $1.duration } }

    /// Nothing dropped, so exporting would only copy the file. Splitting alone
    /// does not count: the row still adds up to the whole clip.
    public var isUnchanged: Bool { keptDuration >= duration - 1e-6 }

    /// Every piece gone: there would be no clip left to write.
    public var isEverythingCut: Bool { pieces.isEmpty }
}

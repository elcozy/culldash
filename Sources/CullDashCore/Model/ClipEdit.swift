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
    public var isEmpty: Bool { duration <= 0 }
}

/// What a clip keeps when it is exported: the whole thing, minus the sections
/// cut out of it.
///
/// Cuts are held rather than the parts kept, because that is how the trim bar
/// is used — mark a dull stretch, cut it, mark another. The parts kept are
/// worked out from them, so two cuts that overlap can never produce a clip
/// with a gap or a doubled frame.
public struct ClipEdit: Hashable, Sendable {
    /// The clip's full length, which no cut may run past.
    public let duration: Double
    /// In order, none touching or overlapping: `cut` keeps it that way.
    public private(set) var cuts: [ClipRange]

    public init(duration: Double, cuts: [ClipRange] = []) {
        self.duration = max(0, duration)
        self.cuts = []
        for cut in cuts { self.cut(cut) }
    }

    /// Takes a section out. Overlapping or touching cuts merge into one, so
    /// cutting 0–5 and then 3–8 leaves a single 0–8 cut.
    public mutating func cut(_ range: ClipRange) {
        let clamped = ClipRange(
            start: min(max(range.start, 0), duration),
            end: min(max(range.end, 0), duration))
        guard !clamped.isEmpty else { return }

        var merged = clamped
        var rest: [ClipRange] = []
        for existing in cuts {
            // Touching counts as overlapping: two cuts that meet are one cut.
            if existing.start <= merged.end, merged.start <= existing.end {
                merged = ClipRange(
                    start: min(merged.start, existing.start),
                    end: max(merged.end, existing.end))
            } else {
                rest.append(existing)
            }
        }
        rest.append(merged)
        cuts = rest.sorted { $0.start < $1.start }
    }

    /// Keeps only `from`–`to`, which is the head and the tail cut away. This
    /// is what dragging the two handles on the trim bar does.
    public mutating func keepOnly(from start: Double, to end: Double) {
        let keep = ClipRange(start: start, end: end)
        cuts = []
        cut(ClipRange(start: 0, end: keep.start))
        cut(ClipRange(start: keep.end, end: duration))
    }

    public mutating func restoreEverything() { cuts = [] }

    /// The parts that survive, in order. Empty when everything is cut.
    public var kept: [ClipRange] {
        var result: [ClipRange] = []
        var position = 0.0
        for cut in cuts {
            if cut.start > position { result.append(ClipRange(start: position, end: cut.start)) }
            position = max(position, cut.end)
        }
        if position < duration { result.append(ClipRange(start: position, end: duration)) }
        return result.filter { !$0.isEmpty }
    }

    public var keptDuration: Double { kept.reduce(0) { $0 + $1.duration } }

    /// Nothing cut, so exporting would only copy the file.
    public var isUnchanged: Bool { cuts.isEmpty }

    /// Everything cut: there would be no clip left to write.
    public var isEverythingCut: Bool { kept.isEmpty }
}

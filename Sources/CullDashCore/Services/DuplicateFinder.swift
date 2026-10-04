import CryptoKit
import Foundation

/// Finds photos whose files are byte for byte the same, so every copy but one
/// can go.
///
/// Only identical files count. Two frames of the same scene, or the same photo
/// exported twice at different settings, are not duplicates here however alike
/// they look — that is what grouping similar shots is for. The promise this
/// makes is that deleting the extras loses nothing at all.
public enum DuplicateFinder {
    /// How much of each end is read to tell two same-sized files apart.
    static let sampleBytes = 64 * 1024

    /// Photos sharing a file, grouped. Each group holds two or more, in the
    /// order they were given, and a photo appears in at most one group.
    ///
    /// Three passes, each narrower than the last, because reading everything
    /// is far too slow to offer: a card of 2,645 Sony RAWs is 63 GB, and on a
    /// USB drive that is nine minutes.
    ///
    /// 1. **Length**, already known from the folder listing, so it is free.
    ///    It is also a weaker filter than it sounds: a camera writes RAWs of
    ///    nearly fixed length, and 1,799 of those 2,645 frames shared a length
    ///    with another. Length alone would have left almost everything to read.
    /// 2. **Both ends**, 64 KB from the head and 64 KB from the tail. Two
    ///    different frames differ within the first few KB of pixel data, so
    ///    this separates them for about a thousandth of the reading.
    /// 3. **The whole file**, for the few that still agree. Real copies reach
    ///    this pass and are read in full, which is the price of being sure.
    ///
    /// On that card, cold, from a USB drive: nine minutes reading everything,
    /// forty seconds this way, the same answer from both.
    public static func groups(
        in photos: [Photo], progress: (@Sendable (Double) -> Void)? = nil,
        isCancelled: (@Sendable () -> Bool)? = nil
    ) -> [[Photo.ID]] {
        var bySize: [Int64: [Photo]] = [:]
        for photo in photos where photo.size > 0 {
            bySize[photo.size, default: []].append(photo)
        }
        // Dictionary order is not the shoot's order; sorting keeps the result
        // stable from one run to the next.
        let sameLength = bySize.keys.sorted().compactMap { size -> [Photo]? in
            let group = bySize[size]!
            return group.count > 1 ? group : nil
        }
        guard !sameLength.isEmpty else {
            progress?(1)
            return []
        }

        // The ends pass carries the weight, so it gets most of the bar.
        let sampled = refine(sameLength, by: sample, progress: progress, upTo: 0.9, isCancelled: isCancelled)
        if isCancelled?() == true { return [] }
        let certain = refine(sampled, by: digest, progress: progress, upTo: 1, from: 0.9, isCancelled: isCancelled)
        progress?(1)
        return certain.map { $0.map(\.id) }
    }

    /// Splits each bucket by a key read from the file, dropping anything that
    /// ends up alone.
    private static func refine(
        _ buckets: [[Photo]], by key: (URL) -> String?,
        progress: (@Sendable (Double) -> Void)?, upTo ceiling: Double, from floor: Double = 0,
        isCancelled: (@Sendable () -> Bool)?
    ) -> [[Photo]] {
        let total = buckets.reduce(0) { $0 + $1.count }
        guard total > 0 else { return [] }
        var done = 0
        var refined: [[Photo]] = []

        for bucket in buckets {
            var byKey: [String: [Photo]] = [:]
            var order: [String] = []
            for photo in bucket {
                if isCancelled?() == true { return [] }
                done += 1
                progress?(floor + (ceiling - floor) * Double(done) / Double(total))
                guard let value = key(photo.primary) else { continue }
                if byKey[value] == nil { order.append(value) }
                byKey[value, default: []].append(photo)
            }
            // Keyed by digest, so the shoot's own order is kept by hand.
            for value in order where (byKey[value]?.count ?? 0) > 1 {
                refined.append(byKey[value]!)
            }
        }
        return refined
    }

    /// 64 KB from each end, which is enough to tell two frames apart without
    /// reading the 37 MB between them.
    static func sample(of url: URL) -> String? {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? handle.close() }
        var hasher = SHA256()
        guard let head = try? handle.read(upToCount: sampleBytes) else { return nil }
        hasher.update(data: head)
        if let end = try? handle.seekToEnd(), end > UInt64(sampleBytes) {
            try? handle.seek(toOffset: end - UInt64(sampleBytes))
            if let tail = try? handle.read(upToCount: sampleBytes) { hasher.update(data: tail) }
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }

    /// The whole file through SHA-256, a megabyte at a time so a 300 MB clip
    /// never has to be held in memory. Different files cannot collide here in
    /// any way worth guarding against.
    static func digest(of url: URL) -> String? {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? handle.close() }
        var hasher = SHA256()
        while let chunk = try? handle.read(upToCount: 1 << 20), !chunk.isEmpty {
            hasher.update(data: chunk)
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }
}

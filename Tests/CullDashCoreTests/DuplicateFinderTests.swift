import Foundation
import Testing

@testable import CullDashCore

@Suite struct DuplicateFinderTests {
    /// Files with real, differing contents, so the hashing is genuinely exercised.
    private func makeFolder(_ files: [(String, String)]) throws -> URL {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        for (name, contents) in files {
            try Data(contents.utf8).write(to: folder.appendingPathComponent(name))
        }
        return folder
    }

    private func names(_ groups: [[Photo.ID]]) -> [[String]] {
        groups.map { $0.map(\.lastPathComponent) }
    }

    @Test func findsFilesThatAreByteForByteTheSame() throws {
        let folder = try makeFolder([
            ("a.ARW", "one"), ("b.ARW", "one"), ("c.ARW", "two"),
        ])
        let photos = try FolderScanner.scan(folder)
        #expect(photos.count == 3)
        let groups = DuplicateFinder.groups(in: photos)
        #expect(names(groups) == [["a.ARW", "b.ARW"]])
    }

    @Test func sameLengthButDifferentContentIsNotADuplicate() throws {
        // Identical sizes, so the cheap check passes and the contents decide.
        let folder = try makeFolder([("a.ARW", "abc"), ("b.ARW", "xyz")])
        let photos = try FolderScanner.scan(folder)
        #expect(photos.map(\.size) == [3, 3])
        #expect(DuplicateFinder.groups(in: photos).isEmpty)
    }

    @Test func differentLengthsAreNeverRead() throws {
        let folder = try makeFolder([("a.ARW", "short"), ("b.ARW", "much longer contents")])
        let photos = try FolderScanner.scan(folder)
        var reported: [Double] = []
        let groups = DuplicateFinder.groups(in: photos) { reported.append($0) }
        #expect(groups.isEmpty)
        // Nothing to compare, so it finishes without reading a byte.
        #expect(reported == [1])
    }

    @Test func threeCopiesComeBackAsOneGroupOfThree() throws {
        let folder = try makeFolder([
            ("a.ARW", "same"), ("b.ARW", "same"), ("c.ARW", "same"), ("d.ARW", "other"),
        ])
        let photos = try FolderScanner.scan(folder)
        let groups = DuplicateFinder.groups(in: photos)
        #expect(names(groups) == [["a.ARW", "b.ARW", "c.ARW"]])
    }

    @Test func severalSeparateSetsOfDuplicates() throws {
        let folder = try makeFolder([
            ("a.ARW", "one"), ("b.ARW", "one"),
            ("c.ARW", "twotwo"), ("d.ARW", "twotwo"),
        ])
        let photos = try FolderScanner.scan(folder)
        let groups = DuplicateFinder.groups(in: photos)
        #expect(groups.count == 2)
        #expect(Set(names(groups).map(Set.init)) == [["a.ARW", "b.ARW"], ["c.ARW", "d.ARW"]])
    }

    @Test func emptyFilesAreLeftAlone() throws {
        // A zero-byte file is identical to every other zero-byte file, which
        // is never what someone means by a duplicate photo.
        let folder = try makeFolder([("a.ARW", ""), ("b.ARW", "")])
        let photos = try FolderScanner.scan(folder)
        #expect(DuplicateFinder.groups(in: photos).isEmpty)
    }

    @Test func progressRunsToTheEndAndCancellingGivesNothing() throws {
        let folder = try makeFolder([("a.ARW", "same"), ("b.ARW", "same")])
        let photos = try FolderScanner.scan(folder)
        var reported: [Double] = []
        _ = DuplicateFinder.groups(in: photos) { reported.append($0) }
        #expect(reported.last == 1)

        #expect(DuplicateFinder.groups(in: photos, isCancelled: { true }).isEmpty)
    }

    @Test func aDigestIsStableAndTellsFilesApart() throws {
        let folder = try makeFolder([("a.ARW", "one"), ("b.ARW", "one"), ("c.ARW", "two")])
        let a = DuplicateFinder.digest(of: folder.appendingPathComponent("a.ARW"))
        let b = DuplicateFinder.digest(of: folder.appendingPathComponent("b.ARW"))
        let c = DuplicateFinder.digest(of: folder.appendingPathComponent("c.ARW"))
        #expect(a != nil && a == b && a != c)
        #expect(DuplicateFinder.digest(of: folder.appendingPathComponent("missing.ARW")) == nil)
    }

    /// The sampled pass must not call two different files the same, even when
    /// they agree on length and on both ends — which is what a long run of
    /// identical padding in the middle would look like.
    @Test func filesAlikeAtBothEndsButNotInTheMiddleAreNotDuplicates() throws {
        let head = String(repeating: "H", count: 70_000)
        let tail = String(repeating: "T", count: 70_000)
        let folder = try makeFolder([
            ("a.ARW", head + "LEFT" + tail),
            ("b.ARW", head + "RGHT" + tail),
            ("c.ARW", head + "LEFT" + tail),
        ])
        let photos = try FolderScanner.scan(folder)
        #expect(Set(photos.map(\.size)).count == 1)  // same length
        // The ends agree, so the full read is what separates them.
        let ends = photos.map { DuplicateFinder.sample(of: $0.primary) }
        #expect(Set(ends).count == 1)
        #expect(names(DuplicateFinder.groups(in: photos)) == [["a.ARW", "c.ARW"]])
    }

    @Test func aSampleReadsBothEndsAndTellsShortFilesApart() throws {
        let folder = try makeFolder([("a.ARW", "one"), ("b.ARW", "one"), ("c.ARW", "two")])
        let a = DuplicateFinder.sample(of: folder.appendingPathComponent("a.ARW"))
        let b = DuplicateFinder.sample(of: folder.appendingPathComponent("b.ARW"))
        let c = DuplicateFinder.sample(of: folder.appendingPathComponent("c.ARW"))
        #expect(a != nil && a == b && a != c)
        #expect(DuplicateFinder.sample(of: folder.appendingPathComponent("missing.ARW")) == nil)
    }
}

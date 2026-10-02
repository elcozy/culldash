import Foundation
import Testing

@testable import WinnowCore

@Suite struct FolderScannerTests {
    @Test func pairsRawWithJpegAndSkipsJunk() throws {
        let folder = try makeFolder([
            "DSC01850.ARW", "DSC01850.JPG", "._DSC01850.ARW", "DSCF0001.RAF", "notes.txt", "DSC01851.jpg",
        ])
        let photos = try FolderScanner.scan(folder)
        #expect(photos.map(\.name).sorted() == ["DSC01850.ARW", "DSC01851.jpg", "DSCF0001.RAF"])
        let paired = try #require(photos.first { $0.name == "DSC01850.ARW" })
        #expect(paired.kind == .raw)
        #expect(paired.companions.map(\.lastPathComponent) == ["DSC01850.JPG"])
    }

    @Test func readsExistingSidecars() throws {
        let folder = try makeFolder(["DSC01850.ARW"])
        try XMPSidecar.write(Culling(flag: .pick, rating: 4), to: folder.appendingPathComponent("DSC01850.xmp"))
        let photos = try FolderScanner.scan(folder)
        #expect(photos.first?.culling == Culling(flag: .pick, rating: 4))
    }

    @Test func ordersByCaptureTimeAcrossCameras() throws {
        let folder = try makeFolder(["DSCF0002.RAF", "DSC01850.ARW", "DSCF0001.RAF"])
        let base = Date(timeIntervalSince1970: 1_800_000_000)
        try stamp(folder, "DSCF0001.RAF", base)
        try stamp(folder, "DSC01850.ARW", base.addingTimeInterval(5))
        try stamp(folder, "DSCF0002.RAF", base.addingTimeInterval(10))
        #expect(try FolderScanner.scan(folder).map(\.name) == ["DSCF0001.RAF", "DSC01850.ARW", "DSCF0002.RAF"])
    }

    @Test func readsSeveralFoldersAsOneShoot() throws {
        let card = try makeFolder([])
        for (folder, name) in [("100MSDCF", "DSC00001.ARW"), ("101MSDCF", "DSC00001.ARW")] {
            let url = card.appendingPathComponent(folder)
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            try Data().write(to: url.appendingPathComponent(name))
        }
        let photos = try FolderScanner.scan([card.appendingPathComponent("100MSDCF"), card.appendingPathComponent("101MSDCF")])
        #expect(photos.count == 2)  // same name, different folders: two photos
    }

    @Test func findsPhotoFoldersAndSkipsCameraHousekeeping() throws {
        let card = try makeFolder([])
        for path in ["DCIM/100MSDCF/DSC00001.ARW", "DCIM/101MSDCF/DSC00002.ARW", "PRIVATE/M4ROOT/THMBNL/C0001.JPG"] {
            let url = card.appendingPathComponent(path)
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Data().write(to: url)
        }
        #expect(StorageScanner.shootFolders(in: card).map(\.path) == ["DCIM/100MSDCF", "DCIM/101MSDCF"])
    }

    @Test func filterMatchesFlagsStarsKindAndName() {
        let raw = Photo(primary: URL(fileURLWithPath: "/c/DSC01612.ARW"), kind: .raw, modified: .now, culling: Culling(flag: .pick, rating: 3))
        let jpeg = Photo(primary: URL(fileURLWithPath: "/c/DSCF0001.JPG"), kind: .image, modified: .now)
        #expect(PhotoFilter(flag: .picks).matches(raw))
        #expect(!PhotoFilter(flag: .rejects).matches(raw))
        #expect(PhotoFilter(minStars: 3).matches(raw) && !PhotoFilter(minStars: 4).matches(raw))
        #expect(PhotoFilter(flag: .unflagged).matches(jpeg))
        #expect(PhotoFilter(kind: .raw).matches(raw) && !PhotoFilter(kind: .raw).matches(jpeg))
        #expect(PhotoFilter(kind: .other).matches(jpeg))
        #expect(PhotoFilter(search: "01612").matches(raw) && !PhotoFilter(search: "01612").matches(jpeg))
        #expect(PhotoFilter(search: "dscf").matches(jpeg))
    }

    @Test func trashedPhotosComeBack() throws {
        let folder = try makeFolder(["DSC09999.ARW", "DSC09999.JPG"])
        let photo = try #require(try FolderScanner.scan(folder).first)
        let moved = try PhotoTrash.trash(photo)
        #expect(moved.count == 2)
        #expect(try FolderScanner.scan(folder).isEmpty)
        try PhotoTrash.restore(moved)
        #expect(try FolderScanner.scan(folder).count == 1)
    }

    @Test func formatsShutterSpeeds() {
        #expect(ExposureInfo.formatShutter(0.00625) == "1/160 s")
        #expect(ExposureInfo.formatShutter(0.004) == "1/250 s")
        #expect(ExposureInfo.formatShutter(0.5) == "0.5 s")
        #expect(ExposureInfo.formatShutter(2) == "2 s")
        #expect(ExposureInfo(aperture: 1.7, iso: 400).settings == ["ƒ/1.7", "ISO 400"])
        let date = ExposureInfo.parseDate("2025:06:01 14:03:22", subseconds: "47")
        let base = ExposureInfo.parseDate("2025:06:01 14:03:22", subseconds: nil)
        #expect(date != nil && abs(date!.timeIntervalSince(base!) - 0.47) < 0.001)
    }

    private func makeFolder(_ names: [String]) throws -> URL {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        for name in names {
            try Data().write(to: folder.appendingPathComponent(name))
        }
        return folder
    }

    private func stamp(_ folder: URL, _ name: String, _ date: Date) throws {
        try FileManager.default.setAttributes(
            [.modificationDate: date], ofItemAtPath: folder.appendingPathComponent(name).path)
    }
}

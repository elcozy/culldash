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

    @Test func filterMatchesFlagsAndStars() {
        let pick3 = Culling(flag: .pick, rating: 3)
        #expect(PhotoFilter(flag: .picks).matches(pick3))
        #expect(!PhotoFilter(flag: .rejects).matches(pick3))
        #expect(PhotoFilter(minStars: 3).matches(pick3))
        #expect(!PhotoFilter(minStars: 4).matches(pick3))
        #expect(PhotoFilter(flag: .unflagged).matches(Culling()))
    }

    @Test func formatsShutterSpeeds() {
        #expect(ExposureInfo.formatShutter(0.00625) == "1/160 s")
        #expect(ExposureInfo.formatShutter(0.004) == "1/250 s")
        #expect(ExposureInfo.formatShutter(0.5) == "0.5 s")
        #expect(ExposureInfo.formatShutter(2) == "2 s")
        #expect(ExposureInfo(aperture: 1.7, iso: 400).settings == ["ƒ/1.7", "ISO 400"])
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

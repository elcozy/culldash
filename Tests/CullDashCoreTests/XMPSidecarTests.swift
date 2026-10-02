import Foundation
import Testing

@testable import CullDashCore

@Suite struct XMPSidecarTests {
    let folder: URL

    init() throws {
        folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    }

    @Test func roundTripsEveryDecision() throws {
        let url = folder.appendingPathComponent("DSC01850.xmp")
        let culling = Culling(flag: .pick, rating: 4, label: .green)
        try XMPSidecar.write(culling, to: url)
        #expect(XMPSidecar.read(url) == culling)
    }

    @Test func writesRejectAsBridgeDoes() throws {
        let url = folder.appendingPathComponent("DSC01851.xmp")
        try XMPSidecar.write(Culling(flag: .reject, rating: 3), to: url)
        let xml = try String(contentsOf: url, encoding: .utf8)
        #expect(xml.contains("xmp:Rating=\"-1\""))
        #expect(XMPSidecar.read(url)?.flag == .reject)
    }

    @Test func readsBridgeRejectWithoutCullDashField() throws {
        let url = folder.appendingPathComponent("bridge.xmp")
        try sidecar(attributes: "xmp:Rating=\"-1\"").write(to: url, atomically: true, encoding: .utf8)
        #expect(XMPSidecar.read(url) == Culling(flag: .reject))
    }

    @Test func readsRatingWrittenAsElement() throws {
        let url = folder.appendingPathComponent("element.xmp")
        try sidecar(attributes: "", body: "<xmp:Rating>5</xmp:Rating><xmp:Label>Blue</xmp:Label>")
            .write(to: url, atomically: true, encoding: .utf8)
        #expect(XMPSidecar.read(url) == Culling(rating: 5, label: .blue))
    }

    @Test func keepsOtherAppsSettings() throws {
        let url = folder.appendingPathComponent("lightroom.xmp")
        let crs = "xmlns:crs=\"http://ns.adobe.com/camera-raw-settings/1.0/\" crs:Exposure2012=\"+0.50\""
        try sidecar(attributes: crs + " xmp:Rating=\"2\"").write(to: url, atomically: true, encoding: .utf8)
        try XMPSidecar.write(Culling(rating: 5), to: url)
        let xml = try String(contentsOf: url, encoding: .utf8)
        #expect(xml.contains("crs:Exposure2012=\"+0.50\""))
        #expect(XMPSidecar.read(url) == Culling(rating: 5))
    }

    @Test func clearsFieldsWhenUndecided() throws {
        let url = folder.appendingPathComponent("clear.xmp")
        try XMPSidecar.write(Culling(flag: .pick, rating: 3, label: .red), to: url)
        try XMPSidecar.write(Culling(), to: url)
        let xml = try String(contentsOf: url, encoding: .utf8)
        #expect(!xml.contains("Rating") && !xml.contains("Label") && !xml.contains("culldash:Flag"))
    }

    @Test func writesNothingForAnUndecidedNewPhoto() throws {
        let url = folder.appendingPathComponent("none.xmp")
        try XMPSidecar.write(Culling(), to: url)
        #expect(!FileManager.default.fileExists(atPath: url.path))
    }

    private func sidecar(attributes: String, body: String = "") -> String {
        """
        <x:xmpmeta xmlns:x="adobe:ns:meta/"><rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
        <rdf:Description rdf:about="" xmlns:xmp="http://ns.adobe.com/xap/1.0/" \(attributes)>\(body)</rdf:Description>
        </rdf:RDF></x:xmpmeta>
        """
    }
}

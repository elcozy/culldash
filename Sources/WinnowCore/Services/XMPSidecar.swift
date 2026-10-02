import Foundation

/// Reads and writes the XMP sidecar files that Bridge, Lightroom, Capture One
/// and darktable all understand, so decisions made here follow the photos.
///
/// Stars go in `xmp:Rating` and colour in `xmp:Label`. A reject is written as
/// rating -1, Bridge's convention. Picks have no standard field, so they are
/// kept in Winnow's own `winnow:Flag`, which other apps ignore. An existing
/// sidecar is edited in place: develop settings other apps stored in it stay.
public enum XMPSidecar {
    static let xmpNS = "http://ns.adobe.com/xap/1.0/"
    static let winnowNS = "https://winnow.app/ns/1.0/"

    static let template = """
        <?xml version="1.0" encoding="UTF-8"?>
        <x:xmpmeta xmlns:x="adobe:ns:meta/" x:xmptk="Winnow">
         <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
          <rdf:Description rdf:about="" xmlns:xmp="http://ns.adobe.com/xap/1.0/"/>
         </rdf:RDF>
        </x:xmpmeta>
        """

    public static func read(_ url: URL) -> Culling? {
        guard let document = try? XMLDocument(contentsOf: url, options: []),
            let description = description(in: document)
        else { return nil }
        let rating = Int(value(of: "Rating", in: xmpNS, on: description) ?? "") ?? 0
        let label = ColorLabel(rawValue: value(of: "Label", in: xmpNS, on: description) ?? "") ?? .none
        var flag = Flag(rawValue: value(of: "Flag", in: winnowNS, on: description) ?? "") ?? .none
        if flag == .none && rating < 0 { flag = .reject }
        return Culling(flag: flag, rating: rating, label: label)
    }

    public static func write(_ culling: Culling, to url: URL) throws {
        let exists = FileManager.default.fileExists(atPath: url.path)
        // No decision and no file yet: don't litter the card with empty sidecars.
        if !exists && culling.isEmpty { return }
        let document =
            exists ? try XMLDocument(contentsOf: url, options: []) : try XMLDocument(xmlString: template, options: [])
        guard let description = description(in: document) else { throw CocoaError(.fileReadCorruptFile) }

        let rating: String? =
            culling.flag == .reject ? "-1" : (culling.rating > 0 ? String(culling.rating) : nil)
        set("Rating", prefix: "xmp", in: xmpNS, to: rating, on: description)
        set("Label", prefix: "xmp", in: xmpNS, to: culling.label == .none ? nil : culling.label.rawValue, on: description)
        set("Flag", prefix: "winnow", in: winnowNS, to: culling.flag == .none ? nil : culling.flag.rawValue, on: description)
        try document.xmlData(options: [.nodePrettyPrint]).write(to: url, options: .atomic)
    }

    static func description(in document: XMLDocument) -> XMLElement? {
        (try? document.nodes(forXPath: "//*[local-name()='Description']"))?.first as? XMLElement
    }

    /// Writers store a field either as an attribute or as a child element.
    static func value(of name: String, in namespace: String, on element: XMLElement) -> String? {
        element.attribute(forLocalName: name, uri: namespace)?.stringValue
            ?? element.elements(forLocalName: name, uri: namespace).first?.stringValue
    }

    /// Sets the field as an attribute (removing any element form), or removes it when `value` is nil.
    static func set(_ name: String, prefix: String, in namespace: String, to value: String?, on element: XMLElement) {
        for child in element.elements(forLocalName: name, uri: namespace).reversed() {
            element.removeChild(at: child.index)
        }
        if let attribute = element.attribute(forLocalName: name, uri: namespace) {
            if let value {
                attribute.stringValue = value
            } else if let qualified = attribute.name {
                element.removeAttribute(forName: qualified)
            }
            return
        }
        guard let value else { return }
        let usedPrefix = element.resolvePrefix(forNamespaceURI: namespace) ?? {
            element.addNamespace(XMLNode.namespace(withName: prefix, stringValue: namespace) as! XMLNode)
            return prefix
        }()
        element.addAttribute(
            XMLNode.attribute(withName: "\(usedPrefix):\(name)", uri: namespace, stringValue: value) as! XMLNode
        )
    }
}

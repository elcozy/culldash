import CoreLocation
import Foundation
import MapKit

/// Turns a photo's GPS position into a place name ("Shoreditch, London").
/// Apple's geocoder needs the network and is rate limited, so names are
/// cached by rounded position and photos from one spot ask only once.
@MainActor
final class PlaceNames {
    static let shared = PlaceNames()
    private var names: [String: String] = [:]

    func name(latitude: Double, longitude: Double) async -> String? {
        // About 100 m: a whole shoot in one place shares one lookup.
        let key = String(format: "%.3f,%.3f", latitude, longitude)
        if let known = names[key] { return known }
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let found: String?
        if #available(macOS 26, *) {
            found = await Self.lookUp(location)
        } else {
            found = await Self.legacyLookUp(location)
        }
        if let found { names[key] = found }
        return found
    }

    @available(macOS 26, *)
    private static func lookUp(_ location: CLLocation) async -> String? {
        guard let request = MKReverseGeocodingRequest(location: location),
            let item = try? await request.mapItems.first
        else { return nil }
        return item.addressRepresentations?.cityWithContext ?? item.address?.shortAddress
    }

    /// macOS 14 and 15, before MapKit took over reverse geocoding.
    @available(macOS, deprecated: 26, message: "Only used before macOS 26")
    private static func legacyLookUp(_ location: CLLocation) async -> String? {
        guard let place = try? await CLGeocoder().reverseGeocodeLocation(location).first else { return nil }
        var parts: [String] = []
        for part in [place.subLocality ?? place.name, place.locality, place.country].compactMap({ $0 }) where !parts.contains(part) {
            parts.append(part)
        }
        return parts.prefix(3).joined(separator: ", ")
    }
}

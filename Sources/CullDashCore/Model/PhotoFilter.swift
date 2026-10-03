import Foundation

/// Which flags are shown.
public enum FlagFilter: String, CaseIterable, Hashable, Sendable {
    case all
    case picks
    case unflagged
    case rejects

    public var title: String {
        switch self {
        case .all: "All"
        case .picks: "Picks"
        case .unflagged: "Unflagged"
        case .rejects: "Rejects"
        }
    }
}

extension FileKind: CaseIterable {
    public static let allCases: [FileKind] = [.raw, .image, .video]

    /// As the filter menu names it. A RAW with a JPEG beside it counts as RAW.
    public var title: String {
        switch self {
        case .raw: "RAW"
        case .image: "JPEG and other images"
        case .video: "Videos"
        }
    }
}

/// Which photos are shown, and so which ones "Send to" hands over.
///
/// Every part narrows what the one before it left, so they combine: 3★ and up,
/// from the a6400, RAW only, named "DSCF" is a single list. Within one part,
/// several choices widen it — two cameras means photos from either.
public struct PhotoFilter: Hashable, Sendable {
    public var flag: FlagFilter
    /// Only photos with at least this many stars; 0 shows every rating.
    public var minStars: Int
    /// Empty shows every kind of file; otherwise only these kinds.
    public var kinds: Set<FileKind>
    /// Empty shows every camera; otherwise only photos from these. Matched
    /// against `Photo.camera`, which is filled in as the shoot is read.
    public var cameras: Set<String>
    /// Part of a file name, e.g. "01612" or "DSCF"; empty matches everything.
    public var search: String

    public init(
        flag: FlagFilter = .all, minStars: Int = 0, kinds: Set<FileKind> = [],
        cameras: Set<String> = [], search: String = ""
    ) {
        self.flag = flag
        self.minStars = minStars
        self.kinds = kinds
        self.cameras = cameras
        self.search = search
    }

    /// How many parts beyond the flag and the search are narrowing the list,
    /// for the Filters button's badge.
    public var extraCount: Int {
        (minStars > 0 ? 1 : 0) + (kinds.isEmpty ? 0 : 1) + (cameras.isEmpty ? 0 : 1)
    }

    /// True when only the flag segment and the search box are deciding, so
    /// "Clear filters" has nothing to do.
    public var isUnrestricted: Bool { extraCount == 0 }

    /// Drops everything the Filters menu sets, leaving the flag and the search.
    public mutating func clearExtras() {
        minStars = 0
        kinds = []
        cameras = []
    }

    public func matches(_ photo: Photo) -> Bool {
        let culling = photo.culling
        let flagMatches =
            switch flag {
            case .all: true
            case .picks: culling.flag == .pick
            case .unflagged: culling.flag == .none
            case .rejects: culling.flag == .reject
            }
        let kindMatches = kinds.isEmpty || kinds.contains(photo.kind)
        // A photo whose camera has not been read yet matches nothing, so the
        // list only ever grows as the shoot is read, never jumps about.
        let cameraMatches = cameras.isEmpty || photo.camera.map(cameras.contains) == true
        let query = search.trimmingCharacters(in: .whitespaces)
        let nameMatches = query.isEmpty || photo.allFiles.contains { $0.lastPathComponent.localizedCaseInsensitiveContains(query) }
        return flagMatches && kindMatches && cameraMatches && nameMatches && culling.rating >= minStars
    }
}

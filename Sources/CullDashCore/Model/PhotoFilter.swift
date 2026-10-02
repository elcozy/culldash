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

/// Which kinds of file are shown. A RAW with a JPEG beside it counts as RAW.
public enum KindFilter: String, CaseIterable, Hashable, Sendable {
    case all
    case raw
    case other

    public var title: String {
        switch self {
        case .all: "All files"
        case .raw: "RAW only"
        case .other: "JPEG and other"
        }
    }
}

/// Which photos are shown, and so which ones "Send to" hands over.
public struct PhotoFilter: Hashable, Sendable {
    public var flag: FlagFilter
    /// Only photos with at least this many stars; 0 shows every rating.
    public var minStars: Int
    public var kind: KindFilter
    /// Part of a file name, e.g. "01612" or "DSCF"; empty matches everything.
    public var search: String

    public init(flag: FlagFilter = .all, minStars: Int = 0, kind: KindFilter = .all, search: String = "") {
        self.flag = flag
        self.minStars = minStars
        self.kind = kind
        self.search = search
    }

    /// Anything narrower than "all files, any rating", for the Filters button's badge.
    public var extraCount: Int { (minStars > 0 ? 1 : 0) + (kind == .all ? 0 : 1) }

    public func matches(_ photo: Photo) -> Bool {
        let culling = photo.culling
        let flagMatches =
            switch flag {
            case .all: true
            case .picks: culling.flag == .pick
            case .unflagged: culling.flag == .none
            case .rejects: culling.flag == .reject
            }
        let kindMatches =
            switch kind {
            case .all: true
            case .raw: photo.kind == .raw
            case .other: photo.kind == .image
            }
        let query = search.trimmingCharacters(in: .whitespaces)
        let nameMatches = query.isEmpty || photo.allFiles.contains { $0.lastPathComponent.localizedCaseInsensitiveContains(query) }
        return flagMatches && kindMatches && nameMatches && culling.rating >= minStars
    }
}

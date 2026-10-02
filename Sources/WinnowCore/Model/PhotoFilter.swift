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

/// Which photos are shown, and so which ones "Send to" hands over.
public struct PhotoFilter: Hashable, Sendable {
    public var flag: FlagFilter
    /// Only photos with at least this many stars; 0 shows every rating.
    public var minStars: Int

    public init(flag: FlagFilter = .all, minStars: Int = 0) {
        self.flag = flag
        self.minStars = minStars
    }

    public func matches(_ culling: Culling) -> Bool {
        let flagMatches =
            switch flag {
            case .all: true
            case .picks: culling.flag == .pick
            case .unflagged: culling.flag == .none
            case .rejects: culling.flag == .reject
            }
        return flagMatches && culling.rating >= minStars
    }
}

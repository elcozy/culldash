/// Whether a photo is kept, thrown out, or not decided yet.
public enum Flag: String, Hashable, Sendable, CaseIterable {
    case none
    case pick
    case reject
}

/// Colour labels, named as Bridge and Lightroom write them to `xmp:Label`.
public enum ColorLabel: String, Hashable, Sendable, CaseIterable {
    case none = ""
    case red = "Red"
    case yellow = "Yellow"
    case green = "Green"
    case blue = "Blue"
    case purple = "Purple"

    /// The label a number key sets (6–9), the same keys Bridge and Lightroom use.
    public static func forKey(_ digit: Int) -> ColorLabel? {
        switch digit {
        case 6: .red
        case 7: .yellow
        case 8: .green
        case 9: .blue
        default: nil
        }
    }
}

/// Everything decided about one photo: its flag, its stars and its colour.
public struct Culling: Hashable, Sendable {
    public var flag: Flag
    /// 0 (unrated) to 5.
    public var rating: Int
    public var label: ColorLabel

    public init(flag: Flag = .none, rating: Int = 0, label: ColorLabel = .none) {
        self.flag = flag
        self.rating = min(max(rating, 0), 5)
        self.label = label
    }

    /// Nothing decided yet, so there is no reason to write a sidecar.
    public var isEmpty: Bool { self == Culling() }
}

/// A device-independent color model that preserves the space it was authored in.
///
/// UIKit's `UIColor` and SwiftUI's `Color` are tied to rendering and aren't a
/// clean value model you can compute with. `Color` is: it stores a color in
/// whatever space you created it (sRGB stays sRGB, Display P3 stays P3, OKLCH
/// stays OKLCH) and converts only on demand, routing every conversion through
/// the CIE XYZ connection space.
///
/// ```swift
/// let brand = Color(hex: "#3B82F6")!          // stored as sRGB
/// let wide  = Color(DisplayP3(red: 1, green: 0, blue: 0))
/// brand.oklch        // convert on demand
/// brand.hsl
/// wide.converted(to: OKLCH.self)
/// ```
public struct Color: Sendable, Hashable {
    /// Preserves the authored space so same-space reads are exact (no round-trip
    /// through the connection space).
    enum Storage: Sendable, Hashable {
        case sRGB(SRGB)
        case linearSRGB(LinearSRGB)
        case displayP3(DisplayP3)
        case hsl(HSL)
        case hsv(HSV)
        case oklab(OKLab)
        case oklch(OKLCH)
        case xyz(XYZ)
        /// A user-defined ``ColorRepresentation``. Stored and read back exactly
        /// in memory; serializes as XYZ (an unknown type can't be reconstructed).
        case custom(any ColorRepresentation)

        var representation: any ColorRepresentation {
            switch self {
            case .sRGB(let v): v
            case .linearSRGB(let v): v
            case .displayP3(let v): v
            case .hsl(let v): v
            case .hsv(let v): v
            case .oklab(let v): v
            case .oklch(let v): v
            case .xyz(let v): v
            case .custom(let v): v
            }
        }

        var space: ColorSpace {
            switch self {
            case .sRGB: .sRGB
            case .linearSRGB: .linearSRGB
            case .displayP3: .displayP3
            case .hsl: .hsl
            case .hsv: .hsv
            case .oklab: .oklab
            case .oklch: .oklch
            case .xyz: .xyz
            case .custom: .custom
            }
        }

        func withAlpha(_ alpha: Double) -> Storage {
            let a = alpha.clamped(to: 0...1)
            switch self {
            case .sRGB(var v): v.alpha = a; return .sRGB(v)
            case .linearSRGB(var v): v.alpha = a; return .linearSRGB(v)
            case .displayP3(var v): v.alpha = a; return .displayP3(v)
            case .hsl(var v): v.alpha = a; return .hsl(v)
            case .hsv(var v): v.alpha = a; return .hsv(v)
            case .oklab(var v): v.alpha = a; return .oklab(v)
            case .oklch(var v): v.alpha = a; return .oklch(v)
            case .xyz(var v): v.alpha = a; return .xyz(v)
            case .custom(var v): v.alpha = a; return .custom(v)
            }
        }

        // `any ColorRepresentation` isn't Hashable on its own (the protocol's
        // `Self` requirements), so the compiler can't synthesize this with a
        // `.custom` case — hand-write it, boxing the custom value via `AnyHashable`.
        static func == (lhs: Storage, rhs: Storage) -> Bool {
            switch (lhs, rhs) {
            case let (.sRGB(a), .sRGB(b)): a == b
            case let (.linearSRGB(a), .linearSRGB(b)): a == b
            case let (.displayP3(a), .displayP3(b)): a == b
            case let (.hsl(a), .hsl(b)): a == b
            case let (.hsv(a), .hsv(b)): a == b
            case let (.oklab(a), .oklab(b)): a == b
            case let (.oklch(a), .oklch(b)): a == b
            case let (.xyz(a), .xyz(b)): a == b
            case let (.custom(a), .custom(b)): AnyHashable(a) == AnyHashable(b)
            default: false
            }
        }

        func hash(into hasher: inout Hasher) {
            switch self {
            case .sRGB(let v): hasher.combine(0); hasher.combine(v)
            case .linearSRGB(let v): hasher.combine(1); hasher.combine(v)
            case .displayP3(let v): hasher.combine(2); hasher.combine(v)
            case .hsl(let v): hasher.combine(3); hasher.combine(v)
            case .hsv(let v): hasher.combine(4); hasher.combine(v)
            case .oklab(let v): hasher.combine(5); hasher.combine(v)
            case .oklch(let v): hasher.combine(6); hasher.combine(v)
            case .xyz(let v): hasher.combine(7); hasher.combine(v)
            case .custom(let v): hasher.combine(8); hasher.combine(AnyHashable(v))
            }
        }
    }

    var storage: Storage

    init(storage: Storage) {
        self.storage = storage
    }

    /// The color in the CIE XYZ (D65) connection space.
    public var xyz: XYZ { storage.representation.toXYZ() }

    /// The color space this value is stored in. The matching accessor reads it
    /// back exactly — a `.oklch`-stored color returns its `oklch` with no
    /// round-trip through the connection space.
    public var space: ColorSpace { storage.space }

    /// Opacity, `0...1`.
    public var alpha: Double {
        get { storage.representation.alpha }
        set { storage = storage.withAlpha(newValue) }
    }

    /// Convert to any color space. The conversion is exact (no round-trip) when
    /// the requested space is the one the color is stored in.
    public func converted<Target: ColorRepresentation>(to type: Target.Type = Target.self) -> Target {
        if let exact = storage.representation as? Target { return exact }
        return Target.fromXYZ(xyz)
    }
}

// MARK: - Space accessors

public extension Color {
    var srgb: SRGB { converted(to: SRGB.self) }
    var linearSRGB: LinearSRGB { converted(to: LinearSRGB.self) }
    var displayP3: DisplayP3 { converted(to: DisplayP3.self) }
    var hsl: HSL { converted(to: HSL.self) }
    var hsv: HSV { converted(to: HSV.self) }
    /// Alias for ``hsv`` using Apple/Adobe's "HSB" terminology.
    var hsb: HSV { hsv }
    var oklab: OKLab { converted(to: OKLab.self) }
    var oklch: OKLCH { converted(to: OKLCH.self) }

    /// Return a copy with a different opacity.
    func alpha(_ value: Double) -> Color {
        Color(storage: storage.withAlpha(value))
    }
}

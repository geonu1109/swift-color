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

        var space: any ColorSpace {
            switch self {
            case .sRGB(let v): v
            case .linearSRGB(let v): v
            case .displayP3(let v): v
            case .hsl(let v): v
            case .hsv(let v): v
            case .oklab(let v): v
            case .oklch(let v): v
            case .xyz(let v): v
            }
        }

        func withAlpha(_ alpha: Double) -> Storage {
            switch self {
            case .sRGB(var v): v.alpha = alpha; return .sRGB(v)
            case .linearSRGB(var v): v.alpha = alpha; return .linearSRGB(v)
            case .displayP3(var v): v.alpha = alpha; return .displayP3(v)
            case .hsl(var v): v.alpha = alpha; return .hsl(v)
            case .hsv(var v): v.alpha = alpha; return .hsv(v)
            case .oklab(var v): v.alpha = alpha; return .oklab(v)
            case .oklch(var v): v.alpha = alpha; return .oklch(v)
            case .xyz(var v): v.alpha = alpha; return .xyz(v)
            }
        }
    }

    var storage: Storage

    init(storage: Storage) {
        self.storage = storage
    }

    /// The color in the CIE XYZ (D65) connection space.
    public var xyz: XYZ { storage.space.toXYZ() }

    /// Opacity, `0...1`.
    public var alpha: Double {
        get { storage.space.alpha }
        set { storage = storage.withAlpha(newValue) }
    }

    /// Convert to any color space. The conversion is exact (no round-trip) when
    /// the requested space is the one the color is stored in.
    public func converted<Target: ColorSpace>(to type: Target.Type = Target.self) -> Target {
        if let exact = storage.space as? Target { return exact }
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

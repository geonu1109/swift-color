import Foundation

extension Color: CustomStringConvertible {
    /// A CSS-like description in the color's stored space, e.g.
    /// `oklch(0.628 0.258 29.2 / 1)` or `srgb(1 0 0 / 1)`.
    public var description: String {
        func f(_ value: Double, _ places: Int = 3) -> String { String(format: "%.\(places)f", value) }
        switch storage {
        case let .sRGB(v): return "srgb(\(f(v.red)) \(f(v.green)) \(f(v.blue)) / \(f(v.alpha)))"
        case let .linearSRGB(v): return "srgb-linear(\(f(v.red)) \(f(v.green)) \(f(v.blue)) / \(f(v.alpha)))"
        case let .displayP3(v): return "display-p3(\(f(v.red)) \(f(v.green)) \(f(v.blue)) / \(f(v.alpha)))"
        case let .hsl(v): return "hsl(\(f(v.hue, 1)) \(f(v.saturation)) \(f(v.lightness)) / \(f(v.alpha)))"
        case let .hsv(v): return "hsv(\(f(v.hue, 1)) \(f(v.saturation)) \(f(v.value)) / \(f(v.alpha)))"
        case let .oklab(v): return "oklab(\(f(v.lightness)) \(f(v.a)) \(f(v.b)) / \(f(v.alpha)))"
        case let .oklch(v): return "oklch(\(f(v.lightness)) \(f(v.chroma)) \(f(v.hue, 1)) / \(f(v.alpha)))"
        case let .xyz(v): return "xyz-d65(\(f(v.x)) \(f(v.y)) \(f(v.z)) / \(f(v.alpha)))"
        case let .custom(v): // user-defined space: name it and show its XYZ coordinates
            let xyz = v.toXYZ()
            return "\(type(of: v))(xyz-d65 \(f(xyz.x)) \(f(xyz.y)) \(f(xyz.z)) / \(f(xyz.alpha)))"
        }
    }
}

extension Color: CustomDebugStringConvertible {
    public var debugDescription: String { "Color(\(description), hex: \(hexString))" }
}

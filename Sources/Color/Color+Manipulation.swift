import Foundation

/// The color space an interpolation runs in.
public enum InterpolationSpace: Sendable {
    case oklch   // perceptual, shortest-arc hue (default)
    case oklab   // perceptual, no hue drift near grey
    case srgb    // naive, matches CSS/UIColor blending
    case displayP3
    case hsl
    case xyz
}

public extension Color {
    /// Blend toward another color.
    /// - Parameters:
    ///   - other: The color to blend toward.
    ///   - amount: `0` returns `self`, `1` returns `other`.
    ///   - space: The space to interpolate in (default ``InterpolationSpace/oklch``).
    func mixed(with other: Color, amount: Double, in space: InterpolationSpace = .oklch) -> Color {
        let t = amount.clamped(to: 0...1)
        switch space {
        case .oklab:
            let a = oklab, b = other.oklab
            return Color(OKLab(lightness: lerp(a.lightness, b.lightness, t), a: lerp(a.a, b.a, t), b: lerp(a.b, b.b, t), alpha: lerp(a.alpha, b.alpha, t)))
        case .oklch:
            let a = oklch, b = other.oklch
            return Color(OKLCH(lightness: lerp(a.lightness, b.lightness, t), chroma: lerp(a.chroma, b.chroma, t), hue: lerpHue(a.hue, b.hue, t), alpha: lerp(a.alpha, b.alpha, t)))
        case .srgb:
            let a = srgb, b = other.srgb
            return Color(SRGB(red: lerp(a.red, b.red, t), green: lerp(a.green, b.green, t), blue: lerp(a.blue, b.blue, t), alpha: lerp(a.alpha, b.alpha, t)))
        case .displayP3:
            let a = displayP3, b = other.displayP3
            return Color(DisplayP3(red: lerp(a.red, b.red, t), green: lerp(a.green, b.green, t), blue: lerp(a.blue, b.blue, t), alpha: lerp(a.alpha, b.alpha, t)))
        case .hsl:
            let a = hsl, b = other.hsl
            return Color(HSL(hue: lerpHue(a.hue, b.hue, t), saturation: lerp(a.saturation, b.saturation, t), lightness: lerp(a.lightness, b.lightness, t), alpha: lerp(a.alpha, b.alpha, t)))
        case .xyz:
            let a = xyz, b = other.xyz
            return Color(XYZ(x: lerp(a.x, b.x, t), y: lerp(a.y, b.y, t), z: lerp(a.z, b.z, t), alpha: lerp(a.alpha, b.alpha, t)))
        }
    }

    /// Return a copy with OKLCH lightness set to `value` (clamped to `0...1`).
    func lightness(_ value: Double) -> Color {
        var components = oklch
        components.lightness = value.clamped(to: 0...1)
        return Color(components)
    }

    /// Return a copy with OKLCH chroma set to `value` (clamped to `≥ 0`).
    func chroma(_ value: Double) -> Color {
        var components = oklch
        components.chroma = max(0, value)
        return Color(components)
    }

    /// Return a copy with OKLCH hue set to `degrees`, normalized to `0..<360`.
    func hue(_ degrees: Double) -> Color {
        var components = oklch
        components.hue = degrees.normalizedHue
        return Color(components)
    }

    /// Return a fully desaturated copy of the same lightness.
    func grayscale() -> Color {
        var components = oklch
        components.chroma = 0
        return Color(components)
    }

    /// Return a copy with its hue rotated by `degrees`.
    func rotatedHue(by degrees: Double) -> Color {
        var components = oklch
        components.hue = (components.hue + degrees).normalizedHue
        return Color(components)
    }

    /// The complementary color (hue rotated 180°).
    var complementary: Color { rotatedHue(by: 180) }
}

private func lerp(_ from: Double, _ to: Double, _ t: Double) -> Double {
    from + (to - from) * t
}

/// Interpolate hues along the shortest arc around the 360° wheel.
private func lerpHue(_ from: Double, _ to: Double, _ t: Double) -> Double {
    var delta = (to - from).truncatingRemainder(dividingBy: 360)
    if delta > 180 { delta -= 360 }
    if delta < -180 { delta += 360 }
    return (from + delta * t).normalizedHue
}

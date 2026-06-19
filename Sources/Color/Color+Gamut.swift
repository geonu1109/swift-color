import Foundation

public extension Color {
    /// Whether the color lies within the sRGB gamut (all sRGB components within
    /// `0...1`, within a small tolerance).
    var isInSRGBGamut: Bool {
        let rgb = srgb
        let range = -0.0001...1.0001
        return range.contains(rgb.red) && range.contains(rgb.green) && range.contains(rgb.blue)
    }

    /// Hard-clip into sRGB by clamping each component to `0...1`. Fast, but can
    /// shift hue and crush saturated colors.
    func clampedToSRGB() -> Color {
        let rgb = srgb
        return Color(SRGB(
            red: rgb.red.clamped(to: 0...1),
            green: rgb.green.clamped(to: 0...1),
            blue: rgb.blue.clamped(to: 0...1),
            alpha: rgb.alpha
        ))
    }

    /// Map into the sRGB gamut perceptually, following the CSS Color 4
    /// algorithm: reduce chroma in OKLCH (keeping lightness and hue) until the
    /// color is displayable, using ΔEOK to stay visually as close as possible.
    func gamutMappedToSRGB() -> Color {
        if isInSRGBGamut { return self }

        var current = oklch
        if current.lightness >= 1 { return Color(SRGB(red: 1, green: 1, blue: 1, alpha: alpha)) }
        if current.lightness <= 0 { return Color(SRGB(red: 0, green: 0, blue: 0, alpha: alpha)) }

        let jnd = 0.02
        let epsilon = 0.0001
        var low = 0.0
        var high = current.chroma
        var lowIsInGamut = true

        while high - low > epsilon {
            let chroma = (low + high) / 2
            current.chroma = chroma
            let candidate = Color(current)

            if lowIsInGamut, candidate.isInSRGBGamut {
                low = chroma
                continue
            }

            let clipped = candidate.clampedToSRGB()
            let deltaE = deltaEOK(clipped.oklab, candidate.oklab)
            if deltaE < jnd {
                if jnd - deltaE < epsilon { return clipped }
                lowIsInGamut = false
                low = chroma
            } else {
                high = chroma
            }
        }
        current.chroma = low
        return Color(current).clampedToSRGB()
    }
}

/// Euclidean distance between two colors in OKLab — a good perceptual difference
/// metric (a value near 0.02 is roughly one just-noticeable difference).
func deltaEOK(_ a: OKLab, _ b: OKLab) -> Double {
    let dl = a.lightness - b.lightness
    let da = a.a - b.a
    let db = a.b - b.b
    return (dl * dl + da * da + db * db).squareRoot()
}

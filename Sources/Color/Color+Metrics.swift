public extension Color {
    /// The WCAG 2.x relative luminance (`0` for black, `1` for white).
    ///
    /// Computed per the spec from gamut-clamped linear sRGB, so it's defined for
    /// any color (out-of-sRGB colors are clamped first).
    var relativeLuminance: Double {
        let linear = clampedToSRGB().linearSRGB
        return 0.2126 * linear.red + 0.7152 * linear.green + 0.0722 * linear.blue
    }

    /// The WCAG contrast ratio between two colors, from `1` (identical luminance)
    /// to `21` (black vs. white). WCAG AA wants ≥ 4.5 for body text, ≥ 3 for large.
    func contrastRatio(to other: Color) -> Double {
        let a = relativeLuminance
        let b = other.relativeLuminance
        return (max(a, b) + 0.05) / (min(a, b) + 0.05)
    }

    /// Perceptual color difference (ΔE OK — Euclidean distance in OKLab).
    ///
    /// Roughly, `0.02` is about one just-noticeable difference; `0` means the
    /// same color. Useful for matching, nearest-color search, and deduplication.
    func difference(to other: Color) -> Double {
        deltaEOK(oklab, other.oklab)
    }
}

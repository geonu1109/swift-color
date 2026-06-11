#if canImport(CoreGraphics)
import CoreGraphics

public extension Color {
    /// A `CGColor` in the sRGB color space, perceptually gamut-mapped.
    var cgColor: CGColor {
        let rgb = gamutMappedToSRGB().srgb
        return CGColor(
            srgbRed: CGFloat(rgb.red),
            green: CGFloat(rgb.green),
            blue: CGFloat(rgb.blue),
            alpha: CGFloat(alpha)
        )
    }
}
#endif

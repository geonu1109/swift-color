#if canImport(UIKit)
import UIKit

public extension Color {
    /// A `UIColor`, perceptually gamut-mapped into sRGB.
    var uiColor: UIColor {
        let rgb = gamutMappedToSRGB().srgb
        return UIColor(red: rgb.red, green: rgb.green, blue: rgb.blue, alpha: alpha)
    }

    /// A `UIColor` in the Display P3 space, for wide-gamut rendering.
    var uiColorDisplayP3: UIColor {
        let p3 = displayP3
        return UIColor(
            displayP3Red: p3.red.clamped(to: 0...1),
            green: p3.green.clamped(to: 0...1),
            blue: p3.blue.clamped(to: 0...1),
            alpha: alpha
        )
    }

    /// Build a model color from a `UIColor` (interpreted in sRGB).
    init(_ uiColor: UIColor) {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        self.init(red: Double(red), green: Double(green), blue: Double(blue), alpha: Double(alpha))
    }
}
#endif

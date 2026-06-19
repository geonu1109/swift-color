#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit

public extension Color {
    /// An `NSColor`, perceptually gamut-mapped into sRGB.
    var nsColor: NSColor {
        let rgb = gamutMappedToSRGB().srgb
        return NSColor(srgbRed: rgb.red, green: rgb.green, blue: rgb.blue, alpha: alpha)
    }

    /// An `NSColor` in the Display P3 space, for wide-gamut rendering.
    var nsColorDisplayP3: NSColor {
        let p3 = displayP3
        return NSColor(
            displayP3Red: p3.red.clamped(to: 0...1),
            green: p3.green.clamped(to: 0...1),
            blue: p3.blue.clamped(to: 0...1),
            alpha: alpha
        )
    }

    /// Build a model color from an `NSColor` (converted to sRGB).
    init(_ nsColor: NSColor) {
        let converted = nsColor.usingColorSpace(.sRGB) ?? nsColor
        self.init(
            red: Double(converted.redComponent),
            green: Double(converted.greenComponent),
            blue: Double(converted.blueComponent),
            alpha: Double(converted.alphaComponent)
        )
    }
}
#endif

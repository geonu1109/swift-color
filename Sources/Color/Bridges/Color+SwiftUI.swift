#if canImport(SwiftUI)
import SwiftUI

/// A clear alias for SwiftUI's color type. Because this module is also named
/// `Color`, importing both `Color` and `SwiftUI` makes the bare name `Color`
/// ambiguous; use `SwiftUIColor` to name SwiftUI's type unambiguously. In
/// practice you rarely need it — the `.swiftUIColor` accessor does the bridging.
public typealias SwiftUIColor = SwiftUI.Color

public extension Color {
    /// A SwiftUI color, perceptually gamut-mapped into sRGB for display.
    var swiftUIColor: SwiftUI.Color {
        let rgb = gamutMappedToSRGB().srgb
        return SwiftUI.Color(.sRGB, red: rgb.red, green: rgb.green, blue: rgb.blue, opacity: alpha)
    }

    /// A SwiftUI color in the Display P3 space, for wide-gamut rendering.
    var swiftUIColorDisplayP3: SwiftUI.Color {
        let p3 = displayP3
        return SwiftUI.Color(
            .displayP3,
            red: p3.red.clamped(to: 0...1),
            green: p3.green.clamped(to: 0...1),
            blue: p3.blue.clamped(to: 0...1),
            opacity: alpha
        )
    }
}

public extension SwiftUI.Color {
    /// Build a SwiftUI color from a ``Color`` model value.
    init(_ color: Color) {
        self = color.swiftUIColor
    }
}
#endif

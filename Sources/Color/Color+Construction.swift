import Foundation

public extension Color {
    /// Wrap a value in any color space, preserving that space.
    init(_ space: some ColorSpace) {
        switch space {
        case let v as SRGB: storage = .sRGB(v)
        case let v as LinearSRGB: storage = .linearSRGB(v)
        case let v as DisplayP3: storage = .displayP3(v)
        case let v as HSL: storage = .hsl(v)
        case let v as HSV: storage = .hsv(v)
        case let v as OKLab: storage = .oklab(v)
        case let v as OKLCH: storage = .oklch(v)
        case let v as XYZ: storage = .xyz(v)
        default: storage = .xyz(space.toXYZ()) // a custom space is kept by value as XYZ
        }
    }

    /// Create an sRGB color from components in `0...1`.
    init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
        self.init(SRGB(red: red, green: green, blue: blue, alpha: alpha))
    }

    /// Parse a hex string (`#RGB`, `#RGBA`, `#RRGGBB`, `#RRGGBBAA`; `#` optional)
    /// as an sRGB color. Returns `nil` for malformed input.
    init?(hex string: String) {
        var hex = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if hex.hasPrefix("#") { hex.removeFirst() }
        guard hex.allSatisfy(\.isHexDigit) else { return nil }

        let digits = Array(hex)
        let red: Double, green: Double, blue: Double, alpha: Double
        switch digits.count {
        case 3, 4:
            let values = digits.map { component -> Double in
                let nibble = Double(Int(String(component), radix: 16)!)
                return (nibble * 16 + nibble) / 255
            }
            red = values[0]; green = values[1]; blue = values[2]
            alpha = digits.count == 4 ? values[3] : 1
        case 6, 8:
            let bytes = stride(from: 0, to: digits.count, by: 2).map { start -> Double in
                Double(Int(String(digits[start..<start + 2]), radix: 16)!) / 255
            }
            red = bytes[0]; green = bytes[1]; blue = bytes[2]
            alpha = digits.count == 8 ? bytes[3] : 1
        default:
            return nil
        }
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }

    /// A `#RRGGBB` (or `#RRGGBBAA`) string, gamut-mapped into sRGB first.
    var hexString: String {
        let rgb = gamutMappedToSRGB().srgb
        func byte(_ value: Double) -> Int { Int((value.clamped(to: 0...1) * 255).rounded()) }
        let base = String(format: "#%02X%02X%02X", byte(rgb.red), byte(rgb.green), byte(rgb.blue))
        guard alpha < 1 else { return base }
        return base + String(format: "%02X", byte(alpha))
    }
}

// Named colors are defined on their space types — `SRGB.red` … `SRGB.clear`
// (standard sRGB colors) and the `OKLCH` palette (`OKLCH.blue` …). Wrap one in
// a Color to use it: `Color(SRGB.red)`, `Color(OKLCH.blue)`.

// HSL and HSB(HSV) are cylindrical re-encodings of gamma-encoded sRGB, so they
// convert to/from SRGB directly and reach XYZ through it.

private func hueToRGB(hue: Double, chroma: Double, m: Double) -> (Double, Double, Double) {
    let hp = hue.normalizedHue / 60
    let x = chroma * (1 - abs(hp.truncatingRemainder(dividingBy: 2) - 1))
    let (r, g, b): (Double, Double, Double)
    switch hp {
    case 0..<1: (r, g, b) = (chroma, x, 0)
    case 1..<2: (r, g, b) = (x, chroma, 0)
    case 2..<3: (r, g, b) = (0, chroma, x)
    case 3..<4: (r, g, b) = (0, x, chroma)
    case 4..<5: (r, g, b) = (x, 0, chroma)
    default: (r, g, b) = (chroma, 0, x)
    }
    return (r + m, g + m, b + m)
}

private func hueChroma(red: Double, green: Double, blue: Double) -> (hue: Double, chroma: Double, max: Double, min: Double) {
    let maximum = max(red, green, blue)
    let minimum = min(red, green, blue)
    let chroma = maximum - minimum
    let hue: Double
    if chroma == 0 {
        hue = 0
    } else if maximum == red {
        hue = 60 * (((green - blue) / chroma).truncatingRemainder(dividingBy: 6))
    } else if maximum == green {
        hue = 60 * ((blue - red) / chroma + 2)
    } else {
        hue = 60 * ((red - green) / chroma + 4)
    }
    return (hue.normalizedHue, chroma, maximum, minimum)
}

/// Hue–saturation–lightness, an encoding of sRGB. `hue` in degrees `0..<360`,
/// `saturation` and `lightness` in `0...1`.
public struct HSL: ColorRepresentation {
    public var hue: Double
    public var saturation: Double
    public var lightness: Double
    public var alpha: Double

    public init(hue: Double, saturation: Double, lightness: Double, alpha: Double = 1) {
        self.hue = hue
        self.saturation = saturation
        self.lightness = lightness
        self.alpha = alpha
    }

    public var srgb: SRGB {
        let chroma = (1 - abs(2 * lightness - 1)) * saturation
        let (r, g, b) = hueToRGB(hue: hue, chroma: chroma, m: lightness - chroma / 2)
        return SRGB(red: r, green: g, blue: b, alpha: alpha)
    }

    public func toXYZ() -> XYZ { srgb.toXYZ() }

    public static func fromXYZ(_ xyz: XYZ) -> HSL {
        let rgb = SRGB.fromXYZ(xyz)
        let (hue, chroma, maximum, minimum) = hueChroma(red: rgb.red, green: rgb.green, blue: rgb.blue)
        let lightness = (maximum + minimum) / 2
        let denom = 1 - abs(2 * lightness - 1)
        let saturation = denom == 0 ? 0 : chroma / denom
        return HSL(hue: hue, saturation: saturation, lightness: lightness, alpha: xyz.alpha)
    }
}

/// Hue–saturation–value, an encoding of sRGB. `hue` in degrees `0..<360`,
/// `saturation` and `value` in `0...1`. Apple/Adobe call this **HSB** (with
/// `value` spelled `brightness`); see the ``HSB`` alias.
public struct HSV: ColorRepresentation {
    public var hue: Double
    public var saturation: Double
    public var value: Double
    public var alpha: Double

    public init(hue: Double, saturation: Double, value: Double, alpha: Double = 1) {
        self.hue = hue
        self.saturation = saturation
        self.value = value
        self.alpha = alpha
    }

    /// Apple/Adobe spelling: `brightness` is the same channel as `value`.
    public init(hue: Double, saturation: Double, brightness: Double, alpha: Double = 1) {
        self.init(hue: hue, saturation: saturation, value: brightness, alpha: alpha)
    }

    /// Alias for ``value`` using Apple/Adobe's "brightness" terminology.
    public var brightness: Double {
        get { value }
        set { value = newValue }
    }

    public var srgb: SRGB {
        let chroma = value * saturation
        let (r, g, b) = hueToRGB(hue: hue, chroma: chroma, m: value - chroma)
        return SRGB(red: r, green: g, blue: b, alpha: alpha)
    }

    public func toXYZ() -> XYZ { srgb.toXYZ() }

    public static func fromXYZ(_ xyz: XYZ) -> HSV {
        let rgb = SRGB.fromXYZ(xyz)
        let (hue, chroma, maximum, _) = hueChroma(red: rgb.red, green: rgb.green, blue: rgb.blue)
        let saturation = maximum == 0 ? 0 : chroma / maximum
        return HSV(hue: hue, saturation: saturation, value: maximum, alpha: xyz.alpha)
    }
}

/// `HSB` (hue, saturation, brightness) is Apple's and Adobe's name for ``HSV``.
public typealias HSB = HSV

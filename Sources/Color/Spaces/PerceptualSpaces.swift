#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#endif

/// OKLab (Björn Ottosson, 2020) — a perceptually uniform space. `lightness`
/// `0...1`; `a` (green–red) and `b` (blue–yellow) are unbounded but small.
public struct OKLab: ColorSpace {
    public var lightness: Double
    public var a: Double
    public var b: Double
    public var alpha: Double

    public init(lightness: Double, a: Double, b: Double, alpha: Double = 1) {
        self.lightness = lightness
        self.a = a
        self.b = b
        self.alpha = alpha
    }

    public func toXYZ() -> XYZ {
        let (lp, mp, sp) = Convert.apply(Convert.okLabToLMSPrime, (lightness, a, b))
        let (r, g, blue) = Convert.apply(Convert.lmsToLinearSRGB, (lp * lp * lp, mp * mp * mp, sp * sp * sp))
        return LinearSRGB(red: r, green: g, blue: blue, alpha: alpha).toXYZ()
    }

    public static func fromXYZ(_ xyz: XYZ) -> OKLab {
        let linear = LinearSRGB.fromXYZ(xyz)
        let (l, m, s) = Convert.apply(Convert.linearSRGBToLMS, (linear.red, linear.green, linear.blue))
        let (lightness, a, b) = Convert.apply(Convert.lmsPrimeToOKLab, (cbrt(l), cbrt(m), cbrt(s)))
        return OKLab(lightness: lightness, a: a, b: b, alpha: xyz.alpha)
    }
}

/// OKLCH — the cylindrical form of OKLab (the CSS `oklch()` space). `lightness`
/// `0...1`, `chroma` ≥ 0, `hue` in degrees `0..<360`.
public struct OKLCH: ColorSpace {
    public var lightness: Double
    public var chroma: Double
    public var hue: Double
    public var alpha: Double

    public init(lightness: Double, chroma: Double, hue: Double, alpha: Double = 1) {
        self.lightness = lightness
        self.chroma = chroma
        self.hue = hue
        self.alpha = alpha
    }

    public var okLab: OKLab {
        let (a, b) = Convert.toCartesian(chroma: chroma, hue: hue)
        return OKLab(lightness: lightness, a: a, b: b, alpha: alpha)
    }

    public func toXYZ() -> XYZ { okLab.toXYZ() }

    public static func fromXYZ(_ xyz: XYZ) -> OKLCH {
        let lab = OKLab.fromXYZ(xyz)
        let (chroma, hue) = Convert.toPolar(lab.a, lab.b)
        return OKLCH(lightness: lab.lightness, chroma: chroma, hue: hue, alpha: xyz.alpha)
    }
}

// MARK: - A perceptually-uniform OKLCH palette

/// Named hues at a shared lightness (`0.7`) and chroma (`0.15`), so they read as
/// equally bright and colorful — the kind of balanced palette OKLCH is for, and
/// which sRGB primaries are not — plus achromatic `white`…`black` (chroma 0) on
/// an even lightness ramp. Wrap one in a ``Color``, e.g. `Color(OKLCH.blue)`.
public extension OKLCH {
    static let red = OKLCH(lightness: 0.7, chroma: 0.15, hue: 29)
    static let yellow = OKLCH(lightness: 0.7, chroma: 0.15, hue: 102)
    static let green = OKLCH(lightness: 0.7, chroma: 0.15, hue: 142)
    static let cyan = OKLCH(lightness: 0.7, chroma: 0.15, hue: 195)
    static let blue = OKLCH(lightness: 0.7, chroma: 0.15, hue: 264)
    static let magenta = OKLCH(lightness: 0.7, chroma: 0.15, hue: 328)

    // Achromatic — chroma 0. `gray` sits at the palette's 0.7 lightness (it's
    // the no-chroma member of the same palette); the rest bracket it.
    static let white = OKLCH(lightness: 1, chroma: 0, hue: 0)
    static let lightGray = OKLCH(lightness: 0.85, chroma: 0, hue: 0)
    static let gray = OKLCH(lightness: 0.7, chroma: 0, hue: 0)
    static let darkGray = OKLCH(lightness: 0.45, chroma: 0, hue: 0)
    static let black = OKLCH(lightness: 0, chroma: 0, hue: 0)
}

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#endif

// Cartesian (a, b) ↔ polar (chroma, hue) — how OKLab relates to its cylindrical
// form OKLCH. Lives here because OKLCH is the only user.
private func toPolar(_ a: Double, _ b: Double) -> (chroma: Double, hue: Double) {
    let chroma = (a * a + b * b).squareRoot()
    // Below this chroma the hue is just atan2 of float noise (an achromatic
    // colour has no meaningful hue) — pin it to 0 so greys are stable.
    let hue = chroma < 1e-6 ? 0 : (atan2(b, a) * 180 / .pi).normalizedHue
    return (chroma, hue)
}

private func toCartesian(chroma: Double, hue: Double) -> (a: Double, b: Double) {
    let radians = hue * .pi / 180
    return (chroma * cos(radians), chroma * sin(radians))
}

/// OKLab (Björn Ottosson, 2020) — a perceptually uniform space. `lightness`
/// `0...1`; `a` (green–red) and `b` (blue–yellow) are unbounded but small.
public struct OKLab: ColorRepresentation {
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

    /// Linear sRGB ⇄ LMS cone responses. `matrix`: linear sRGB → LMS. OKLab
    /// reaches the XYZ hub through linear sRGB, so its maps are to the adjacent
    /// space in the chain, not to XYZ directly.
    static let lms = LinearMap(
        matrix: Matrix<3, 3>([
            [0.4122214708, 0.5363325363, 0.0514459929],
            [0.2119034982, 0.6806995451, 0.1073969566],
            [0.0883024619, 0.2817188376, 0.6299787005],
        ]),
        inverse: Matrix<3, 3>([
            [4.0767416621,  -3.3077115913, 0.2309699292],
            [-1.2684380046, 2.6097574011,  -0.3413193965],
            [-0.0041960863, -0.7034186147, 1.7076147010],
        ])
    )
    /// Nonlinear LMS′ ⇄ OKLab. `matrix`: LMS′ → OKLab. (The cube/cube-root
    /// between LMS and LMS′ is applied by the conversions below.)
    static let lab = LinearMap(
        matrix: Matrix<3, 3>([
            [0.2104542553, 0.7936177850,  -0.0040720468],
            [1.9779984951, -2.4285922050, 0.4505937099],
            [0.0259040371, 0.7827717662,  -0.8086757660],
        ]),
        inverse: Matrix<3, 3>([
            [1.0, 0.3963377774,  0.2158037573],
            [1.0, -0.1055613458, -0.0638541728],
            [1.0, -0.0894841775, -1.2914855480],
        ])
    )

    public func toXYZ() -> XYZ {
        let p = Self.lab.inverse * Vector([lightness, a, b])              // OKLab → LMS′
        let lms = Self.lms.inverse * Vector([p[0] * p[0] * p[0], p[1] * p[1] * p[1], p[2] * p[2] * p[2]])
        return LinearSRGB(red: lms[0], green: lms[1], blue: lms[2], alpha: alpha).toXYZ()
    }

    public static func fromXYZ(_ xyz: XYZ) -> OKLab {
        let linear = LinearSRGB.fromXYZ(xyz)
        let lms = Self.lms.matrix * Vector([linear.red, linear.green, linear.blue])  // linear sRGB → LMS
        let lab = Self.lab.matrix * Vector([cbrt(lms[0]), cbrt(lms[1]), cbrt(lms[2])])
        return OKLab(lightness: lab[0], a: lab[1], b: lab[2], alpha: xyz.alpha)
    }
}

/// OKLCH — the cylindrical form of OKLab (the CSS `oklch()` space). `lightness`
/// `0...1`, `chroma` ≥ 0, `hue` in degrees `0..<360`.
public struct OKLCH: ColorRepresentation {
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
        let (a, b) = toCartesian(chroma: chroma, hue: hue)
        return OKLab(lightness: lightness, a: a, b: b, alpha: alpha)
    }

    public func toXYZ() -> XYZ { okLab.toXYZ() }

    public static func fromXYZ(_ xyz: XYZ) -> OKLCH {
        let lab = OKLab.fromXYZ(xyz)
        let (chroma, hue) = toPolar(lab.a, lab.b)
        return OKLCH(lightness: lab.lightness, chroma: chroma, hue: hue, alpha: xyz.alpha)
    }
}

// MARK: - A perceptually-uniform OKLCH palette

/// Named hues at a shared lightness (`0.7`) and chroma (`0.15`), so they read as
/// equally bright and colorful — the kind of balanced palette OKLCH is for, and
/// which sRGB primaries are not — plus achromatic `white`…`black` (chroma 0),
/// with `gray` at the palette's `0.7` lightness. Wrap one in a ``Color``, e.g.
/// `Color(OKLCH.blue)`.
///
/// At `0.7`/`0.15` some hues (e.g. `yellow`, `cyan`) fall outside the sRGB
/// gamut, so reading `.srgb` can give out-of-range components — the `hexString`
/// and UI bridges gamut-map automatically.
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

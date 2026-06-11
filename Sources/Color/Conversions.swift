#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#endif

/// Shared, dependency-free color math. Every conversion in this package routes
/// through the CIE XYZ (D65) connection space, so each color space only needs to
/// define how it maps to and from XYZ; arbitrary conversions then compose.
///
/// Matrices follow the CSS Color 4 reference values. sRGB and Display P3 share
/// the sRGB transfer function but use different primaries. The whole system is
/// on a single D65 white point, so no chromatic adaptation is ever needed.
enum Convert {
    // MARK: - Matrix helper

    /// Multiply a row-major 3×3 matrix (9 elements) by a 3-vector.
    @inline(__always)
    static func apply(_ m: [Double], _ v: (Double, Double, Double)) -> (Double, Double, Double) {
        (
            m[0] * v.0 + m[1] * v.1 + m[2] * v.2,
            m[3] * v.0 + m[4] * v.1 + m[5] * v.2,
            m[6] * v.0 + m[7] * v.1 + m[8] * v.2
        )
    }

    // MARK: - sRGB transfer function (also used by Display P3)

    @inline(__always)
    static func gammaToLinear(_ c: Double) -> Double {
        let sign = c < 0 ? -1.0 : 1.0
        let a = abs(c)
        return a <= 0.04045 ? c / 12.92 : sign * pow((a + 0.055) / 1.055, 2.4)
    }

    @inline(__always)
    static func linearToGamma(_ c: Double) -> Double {
        let sign = c < 0 ? -1.0 : 1.0
        let a = abs(c)
        return a <= 0.0031308 ? c * 12.92 : sign * (1.055 * pow(a, 1 / 2.4) - 0.055)
    }

    // MARK: - Linear sRGB ↔ XYZ (D65)

    static let linearSRGBToXYZ: [Double] = [
        0.41239079926595934, 0.357584339383878, 0.1804807884018343,
        0.21263900587151027, 0.715168678767756, 0.07219231536073371,
        0.01933081871559182, 0.11919477979462598, 0.9505321522496607,
    ]
    static let xyzToLinearSRGB: [Double] = [
        3.2409699419045226, -1.537383177570094, -0.4986107602930034,
        -0.9692436362808796, 1.8759675015077202, 0.04155505740717559,
        0.05563007969699366, -0.20397695888897652, 1.0569715142428786,
    ]

    // MARK: - Linear Display P3 ↔ XYZ (D65)

    static let linearP3ToXYZ: [Double] = [
        0.4865709486482162, 0.26566769316909306, 0.19821728523436247,
        0.2289745640697488, 0.6917385218365064, 0.079286914093745,
        0.0, 0.04511338185890264, 1.043944368900976,
    ]
    static let xyzToLinearP3: [Double] = [
        2.493496911941425, -0.9313836179191239, -0.40271078445071684,
        -0.8294889695615747, 1.7626640603183463, 0.023624685841943577,
        0.03584583024378447, -0.07617238926804182, 0.9568845240076872,
    ]

    // MARK: - Linear sRGB ↔ OKLab (Björn Ottosson)

    static let linearSRGBToLMS: [Double] = [
        0.4122214708, 0.5363325363, 0.0514459929,
        0.2119034982, 0.6806995451, 0.1073969566,
        0.0883024619, 0.2817188376, 0.6299787005,
    ]
    static let lmsToLinearSRGB: [Double] = [
        4.0767416621, -3.3077115913, 0.2309699292,
        -1.2684380046, 2.6097574011, -0.3413193965,
        -0.0041960863, -0.7034186147, 1.7076147010,
    ]
    static let lmsPrimeToOKLab: [Double] = [
        0.2104542553, 0.7936177850, -0.0040720468,
        1.9779984951, -2.4285922050, 0.4505937099,
        0.0259040371, 0.7827717662, -0.8086757660,
    ]
    static let okLabToLMSPrime: [Double] = [
        1.0, 0.3963377774, 0.2158037573,
        1.0, -0.1055613458, -0.0638541728,
        1.0, -0.0894841775, -1.2914855480,
    ]

    // MARK: - Angles

    /// Normalize an angle in degrees to `[0, 360)`. Used everywhere a hue is
    /// produced or adjusted, so the wrap-around lives in one place.
    @inline(__always)
    static func normalizeHue(_ degrees: Double) -> Double {
        var hue = degrees.truncatingRemainder(dividingBy: 360)
        if hue < 0 { hue += 360 }
        if hue >= 360 { hue -= 360 } // sub-ULP noise near 0 can round up to exactly 360
        return hue
    }

    // MARK: - Cartesian ↔ polar (used by OKLCH and the cylindrical RGB spaces)

    static func toPolar(_ a: Double, _ b: Double) -> (chroma: Double, hue: Double) {
        let chroma = (a * a + b * b).squareRoot()
        return (chroma, normalizeHue(atan2(b, a) * 180 / .pi))
    }

    static func toCartesian(chroma: Double, hue: Double) -> (a: Double, b: Double) {
        let radians = hue * .pi / 180
        return (chroma * cos(radians), chroma * sin(radians))
    }
}

extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        guard !isNaN else { return range.lowerBound }
        return Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

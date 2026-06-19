#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#endif

/// A 3×3 linear transform paired with its inverse. Color spaces relate to each
/// other (and to the CIE XYZ hub) by linear maps; bundling a matrix with its
/// inverse keeps a space's forward and backward conversions together — and owned
/// by the space they describe — instead of as loose, far-apart constants.
///
/// `matrix` and `inverse` are plain ``Matrix`` values; apply them with `*`:
/// `LinearSRGB.xyz.matrix * Vector(r, g, b)`. Each space documents which
/// direction `matrix` runs.
struct LinearMap {
    let matrix: Matrix<3, 3>
    let inverse: Matrix<3, 3>
}

/// A display transfer function ("gamma"): the encode/decode pair mapping between
/// linear-light and encoded component values. It's a value — different curves
/// are different instances — so a space declares which one it uses rather than
/// calling loose functions. sRGB and Display P3 share ``sRGB`` (same transfer
/// function, different primaries).
struct TransferFunction {
    /// Slope of the near-black linear segment.
    let slope: Double
    /// Affine offset of the power segment; `1 + offset` scales it.
    let offset: Double
    /// Exponent of the power segment.
    let gamma: Double
    /// Encoded value at/below which decoding is linear.
    let decodeThreshold: Double
    /// Linear value at/below which encoding is linear.
    let encodeThreshold: Double

    /// Encoded → linear-light.
    func toLinear(_ c: Double) -> Double {
        let sign = c < 0 ? -1.0 : 1.0
        let a = abs(c)
        return a <= decodeThreshold ? c / slope : sign * pow((a + offset) / (1 + offset), gamma)
    }

    /// Linear-light → encoded.
    func toEncoded(_ c: Double) -> Double {
        let sign = c < 0 ? -1.0 : 1.0
        let a = abs(c)
        return a <= encodeThreshold ? c * slope : sign * ((1 + offset) * pow(a, 1 / gamma) - offset)
    }

    /// The sRGB / Display P3 transfer function.
    static let sRGB = TransferFunction(
        slope: 12.92,
        offset: 0.055,
        gamma: 2.4,
        decodeThreshold: 0.04045,
        encodeThreshold: 0.0031308
    )
}

extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        guard !isNaN else { return range.lowerBound }
        return Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }

    /// This value, read as degrees, wrapped into the hue range `[0, 360)`.
    /// Used wherever a hue is produced or adjusted, so the wrap lives in one place.
    var normalizedHue: Double {
        var hue = truncatingRemainder(dividingBy: 360)
        if hue < 0 { hue += 360 }
        if hue >= 360 { hue -= 360 } // sub-ULP noise near 0 can round up to exactly 360
        return hue
    }
}

/// A color space: a coordinate system in which a color can be expressed.
///
/// A space only has to say how it maps to and from the CIE XYZ (D65) connection
/// space; every other conversion composes through XYZ automatically. Conform
/// your own space and it immediately interoperates with all the built-in ones.
public protocol ColorSpace: Sendable, Hashable, Codable {
    /// Opacity, `0...1`. Alpha is space-independent and is carried through
    /// conversions unchanged.
    var alpha: Double { get set }

    /// Map to the CIE XYZ (D65) connection space.
    func toXYZ() -> XYZ

    /// Reconstruct from the CIE XYZ (D65) connection space.
    static func fromXYZ(_ xyz: XYZ) -> Self
}

public extension ColorSpace {
    /// Convert to any other color space, routing through XYZ.
    func converted<Target: ColorSpace>(to type: Target.Type = Target.self) -> Target {
        Target.fromXYZ(toXYZ())
    }
}

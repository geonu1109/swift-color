/// A representation of a color in a specific color space (see ``ColorSpace``) —
/// for example ``SRGB``, ``OKLCH``, or ``XYZ``. A value is a color; the type is
/// the space it's expressed in.
///
/// A representation only has to say how it maps to and from the CIE XYZ (D65)
/// connection space; every other conversion composes through XYZ automatically.
/// Conform your own and it immediately interoperates with all the built-in ones.
public protocol ColorRepresentation: Sendable, Hashable, Codable {
    /// Opacity, `0...1`. Alpha is space-independent and is carried through
    /// conversions unchanged.
    var alpha: Double { get set }

    /// Map to the CIE XYZ (D65) connection space.
    func toXYZ() -> XYZ

    /// Reconstruct from the CIE XYZ (D65) connection space.
    static func fromXYZ(_ xyz: XYZ) -> Self
}

public extension ColorRepresentation {
    /// Convert to any other representation, routing through XYZ.
    func converted<Target: ColorRepresentation>(to type: Target.Type = Target.self) -> Target {
        Target.fromXYZ(toXYZ())
    }
}

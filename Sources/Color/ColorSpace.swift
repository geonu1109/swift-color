/// Identifies a color space — the coordinate system a ``Color`` is stored in.
///
/// A lightweight tag for introspection: `color.space` tells you which space a
/// value was authored in, so you know which accessor reads it back exactly (a
/// `.oklch`-stored color returns its `oklch` with no conversion round-trip). To
/// work with the values themselves, use the typed representations (``SRGB``,
/// ``OKLCH``, …) and ``Color``'s accessors; this enum is only the identity.
///
/// ``custom`` covers any user-defined ``ColorRepresentation``: such a color is
/// stored and read back exactly in memory, but it serializes (``Codable``) as
/// CIE XYZ, since an unknown type can't be reconstructed without a registry.
public enum ColorSpace: Sendable, Hashable, Codable {
    case sRGB
    case linearSRGB
    case displayP3
    case hsl
    case hsv
    case oklab
    case oklch
    case xyz
    case custom
}

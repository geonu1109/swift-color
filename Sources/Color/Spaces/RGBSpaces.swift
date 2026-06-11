/// CIE 1931 XYZ tristimulus values (D65 white point). The connection space
/// every other space converts through.
public struct XYZ: ColorSpace {
    public var x: Double
    public var y: Double
    public var z: Double
    public var alpha: Double

    public init(x: Double, y: Double, z: Double, alpha: Double = 1) {
        self.x = x
        self.y = y
        self.z = z
        self.alpha = alpha
    }

    public func toXYZ() -> XYZ { self }
    public static func fromXYZ(_ xyz: XYZ) -> XYZ { xyz }
}

/// Linear-light sRGB (no gamma encoding). Components are unbounded; values
/// outside `0...1` represent colors beyond the sRGB gamut.
public struct LinearSRGB: ColorSpace {
    public var red: Double
    public var green: Double
    public var blue: Double
    public var alpha: Double

    public init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    public func toXYZ() -> XYZ {
        let (x, y, z) = Convert.apply(Convert.linearSRGBToXYZ, (red, green, blue))
        return XYZ(x: x, y: y, z: z, alpha: alpha)
    }

    public static func fromXYZ(_ xyz: XYZ) -> LinearSRGB {
        let (r, g, b) = Convert.apply(Convert.xyzToLinearSRGB, (xyz.x, xyz.y, xyz.z))
        return LinearSRGB(red: r, green: g, blue: b, alpha: xyz.alpha)
    }
}

/// Gamma-encoded sRGB — the default web/display space. Components are nominally
/// `0...1`.
public struct SRGB: ColorSpace {
    public var red: Double
    public var green: Double
    public var blue: Double
    public var alpha: Double

    public init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    public var linear: LinearSRGB {
        LinearSRGB(
            red: Convert.gammaToLinear(red),
            green: Convert.gammaToLinear(green),
            blue: Convert.gammaToLinear(blue),
            alpha: alpha
        )
    }

    public func toXYZ() -> XYZ { linear.toXYZ() }

    public static func fromXYZ(_ xyz: XYZ) -> SRGB {
        let linear = LinearSRGB.fromXYZ(xyz)
        return SRGB(
            red: Convert.linearToGamma(linear.red),
            green: Convert.linearToGamma(linear.green),
            blue: Convert.linearToGamma(linear.blue),
            alpha: xyz.alpha
        )
    }
}

/// Display P3 — Apple's wide-gamut space. Same transfer function as sRGB, wider
/// primaries, so it can express more saturated colors.
public struct DisplayP3: ColorSpace {
    public var red: Double
    public var green: Double
    public var blue: Double
    public var alpha: Double

    public init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    public func toXYZ() -> XYZ {
        let lr = Convert.gammaToLinear(red)
        let lg = Convert.gammaToLinear(green)
        let lb = Convert.gammaToLinear(blue)
        let (x, y, z) = Convert.apply(Convert.linearP3ToXYZ, (lr, lg, lb))
        return XYZ(x: x, y: y, z: z, alpha: alpha)
    }

    public static func fromXYZ(_ xyz: XYZ) -> DisplayP3 {
        let (lr, lg, lb) = Convert.apply(Convert.xyzToLinearP3, (xyz.x, xyz.y, xyz.z))
        return DisplayP3(
            red: Convert.linearToGamma(lr),
            green: Convert.linearToGamma(lg),
            blue: Convert.linearToGamma(lb),
            alpha: xyz.alpha
        )
    }
}

// MARK: - Named sRGB colors

/// The conventional web/sRGB definitions of these named colors. Wrap one in a
/// ``Color`` to use it, e.g. `Color(SRGB.red)`.
public extension SRGB {
    static let red = SRGB(red: 1, green: 0, blue: 0)
    static let green = SRGB(red: 0, green: 1, blue: 0)
    static let blue = SRGB(red: 0, green: 0, blue: 1)
    static let cyan = SRGB(red: 0, green: 1, blue: 1)
    static let magenta = SRGB(red: 1, green: 0, blue: 1)
    static let yellow = SRGB(red: 1, green: 1, blue: 0)

    static let white = SRGB(red: 1, green: 1, blue: 1)
    static let lightGray = SRGB(red: 2 / 3, green: 2 / 3, blue: 2 / 3)
    static let gray = SRGB(red: 0.5, green: 0.5, blue: 0.5)
    static let darkGray = SRGB(red: 1 / 3, green: 1 / 3, blue: 1 / 3)
    static let black = SRGB(red: 0, green: 0, blue: 0)

    /// Fully transparent.
    static let clear = SRGB(red: 0, green: 0, blue: 0, alpha: 0)
}

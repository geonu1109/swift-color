/// CIE 1931 XYZ tristimulus values (D65 white point). The connection space
/// every other space converts through.
public struct XYZ: ColorRepresentation {
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
public struct LinearSRGB: ColorRepresentation {
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

    /// Linear sRGB ⇄ CIE XYZ (D65). `matrix`: linear sRGB → XYZ. CSS Color 4
    /// reference values.
    static let xyz = LinearMap(
        matrix: Matrix<3, 3>([
            [0.41239079926595934, 0.357584339383878,   0.1804807884018343],
            [0.21263900587151027, 0.715168678767756,   0.07219231536073371],
            [0.01933081871559182, 0.11919477979462598, 0.9505321522496607],
        ]),
        inverse: Matrix<3, 3>([
            [3.2409699419045226,   -1.537383177570094,   -0.4986107602930034],
            [-0.9692436362808796,  1.8759675015077202,   0.04155505740717559],
            [0.05563007969699366,  -0.20397695888897652, 1.0569715142428786],
        ])
    )

    public func toXYZ() -> XYZ {
        let v = Self.xyz.matrix * Vector([red, green, blue])
        return XYZ(x: v[0], y: v[1], z: v[2], alpha: alpha)
    }

    public static func fromXYZ(_ xyz: XYZ) -> LinearSRGB {
        let v = Self.xyz.inverse * Vector([xyz.x, xyz.y, xyz.z])
        return LinearSRGB(red: v[0], green: v[1], blue: v[2], alpha: xyz.alpha)
    }
}

/// Gamma-encoded sRGB — the default web/display space. Components are nominally
/// `0...1`.
public struct SRGB: ColorRepresentation {
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
            red: TransferFunction.sRGB.toLinear(red),
            green: TransferFunction.sRGB.toLinear(green),
            blue: TransferFunction.sRGB.toLinear(blue),
            alpha: alpha
        )
    }

    public func toXYZ() -> XYZ { linear.toXYZ() }

    public static func fromXYZ(_ xyz: XYZ) -> SRGB {
        let linear = LinearSRGB.fromXYZ(xyz)
        return SRGB(
            red: TransferFunction.sRGB.toEncoded(linear.red),
            green: TransferFunction.sRGB.toEncoded(linear.green),
            blue: TransferFunction.sRGB.toEncoded(linear.blue),
            alpha: xyz.alpha
        )
    }
}

/// Display P3 — Apple's wide-gamut space. Same transfer function as sRGB, wider
/// primaries, so it can express more saturated colors.
public struct DisplayP3: ColorRepresentation {
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

    /// Linear Display P3 ⇄ CIE XYZ (D65). `matrix`: linear P3 → XYZ. CSS Color 4
    /// reference values. (P3 shares sRGB's transfer function but has wider
    /// primaries, hence a different matrix.)
    static let xyz = LinearMap(
        matrix: Matrix<3, 3>([
            [0.4865709486482162, 0.26566769316909306, 0.19821728523436247],
            [0.2289745640697488, 0.6917385218365064,  0.079286914093745],
            [0.0,                0.04511338185890264, 1.043944368900976],
        ]),
        inverse: Matrix<3, 3>([
            [2.493496911941425,   -0.9313836179191239,  -0.40271078445071684],
            [-0.8294889695615747, 1.7626640603183463,   0.023624685841943577],
            [0.03584583024378447, -0.07617238926804182, 0.9568845240076872],
        ])
    )

    public func toXYZ() -> XYZ {
        let lr = TransferFunction.sRGB.toLinear(red)
        let lg = TransferFunction.sRGB.toLinear(green)
        let lb = TransferFunction.sRGB.toLinear(blue)
        let v = Self.xyz.matrix * Vector([lr, lg, lb])
        return XYZ(x: v[0], y: v[1], z: v[2], alpha: alpha)
    }

    public static func fromXYZ(_ xyz: XYZ) -> DisplayP3 {
        let v = Self.xyz.inverse * Vector([xyz.x, xyz.y, xyz.z])
        return DisplayP3(
            red: TransferFunction.sRGB.toEncoded(v[0]),
            green: TransferFunction.sRGB.toEncoded(v[1]),
            blue: TransferFunction.sRGB.toEncoded(v[2]),
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

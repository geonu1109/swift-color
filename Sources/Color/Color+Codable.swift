/// `Color` encodes as `{ "colorSpace": <tag>, "components": { … }, "alpha": <n> }`.
///
/// `colorSpace` is a stable lowercase-hyphen tag, `components` holds only the
/// space's color coordinates (so the shape matches the space), and `alpha` is a
/// top-level sibling because opacity is space-independent. The authored space is
/// preserved, so encoding round-trips losslessly — except a user-defined
/// (`.custom`) space serializes as `xyz`, since an unknown type can't be
/// reconstructed without a registry. Example:
/// `{"colorSpace":"oklch","components":{"lightness":0.7,"chroma":0.15,"hue":250},"alpha":1}`.
extension Color: Codable {
    private enum CodingKeys: String, CodingKey {
        case colorSpace, components, alpha
    }

    /// A string-keyed `CodingKey` for the variable `components` object.
    private struct ComponentKey: CodingKey {
        let stringValue: String
        var intValue: Int? { nil }
        init(_ stringValue: String) { self.stringValue = stringValue }
        init?(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { nil }
    }

    /// The space tag, its ordered coordinate (name, value) pairs, and alpha.
    private var encodedForm: (tag: String, components: [(String, Double)], alpha: Double) {
        switch storage {
        case let .sRGB(v):       return ("srgb",        [("red", v.red), ("green", v.green), ("blue", v.blue)], v.alpha)
        case let .linearSRGB(v): return ("srgb-linear", [("red", v.red), ("green", v.green), ("blue", v.blue)], v.alpha)
        case let .displayP3(v):  return ("display-p3",  [("red", v.red), ("green", v.green), ("blue", v.blue)], v.alpha)
        case let .hsl(v):        return ("hsl",         [("hue", v.hue), ("saturation", v.saturation), ("lightness", v.lightness)], v.alpha)
        case let .hsv(v):        return ("hsv",         [("hue", v.hue), ("saturation", v.saturation), ("value", v.value)], v.alpha)
        case let .oklab(v):      return ("oklab",       [("lightness", v.lightness), ("a", v.a), ("b", v.b)], v.alpha)
        case let .oklch(v):      return ("oklch",       [("lightness", v.lightness), ("chroma", v.chroma), ("hue", v.hue)], v.alpha)
        case let .xyz(v):        return ("xyz",         [("x", v.x), ("y", v.y), ("z", v.z)], v.alpha)
        // A user-defined space can't be reconstructed from JSON without a type
        // registry, so it serializes as XYZ (color preserved, type identity not).
        case let .custom(v):     let xyz = v.toXYZ(); return ("xyz", [("x", xyz.x), ("y", xyz.y), ("z", xyz.z)], xyz.alpha)
        }
    }

    public func encode(to encoder: any Encoder) throws {
        let form = encodedForm
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(form.tag, forKey: .colorSpace)
        var components = container.nestedContainer(keyedBy: ComponentKey.self, forKey: .components)
        for (name, value) in form.components {
            try components.encode(value, forKey: ComponentKey(name))
        }
        try container.encode(form.alpha, forKey: .alpha)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let tag = try container.decode(String.self, forKey: .colorSpace)
        let alpha = try container.decodeIfPresent(Double.self, forKey: .alpha) ?? 1
        let c = try container.nestedContainer(keyedBy: ComponentKey.self, forKey: .components)
        func value(_ name: String) throws -> Double { try c.decode(Double.self, forKey: ComponentKey(name)) }

        switch tag {
        case "srgb":        storage = .sRGB(SRGB(red: try value("red"), green: try value("green"), blue: try value("blue"), alpha: alpha))
        case "srgb-linear": storage = .linearSRGB(LinearSRGB(red: try value("red"), green: try value("green"), blue: try value("blue"), alpha: alpha))
        case "display-p3":  storage = .displayP3(DisplayP3(red: try value("red"), green: try value("green"), blue: try value("blue"), alpha: alpha))
        case "hsl":         storage = .hsl(HSL(hue: try value("hue"), saturation: try value("saturation"), lightness: try value("lightness"), alpha: alpha))
        case "hsv":         storage = .hsv(HSV(hue: try value("hue"), saturation: try value("saturation"), value: try value("value"), alpha: alpha))
        case "oklab":       storage = .oklab(OKLab(lightness: try value("lightness"), a: try value("a"), b: try value("b"), alpha: alpha))
        case "oklch":       storage = .oklch(OKLCH(lightness: try value("lightness"), chroma: try value("chroma"), hue: try value("hue"), alpha: alpha))
        case "xyz":         storage = .xyz(XYZ(x: try value("x"), y: try value("y"), z: try value("z"), alpha: alpha))
        default:
            throw DecodingError.dataCorruptedError(forKey: .colorSpace, in: container, debugDescription: "Unknown color space '\(tag)'")
        }
    }
}

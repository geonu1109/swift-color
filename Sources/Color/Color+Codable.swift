/// `Color` encodes the space it was authored in plus that space's components,
/// so encoding round-trips losslessly. Example: `{"space":"srgb","red":0.2,
/// "green":0.5,"blue":0.9,"alpha":1}`.
extension Color: Codable {
    private enum CodingKeys: String, CodingKey {
        case space
    }

    private enum SpaceTag: String, Codable {
        case srgb, linearSRGB, displayP3, hsl, hsv, oklab, oklch, xyz
    }

    private var tag: SpaceTag {
        switch storage {
        case .sRGB: .srgb
        case .linearSRGB: .linearSRGB
        case .displayP3: .displayP3
        case .hsl: .hsl
        case .hsv: .hsv
        case .oklab: .oklab
        case .oklch: .oklch
        case .xyz: .xyz
        }
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(SpaceTag.self, forKey: .space) {
        case .srgb: storage = .sRGB(try SRGB(from: decoder))
        case .linearSRGB: storage = .linearSRGB(try LinearSRGB(from: decoder))
        case .displayP3: storage = .displayP3(try DisplayP3(from: decoder))
        case .hsl: storage = .hsl(try HSL(from: decoder))
        case .hsv: storage = .hsv(try HSV(from: decoder))
        case .oklab: storage = .oklab(try OKLab(from: decoder))
        case .oklch: storage = .oklch(try OKLCH(from: decoder))
        case .xyz: storage = .xyz(try XYZ(from: decoder))
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(tag, forKey: .space)
        // The stored space writes its own component fields alongside `space`.
        try storage.space.encode(to: encoder)
    }
}

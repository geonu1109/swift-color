import Testing
import Foundation
@testable import Color

private func isClose(_ lhs: Double, _ rhs: Double, tolerance: Double = 0.001) -> Bool {
    abs(lhs - rhs) <= tolerance
}

@Suite("Authored space is preserved")
struct StorageTests {
    @Test("Reading back the stored space is exact (no round-trip drift)")
    func exactSameSpace() {
        let srgb = SRGB(red: 0.2, green: 0.5, blue: 0.9, alpha: 0.8)
        let color = Color(srgb)
        // Same space → returns the stored value verbatim.
        #expect(color.srgb == srgb)

        let p3 = DisplayP3(red: 1, green: 0, blue: 0)
        #expect(Color(p3).displayP3 == p3)
    }

    @Test("alpha is editable without disturbing the color")
    func alpha() {
        let color = Color(OKLCH(lightness: 0.7, chroma: 0.1, hue: 200)).alpha(0.3)
        #expect(isClose(color.alpha, 0.3))
        #expect(isClose(color.oklch.lightness, 0.7))
    }
}

@Suite("Cross-space conversions")
struct ConversionTests {
    @Test("sRGB ↔ any space round-trips")
    func roundTrips() {
        let color = Color(red: 0.3, green: 0.6, blue: 0.85)
        for restored in [
            Color(color.oklch), Color(color.oklab), Color(color.hsl),
            Color(color.hsb), Color(color.displayP3), Color(color.xyz),
            Color(color.linearSRGB),
        ] {
            let rgb = restored.srgb
            #expect(isClose(rgb.red, 0.3))
            #expect(isClose(rgb.green, 0.6))
            #expect(isClose(rgb.blue, 0.85))
        }
    }

    @Test("sRGB red matches OKLCH reference (Ottosson)")
    func referenceOKLCH() {
        let oklch = Color(SRGB.red).oklch
        #expect(isClose(oklch.lightness, 0.6279, tolerance: 0.002))
        #expect(isClose(oklch.chroma, 0.2577, tolerance: 0.002))
        #expect(isClose(oklch.hue, 29.23, tolerance: 0.5))
    }

    @Test("sRGB red matches XYZ (D65) reference")
    func referenceXYZ() {
        let xyz = Color(SRGB.red).xyz
        #expect(isClose(xyz.x, 0.4124, tolerance: 0.001))
        #expect(isClose(xyz.y, 0.2126, tolerance: 0.001))
        #expect(isClose(xyz.z, 0.0193, tolerance: 0.001))
    }

    @Test("Primary hues map to expected HSL/HSB")
    func hslHsb() {
        #expect(isClose(Color(SRGB.red).hsl.hue, 0, tolerance: 0.01))
        #expect(isClose(Color(SRGB.red).hsl.saturation, 1))
        #expect(isClose(Color(SRGB.red).hsl.lightness, 0.5))
        #expect(isClose(Color(SRGB.green).hsb.hue, 120, tolerance: 0.01))
        #expect(isClose(Color(SRGB.blue).hsb.brightness, 1))
    }

    @Test("sRGB red is a less saturated red in Display P3")
    func sRGBtoP3() {
        // sRGB's gamut is inside P3, so pure sRGB red sits within P3.
        let p3 = Color(SRGB.red).displayP3
        #expect(isClose(p3.red, 0.9175, tolerance: 0.01))
        #expect(isClose(p3.green, 0.2003, tolerance: 0.01))
        #expect(isClose(p3.blue, 0.1387, tolerance: 0.01))
    }

    @Test("Custom ColorSpace conformance interoperates")
    func customSpace() {
        // Any space conforming to ColorSpace converts via XYZ for free.
        let viaProtocol: OKLCH = SRGB(red: 1, green: 0, blue: 0).converted(to: OKLCH.self)
        #expect(isClose(viaProtocol.hue, 29.23, tolerance: 0.5))
    }
}

@Suite("Gamut")
struct GamutTests {
    @Test("Wide-gamut colors are detected and perceptually mapped")
    func gamutMapping() {
        // A saturated P3 green outside sRGB.
        let wide = Color(DisplayP3(red: 0, green: 1, blue: 0))
        #expect(!wide.isInSRGBGamut)

        let mapped = wide.gamutMappedToSRGB()
        #expect(mapped.isInSRGBGamut)
        // Hue is preserved far better than a hard clip.
        #expect(isClose(mapped.oklch.hue, wide.oklch.hue, tolerance: 5))
    }

    @Test("In-gamut colors are unchanged by mapping")
    func inGamutUnchanged() {
        #expect(Color(SRGB.red).isInSRGBGamut)
        #expect(isClose(Color(SRGB.red).gamutMappedToSRGB().srgb.red, 1))
    }

    @Test("hexString never traps and round-trips in-gamut colors")
    func hex() {
        #expect(Color(hex: "#3B82F6")?.hexString == "#3B82F6")
        #expect(Color(hex: "#FFF")?.hexString == "#FFFFFF")
        // Out of gamut → valid clamped hex, no crash.
        let wide = Color(OKLCH(lightness: 0.9, chroma: 0.4, hue: 145))
        #expect(wide.hexString.count == 7)
    }
}

@Suite("Codable & bridging")
struct CodableBridgingTests {
    @Test("Codable preserves the authored space losslessly")
    func codable() throws {
        for original in [
            Color(OKLCH(lightness: 0.7, chroma: 0.18, hue: 264, alpha: 0.5)),
            Color(DisplayP3(red: 1, green: 0.2, blue: 0.1)),
            Color(red: 0.3, green: 0.6, blue: 0.9),
        ] {
            let data = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(Color.self, from: data)
            #expect(decoded == original)
        }
    }

    @Test("Codable JSON carries the space tag")
    func codableShape() throws {
        let data = try JSONEncoder().encode(Color(red: 1, green: 0, blue: 0))
        let json = String(decoding: data, as: UTF8.self)
        #expect(json.contains("\"space\":\"srgb\""))
        #expect(json.contains("\"red\":1"))
    }

    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
    @Test("NSColor bridge round-trips within sRGB")
    func nsColorBridge() {
        let color = Color(hex: "#3B82F6")!
        #expect(Color(color.nsColor).hexString == "#3B82F6")
    }
    #endif
}

@Suite("Modifiers & palette")
struct ModifierPaletteTests {
    @Test("lightness/chroma/hue set absolute OKLCH values; only the targeted channel changes")
    func absoluteSetters() {
        let base = Color(OKLCH(lightness: 0.5, chroma: 0.1, hue: 30))
        #expect(isClose(base.lightness(0.8).oklch.lightness, 0.8))
        #expect(isClose(base.chroma(0.2).oklch.chroma, 0.2))
        #expect(isClose(base.hue(200).oklch.hue, 200, tolerance: 0.01))
        #expect(isClose(base.lightness(5).oklch.lightness, 1))            // clamps to 0...1
        #expect(isClose(base.lightness(0.8).oklch.hue, 30, tolerance: 0.01)) // hue untouched
    }

    @Test("alpha modifier and property agree")
    func alphaModifier() {
        #expect(isClose(Color(SRGB.red).alpha(0.4).alpha, 0.4))
    }

    @Test("grayscale removes chroma; complementary rotates hue 180°")
    func grayscaleAndComplementary() {
        #expect(isClose(Color(SRGB.red).grayscale().oklch.chroma, 0, tolerance: 0.0001))
        let base = Color(OKLCH(lightness: 0.6, chroma: 0.2, hue: 40))
        #expect(isClose(base.complementary.oklch.hue, 220, tolerance: 0.01))
    }

    @Test("Named sRGB palette on the SRGB type")
    func srgbPalette() {
        #expect(Color(SRGB.red).hexString == "#FF0000")
        #expect(Color(SRGB.cyan).hexString == "#00FFFF")
        #expect(Color(SRGB.gray).hexString == "#808080")
        // grays form a light → dark lightness ramp
        #expect(Color(SRGB.lightGray).oklch.lightness > Color(SRGB.gray).oklch.lightness)
        #expect(Color(SRGB.gray).oklch.lightness > Color(SRGB.darkGray).oklch.lightness)
        #expect(isClose(Color(SRGB.clear).alpha, 0))
    }

    @Test("OKLCH palette: chromatic hues at shared L/C, achromatic at zero chroma")
    func oklchPalette() {
        for preset in [OKLCH.red, .yellow, .green, .cyan, .blue, .magenta] {
            #expect(isClose(preset.lightness, 0.7))
            #expect(isClose(preset.chroma, 0.15))
        }
        #expect(OKLCH.red.hue != OKLCH.blue.hue)
        #expect(isClose(Color(OKLCH.blue).oklch.chroma, 0.15)) // usable as a Color

        // Achromatic presets: zero chroma on a light → dark ramp.
        for achromatic in [OKLCH.white, .lightGray, .gray, .darkGray, .black] {
            #expect(isClose(achromatic.chroma, 0))
        }
        #expect(OKLCH.white.lightness > OKLCH.gray.lightness)
        #expect(OKLCH.gray.lightness > OKLCH.black.lightness)
    }
}

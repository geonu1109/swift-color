# swift-color

**English** · [한국어](README.ko.md)

A general, device-independent **color model** for Swift — not an OKLCH library, but a model for color *in general*.

> The directory and repo are named `swift-color`, but the importable module is **`Color`**:
>
> ```swift
> import Color
> ```

## Why

On Apple platforms the only "color" types are `UIColor` and SwiftUI's `Color`. Both are **rendering objects**, not values you can compute with:

- They're tied to a drawing/display context, not a clean `Sendable`, `Codable`, `Hashable` value you can store, diff, and do math on.
- Reading components back out is clumsy (`getRed(_:green:blue:alpha:)`), and there's no first-class notion of *which color space* a value lives in.

Meanwhile real color work spans many spaces — **OKLCH** for perceptually even gradients and tints, **Display P3** for wide-gamut screens, **HSL/HSV** for pickers — and needs correct conversion between them. Apple exposes none of that cleanly, so projects end up hand-rolling hex parsing, mixing colors in sRGB (which produces muddy midpoints), and hard-clipping wide-gamut colors the moment they're created — losing information they can't get back.

## What it gives you

A `Color` **value type** that:

- **Preserves the space you authored in** — sRGB stays sRGB, Display P3 stays P3, OKLCH stays OKLCH — and converts only on demand.
- **Interconverts every space** through one connection hub, so any A→B conversion is exact-by-construction and composes automatically.
- Mixes and manipulates **perceptually** (OKLCH), maps wide-gamut colors into sRGB the **right** way (chroma reduction, not naive clipping), and is `Sendable` / `Hashable` / `Codable`.
- Bridges to **SwiftUI / UIKit / AppKit / CoreGraphics** when you actually need to draw.

Supported spaces: sRGB, linear sRGB, Display P3, HSL, HSV, OKLab, OKLCH, CIE XYZ — and your own, via the `ColorSpace` protocol.

## Installation

Swift Package Manager — add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/geonu1109/swift-color.git", from: "1.0.0"),
],
```

then list the `Color` product in your target:

```swift
.target(name: "YourTarget", dependencies: [
    .product(name: "Color", package: "swift-color"),
]),
```

In Xcode: **File ▸ Add Package Dependencies…**, then paste the repository URL.

## Usage

```swift
import Color

// Construct in any space — the space is preserved.
let brand = Color(hex: "#3B82F6")!                       // sRGB
let wide  = Color(DisplayP3(red: 1, green: 0, blue: 0))  // stays P3
let vivid = Color(OKLCH(lightness: 0.7, chroma: 0.15, hue: 250))

// Read in any space — converted on demand (exact when it's the stored space).
brand.oklch          // OKLCH
brand.hsl            // HSL
brand.hsv            // HSV  (a.k.a. HSB — `brand.hsb` and the `HSB` alias also work)
brand.displayP3
brand.converted(to: HSV.self)

// Manipulate perceptually. lightness/chroma/hue set absolute OKLCH values
// (no ambiguous "by" deltas); each returns a new Color.
brand.lightness(0.8)
brand.chroma(0.05)
brand.hue(120)
brand.alpha(0.5)
brand.grayscale()
brand.complementary                                  // hue + 180°
brand.rotatedHue(by: 30)                             // relative, in degrees
brand.mixed(with: Color(SRGB.white), amount: 0.25)   // OKLCH by default
brand.mixed(with: wide, amount: 0.5, in: .oklab)     // or .srgb / .hsl / .displayP3 / .xyz

// Named colors live on their space types — wrap to use:
//   Color(SRGB.red) … Color(SRGB.clear)   standard sRGB colors
//   Color(OKLCH.blue) …                   perceptually-uniform OKLCH palette (L 0.7 / C 0.15)
```

### Gamut mapping

Wide-gamut colors (P3, high-chroma OKLCH) must be mapped to display in sRGB. Both strategies are provided; the perceptual one is the default used by `hexString` and the UI bridges:

```swift
color.isInSRGBGamut
color.gamutMappedToSRGB()   // CSS Color 4: reduce OKLCH chroma, preserve hue (perceptual)
color.clampedToSRGB()       // hard clip each channel (fast)
```

### Bridging to Apple frameworks

```swift
brand.swiftUIColor            // SwiftUI.Color (sRGB, gamut-mapped)
brand.swiftUIColorDisplayP3   // wide-gamut variant
brand.uiColor / brand.nsColor / brand.cgColor

Color(someUIColor)            // back into the model
SwiftUI.Color(brand)
```

> **Naming:** the module and the model type are both `Color`. They don't clash with `SwiftUI.Color` on their own, but in a file that imports both `Color` and `SwiftUI` the bare name `Color` is ambiguous. This module exports `typealias SwiftUIColor = SwiftUI.Color` so you can name SwiftUI's type cleanly; in practice the `.swiftUIColor` accessor means you rarely need to.

### Extending with your own space

Conform to `ColorSpace` (define `toXYZ()` / `fromXYZ()`) and your space instantly converts to and from every built-in one:

```swift
struct Rec2020: ColorSpace { /* … toXYZ / fromXYZ … */ }
Rec2020(...).converted(to: OKLCH.self)
```

## How it works

- **Authored-space storage.** A `Color` keeps the components of whatever space created it, so reading that same space returns the exact values you put in — no round-trip drift, and the authoring intent (e.g. "this is a P3 color") survives.
- **One connection hub.** Every space defines only how it maps to and from **CIE XYZ (D65)**. Any A→B conversion is then `A → XYZ → B`, composed automatically — N spaces need N pairs of transforms instead of N² direct ones, and new spaces drop in with two functions.

```
   sRGB ─┐                          ┌─ HSL / HSV
 linear ─┤──  CIE XYZ (D65) hub  ──┼─ OKLab / OKLCH
     P3 ─┘                          └─ …your own space
```

- **Gamut mapping happens at the boundary, not at construction.** Storage stays wide and lossless; only when you ask for sRGB output (hex, UI bridge) is the color reduced into gamut, perceptually by default (CSS Color 4 chroma reduction in OKLCH).

## Guarantees & semantics

These are the behaviors you can rely on (and the criteria the test suite checks):

- **Same-space reads are exact.** `Color(SRGB(...)).srgb` returns the stored value verbatim — conversion only happens when the requested space differs.
- **Conversions are near-lossless.** They run in `Double` through the XYZ hub; round-trips agree well within 8-bit display precision (e.g. `Color(hex:)` ↔ `hexString` round-trips exactly).
- **No premature gamut loss.** Wide-gamut and out-of-sRGB colors are preserved in storage; clipping/mapping is applied only at output. `hexString` clamps into gamut and never traps on out-of-range or non-finite components.
- **One white point.** The whole system is D65 (the white point of sRGB, P3, and OKLab), so no chromatic adaptation is ever needed. If you need CIE Lab/LCH or D50 (print, ICC, CSS `lab()`), add it as your own `ColorSpace`.
- **`Codable` preserves the authored space** (encoded with a space tag), so values round-trip losslessly.
- **Equality is space + component based.** Two colors that are the *same color* but stored in *different spaces* are not `==` (much like a `Money` value carries its currency). Compare in a common space — e.g. `a.oklch == b.oklch` — when you mean perceptual equality.

## Requirements

Swift 6.0+ · macOS 13 / iOS 16 / tvOS 16 / watchOS 9 / visionOS 1 · **Linux** (server-side — the UI bridges compile out under `canImport`, the rest is portable). No external dependencies.

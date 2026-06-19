# swift-color

[English](README.md) · **한국어**

Swift용 범용·장치 독립 **색 모델**. OKLCH 전용 라이브러리가 아니라 *색 전반*을 위한 모델이다.

> 디렉터리·repo 이름은 `swift-color`이지만, import하는 모듈명은 **`Color`**이다.
>
> ```swift
> import Color
> ```

## 왜 (Why)

Apple 플랫폼에서 "색" 타입은 `UIColor`와 SwiftUI의 `Color`뿐인데, 둘 다 **렌더링 객체**지 계산에 쓸 값이 아니다.

- 그리기/표시 컨텍스트에 묶여 있어서, 저장·비교·연산할 수 있는 깔끔한 `Sendable`·`Codable`·`Hashable` 값이 아니다.
- 성분을 다시 읽어내는 것도 번거롭고(`getRed(_:green:blue:alpha:)`), *어느 색 공간*에 있는 값인지를 1급으로 다루는 개념이 없다.

한편 실제 색 작업은 여러 공간에 걸쳐 있다 — 지각적으로 균일한 그라디언트·틴트엔 **OKLCH**, 광색역 화면엔 **Display P3**, 피커엔 **HSL/HSV** — 그리고 그 사이를 올바르게 변환해야 한다. Apple은 이걸 깔끔하게 제공하지 않아서, 프로젝트마다 hex 파싱을 직접 짜고, sRGB에서 색을 섞어(중간색이 탁해진다) 광색역 색을 만들자마자 하드 클립해 되돌릴 수 없는 정보를 잃곤 한다.

## 무엇을 (What)

다음을 갖춘 `Color` **값 타입**:

- **작성한 공간을 보존한다** — sRGB는 sRGB로, Display P3는 P3로, OKLCH는 OKLCH로 — 그리고 요청할 때만 변환한다.
- **모든 공간을 하나의 연결 허브를 통해 상호 변환**하므로, 임의의 A→B 변환이 구성상 정확하고 자동으로 조합된다.
- **지각적으로**(OKLCH) 섞고 조작하며, 광색역 색을 **올바른 방식**(단순 클리핑이 아니라 채도 감소)으로 sRGB에 매핑하고, `Sendable`·`Hashable`·`Codable`이다.
- 실제로 그릴 때를 위해 **SwiftUI / UIKit / AppKit / CoreGraphics**로 브리지한다.

지원 공간: sRGB, linear sRGB, Display P3, HSL, HSV, OKLab, OKLCH, CIE XYZ — 그리고 `ColorRepresentation` 프로토콜로 직접 정의한 공간.

## 설치

Swift Package Manager — `Package.swift`에 추가한다.

```swift
dependencies: [
    .package(url: "https://github.com/geonu1109/swift-color.git", from: "1.0.0"),
],
```

그리고 타깃에 `Color` 프로덕트를 추가한다.

```swift
.target(name: "YourTarget", dependencies: [
    .product(name: "Color", package: "swift-color"),
]),
```

Xcode에서는 **File ▸ Add Package Dependencies…**를 열고 저장소 URL을 입력한다.

## 사용법

```swift
import Color

// 어느 공간으로든 생성 — 그 공간이 보존된다.
let brand = Color(hex: "#3B82F6")!                       // sRGB
let wide  = Color(DisplayP3(red: 1, green: 0, blue: 0))  // P3로 유지
let vivid = Color(OKLCH(lightness: 0.7, chroma: 0.15, hue: 250))

// 어느 공간으로든 읽기 — 요청 시 변환된다(저장된 공간이면 정확).
brand.oklch          // OKLCH
brand.hsl            // HSL
brand.hsv            // HSV  (= HSB — brand.hsb, HSB 별칭도 동작)
brand.displayP3
brand.converted(to: HSV.self)
brand.space          // .sRGB — 어느 공간에 저장됐는지

// 지각적으로 조작. lightness/chroma/hue는 OKLCH 절대값을 지정하며
// (모호한 "by" 증분 없음) 각각 새 Color를 반환한다.
brand.lightness(0.8)
brand.chroma(0.05)
brand.hue(120)
brand.alpha(0.5)
brand.grayscale()
brand.complementary                                  // 색상 + 180°
brand.rotatedHue(by: 30)                             // 상대 회전(도 단위)
brand.mixed(with: Color(SRGB.white), amount: 0.25)   // 기본은 OKLCH
brand.mixed(with: wide, amount: 0.5, in: .oklab)     // 또는 .srgb / .hsl / .displayP3 / .xyz

// 지표 — 접근성·매칭.
brand.relativeLuminance                              // WCAG 상대 휘도 (0…1)
brand.contrastRatio(to: Color(SRGB.white))           // WCAG 명도 대비 (1…21)
brand.difference(to: Color(SRGB.blue))               // 지각적 색차 (ΔEOK)

// 명명 색상은 각 공간 타입에 있다 — 감싸서 사용:
//   Color(SRGB.red) … Color(SRGB.clear)   표준 sRGB 색상
//   Color(OKLCH.blue) …                   지각 균일 OKLCH 팔레트 (L 0.7 / C 0.15, 무채색 포함)
```

### 게멋(색역) 매핑

광색역 색(P3, 고채도 OKLCH)을 sRGB로 표시하려면 매핑이 필요하다. 두 방식을 모두 제공하며, `hexString`과 UI 브리지의 기본값은 지각적(perceptual) 방식이다.

```swift
color.isInSRGBGamut
color.gamutMappedToSRGB()   // CSS Color 4: OKLCH 채도를 줄이고 색상은 유지(지각적)
color.clampedToSRGB()       // 각 채널을 하드 클립(빠름)
```

### Apple 프레임워크 브리지

```swift
brand.swiftUIColor            // SwiftUI.Color (sRGB, 게멋 매핑됨)
brand.swiftUIColorDisplayP3   // 광색역 변형
brand.uiColor / brand.nsColor / brand.cgColor

Color(someUIColor)            // 모델로 역변환
SwiftUI.Color(brand)
```

> **네이밍:** 모듈과 모델 타입이 모두 `Color`이다. 그 자체로는 `SwiftUI.Color`와 충돌하지 않으나, 한 파일에서 `Color`와 `SwiftUI`를 함께 import하면 맨이름 `Color`가 모호해진다. 이 모듈은 `typealias SwiftUIColor = SwiftUI.Color`를 노출하여 SwiftUI 타입을 명확히 지칭할 수 있게 한다. 다만 `.swiftUIColor` 접근자가 있어 직접 지칭할 일은 거의 없다.

### 직접 정의한 공간으로 확장

`ColorRepresentation`를 준수하면(`toXYZ()` / `fromXYZ()` 정의) 해당 공간은 즉시 모든 내장 공간과 상호 변환된다.

```swift
struct Rec2020: ColorRepresentation { /* … toXYZ / fromXYZ … */ }
Rec2020(...).converted(to: OKLCH.self)
Color(Rec2020(...))   // 그대로 저장·정확 복원; color.space == .custom
```

`Color`로 감싸면 커스텀 공간도 그대로 저장되고 정확히 복원된다(`color.space`는 `.custom`). 단 `Codable` 직렬화 시에는 XYZ로 저장된다 — 미지의 타입은 레지스트리 없이 JSON에서 복원할 수 없기 때문이라, 색은 왕복하지만 커스텀 *타입 정체성*은 보존되지 않는다.

## 동작 원리

- **작성 공간 저장.** `Color`는 자신을 만든 공간의 성분을 그대로 보관하므로, 같은 공간으로 읽으면 넣은 값이 정확히 돌아온다 — 왕복 오차가 없고, 작성 의도("이건 P3 색")가 유지된다.
- **하나의 연결 허브.** 각 공간은 **CIE XYZ (D65)** 와의 변환만 정의한다. 임의의 A→B 변환은 `A → XYZ → B`로 자동 조합된다 — N개 공간에 N² 변환 대신 N쌍만 필요하고, 새 공간은 함수 두 개로 끼워진다.

```
   sRGB ─┐                          ┌─ HSL / HSV
 linear ─┤──  CIE XYZ (D65) hub  ──┼─ OKLab / OKLCH
     P3 ─┘                          └─ …직접 정의한 공간
```

- **게멋 매핑은 생성 시점이 아니라 출력 경계에서 일어난다.** 저장은 넓고 무손실로 유지하고, sRGB 출력(hex, UI 브리지)을 요청할 때만 게멋 안으로 줄인다 — 기본은 지각적 방식(OKLCH 채도 감소, CSS Color 4).
- **변환 행렬은 차원이 검증된다.** 각 색상 행렬은 `Matrix<rows, columns>`, 각 삼자극치는 `Vector<count>`다 — Swift의 정수 제네릭 파라미터를 쓰는 고정 크기 타입이라, 크기가 어긋난 곱셈은 컴파일 에러이고, 상수 3×3 행렬은 평평한 9-원소 배열이 아니라 세 개의 행으로 읽힌다.

## 보장 동작

신뢰할 수 있는 동작이자 테스트가 검증하는 기준이다.

- **같은 공간 읽기는 정확하다.** `Color(SRGB(...)).srgb`는 저장된 값을 그대로 반환한다 — 변환은 다른 공간을 요청할 때만 일어난다.
- **변환은 거의 무손실이다.** XYZ 허브를 통해 `Double`로 수행되며, 왕복이 8비트 표시 정밀도 안에서 일치한다(예: `Color(hex:)` ↔ `hexString` 정확히 왕복).
- **조기 게멋 손실이 없다.** 광색역·sRGB 밖 색은 저장에 보존되고, 클리핑/매핑은 출력 시에만 적용된다. `hexString`은 게멋 안으로 클램프하며 범위 밖·비유한 성분에도 트랩하지 않는다.
- **단일 흰색점.** 전체 시스템이 D65(sRGB·P3·OKLab의 흰색점)이라 chromatic adaptation이 전혀 필요 없다. CIE Lab/LCH나 D50이 필요하면(인쇄·ICC·CSS `lab()`) 직접 `ColorRepresentation`로 추가한다.
- **`Codable`은 작성 공간을 보존한다**므로 무손실로 왕복한다. 형태는 `{"colorSpace":"oklch","components":{"lightness":0.7,"chroma":0.15,"hue":250},"alpha":1}` — 소문자-하이픈 공간 태그, 그 공간의 좌표는 `components` 아래, `alpha`는 최상위(불투명도는 공간 무관).
- **동등성은 공간 + 성분 기준이다.** *같은 색*이라도 *다른 공간*에 저장돼 있으면 `==`가 아니다(통화를 들고 다니는 `Money` 값처럼). 지각적 동등성을 원하면 공통 공간에서 비교한다 — 예: `a.oklch == b.oklch`.

## 요구 사항

Swift 6.3+ · macOS 26 / iOS 26 / tvOS 26 / watchOS 26 / visionOS 26 · **Linux**(서버사이드 — UI 브리지는 `canImport`로 제외되고 나머지는 이식 가능). 외부 의존성이 없다.

> 요구 버전이 높은 이유는 최신 Swift 기능을 쓰기 때문이다: **value generics**와 `InlineArray`(OS 표준 라이브러리에 포함되어 Apple 플랫폼에선 2025년 릴리스를 요구), 그리고 `::` **module selector**(Swift 6.3 기능). Linux에는 OS 버전 하한이 없고 Swift 6.3 툴체인만 있으면 된다.

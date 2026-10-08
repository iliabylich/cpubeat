import CoreGraphics

enum Style {
  struct AdaptiveColor {
    let light: CGColor
    let dark: CGColor

    func resolve(_ appearance: Appearance) -> CGColor {
      switch appearance {
      case .light: light
      case .dark: dark
      }
    }
  }

  struct Bar {
    let color: CGColor
    let height: CGFloat
  }

  private struct BarTemplate {
    let color: AdaptiveColor
    let height: CGFloat

    init(light: CGColor, dark: CGColor, heightFraction: CGFloat) {
      color = AdaptiveColor(light: light, dark: dark)
      height = (heightFraction * Layout.maxBarHeight).rounded()
    }

    func resolve(_ appearance: Appearance) -> Bar {
      Bar(color: color.resolve(appearance), height: height)
    }
  }

  static let borderColor = AdaptiveColor(light: .rgb(0x404040), dark: .rgb(0xFFFFFF))

  private static let bars: [8 of BarTemplate] = [
    .init(light: .rgb(0x404040), dark: .rgb(0xFFFFFF), heightFraction: 0.125),
    .init(light: .rgb(0x583737), dark: .rgb(0xFFD5D5), heightFraction: 0.25),
    .init(light: .rgb(0x6F2E2E), dark: .rgb(0xFFAAAA), heightFraction: 0.375),
    .init(light: .rgb(0x872525), dark: .rgb(0xFF8080), heightFraction: 0.5),
    .init(light: .rgb(0x9F1B1B), dark: .rgb(0xFF5555), heightFraction: 0.625),
    .init(light: .rgb(0xB71212), dark: .rgb(0xFF2B2B), heightFraction: 0.75),
    .init(light: .rgb(0xCE0909), dark: .rgb(0xFF0000), heightFraction: 0.875),
    .init(light: .rgb(0xE60000), dark: .rgb(0xE60000), heightFraction: 1),
  ]

  static let barCount = bars.count

  static func bar(level: CoreUsageLevel, appearance: Appearance) -> Bar {
    bars[level.value].resolve(appearance)
  }
}

extension CGColor {
  fileprivate static func rgb(_ hex: UInt32) -> CGColor {
    CGColor(
      srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
      green: CGFloat((hex >> 8) & 0xFF) / 255,
      blue: CGFloat(hex & 0xFF) / 255,
      alpha: 1)
  }
}

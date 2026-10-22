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

  private static let bars: [5 of BarTemplate] = [
    .init(light: .rgb(0x404040), dark: .rgb(0xFFFFFF), heightFraction: 0.125),
    .init(light: .rgb(0x6A3030), dark: .rgb(0xFFAAAA), heightFraction: 0.25),
    .init(light: .rgb(0x932020), dark: .rgb(0xFF5555), heightFraction: 0.5),
    .init(light: .rgb(0xBC1010), dark: .rgb(0xFF0000), heightFraction: 0.75),
    .init(light: .rgb(0xE60000), dark: .rgb(0xE60000), heightFraction: 1),
  ]

  static func level(_ usage: Double) -> UInt8 {
    UInt8(min(bars.count - 1, Int((usage * Double(bars.count - 1)).rounded())))
  }

  static func bar(level: UInt8, appearance: Appearance) -> Bar {
    bars[Int(level)].resolve(appearance)
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

import AppKit

enum Appearance {
  case light
  case dark

  init(_ appearance: NSAppearance) {
    self = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? .dark : .light
  }
}

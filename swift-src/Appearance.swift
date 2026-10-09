import AppKit

enum Appearance {
  case light
  case dark

  init(_ appearance: NSAppearance) {
    switch appearance.bestMatch(from: [.aqua, .darkAqua]) {
    case .aqua, nil: self = .light
    case .darkAqua: self = .dark
    default: fatalError("unsupported appearance: \(appearance.name)")
    }
  }
}

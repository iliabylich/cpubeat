import AppKit

enum Layout {
  static let barWidth: CGFloat = 10
  static let barGap: CGFloat = 2
  static let borderWidth: CGFloat = 1
  static let cornerRadius: CGFloat = 3
  static let padding: CGFloat = 4
  static let inset: CGFloat = borderWidth + padding
  static let height: CGFloat = NSStatusBar.system.thickness
  static let maxBarHeight: CGFloat = height - 2 * inset
  static let width: CGFloat =
    CGFloat(FFI.coreCount) * barWidth
    + CGFloat(FFI.coreCount - 1) * barGap
    + 2 * inset
}

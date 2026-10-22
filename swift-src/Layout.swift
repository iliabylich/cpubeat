import CoreGraphics

enum Layout {
  static let barWidth: CGFloat = 10
  static let barGap: CGFloat = 2
  static let cornerRadius: CGFloat = 8
  static let inset: CGFloat = 5
  static let height: CGFloat = 22
  static let maxBarHeight: CGFloat = height - 2 * inset
  static let width: CGFloat =
    CGFloat(FFI.coreCount) * barWidth
    + CGFloat(FFI.coreCount - 1) * barGap
    + 2 * inset
}

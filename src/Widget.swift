import AppKit

final class Widget: NSView {
  private var levels = [CoreUsageLevel](repeating: CoreUsageLevel(0), count: CPU.coreCount)

  init(parent: NSView) {
    super.init(
      frame: NSRect(
        x: 0,
        y: 0,
        width: Layout.width,
        height: Layout.height
      )
    )
    wantsLayer = true

    parent.addSubview(self)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  func update(_ newLevels: [CoreUsageLevel]) {
    precondition(newLevels.count == levels.count, "bar count changed between updates")
    for index in levels.indices where newLevels[index] != levels[index] {
      levels[index] = newLevels[index]
      setNeedsDisplay(Self.barRect(index, height: Layout.maxBarHeight))
    }
  }

  override func draw(_ dirtyRect: NSRect) {
    guard let context = NSGraphicsContext.current?.cgContext else { return }
    let appearance = Appearance(NSAppearance.currentDrawing())

    context.addPath(Self.borderPath)
    context.setLineWidth(Layout.borderWidth)
    context.setStrokeColor(Style.borderColor.resolved(for: appearance))
    context.strokePath()

    for (index, level) in levels.enumerated() {
      let bar = Style.bar(level: level, appearance: appearance)
      context.setFillColor(bar.color)
      context.fill(Self.barRect(index, height: bar.height))
    }
  }

  private static let borderPath: CGPath = {
    let borderInset = Layout.borderWidth / 2
    let borderRadius = Layout.cornerRadius - borderInset
    return CGPath(
      roundedRect: CGRect(x: 0, y: 0, width: Layout.width, height: Layout.height)
        .insetBy(dx: borderInset, dy: borderInset),
      cornerWidth: borderRadius,
      cornerHeight: borderRadius,
      transform: nil)
  }()

  private static func barRect(_ index: Int, height: CGFloat) -> CGRect {
    CGRect(
      x: Layout.inset + CGFloat(index) * (Layout.barWidth + Layout.barGap),
      y: Layout.inset,
      width: Layout.barWidth,
      height: height)
  }
}

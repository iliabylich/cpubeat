import AppKit

final class Widget: NSView {
  private var levels = [UInt8](repeating: 0, count: FFI.coreCount)

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

  func update(_ newLevels: [UInt8]) {
    precondition(newLevels.count == levels.count, "bar count changed between updates")
    for core in 0..<FFI.coreCount where newLevels[core] != levels[core] {
      levels[core] = newLevels[core]
      setNeedsDisplay(Self.barRect(core, height: Layout.maxBarHeight))
    }
  }

  override func draw(_ dirtyRect: NSRect) {
    guard let context = NSGraphicsContext.current?.cgContext else { return }
    let appearance = Appearance(NSAppearance.currentDrawing())

    context.addPath(Self.borderPath)
    context.setLineWidth(Layout.borderWidth)
    context.setStrokeColor(Style.borderColor.resolve(appearance))
    context.strokePath()

    for core in 0..<FFI.coreCount {
      let bar = Style.bar(level: levels[core], appearance: appearance)
      context.setFillColor(bar.color)
      context.fill(Self.barRect(core, height: bar.height))
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

  private static func barRect(_ core: Int, height: CGFloat) -> CGRect {
    CGRect(
      x: Layout.inset + CGFloat(core) * (Layout.barWidth + Layout.barGap),
      y: Layout.inset,
      width: Layout.barWidth,
      height: height)
  }
}

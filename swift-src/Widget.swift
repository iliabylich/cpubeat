import AppKit

final class Widget: NSView {
  private var levels = [UInt8](repeating: 0, count: FFI.coreCount)
  private var occlusionObserver: Task<Void, Never>?

  private var isVisible: Bool {
    window?.occlusionState.contains(.visible) ?? false
  }

  init() {
    super.init(
      frame: NSRect(
        x: 0,
        y: 0,
        width: Layout.width,
        height: Layout.height
      )
    )
    wantsLayer = true
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  func update(_ newLevels: [UInt8]) {
    precondition(newLevels.count == levels.count, "bar count changed between updates")
    var dirty = CGRect.null
    for core in 0..<FFI.coreCount where newLevels[core] != levels[core] {
      levels[core] = newLevels[core]
      dirty = dirty.union(Self.barRect(core, height: Layout.maxBarHeight))
    }
    if isVisible {
      setNeedsDisplay(dirty)
    }
  }

  override func viewDidMoveToWindow() {
    super.viewDidMoveToWindow()
    occlusionObserver?.cancel()
    guard let window else { return }
    occlusionObserver = Task { [weak self] in
      for await _ in NotificationCenter.default.notifications(
        named: NSWindow.didChangeOcclusionStateNotification, object: window)
      {
        guard let self, isVisible else { continue }
        needsDisplay = true
      }
    }
  }

  override func draw(_ dirtyRect: NSRect) {
    guard let context = NSGraphicsContext.current?.cgContext else { return }
    let appearance = Appearance(NSAppearance.currentDrawing())

    for core in 0..<FFI.coreCount {
      let bar = Style.bar(level: levels[core], appearance: appearance)
      context.setFillColor(bar.color)
      context.fill(Self.barRect(core, height: bar.height))
    }
  }

  private static func barRect(_ core: Int, height: CGFloat) -> CGRect {
    CGRect(
      x: Layout.inset + CGFloat(core) * (Layout.barWidth + Layout.barGap),
      y: Layout.inset,
      width: Layout.barWidth,
      height: height)
  }
}

import AppKit

final class Widget: NSView {
  private let rootLayer: CALayer
  private let barLayers: [CALayer]
  private var appearanceChangeHandler: (Appearance) -> Void = { _ in }

  init(parent: NSView) {
    barLayers = (0..<CPU.coreCount).map(Self.makeBarLayer)

    rootLayer = CALayer()
    rootLayer.borderWidth = Layout.borderWidth
    rootLayer.cornerRadius = Layout.cornerRadius
    rootLayer.sublayers = barLayers

    super.init(
      frame: NSRect(
        x: 0,
        y: 0,
        width: Layout.width,
        height: Layout.height
      )
    )
    layer = rootLayer
    wantsLayer = true

    parent.addSubview(self)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  private static func makeBarLayer(_ index: Int) -> CALayer {
    let layer = CALayer()
    layer.frame = CGRect(
      x: Layout.inset + CGFloat(index) * (Layout.barWidth + Layout.barGap),
      y: Layout.inset,
      width: Layout.barWidth,
      height: 0)
    return layer
  }

  func onAppearanceChange(_ handler: @escaping (Appearance) -> Void) {
    appearanceChangeHandler = handler
    handler(Appearance(effectiveAppearance))
  }

  override func viewDidChangeEffectiveAppearance() {
    super.viewDidChangeEffectiveAppearance()
    appearanceChangeHandler(Appearance(effectiveAppearance))
  }

  func rerender(_ diff: State.Diff) {
    withoutAnimation {
      if let borderColor = diff.borderColor {
        rootLayer.borderColor = borderColor
      }
      for barDiff in diff.bars {
        rerenderBar(barDiff)
      }
    }
    superview?.needsDisplay = true
  }

  private func withoutAnimation(_ changes: () -> Void) {
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    changes()
    CATransaction.commit()
  }

  private func rerenderBar(_ barDiff: State.BarDiff) {
    let layer = barLayers[barDiff.index]
    layer.frame.size.height = barDiff.height
    layer.backgroundColor = barDiff.color
  }
}

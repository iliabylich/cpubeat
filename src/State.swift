import CoreGraphics

@MainActor
final class State {
  struct BarDiff {
    let index: Int
    let color: CGColor
    let height: CGFloat
  }

  struct Diff {
    let borderColor: CGColor?
    let bars: [BarDiff]
  }

  private var usage: [Double]
  private var appearance: Appearance
  private var bars: [Style.Bar?]
  private var changeHandler: (Diff) -> Void = { _ in }

  init() {
    usage = Array(repeating: 0, count: CPU.coreCount)
    appearance = .light
    bars = Array(repeating: nil, count: CPU.coreCount)
  }

  func onChange(_ handler: @escaping (Diff) -> Void) {
    changeHandler = handler
  }

  func update(_ newUsage: [Double]) {
    usage = newUsage
    let diffs = updateBars()
    if !diffs.isEmpty {
      changeHandler(Diff(borderColor: nil, bars: diffs))
    }
  }

  func update(_ newAppearance: Appearance) {
    appearance = newAppearance
    changeHandler(
      Diff(
        borderColor: Style.borderColor.resolved(for: appearance),
        bars: updateBars()))
  }

  private func updateBars() -> [BarDiff] {
    precondition(usage.count == bars.count, "bar count changed between updates")
    var diffs: [BarDiff] = []
    for index in usage.indices {
      let next = Style.bar(usage: usage[index], appearance: appearance)
      guard bars[index] != next else { continue }
      bars[index] = next
      diffs.append(BarDiff(index: index, color: next.color, height: next.height))
    }
    return diffs
  }
}

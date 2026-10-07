struct CoreUsageLevel: Equatable {
  let value: Int

  init(_ value: Int) {
    precondition((0..<Style.barCount).contains(value), "core usage level out of range: \(value)")
    self.value = value
  }

  init(_ usage: CoreUsage) {
    self.init(min(Style.barCount - 1, Int(usage.value * Double(Style.barCount))))
  }
}

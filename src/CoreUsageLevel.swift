struct CoreUsageLevel: Equatable {
  private static let minValue = 0
  private static let maxValue = Style.barCount - 1
  private static let validRange = minValue...maxValue
  static let zero = Self(minValue)

  let value: Int

  init(_ value: Int) {
    precondition(Self.validRange.contains(value), "core usage level out of range: \(value)")
    self.value = value
  }

  init(_ usage: NormalizedCoreUsage) {
    self.init(
      min(
        Self.maxValue,
        Self.minValue + Int(usage.value * Double(Self.maxValue - Self.minValue + 1))
      )
    )
  }
}

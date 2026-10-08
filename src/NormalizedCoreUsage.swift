struct NormalizedCoreUsage {
  private static let minValue = 0.0
  private static let maxValue = 1.0
  private static let validRange = minValue...maxValue
  static let zero = Self(minValue)

  let value: Double

  init(_ value: Double) {
    precondition(Self.validRange.contains(value), "core usage out of range: \(value)")
    self.value = value
  }
}

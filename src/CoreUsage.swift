struct CoreUsage {
  let value: Double

  init(_ value: Double) {
    precondition((0...1).contains(value), "core usage out of range: \(value)")
    self.value = value
  }
}

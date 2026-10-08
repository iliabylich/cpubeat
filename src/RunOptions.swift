enum RunOptions {
  case live
  case synthetic(syscall: Bool, ui: Bool)

  static func parse(_ string: String?) -> Self {
    guard let string, !string.isEmpty else { return .live }

    func fail(_ reason: String) -> Never {
      fatalError("invalid run options \"\(string)\": \(reason)")
    }

    var syscall = false
    var ui = false
    for pair in string.split(separator: ",", omittingEmptySubsequences: false) {
      let parts = pair.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
      guard parts.count == 2 else { fail("expected key=value, got \"\(pair)\"") }
      let (key, value) = (parts[0], parts[1])
      let enabled =
        switch value {
        case "0": false
        case "1": true
        default: fail("expected 0 or 1 for \"\(key)\", got \"\(value)\"")
        }
      switch key {
      case "syscall": syscall = enabled
      case "ui": ui = enabled
      default: fail("unknown key \"\(key)\"")
      }
    }
    return .synthetic(syscall: syscall, ui: ui)
  }

  func sampler() -> any Sampler {
    switch self {
    case .live:
      LiveSampler()
    case .synthetic(let syscall, let ui):
      SyntheticSampler(
        syscall: syscall ? Self.liveSyscall() : { _ in },
        data: ui ? .rotatingSequence() : .zeroes)
    }
  }

  private static func liveSyscall() -> (inout [NormalizedCoreUsage]) -> Void {
    var live = LiveSampler()
    return { live.read(into: &$0) }
  }
}

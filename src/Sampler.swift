import Foundation

protocol Sampler {
  mutating func read(into usage: inout [CoreUsage])
}

enum SyntheticData {
  case zeroes
  case rotatingSequence(offset: Int = 0)

  mutating func fill(_ usage: inout [CoreUsage]) {
    switch self {
    case .zeroes:
      for core in usage.indices {
        usage[core] = CoreUsage(0)
      }
    case .rotatingSequence(let offset):
      let next = (offset + 1) % usage.count
      for core in usage.indices {
        usage[core] = CoreUsage(Double((core + next) % usage.count) / Double(usage.count - 1))
      }
      self = .rotatingSequence(offset: next)
    }
  }
}

struct SyntheticSampler: Sampler {
  private let syscall: (inout [CoreUsage]) -> Void
  private var data: SyntheticData

  init(syscall: @escaping (inout [CoreUsage]) -> Void, data: SyntheticData) {
    self.syscall = syscall
    self.data = data
  }

  mutating func read(into usage: inout [CoreUsage]) {
    syscall(&usage)
    data.fill(&usage)
  }
}

struct LiveSampler: Sampler {
  private struct DataPoint {
    let busy: UInt32
    let idle: UInt32

    init(busy: UInt32, idle: UInt32) {
      self.busy = busy
      self.idle = idle
    }

    init(_ ticks: CPUTicks) {
      self.init(busy: ticks.user &+ ticks.system &+ ticks.nice, idle: ticks.idle)
    }

    var usage: CoreUsage {
      let busy = Double(busy)
      let total = busy + Double(idle)
      guard total > 0 else { return CoreUsage(0) }
      return CoreUsage(busy / total)
    }

    static func - (next: DataPoint, previous: DataPoint) -> DataPoint {
      DataPoint(busy: next.busy &- previous.busy, idle: next.idle &- previous.idle)
    }
  }

  private var previous: [DataPoint]

  init() {
    previous = CPU.withHostProcessorInfo { ticks in ticks.map(DataPoint.init) }
    precondition(previous.count == CPU.coreCount, "unexpected core layout")
  }

  mutating func read(into usage: inout [CoreUsage]) {
    CPU.withHostProcessorInfo { ticks in
      precondition(ticks.count == previous.count, "CPU count changed at runtime")
      for core in ticks.indices {
        let next = DataPoint(ticks[core])
        usage[core] = (next - previous[core]).usage
        previous[core] = next
      }
    }
  }
}

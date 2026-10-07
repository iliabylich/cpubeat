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

  private static let host = mach_host_self()
  private var previous: [DataPoint]

  init() {
    previous = Self.withHostProcessorInfo { ticks in ticks.map(DataPoint.init) }
    precondition(previous.count == CPU.coreCount, "unexpected core layout")
  }

  mutating func read(into usage: inout [CoreUsage]) {
    Self.withHostProcessorInfo { ticks in
      precondition(ticks.count == previous.count, "CPU count changed at runtime")
      for core in ticks.indices {
        let next = DataPoint(ticks[core])
        usage[core] = (next - previous[core]).usage
        previous[core] = next
      }
    }
  }

  private static func withHostProcessorInfo<Result>(
    _ body: (UnsafeBufferPointer<CPUTicks>) -> Result
  ) -> Result {
    var cpuCount: natural_t = 0
    var info: processor_info_array_t?
    var infoCount: mach_msg_type_number_t = 0

    let result = host_processor_info(
      host, PROCESSOR_CPU_LOAD_INFO, &cpuCount, &info, &infoCount)
    guard result == KERN_SUCCESS, let info else {
      fatalError("host_processor_info failed: \(result)")
    }

    let infoByteCount = Int(infoCount) * MemoryLayout<integer_t>.stride
    let cpuTicksByteCount = Int(cpuCount) * MemoryLayout<CPUTicks>.stride

    defer {
      vm_deallocate(
        mach_task_self_, vm_address_t(bitPattern: info),
        vm_size_t(infoByteCount))
    }

    precondition(infoByteCount == cpuTicksByteCount, "unexpected processor info size")

    let ticks = UnsafeRawBufferPointer(start: info, count: infoByteCount)
      .bindMemory(to: CPUTicks.self)
    return body(UnsafeBufferPointer(rebasing: ticks.dropFirst(CPU.efficiencyCoreCount)))
  }
}

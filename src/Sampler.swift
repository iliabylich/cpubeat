import Foundation

protocol Sampler {
  mutating func read() -> [Double]
}

struct DummySampler: Sampler {
  private var usage = (0..<CPU.coreCount).map { core in
    Double(core) / Double(CPU.coreCount - 1)
  }

  mutating func read() -> [Double] {
    usage.append(usage.removeFirst())
    return usage
  }
}

struct EmptySampler: Sampler {
  func read() -> [Double] {
    Array(repeating: 0, count: CPU.coreCount)
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

    var usage: Double {
      let busy = Double(busy)
      let total = busy + Double(idle)
      guard total > 0 else { return 0 }
      return busy / total
    }

    static func - (next: DataPoint, previous: DataPoint) -> DataPoint {
      DataPoint(busy: next.busy &- previous.busy, idle: next.idle &- previous.idle)
    }
  }

  private static let host = mach_host_self()
  private var previous: [DataPoint]

  init() {
    previous = Self.hostProcessorInfo()
    precondition(previous.count == CPU.coreCount, "unexpected core layout")
  }

  mutating func read() -> [Double] {
    let next = Self.hostProcessorInfo()
    precondition(next.count == previous.count, "CPU count changed at runtime")
    let usage = zip(next, previous).map { next, previous in (next - previous).usage }
    previous = next
    return usage
  }

  private static func hostProcessorInfo() -> [DataPoint] {
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

    return UnsafeRawBufferPointer(start: info, count: infoByteCount)
      .bindMemory(to: CPUTicks.self)
      .dropFirst(CPU.efficiencyCoreCount)
      .map(DataPoint.init)
  }
}

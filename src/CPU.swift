import Foundation

enum CPU {
  static let efficiencyCoreCount = sysctlInt("hw.perflevel1.logicalcpu")
  static let performanceCoreCount = sysctlInt("hw.perflevel0.logicalcpu")
  static let coreCount = performanceCoreCount
  static let cores = 0..<coreCount
  private static let host = mach_host_self()

  static func withHostProcessorInfo<Result>(_ body: (UnsafeBufferPointer<CPUTicks>) -> Result)
    -> Result
  {
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
        mach_task_self_,
        vm_address_t(bitPattern: info),
        vm_size_t(infoByteCount)
      )
    }

    precondition(infoByteCount == cpuTicksByteCount, "unexpected processor info size")

    let ticks = UnsafeRawBufferPointer(start: info, count: infoByteCount)
      .bindMemory(to: CPUTicks.self)
    return body(UnsafeBufferPointer(rebasing: ticks.dropFirst(efficiencyCoreCount)))
  }

  private static func sysctlInt(_ name: String) -> Int {
    var value: Int32 = 0
    var size = MemoryLayout<Int32>.size
    guard sysctlbyname(name, &value, &size, nil, 0) == 0 else {
      fatalError("sysctlbyname(\(name)) failed: errno \(errno)")
    }
    return Int(value)
  }
}

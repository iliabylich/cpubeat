enum FFI {
  static let coreCount: Int = Int(cpubeat_core_count())

  struct CpuBeat: ~Copyable {
    private let pointer: OpaquePointer

    init() {
      pointer = cpubeat_new()
    }

    func read(into usage: inout [Double]) {
      let output = cpubeat_read(pointer)
      precondition(output.len == usage.count, "core count changed at runtime")
      for core in 0..<output.len {
        usage[core] = output.ptr[core]
      }
    }
  }
}

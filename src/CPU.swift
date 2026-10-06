import Foundation

enum CPU {
  static let efficiencyCoreCount = sysctlInt("hw.perflevel1.logicalcpu")
  static let performanceCoreCount = sysctlInt("hw.perflevel0.logicalcpu")
  static let coreCount = performanceCoreCount

  private static func sysctlInt(_ name: String) -> Int {
    var value: Int32 = 0
    var size = MemoryLayout<Int32>.size
    guard sysctlbyname(name, &value, &size, nil, 0) == 0 else {
      fatalError("sysctlbyname(\(name)) failed: errno \(errno)")
    }
    return Int(value)
  }
}

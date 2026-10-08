import Foundation

enum Logger {
  private static let isEnabled = isatty(STDOUT_FILENO) != 0

  static func log(_ usage: [NormalizedCoreUsage]) {
    if isEnabled {
      print("[" + usage.map { String(format: "%.2f", $0.value) }.joined(separator: ", ") + "]")
    }
  }
}

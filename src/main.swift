import AppKit

let app = NSApplication.shared

let options = RunOptions.parse(ProcessInfo.processInfo.environment["CPUBEAT_SYNTHETIC"])

let statusItem = StatusItem()
let widget = Widget(parent: statusItem.button)

let thread = Thread { @Sendable [options] in
  var sampler = options.sampler()
  var usage = [NormalizedCoreUsage](repeating: .zero, count: CPU.coreCount)
  var levels = [CoreUsageLevel](repeating: .zero, count: CPU.coreCount)
  SleepBasedTimer(interval: .seconds(1)).run {
    sampler.read(into: &usage)
    Logger.log(usage)
    let newLevels = usage.lazy.map(CoreUsageLevel.init)
    guard !newLevels.elementsEqual(levels) else { return }
    levels = Array(newLevels)
    DispatchQueue.main.async { [levels] in
      MainActor.assumeIsolated { widget.update(levels) }
    }
  }
}
thread.qualityOfService = .utility
thread.start()

app.run()

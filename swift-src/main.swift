import AppKit

let app = NSApplication.shared
app.setActivationPolicy(.prohibited)

let widget = Widget()
let floatingWindow = FloatingWindow(content: widget)
floatingWindow.refresh()

let thread = Thread {
  let cpubeat = FFI.CpuBeat()
  var usage = [Double](repeating: 0, count: FFI.coreCount)
  var levels = [UInt8](repeating: 0, count: FFI.coreCount)
  while true {
    cpubeat.read(into: &usage)
    let newLevels = usage.lazy.map(Style.level)
    guard !newLevels.elementsEqual(levels) else { continue }
    levels = Array(newLevels)
    DispatchQueue.main.async { [levels] in
      MainActor.assumeIsolated { widget.update(levels) }
    }
  }
}
thread.qualityOfService = .utility
thread.start()

app.run()

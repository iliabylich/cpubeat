import AppKit

let app = NSApplication.shared

var sampler: any Sampler =
  switch ProcessInfo.processInfo.environment["CPUBEAT_SAMPLER"] {
  case nil: LiveSampler()
  case "dummy": DummySampler()
  case "empty": EmptySampler()
  case let other?: fatalError("unknown CPUBEAT_SAMPLER: \(other)")
  }

let statusItem = StatusItem()
let widget = Widget(parent: statusItem.button)
let state = State()

state.onChange(widget.rerender)
widget.onAppearanceChange(state.update)

Task {
  while !Task.isCancelled {
    try? await Task.sleep(for: .seconds(1), tolerance: .milliseconds(250))
    let usage = sampler.read()
    Logger.log(usage)
    state.update(usage)
  }
}

app.run()

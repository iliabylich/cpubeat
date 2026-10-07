import Darwin

struct SleepBasedTimer {
  private let interval: UInt64

  init(interval: Duration) {
    var timebase = mach_timebase_info_data_t()
    mach_timebase_info(&timebase)
    let (seconds, attoseconds) = interval.components
    let nanoseconds = UInt64(seconds) * 1_000_000_000 + UInt64(attoseconds / 1_000_000_000)
    self.interval = nanoseconds * UInt64(timebase.denom) / UInt64(timebase.numer)
  }

  func run(_ tick: () -> Void) -> Never {
    var deadline = mach_absolute_time()
    while true {
      deadline += interval
      mach_wait_until(deadline)
      tick()
    }
  }
}

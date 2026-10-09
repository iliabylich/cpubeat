use core::time::Duration;
use std::time::Instant;

pub(crate) struct Timer {
    interval: Duration,
    deadline: Instant,
}

impl Timer {
    pub(crate) fn new(interval: Duration) -> Self {
        Self {
            interval,
            deadline: Instant::now(),
        }
    }

    pub(crate) fn tick(&mut self) {
        self.deadline = self
            .deadline
            .checked_add(self.interval)
            .expect("time nor longer fits into Instant");
        std::thread::sleep(self.deadline.saturating_duration_since(Instant::now()));
    }
}

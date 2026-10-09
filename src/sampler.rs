use libc::host_t;
use mach2::mach_init::mach_host_self;

use crate::host_processor_info::{HostProcessorInfo, HostProcessorInfoItem};

pub(crate) trait Sampler {
    fn read(&mut self, buf: &mut [f64]);
}

enum SyntheticDataGenerator {
    Zeroes,
    Alternating { flipped: bool },
}

impl SyntheticDataGenerator {
    fn fill(&mut self, buf: &mut [f64]) {
        match self {
            Self::Zeroes => buf.fill(0.0),
            Self::Alternating { flipped } => {
                let mut value = if *flipped { 1.0 } else { 0.0 };
                for usage in buf.iter_mut() {
                    *usage = value;
                    value = 1.0 - value;
                }
                *flipped = !*flipped;
            }
        }
    }
}

pub(crate) struct SyntheticSampler {
    do_syscall: bool,
    data_generator: SyntheticDataGenerator,
    host: host_t,
}

impl SyntheticSampler {
    pub(crate) fn new(do_syscall: bool, do_full_ui_update: bool) -> Self {
        let data_generator = if do_full_ui_update {
            SyntheticDataGenerator::Alternating { flipped: false }
        } else {
            SyntheticDataGenerator::Zeroes
        };
        let host = unsafe { mach_host_self() };

        Self {
            do_syscall,
            data_generator,
            host,
        }
    }
}

impl Sampler for SyntheticSampler {
    fn read(&mut self, buf: &mut [f64]) {
        if self.do_syscall {
            let _ = HostProcessorInfo::new(self.host);
        }
        self.data_generator.fill(buf);
    }
}

pub(crate) struct LiveSampler {
    host: host_t,
    prev: Vec<HostProcessorInfoItem>,
}

impl LiveSampler {
    pub(crate) fn new() -> Self {
        let host = unsafe { mach_host_self() };
        let prev = HostProcessorInfo::new(host).iter().collect::<Vec<_>>();
        Self { host, prev }
    }
}

impl Sampler for LiveSampler {
    fn read(&mut self, buf: &mut [f64]) {
        let host_processor_info = HostProcessorInfo::new(self.host);
        let len = host_processor_info.iter().len();

        assert_eq!(self.prev.len(), len);
        assert_eq!(buf.len(), len);

        for ((prev, next), delta) in self
            .prev
            .iter_mut()
            .zip(host_processor_info.iter())
            .zip(buf)
        {
            *delta = next.delta(*prev);
            *prev = next;
        }
    }
}

#[cfg(test)]
mod tests {
    use super::SyntheticDataGenerator;

    #[test]
    fn test_alternating() {
        let mut buf = [0.0f64; 4];
        let mut generator = SyntheticDataGenerator::Alternating { flipped: false };

        generator.fill(&mut buf);
        assert_eq!(buf, [0.0, 1.0, 0.0, 1.0]);

        generator.fill(&mut buf);
        assert_eq!(buf, [1.0, 0.0, 1.0, 0.0]);

        generator.fill(&mut buf);
        assert_eq!(buf, [0.0, 1.0, 0.0, 1.0]);
    }
}

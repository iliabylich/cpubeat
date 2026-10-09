use crate::{
    cpu_core_count::CpuCoreCount, logger::Logger, run_options::RunOptions, sampler::Sampler,
    timer::Timer,
};

pub struct CpuBeat {
    core_count: CpuCoreCount,
    logger: Logger,
    sampler: Box<dyn Sampler>,
    buf: Vec<f64>,
    timer: Timer,
}

impl CpuBeat {
    pub(crate) fn new() -> Self {
        let core_count = CpuCoreCount::new();
        let logger = Logger::new();
        let run_options = RunOptions::parse(std::env::var("CPUBEAT_SYNTHETIC").ok().as_deref());
        let sampler = run_options.build_sampler();
        let buf = vec![0.0; usize::from(core_count.total)];
        let timer = Timer::new(core::time::Duration::from_secs(1));

        Self {
            core_count,
            logger,
            sampler,
            buf,
            timer,
        }
    }

    pub(crate) fn read(&mut self) -> &[f64] {
        self.timer.tick();
        self.sampler.read(&mut self.buf);
        let data = self
            .buf
            .get(usize::from(self.core_count.efficiency)..)
            .expect("bug: wrong output buffer size");
        let _ = self.logger.log(data);
        data
    }
}

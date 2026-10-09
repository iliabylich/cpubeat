#![warn(
    trivial_casts,
    trivial_numeric_casts,
    unused_qualifications,
    deprecated_in_future,
    unused_lifetimes,
    clippy::unwrap_used,
    clippy::indexing_slicing,
    clippy::arithmetic_side_effects,
    clippy::pedantic,
    clippy::nursery,
    clippy::std_instead_of_alloc,
    clippy::std_instead_of_core
)]
#![expect(clippy::redundant_pub_crate)]
#![allow(clippy::option_if_let_else)]

mod cpu_core_count;
mod cpubeat;
mod host_processor_info;
mod logger;
mod run_options;
mod sampler;
mod timer;

use cpu_core_count::CpuCoreCount;
use cpubeat::CpuBeat;

#[unsafe(no_mangle)]
pub extern "C" fn cpubeat_new() -> Box<CpuBeat> {
    Box::new(CpuBeat::new())
}

#[repr(C)]
pub struct CpuBeatOutput {
    pub len: usize,
    pub ptr: *const f64,
}

#[unsafe(no_mangle)]
pub extern "C" fn cpubeat_read(cpubeat: &mut CpuBeat) -> CpuBeatOutput {
    let data = cpubeat.read();
    CpuBeatOutput {
        len: data.len(),
        ptr: data.as_ptr(),
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn cpubeat_core_count() -> u8 {
    CpuCoreCount::new().performance
}

use core::ffi::CStr;
use libc::sysctlbyname;

#[derive(Debug)]
pub(crate) struct CpuCoreCount {
    pub(crate) performance: u8,
    pub(crate) efficiency: u8,
    pub(crate) total: u8,
}

impl CpuCoreCount {
    pub(crate) fn new() -> Self {
        let performance = sysctl(c"hw.perflevel0.logicalcpu");
        let efficiency = sysctl(c"hw.perflevel1.logicalcpu");
        let total = performance
            .checked_add(efficiency)
            .expect("too many cores, max 255");

        Self {
            performance,
            efficiency,
            total,
        }
    }
}

fn sysctl(name: &CStr) -> u8 {
    let mut value = 0u32;
    let mut value_size: usize = size_of::<u32>();

    let res = unsafe {
        sysctlbyname(
            name.as_ptr(),
            (&raw mut value).cast::<core::ffi::c_void>(),
            &raw mut value_size,
            core::ptr::null_mut(),
            0,
        )
    };

    assert_eq!(res, 0, "{}", std::io::Error::last_os_error());
    assert_eq!(value_size, size_of::<u32>());

    u8::try_from(value).expect("too many cores, max 255")
}

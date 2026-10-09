use libc::{PROCESSOR_CPU_LOAD_INFO, host_processor_info, processor_info_array_t, vm_deallocate};
use mach2::{kern_return::KERN_SUCCESS, port::mach_port_t, traps::mach_task_self};

#[derive(Debug)]
pub(crate) struct HostProcessorInfo {
    processor_info: processor_info_array_t,
    processor_info_count: usize,
}

const _: () = assert!(
    size_of::<core::ffi::c_uint>() == size_of::<u32>(),
    "uint != u32"
);

impl HostProcessorInfo {
    pub(crate) fn new(host: mach_port_t) -> Self {
        let mut processor_count: u32 = 0;
        let mut processor_info: processor_info_array_t = core::ptr::null_mut();
        let mut processor_info_count: u32 = 0;

        let res = unsafe {
            host_processor_info(
                host,
                PROCESSOR_CPU_LOAD_INFO,
                &raw mut processor_count,
                &raw mut processor_info,
                &raw mut processor_info_count,
            )
        };
        assert_eq!(res, KERN_SUCCESS);
        assert!(!processor_info.is_null());

        let (processor_count, processor_info_count) = usize::try_from(processor_count)
            .ok()
            .zip(usize::try_from(processor_info_count).ok())
            .expect("u32 doesn't fit into usize");

        assert_eq!(
            Some(processor_info_count),
            processor_count.checked_mul(CPU_STATE_MAX)
        );

        Self {
            processor_info,
            processor_info_count,
        }
    }

    pub(crate) fn iter(&self) -> HostProcessorInfoIterator<'_> {
        let data = self.processor_info.cast_const();
        let len = self.processor_info_count;
        let data = unsafe { core::slice::from_raw_parts(data, len) };
        let (chunks, rest) = data.as_chunks::<CPU_STATE_MAX>();
        assert!(
            rest.is_empty(),
            "HostProcessorInfo data isn't a multiple of CPU_STATE_MAX"
        );

        HostProcessorInfoIterator {
            chunks: chunks.iter(),
        }
    }
}

impl Drop for HostProcessorInfo {
    fn drop(&mut self) {
        let address = self.processor_info.addr();
        let Some(size) = self.processor_info_count.checked_mul(size_of::<i32>()) else {
            if std::thread::panicking() {
                return;
            }
            panic!("malformed HostProcessorInfo.processor_info_count");
        };

        let res = unsafe { vm_deallocate(mach_task_self(), address, size) };
        if !std::thread::panicking() {
            assert_eq!(res, KERN_SUCCESS);
        }
    }
}

#[derive(Clone, Copy)]
pub(crate) struct HostProcessorInfoItem {
    pub(crate) busy: i32,
    pub(crate) idle: i32,
}

impl HostProcessorInfoItem {
    pub(crate) fn delta(self, prev: Self) -> f64 {
        let d_busy = f64::from(self.busy.wrapping_sub(prev.busy));
        let d_idle = f64::from(self.idle.wrapping_sub(prev.idle));
        let d_total = d_busy + d_idle;
        if d_total <= 0.0 {
            0.0
        } else {
            (d_busy / d_total).clamp(0.0, 1.0)
        }
    }
}

impl core::fmt::Debug for HostProcessorInfoItem {
    fn fmt(&self, f: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        write!(f, "(busy={}, idle={})", self.busy, self.idle)
    }
}

pub(crate) struct HostProcessorInfoIterator<'a> {
    chunks: core::slice::Iter<'a, [i32; CPU_STATE_MAX]>,
}

const CPU_STATE_USER: usize = libc::CPU_STATE_USER as usize;
const CPU_STATE_SYSTEM: usize = libc::CPU_STATE_SYSTEM as usize;
const CPU_STATE_IDLE: usize = libc::CPU_STATE_IDLE as usize;
const CPU_STATE_NICE: usize = libc::CPU_STATE_NICE as usize;
const CPU_STATE_MAX: usize = libc::CPU_STATE_MAX as usize;

impl Iterator for HostProcessorInfoIterator<'_> {
    type Item = HostProcessorInfoItem;

    fn next(&mut self) -> Option<Self::Item> {
        let chunk = self.chunks.next()?;

        let user = chunk[CPU_STATE_USER];
        let system = chunk[CPU_STATE_SYSTEM];
        let idle = chunk[CPU_STATE_IDLE];
        let nice = chunk[CPU_STATE_NICE];

        Some(HostProcessorInfoItem {
            busy: user.wrapping_add(system).wrapping_add(nice),
            idle,
        })
    }

    fn size_hint(&self) -> (usize, Option<usize>) {
        self.chunks.size_hint()
    }
}

impl ExactSizeIterator for HostProcessorInfoIterator<'_> {}

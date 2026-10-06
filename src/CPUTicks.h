#include <mach/machine.h>
#include <mach/processor_info.h>
#include <stddef.h>
#include <stdint.h>

typedef struct {
  uint32_t user;
  uint32_t system;
  uint32_t idle;
  uint32_t nice;
} CPUTicks;

_Static_assert(sizeof(CPUTicks) == sizeof(processor_cpu_load_info_data_t), "");
_Static_assert(offsetof(CPUTicks, user) == CPU_STATE_USER * sizeof(uint32_t), "");
_Static_assert(offsetof(CPUTicks, system) == CPU_STATE_SYSTEM * sizeof(uint32_t), "");
_Static_assert(offsetof(CPUTicks, idle) == CPU_STATE_IDLE * sizeof(uint32_t), "");
_Static_assert(offsetof(CPUTicks, nice) == CPU_STATE_NICE * sizeof(uint32_t), "");

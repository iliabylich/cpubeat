#include <stdarg.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>

typedef struct CpuBeat CpuBeat;

typedef struct {
  size_t len;
  const double *ptr;
} CpuBeatOutput;

CpuBeat *cpubeat_new(void);

CpuBeatOutput cpubeat_read(CpuBeat *cpubeat);

uint8_t cpubeat_core_count(void);

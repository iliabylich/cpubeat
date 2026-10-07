#include <fcntl.h>
#include <libproc.h>
#include <mach/mach_time.h>
#include <signal.h>
#include <spawn.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/resource.h>
#include <sys/wait.h>
#include <unistd.h>

#define MAX_SECONDS 600

extern char **environ;

static struct rusage_info_v6 sample(pid_t pid) {
  struct rusage_info_v6 info;
  if (proc_pid_rusage(pid, RUSAGE_INFO_V6, (rusage_info_t *)&info) != 0) {
    perror("proc_pid_rusage");
    kill(pid, SIGTERM);
    exit(1);
  }
  return info;
}

static int compare(const void *a, const void *b) {
  double x = *(const double *)a, y = *(const double *)b;
  return (x > y) - (x < y);
}

static void report(const char *name, double *values, int count, double scale,
                   int precision) {
  double sum = 0;
  for (int i = 0; i < count; i++) {
    sum += values[i];
  }
  qsort(values, count, sizeof(double), compare);
  double median = count % 2 ? values[count / 2]
                            : (values[count / 2 - 1] + values[count / 2]) / 2;
  printf("%-10s %11.*f %11.*f %11.*f %11.*f\n", name, precision,
         values[0] * scale, precision, median * scale, precision,
         sum / count * scale, precision, values[count - 1] * scale);
}

int main(int argc, char **argv) {
  if (argc < 3) {
    fprintf(stderr, "usage: %s seconds command...\n", argv[0]);
    return 1;
  }
  int seconds = atoi(argv[1]);
  int warmup = getenv("WARMUP") ? atoi(getenv("WARMUP")) : 5;
  if (seconds < 1 || seconds > MAX_SECONDS) {
    fprintf(stderr, "seconds must be in 1..%d\n", MAX_SECONDS);
    return 1;
  }

  posix_spawn_file_actions_t actions;
  posix_spawn_file_actions_init(&actions);
  posix_spawn_file_actions_addopen(&actions, STDOUT_FILENO, "/dev/null",
                                   O_WRONLY, 0);

  pid_t pid;
  if (posix_spawnp(&pid, argv[2], &actions, NULL, argv + 2, environ) != 0) {
    perror("posix_spawnp");
    return 1;
  }

  mach_timebase_info_data_t timebase;
  mach_timebase_info(&timebase);

  double cpu[MAX_SECONDS], instructions[MAX_SECONDS], wakeups[MAX_SECONDS];
  double energy[MAX_SECONDS], pcore_instructions[MAX_SECONDS];

  sleep(warmup);
  struct rusage_info_v6 previous = sample(pid);
  for (int i = 0; i < seconds; i++) {
    sleep(1);
    struct rusage_info_v6 next = sample(pid);
    uint64_t ticks = (next.ri_user_time - previous.ri_user_time) +
                     (next.ri_system_time - previous.ri_system_time);
    cpu[i] = (double)ticks * timebase.numer / timebase.denom / 1e3;
    instructions[i] = (double)(next.ri_instructions - previous.ri_instructions);
    wakeups[i] =
        (double)((next.ri_pkg_idle_wkups - previous.ri_pkg_idle_wkups) +
                 (next.ri_interrupt_wkups - previous.ri_interrupt_wkups));
    energy[i] = (double)(next.ri_energy_nj - previous.ri_energy_nj);
    pcore_instructions[i] =
        (double)(next.ri_pinstructions - previous.ri_pinstructions);
    previous = next;
  }

  if (waitpid(pid, NULL, WNOHANG) != 0) {
    fprintf(stderr, "process exited during measurement\n");
    return 1;
  }
  kill(pid, SIGTERM);
  waitpid(pid, NULL, 0);

  printf("%-10s %11s %11s %11s %11s\n", "per second", "min", "median", "mean",
         "max");
  report("cpu %", cpu, seconds, 1e-4, 4);
  report("cpu us", cpu, seconds, 1, 1);
  report("instr", instructions, seconds, 1, 0);
  report("wakeups", wakeups, seconds, 1, 0);
  report("energy uJ", energy, seconds, 1e-3, 1);
  report("p-instr", pcore_instructions, seconds, 1, 0);
  return 0;
}

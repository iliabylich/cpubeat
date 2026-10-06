#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

static void *spin(void *arg) {
  (void)arg;
  volatile unsigned long n = 0;
  for (;;) {
    n++;
  }
  return NULL;
}

int main(int argc, char **argv) {
  int threads = argc > 1 ? atoi(argv[1]) : 8;
  int seconds = argc > 2 ? atoi(argv[2]) : 0;

  for (int i = 0; i < threads; i++) {
    pthread_t thread;
    pthread_create(&thread, NULL, spin, NULL);
  }

  if (seconds > 0) {
    printf("burning %d threads for %ds\n", threads, seconds);
    sleep(seconds);
  } else {
    printf("burning %d threads, Ctrl-C to stop\n", threads);
    pause();
  }
  return 0;
}

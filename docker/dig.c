#include <stdlib.h>
#include <stdio.h>
#include <errno.h>
#include <time.h>
#include <ares.h>

inline struct timespec diff_timespec(const struct timespec time1,
				     const struct timespec time0)
{
	struct timespec diff = {.tv_sec = time1.tv_sec - time0.tv_sec, .tv_nsec = time1.tv_nsec - time0.tv_nsec};
	if (diff.tv_nsec < 0)
	{
		diff.tv_nsec += 1000000000;
		diff.tv_sec--;
	}
	return diff;
}

void callback(void *arg, int status, int timeouts, struct hostent *hostent)
{
	puts("in resolv");
	puts(ares_strerror(status));
}

int main(int argc, char **argv)
{
	int nfds, count;
	fd_set readers, writers;
	struct timeval tv, *tvp;

	ares_library_init(ARES_LIB_INIT_NONE);
	ares_channel channleptr;
	ares_init(&channleptr);
	char domain[256];
	int ret;
	long msecs = atol(argv[1]);
	struct timespec sleep_for, sleeped_for, exp_start, exp_end, exp_duration, start_sleep, stop_sleep, delta;
	struct timespec interval = {
	    .tv_sec = msecs / 1000,
	    .tv_nsec = (msecs % 1000) * 1000000};
	sleep_for = interval;
	clock_gettime(CLOCK_REALTIME, &exp_start);
	while (fgets(domain, 256, stdin) != NULL)
	{
		ares_gethostbyname(channleptr, domain, AF_INET, callback, NULL);
		do
		{
			ret = nanosleep(&sleep_for, &sleep_for);
		} while (ret && errno == EINTR);
		clock_gettime(CLOCK_REALTIME, &stop_sleep);
		sleeped_for = diff_timespec(stop_sleep, start_sleep);
		delta = diff_timespec(sleeped_for, interval);
		sleep_for = diff_timespec(sleeped_for, delta);
	}
	ares_destroy(channleptr);
	ares_library_cleanup();
}
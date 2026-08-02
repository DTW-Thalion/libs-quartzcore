/* qc_clock_probe.m -- what does CACurrentMediaTime() actually measure?
 *
 * Questions:
 *  1. Is it the wall clock (seconds since 1970) or a time since boot?
 *  2. Does it ever go backwards over a tight loop?
 *  3. Does it advance by the elapsed interval over a known sleep, i.e. are
 *     the units really seconds?
 *  4. Is mach_absolute_time() / 1e9 the same thing, or does the timebase
 *     matter on this machine?
 *  5. What is its granularity?
 */

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <mach/mach_time.h>
#include <time.h>

int main(int argc, char **argv)
{
  @autoreleasepool
    {
      printf("== CACurrentMediaTime ground truth ==\n");

      double media = CACurrentMediaTime();
      double wall = [[NSDate date] timeIntervalSince1970];
      double uptime = [[NSProcessInfo processInfo] systemUptime];

      printf("CACurrentMediaTime()          = %.6f\n", media);
      printf("timeIntervalSince1970         = %.6f\n", wall);
      printf("NSProcessInfo systemUptime    = %.6f\n", uptime);
      printf("wall - media                  = %.6f\n", wall - media);
      printf("media - systemUptime          = %.9f\n", media - uptime);
      printf("media is wall clock?          = %s\n",
             (fabs(media - wall) < 1.0) ? "YES" : "no");
      printf("media is systemUptime?        = %s\n",
             (fabs(media - uptime) < 0.01) ? "YES" : "no");

      /* 2. monotonic over a tight loop */
      {
        int i, backwards = 0;
        double prev = CACurrentMediaTime();
        double now;
        for (i = 0; i < 200000; i++)
          {
            now = CACurrentMediaTime();
            if (now < prev)
              backwards++;
            prev = now;
          }
        printf("backwards steps in 200000 samples = %d\n", backwards);
      }

      /* 3. does it advance by the elapsed interval? */
      {
        double t0 = CACurrentMediaTime();
        struct timespec ts;
        ts.tv_sec = 0;
        ts.tv_nsec = 250 * 1000 * 1000;
        nanosleep(&ts, NULL);
        double t1 = CACurrentMediaTime();
        printf("delta over a 0.25s sleep      = %.6f\n", t1 - t0);
      }

      /* 4. the mach timebase on this machine */
      {
        mach_timebase_info_data_t tb;
        mach_timebase_info(&tb);
        uint64_t ticks = mach_absolute_time();
        double naive = ticks / (1000 * 1000 * 1000.);
        double scaled = ((double)ticks * tb.numer / tb.denom)
                          / (1000 * 1000 * 1000.);
        printf("mach timebase numer/denom     = %u/%u\n", tb.numer, tb.denom);
        printf("mach_absolute_time()/1e9      = %.6f\n", naive);
        printf("timebase-scaled to seconds    = %.6f\n", scaled);
        printf("CACurrentMediaTime() again    = %.6f\n", CACurrentMediaTime());
        printf("naive matches media?          = %s\n",
               (fabs(naive - CACurrentMediaTime()) < 1.0) ? "YES" : "no");
        printf("scaled matches media?         = %s\n",
               (fabs(scaled - CACurrentMediaTime()) < 1.0) ? "YES" : "no");
      }

      /* 5. granularity: how long until the value changes at all */
      {
        double t0 = CACurrentMediaTime();
        double t1 = t0;
        int spins = 0;
        while (t1 == t0 && spins < 100000000)
          {
            t1 = CACurrentMediaTime();
            spins++;
          }
        printf("spins until the value changed = %d, step = %.9f\n",
               spins, t1 - t0);
      }

      /* 6. is it affected by the process being busy vs idle -- i.e. is it a
       * CPU-time clock rather than an elapsed-time one? */
      {
        double t0 = CACurrentMediaTime();
        volatile double acc = 0;
        long i;
        for (i = 0; i < 20000000; i++)
          acc += i;
        double t1 = CACurrentMediaTime();
        struct timespec ts;
        ts.tv_sec = 0;
        ts.tv_nsec = 100 * 1000 * 1000;
        double t2 = CACurrentMediaTime();
        nanosleep(&ts, NULL);
        double t3 = CACurrentMediaTime();
        printf("busy loop delta               = %.6f\n", t1 - t0);
        printf("idle 0.1s delta               = %.6f (counts idle time = %s)\n",
               t3 - t2, ((t3 - t2) > 0.09) ? "YES" : "no");
      }
    }
  return 0;
}

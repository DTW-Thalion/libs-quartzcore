/* Probe +[CATransaction flush], +lock and +unlock against Apple.

   The recursion below is safe: the lock is documented as recursive.

   Run on a macOS runner:
     clang -fobjc-arc -framework QuartzCore -framework CoreGraphics \
       -framework Foundation Tests/oracle/qc_flushlock_probe.m -o qc_flushlock_probe
*/

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

int main(int argc, char **argv)
{
  @autoreleasepool
    {
      printf("=== flush and the implicit transaction ===\n");
      {
        [CATransaction setAnimationDuration: 5.0];
        printf("%-46s %g\n", "duration set on the implicit one",
               (double)[CATransaction animationDuration]);
        [CATransaction flush];
        printf("%-46s %g\n", "and after flushing",
               (double)[CATransaction animationDuration]);
      }

      printf("\n=== flush inside an explicit transaction ===\n");
      {
        [CATransaction begin];
        [CATransaction setAnimationDuration: 7.0];
        [CATransaction flush];
        printf("%-46s %g\n", "the explicit one during a flush",
               (double)[CATransaction animationDuration]);
        [CATransaction commit];
        printf("%-46s %g\n", "and after it commits",
               (double)[CATransaction animationDuration]);
      }

      printf("\n=== flush and a completion block ===\n");
      {
        __block int ran = 0;

        [CATransaction setCompletionBlock: ^{ ran++; }];
        printf("%-46s %d\n", "before flushing", ran);
        [CATransaction flush];
        printf("%-46s %d\n", "right after flushing", ran);
        [[NSRunLoop currentRunLoop] runUntilDate:
          [NSDate dateWithTimeIntervalSinceNow: 0.3]];
        printf("%-46s %d\n", "after a run-loop turn", ran);
      }

      printf("\n=== flush with nothing outstanding ===\n");
      {
        [CATransaction flush];
        [CATransaction flush];
        printf("%-46s %s\n", "flushing twice over", "returned");
        printf("%-46s %g\n", "duration afterwards",
               (double)[CATransaction animationDuration]);
      }

      printf("\n=== the lock ===\n");
      {
        [CATransaction lock];
        printf("%-46s %s\n", "locked once", "returned");
        [CATransaction lock];
        printf("%-46s %s\n", "locked twice over", "returned");
        [CATransaction unlock];
        [CATransaction unlock];
        printf("%-46s %s\n", "unlocked twice", "returned");
      }

      printf("\n=== reading and writing while locked ===\n");
      {
        [CATransaction lock];
        [CATransaction begin];
        [CATransaction setAnimationDuration: 9.0];
        printf("%-46s %g\n", "a transaction still works while locked",
               (double)[CATransaction animationDuration]);
        [CATransaction commit];
        [CATransaction unlock];
        printf("%-46s %g\n", "and after unlocking",
               (double)[CATransaction animationDuration]);
      }

      printf("\n=== unlocking without locking ===\n");
      {
        @try
          {
            [CATransaction unlock];
            printf("%-46s %s\n", "unlock on its own", "returned");
          }
        @catch (NSException *e)
          {
            printf("%-46s RAISED %s\n", "unlock on its own",
                   [[e name] UTF8String]);
          }
      }
    }
  return 0;
}

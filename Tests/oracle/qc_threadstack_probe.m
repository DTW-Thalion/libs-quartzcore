/* Is a transaction stack shared between threads, or one per thread?

   Every wait below has a deadline, so a wrong guess cannot hang the runner.

   Run on a macOS runner:
     clang -framework QuartzCore -framework CoreGraphics -framework Foundation \
       Tests/oracle/qc_threadstack_probe.m -o qc_threadstack_probe
*/

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

static NSCondition *gate = nil;
static BOOL         finished = NO;
static double       seenDuration = -1.0;
static BOOL         seenDisableActions = NO;

@interface Other : NSObject
+ (void) look: (id)ignored;
+ (void) beginAndLeaveOpen: (id)ignored;
@end

@implementation Other

+ (void) look: (id)ignored
{
  @autoreleasepool
    {
      seenDuration = (double)[CATransaction animationDuration];
      seenDisableActions = [CATransaction disableActions];
    }
  [gate lock];
  finished = YES;
  [gate signal];
  [gate unlock];
}

+ (void) beginAndLeaveOpen: (id)ignored
{
  @autoreleasepool
    {
      [CATransaction begin];
      [CATransaction setAnimationDuration: 11.0];
      seenDuration = (double)[CATransaction animationDuration];
      [CATransaction commit];
    }
  [gate lock];
  finished = YES;
  [gate signal];
  [gate unlock];
}

@end

static BOOL runOther(SEL what)
{
  NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow: 10.0];
  BOOL ok = YES;

  finished = NO;
  seenDuration = -1.0;
  [NSThread detachNewThreadSelector: what toTarget: [Other class] withObject: nil];

  [gate lock];
  while (!finished)
    {
      if (![gate waitUntilDate: deadline])
        {
          ok = NO;
          break;
        }
    }
  [gate unlock];
  return ok;
}

int main(int argc, char **argv)
{
  @autoreleasepool
    {
      gate = [NSCondition new];

      printf("=== what another thread sees of this one's transaction ===\n");
      [CATransaction begin];
      [CATransaction setAnimationDuration: 5.0];
      [CATransaction setDisableActions: YES];
      printf("%-46s %g\n", "this thread has set", 5.0);

      if (runOther(@selector(look:)))
        {
          printf("%-46s %g\n", "the other thread reads a duration of",
                 seenDuration);
          printf("%-46s %d\n", "and disableActions of",
                 (int)seenDisableActions);
        }
      else
        {
          printf("%-46s %s\n", "the other thread", "TIMED OUT");
        }

      printf("%-46s %g\n", "this thread still reads",
             (double)[CATransaction animationDuration]);
      [CATransaction commit];
      printf("%-46s %g\n", "and after committing",
             (double)[CATransaction animationDuration]);

      printf("\n=== another thread running its own transaction ===\n");
      [CATransaction begin];
      [CATransaction setAnimationDuration: 3.0];

      if (runOther(@selector(beginAndLeaveOpen:)))
        {
          printf("%-46s %g\n", "the other thread saw its own",
                 seenDuration);
        }
      else
        {
          printf("%-46s %s\n", "the other thread", "TIMED OUT");
        }

      printf("%-46s %g\n", "this thread is undisturbed at",
             (double)[CATransaction animationDuration]);
      [CATransaction commit];
      printf("%-46s %g\n", "and commits cleanly to",
             (double)[CATransaction animationDuration]);
    }
  return 0;
}

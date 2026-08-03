/* CADisplayLink: what one holds before it runs, and whether it fires at all
 * on a machine with no display.  Every wait is bounded. */

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

static int fireCount = 0;

@interface Ticker : NSObject
- (void) step: (id)sender;
@end

@implementation Ticker
- (void) step: (id)sender
{
  fireCount++;
}
@end

int main(void)
{
  setbuf(stdout, NULL);

  @autoreleasepool
    {
      Class cls = NSClassFromString(@"CADisplayLink");

      printf("CADisplayLink present            %s\n", cls ? "yes" : "no");
      if (cls == Nil)
        {
          return 0;
        }
      printf("responds to displayLinkWithTarget %d\n",
             (int)[cls respondsToSelector:
                     NSSelectorFromString(@"displayLinkWithTarget:selector:")]);

      Ticker *ticker = [[Ticker alloc] init];
      CADisplayLink *link = nil;

      @try
        {
          link = [CADisplayLink displayLinkWithTarget: ticker
                                             selector: @selector(step:)];
        }
      @catch (NSException *e)
        {
          printf("making one RAISED %s: %s\n", [[e name] UTF8String],
                 [[e reason] UTF8String]);
          return 0;
        }

      printf("made one                         %s\n", link ? "yes" : "nil");
      if (link == nil)
        {
          return 0;
        }

      printf("paused                           %d\n", (int)[link isPaused]);
      printf("timestamp                        %g\n", (double)[link timestamp]);
      printf("duration                         %g\n", (double)[link duration]);
      printf("targetTimestamp                  %g\n",
             (double)[link targetTimestamp]);
      printf("preferredFramesPerSecond         %ld\n",
             (long)[link preferredFramesPerSecond]);

      /* Does it fire with no display?  Bounded to half a second. */
      [link addToRunLoop: [NSRunLoop currentRunLoop]
                 forMode: NSDefaultRunLoopMode];
      [[NSRunLoop currentRunLoop] runUntilDate:
        [NSDate dateWithTimeIntervalSinceNow: 0.5]];
      printf("fired in half a second           %d times\n", fireCount);
      printf("timestamp after running          %g\n", (double)[link timestamp]);
      printf("duration after running           %g\n", (double)[link duration]);

      /* paused round trip */
      [link setPaused: YES];
      printf("paused after setting it          %d\n", (int)[link isPaused]);
      [link setPaused: NO];

      [link invalidate];
      printf("invalidate returned\n");

      /* a second one, to see whether invalidate stops the firing */
      fireCount = 0;
      [[NSRunLoop currentRunLoop] runUntilDate:
        [NSDate dateWithTimeIntervalSinceNow: 0.2]];
      printf("fired after invalidate           %d times\n", fireCount);

      [ticker release];
    }
  return 0;
}

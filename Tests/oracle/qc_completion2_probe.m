/* If a nested transaction inherits a completion block and does not replace
   it, does that block run when the nested one commits, the outer one, or
   both?

   Run on a macOS runner:
     clang -fobjc-arc -framework QuartzCore -framework CoreGraphics \
       -framework Foundation Tests/oracle/qc_completion2_probe.m -o qc_completion2_probe
*/

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

static void turn(void)
{
  [[NSRunLoop currentRunLoop] runUntilDate:
    [NSDate dateWithTimeIntervalSinceNow: 0.3]];
}

int main(int argc, char **argv)
{
  @autoreleasepool
    {
      printf("=== inherited and left alone ===\n");
      {
        __block int ran = 0;

        [CATransaction begin];
        [CATransaction setCompletionBlock: ^{ ran++; }];

        [CATransaction begin];
        [CATransaction commit];
        turn();
        printf("%-46s %d\n", "after the nested one commits", ran);

        [CATransaction commit];
        turn();
        printf("%-46s %d\n", "after the outer one commits", ran);
      }

      printf("\n=== what the getter answers after two are set ===\n");
      {
        __block int first = 0;
        __block int second = 0;
        void (^a)(void) = ^{ first++; };
        void (^b)(void) = ^{ second++; };

        [CATransaction begin];
        [CATransaction setCompletionBlock: a];
        [CATransaction setCompletionBlock: b];
        printf("%-46s %s\n", "the getter answers the second one",
               [CATransaction completionBlock] == b ? "YES" : "NO");
        printf("%-46s %s\n", "or the first one",
               [CATransaction completionBlock] == a ? "YES" : "NO");
        [CATransaction commit];
        turn();
        printf("%-46s first %d second %d\n", "and both ran", first, second);
      }

      printf("\n=== setting it back to nothing ===\n");
      {
        __block int ran = 0;

        [CATransaction begin];
        [CATransaction setCompletionBlock: ^{ ran++; }];
        [CATransaction setCompletionBlock: nil];
        printf("%-46s %s\n", "the getter afterwards",
               [CATransaction completionBlock] ? "(non-nil)" : "(nil)");
        [CATransaction commit];
        turn();
        printf("%-46s %d\n", "and whether the first still ran", ran);
      }
    }
  return 0;
}

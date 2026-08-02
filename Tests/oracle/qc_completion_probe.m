/* When does a transaction's completion block run, and is it inherited?

   Run on a macOS runner:
     clang -fobjc-arc -framework QuartzCore -framework CoreGraphics \
       -framework Foundation Tests/oracle/qc_completion_probe.m -o qc_completion_probe
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
      printf("=== reading it back ===\n");
      {
        [CATransaction begin];
        printf("%-46s %s\n", "before setting one",
               [CATransaction completionBlock] ? "(non-nil)" : "(nil)");
        [CATransaction setCompletionBlock: ^{ }];
        printf("%-46s %s\n", "after setting one",
               [CATransaction completionBlock] ? "(non-nil)" : "(nil)");
        [CATransaction commit];
        printf("%-46s %s\n", "after the transaction commits",
               [CATransaction completionBlock] ? "(non-nil)" : "(nil)");
        turn();
      }

      printf("\n=== is it inherited by a nested transaction? ===\n");
      {
        __block int outer = 0;
        __block int inner = 0;

        [CATransaction begin];
        [CATransaction setCompletionBlock: ^{ outer++; }];

        [CATransaction begin];
        printf("%-46s %s\n", "the nested one starts with",
               [CATransaction completionBlock] ? "(non-nil)" : "(nil)");
        [CATransaction setCompletionBlock: ^{ inner++; }];
        [CATransaction commit];
        turn();
        printf("%-46s outer %d inner %d\n", "after the nested one commits",
               outer, inner);

        [CATransaction commit];
        turn();
        printf("%-46s outer %d inner %d\n", "after the outer one commits",
               outer, inner);
      }

      printf("\n=== setting one twice over ===\n");
      {
        __block int first = 0;
        __block int second = 0;

        [CATransaction begin];
        [CATransaction setCompletionBlock: ^{ first++; }];
        [CATransaction setCompletionBlock: ^{ second++; }];
        [CATransaction commit];
        turn();
        printf("%-46s first %d second %d\n", "which of the two ran",
               first, second);
      }

      printf("\n=== a transaction with nothing in it ===\n");
      {
        __block int ran = 0;

        [CATransaction begin];
        [CATransaction setCompletionBlock: ^{ ran++; }];
        [CATransaction commit];
        printf("%-46s %d\n", "straight after committing", ran);
        turn();
        printf("%-46s %d\n", "after a run-loop turn", ran);
        turn();
        printf("%-46s %d\n", "after a second turn", ran);
      }

      printf("\n=== one set outside any transaction ===\n");
      {
        __block int ran = 0;

        [CATransaction setCompletionBlock: ^{ ran++; }];
        printf("%-46s %d\n", "before flushing", ran);
        [CATransaction flush];
        printf("%-46s %d\n", "straight after flushing", ran);
        turn();
        printf("%-46s %d\n", "after a run-loop turn", ran);
      }

      printf("\n=== never committed ===\n");
      {
        __block int ran = 0;

        [CATransaction begin];
        [CATransaction setCompletionBlock: ^{ ran++; }];
        turn();
        printf("%-46s %d\n", "left open over a run-loop turn", ran);
        [CATransaction commit];
        turn();
        printf("%-46s %d\n", "and then committed", ran);
      }
    }
  return 0;
}

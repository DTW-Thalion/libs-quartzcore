/* Probe CATransaction against Apple's QuartzCore.

   Run on a macOS runner:
     clang -framework QuartzCore -framework CoreGraphics -framework Foundation \
       Tests/oracle/qc_transaction_probe.m -o qc_transaction_probe
*/

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

static void section(const char *name)
{
  printf("\n=== %s ===\n", name);
}

static void showDuration(const char *what)
{
  printf("%-46s %.6f\n", what, (double)[CATransaction animationDuration]);
}

static void showFn(const char *what)
{
  CAMediaTimingFunction *fn = [CATransaction animationTimingFunction];
  if (!fn)
    {
      printf("%-46s (nil)\n", what);
      return;
    }
  float cp[2];
  [fn getControlPointAtIndex: 1 values: cp];
  float cp2[2];
  [fn getControlPointAtIndex: 2 values: cp2];
  printf("%-46s c1(%.4f,%.4f) c2(%.4f,%.4f)\n", what,
         cp[0], cp[1], cp2[0], cp2[1]);
}

int main(int argc, char **argv)
{
  @autoreleasepool
    {
      section("constant string VALUES");
      printf("kCATransactionAnimationDuration        = \"%s\"\n",
             [kCATransactionAnimationDuration UTF8String]);
      printf("kCATransactionDisableActions           = \"%s\"\n",
             [kCATransactionDisableActions UTF8String]);
      printf("kCATransactionAnimationTimingFunction  = \"%s\"\n",
             [kCATransactionAnimationTimingFunction UTF8String]);
      printf("kCATransactionCompletionBlock          = \"%s\"\n",
             [kCATransactionCompletionBlock UTF8String]);

      section("defaults with NO explicit transaction (implicit)");
      showDuration("animationDuration");
      showFn("animationTimingFunction");
      printf("%-46s %d\n", "disableActions", (int)[CATransaction disableActions]);
      printf("%-46s %s\n", "completionBlock",
             [CATransaction completionBlock] ? "(non-nil)" : "(nil)");

      section("valueForKey on the implicit transaction");
      printf("%-46s %s\n", "valueForKey:AnimationDuration",
             [[[CATransaction valueForKey: kCATransactionAnimationDuration]
                description] UTF8String]);
      printf("%-46s %s\n", "valueForKey:DisableActions",
             [[[CATransaction valueForKey: kCATransactionDisableActions]
                description] UTF8String]);
      printf("%-46s %s\n", "valueForKey:AnimationTimingFunction",
             [CATransaction valueForKey: kCATransactionAnimationTimingFunction]
               ? "(non-nil)" : "(nil)");
      @try
        {
          id v = [CATransaction valueForKey: @"aKeyNobodyDefined"];
          printf("%-46s %s\n", "valueForKey:aKeyNobodyDefined",
                 v ? [[v description] UTF8String] : "(nil)");
        }
      @catch (NSException *e)
        {
          printf("%-46s RAISED %s\n", "valueForKey:aKeyNobodyDefined",
                 [[e name] UTF8String]);
        }

      section("arbitrary key round-trip");
      @try
        {
          [CATransaction setValue: @"hello" forKey: @"aKeyNobodyDefined"];
          id v = [CATransaction valueForKey: @"aKeyNobodyDefined"];
          printf("%-46s %s\n", "set then get aKeyNobodyDefined",
                 v ? [[v description] UTF8String] : "(nil)");
        }
      @catch (NSException *e)
        {
          printf("%-46s RAISED %s\n", "set aKeyNobodyDefined",
                 [[e name] UTF8String]);
        }

      section("setter/valueForKey share storage?");
      [CATransaction setAnimationDuration: 3.5];
      showDuration("after setAnimationDuration:3.5");
      printf("%-46s %s\n", "valueForKey:AnimationDuration now",
             [[[CATransaction valueForKey: kCATransactionAnimationDuration]
                description] UTF8String]);
      [CATransaction setValue: [NSNumber numberWithDouble: 7.25]
                       forKey: kCATransactionAnimationDuration];
      showDuration("after setValue:7.25 forKey:duration");

      [CATransaction setDisableActions: YES];
      printf("%-46s %d / %s\n", "disableActions after setter",
             (int)[CATransaction disableActions],
             [[[CATransaction valueForKey: kCATransactionDisableActions]
                description] UTF8String]);
      [CATransaction setValue: [NSNumber numberWithBool: NO]
                       forKey: kCATransactionDisableActions];
      printf("%-46s %d\n", "disableActions after setValue:NO",
             (int)[CATransaction disableActions]);

      section("nesting: does an inner transaction inherit?");
      [CATransaction begin];
      [CATransaction setAnimationDuration: 1.0];
      [CATransaction setDisableActions: YES];
      showDuration("outer after set 1.0");
      [CATransaction begin];
      showDuration("INNER, immediately after begin");
      printf("%-46s %d\n", "INNER disableActions", (int)[CATransaction disableActions]);
      showFn("INNER animationTimingFunction");
      [CATransaction setAnimationDuration: 2.0];
      showDuration("INNER after set 2.0");
      [CATransaction commit];
      showDuration("outer after inner commit");
      printf("%-46s %d\n", "outer disableActions after inner commit",
             (int)[CATransaction disableActions]);
      [CATransaction commit];
      showDuration("after outer commit");

      section("a timing function set on a transaction");
      [CATransaction begin];
      [CATransaction setAnimationTimingFunction:
        [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseIn]];
      showFn("after setAnimationTimingFunction:EaseIn");
      [CATransaction commit];
      showFn("after commit");

      section("commit with no matching begin");
      @try
        {
          [CATransaction commit];
          printf("%-46s did not raise\n", "unbalanced commit");
        }
      @catch (NSException *e)
        {
          printf("%-46s RAISED %s: %s\n", "unbalanced commit",
                 [[e name] UTF8String], [[e reason] UTF8String]);
        }
      showDuration("animationDuration after unbalanced commit");

      section("completion block");
      __block int ran = 0;
      [CATransaction begin];
      [CATransaction setCompletionBlock: ^{ ran++; }];
      printf("%-46s %s\n", "completionBlock inside transaction",
             [CATransaction completionBlock] ? "(non-nil)" : "(nil)");
      printf("%-46s %d\n", "ran before commit", ran);
      [CATransaction commit];
      printf("%-46s %d\n", "ran right after commit", ran);
      [[NSRunLoop currentRunLoop] runUntilDate:
        [NSDate dateWithTimeIntervalSinceNow: 0.3]];
      printf("%-46s %d\n", "ran after a run-loop turn", ran);

      section("disableActions and implicit animation on a layer");
      CALayer *layer = [CALayer layer];
      [layer setBounds: CGRectMake(0, 0, 100, 100)];
      [CATransaction begin];
      [CATransaction setDisableActions: NO];
      [layer setPosition: CGPointMake(10, 10)];
      printf("%-46s %s\n", "animationKeys, actions enabled",
             [[[layer animationKeys] description] UTF8String]);
      [CATransaction commit];
      printf("%-46s %s\n", "animationKeys after commit",
             [[[layer animationKeys] description] UTF8String]);

      CALayer *layer2 = [CALayer layer];
      [layer2 setBounds: CGRectMake(0, 0, 100, 100)];
      [CATransaction begin];
      [CATransaction setDisableActions: YES];
      [layer2 setPosition: CGPointMake(20, 20)];
      printf("%-46s %s\n", "animationKeys, actions DISABLED",
             [[[layer2 animationKeys] description] UTF8String]);
      [CATransaction commit];
      printf("%-46s %s\n", "animationKeys after commit (disabled)",
             [[[layer2 animationKeys] description] UTF8String]);

      section("is a transaction instance usable directly?");
      printf("%-46s %s\n", "+[CATransaction new] responds to -commit",
             [CATransaction instancesRespondToSelector: @selector(commit)]
               ? "YES" : "NO");
      printf("%-46s %s\n", "responds to +topTransaction",
             [CATransaction respondsToSelector: @selector(topTransaction)]
               ? "YES" : "NO");

      section("flush");
      @try
        {
          [CATransaction flush];
          printf("%-46s did not raise\n", "flush outside a transaction");
        }
      @catch (NSException *e)
        {
          printf("%-46s RAISED %s\n", "flush", [[e name] UTF8String]);
        }
      showDuration("animationDuration after flush");

      section("lock/unlock");
      @try
        {
          [CATransaction lock];
          [CATransaction unlock];
          printf("%-46s did not raise\n", "lock+unlock");
        }
      @catch (NSException *e)
        {
          printf("%-46s RAISED %s\n", "lock+unlock", [[e name] UTF8String]);
        }
    }
  return 0;
}

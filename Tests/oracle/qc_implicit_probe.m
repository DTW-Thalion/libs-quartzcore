/* When does a standalone layer take an implicit animation, and is it ever
 * visible through -animationKeys?  And does disableActions stop it? */

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

static void keys(const char *label, CALayer *l)
{
  NSArray *k = [l animationKeys];

  printf("%-46s keys=%-28s position=%s\n", label,
         k ? [[k description] UTF8String] : "(nil)",
         [l animationForKey: @"position"] ? "animation" : "(none)");
}

static void spin(void)
{
  [[NSRunLoop currentRunLoop] runUntilDate:
    [NSDate dateWithTimeIntervalSinceNow: 0.05]];
}

int main(void)
{
  setbuf(stdout, NULL);

  @autoreleasepool
    {
      printf("== implicit animation on a standalone layer ==\n");

      {
        CALayer *l = [CALayer layer];
        keys("fresh layer", l);
        [l setPosition: CGPointMake(10, 10)];
        keys("after setPosition, no transaction", l);
        spin();
        keys("after a run loop turn", l);
      }

      {
        CALayer *l = [CALayer layer];
        [CATransaction begin];
        [l setPosition: CGPointMake(20, 20)];
        keys("inside a transaction, before commit", l);
        [CATransaction commit];
        keys("after commit", l);
        spin();
        keys("after commit and a run loop turn", l);
      }

      {
        CALayer *l = [CALayer layer];
        [CATransaction begin];
        [CATransaction setDisableActions: YES];
        printf("disableActions reads %d\n", (int)[CATransaction disableActions]);
        [l setPosition: CGPointMake(30, 30)];
        keys("with actions disabled, before commit", l);
        [CATransaction commit];
        keys("with actions disabled, after commit", l);
        spin();
        keys("with actions disabled, after a turn", l);
      }

      {
        CALayer *l = [CALayer layer];
        [l setPosition: CGPointMake(40, 40)];
        spin();
        [l setPosition: CGPointMake(40, 40)];
        keys("set to the value it already had", l);
      }

      /* what the layer answers for the action itself */
      {
        CALayer *l = [CALayer layer];

        printf("actionForKey position, no transaction: %s\n",
               [l actionForKey: @"position"] ?
                 [[[l actionForKey: @"position"] description] UTF8String]
                 : "(nil)");
        [CATransaction begin];
        [CATransaction setDisableActions: YES];
        printf("actionForKey position, actions off:    %s\n",
               [l actionForKey: @"position"] ?
                 [[[l actionForKey: @"position"] description] UTF8String]
                 : "(nil)");
        [CATransaction commit];
      }

      /* a layer inside a hierarchy that is being displayed */
      {
        CALayer *root = [CALayer layer];
        CALayer *child = [CALayer layer];

        [root addSublayer: child];
        [child setPosition: CGPointMake(50, 50)];
        spin();
        keys("a sublayer of a root layer", child);
      }
    }
  return 0;
}

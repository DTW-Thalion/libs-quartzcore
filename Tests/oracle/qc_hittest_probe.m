/* Probe -containsPoint: and -hitTest: against Apple's QuartzCore.

   Run on a macOS runner:
     clang -framework QuartzCore -framework CoreGraphics -framework Foundation \
       Tests/oracle/qc_hittest_probe.m -o qc_hittest_probe
*/

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

static const char *nameOf(CALayer *l)
{
  if (l == nil)
    return "(nil)";
  return [l name] ? [[l name] UTF8String] : "(unnamed)";
}

int main(int argc, char **argv)
{
  @autoreleasepool
    {
      printf("=== containsPoint, in the layer's own space ===\n");
      {
        CALayer *l = [CALayer layer];

        [l setBounds: CGRectMake(0, 0, 100, 100)];
        [l setPosition: CGPointMake(500, 500)];

        printf("%-44s %d\n", "0,0", [l containsPoint: CGPointMake(0, 0)]);
        printf("%-44s %d\n", "99.9,99.9",
               [l containsPoint: CGPointMake(99.9, 99.9)]);
        printf("%-44s %d\n", "100,100",
               [l containsPoint: CGPointMake(100, 100)]);
        printf("%-44s %d\n", "-0.1,50",
               [l containsPoint: CGPointMake(-0.1, 50)]);
        printf("%-44s %d\n", "the position, 500,500",
               [l containsPoint: CGPointMake(500, 500)]);
      }

      printf("\n=== containsPoint with a shifted bounds origin ===\n");
      {
        CALayer *l = [CALayer layer];

        [l setBounds: CGRectMake(10, 10, 100, 100)];
        printf("%-44s %d\n", "5,5", [l containsPoint: CGPointMake(5, 5)]);
        printf("%-44s %d\n", "15,15", [l containsPoint: CGPointMake(15, 15)]);
        printf("%-44s %d\n", "109,109",
               [l containsPoint: CGPointMake(109, 109)]);
      }

      printf("\n=== hitTest, in the superlayer's space ===\n");
      {
        CALayer *root = [CALayer layer];
        CALayer *child = [CALayer layer];

        [root setName: @"root"];
        [child setName: @"child"];
        [root setBounds: CGRectMake(0, 0, 100, 100)];
        [root setPosition: CGPointMake(50, 50)];
        [child setBounds: CGRectMake(0, 0, 20, 20)];
        [child setPosition: CGPointMake(50, 50)];
        [root addSublayer: child];

        printf("%-44s %s\n", "at the centre", nameOf([root hitTest: CGPointMake(50, 50)]));
        printf("%-44s %s\n", "at a corner", nameOf([root hitTest: CGPointMake(5, 5)]));
        printf("%-44s %s\n", "outside", nameOf([root hitTest: CGPointMake(500, 500)]));
        printf("%-44s %s\n", "on the root's edge, 100,100",
               nameOf([root hitTest: CGPointMake(100, 100)]));
      }

      printf("\n=== two sublayers on top of each other ===\n");
      {
        CALayer *root = [CALayer layer];
        CALayer *lower = [CALayer layer];
        CALayer *upper = [CALayer layer];

        [root setName: @"root"];
        [lower setName: @"lower"];
        [upper setName: @"upper"];
        [root setBounds: CGRectMake(0, 0, 100, 100)];
        [root setPosition: CGPointMake(50, 50)];
        for (CALayer *l in [NSArray arrayWithObjects: lower, upper, nil])
          {
            [l setBounds: CGRectMake(0, 0, 40, 40)];
            [l setPosition: CGPointMake(50, 50)];
            [root addSublayer: l];
          }

        printf("%-44s %s\n", "the one added last wins",
               nameOf([root hitTest: CGPointMake(50, 50)]));

        [upper setHidden: YES];
        printf("%-44s %s\n", "with the top one hidden",
               nameOf([root hitTest: CGPointMake(50, 50)]));
        [upper setHidden: NO];

        [lower setZPosition: 10];
        printf("%-44s %s\n", "with the lower one raised by zPosition",
               nameOf([root hitTest: CGPointMake(50, 50)]));
      }

      printf("\n=== a sublayer outside its parent's bounds ===\n");
      {
        CALayer *root = [CALayer layer];
        CALayer *child = [CALayer layer];

        [root setName: @"root"];
        [child setName: @"child"];
        [root setBounds: CGRectMake(0, 0, 100, 100)];
        [root setPosition: CGPointMake(50, 50)];
        [child setBounds: CGRectMake(0, 0, 20, 20)];
        [child setPosition: CGPointMake(150, 150)];
        [root addSublayer: child];

        printf("%-44s %s\n", "over the child, outside the root",
               nameOf([root hitTest: CGPointMake(150, 150)]));
        [root setMasksToBounds: YES];
        printf("%-44s %s\n", "the same, with the root masking",
               nameOf([root hitTest: CGPointMake(150, 150)]));
      }

      printf("\n=== hitTest on a layer with no superlayer ===\n");
      {
        CALayer *lone = [CALayer layer];

        [lone setName: @"lone"];
        [lone setBounds: CGRectMake(0, 0, 100, 100)];
        [lone setPosition: CGPointMake(50, 50)];
        printf("%-44s %s\n", "inside its frame",
               nameOf([lone hitTest: CGPointMake(50, 50)]));
        printf("%-44s %s\n", "outside its frame",
               nameOf([lone hitTest: CGPointMake(500, 500)]));
      }
    }
  return 0;
}

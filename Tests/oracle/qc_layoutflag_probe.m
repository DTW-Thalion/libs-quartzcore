/* Which changes to the sublayer tree make a layer want laying out again?

   Run on a macOS runner:
     clang -framework QuartzCore -framework CoreGraphics -framework Foundation \
       Tests/oracle/qc_layoutflag_probe.m -o qc_layoutflag_probe
*/

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

/* A parent with one sublayer already, laid out and settled. */
static CALayer *settled(CALayer **existing)
{
  CALayer *root = [CALayer layer];
  CALayer *first = [CALayer layer];

  [root setBounds: CGRectMake(0, 0, 100, 100)];
  [root addSublayer: first];
  [root layoutIfNeeded];
  if (existing)
    *existing = first;
  return root;
}

static void show(const char *what, CALayer *root)
{
  printf("%-46s %d\n", what, (int)[root needsLayout]);
}

int main(int argc, char **argv)
{
  @autoreleasepool
    {
      {
        CALayer *root = settled(NULL);

        show("settled, before anything", root);
      }
      {
        CALayer *root = settled(NULL);

        [root addSublayer: [CALayer layer]];
        show("addSublayer:", root);
      }
      {
        CALayer *root = settled(NULL);

        [root insertSublayer: [CALayer layer] atIndex: 0];
        show("insertSublayer:atIndex:", root);
      }
      {
        CALayer *first;
        CALayer *root = settled(&first);

        [root insertSublayer: [CALayer layer] below: first];
        show("insertSublayer:below:", root);
      }
      {
        CALayer *first;
        CALayer *root = settled(&first);

        [root insertSublayer: [CALayer layer] above: first];
        show("insertSublayer:above:", root);
      }
      {
        CALayer *first;
        CALayer *root = settled(&first);

        [first removeFromSuperlayer];
        show("the sublayer removing itself", root);
      }
      {
        CALayer *first;
        CALayer *root = settled(&first);

        [root replaceSublayer: first with: [CALayer layer]];
        show("replaceSublayer:with:", root);
      }
      {
        CALayer *root = settled(NULL);

        [root setSublayers: [NSArray arrayWithObject: [CALayer layer]]];
        show("setSublayers:", root);
      }

      printf("\n--- and does the layer added want laying out itself? ---\n");
      {
        CALayer *root = settled(NULL);
        CALayer *added = [CALayer layer];

        [added layoutIfNeeded];
        [root addSublayer: added];
        printf("%-46s %d\n", "the layer that was added", (int)[added needsLayout]);
      }

      printf("\n--- what about its own bounds changing? ---\n");
      {
        CALayer *root = settled(NULL);

        [root setBounds: CGRectMake(0, 0, 200, 200)];
        show("after its bounds change", root);
      }
    }
  return 0;
}

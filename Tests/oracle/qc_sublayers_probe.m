/* Does a layer answer nil or an empty array for its sublayers, once it has
   had some and lost them?

   Run on a macOS runner:
     clang -framework QuartzCore -framework CoreGraphics -framework Foundation \
       Tests/oracle/qc_sublayers_probe.m -o qc_sublayers_probe
*/

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

static void show(const char *what, CALayer *l)
{
  NSArray *s = [l sublayers];

  printf("%-46s %s", what, s ? "array" : "(nil)");
  if (s)
    printf(" of %lu", (unsigned long)[s count]);
  printf("\n");
}

int main(int argc, char **argv)
{
  @autoreleasepool
    {
      printf("=== never had any ===\n");
      {
        CALayer *l = [CALayer layer];

        show("a fresh layer", l);
      }

      printf("\n=== had one, then lost it ===\n");
      {
        CALayer *l = [CALayer layer];
        CALayer *child = [CALayer layer];

        [l addSublayer: child];
        show("after adding one", l);
        [child removeFromSuperlayer];
        show("after removing the only one", l);
      }

      printf("\n=== had two, lost both ===\n");
      {
        CALayer *l = [CALayer layer];
        CALayer *a = [CALayer layer];
        CALayer *b = [CALayer layer];

        [l addSublayer: a];
        [l addSublayer: b];
        [a removeFromSuperlayer];
        show("after removing the first of two", l);
        [b removeFromSuperlayer];
        show("after removing the second", l);
      }

      printf("\n=== set wholesale ===\n");
      {
        CALayer *l = [CALayer layer];
        CALayer *a = [CALayer layer];

        [l setSublayers: [NSArray arrayWithObject: a]];
        show("after setSublayers: with one", l);

        [l setSublayers: [NSArray array]];
        show("after setSublayers: with an empty array", l);

        [l setSublayers: [NSArray arrayWithObject: a]];
        [l setSublayers: nil];
        show("after setSublayers: nil", l);
      }

      printf("\n=== replaced away ===\n");
      {
        CALayer *l = [CALayer layer];
        CALayer *a = [CALayer layer];
        CALayer *b = [CALayer layer];

        [l addSublayer: a];
        [l replaceSublayer: a with: b];
        show("after replacing the only one", l);
        [b removeFromSuperlayer];
        show("and then removing the replacement", l);
      }
    }
  return 0;
}

/* Probe the display and layout flags on a layer, and CATransition's
   defaults, against Apple's QuartzCore.

   Run on a macOS runner:
     clang -framework QuartzCore -framework CoreGraphics -framework Foundation \
       Tests/oracle/qc_display_probe.m -o qc_display_probe
*/

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

static void showObj(const char *what, id v)
{
  printf("%-40s %s\n", what, v ? [[v description] UTF8String] : "(nil)");
}

int main(int argc, char **argv)
{
  @autoreleasepool
    {
      printf("=== the display flag ===\n");
      {
        CALayer *l = [CALayer layer];

        [l setBounds: CGRectMake(0, 0, 50, 50)];
        printf("%-40s %d\n", "needsDisplay on a fresh layer",
               (int)[l needsDisplay]);

        [l setNeedsDisplay];
        printf("%-40s %d\n", "after setNeedsDisplay", (int)[l needsDisplay]);

        [l displayIfNeeded];
        printf("%-40s %d\n", "after displayIfNeeded", (int)[l needsDisplay]);

        [l setNeedsDisplay];
        [l display];
        printf("%-40s %d\n", "after display", (int)[l needsDisplay]);

        [l setNeedsDisplayInRect: CGRectMake(0, 0, 10, 10)];
        printf("%-40s %d\n", "after setNeedsDisplayInRect",
               (int)[l needsDisplay]);
      }

      printf("\n=== needsDisplayOnBoundsChange ===\n");
      {
        CALayer *off = [CALayer layer];
        CALayer *on = [CALayer layer];

        [off displayIfNeeded];
        [off setBounds: CGRectMake(0, 0, 30, 30)];
        printf("%-40s %d\n", "bounds changed, flag off",
               (int)[off needsDisplay]);

        [on setNeedsDisplayOnBoundsChange: YES];
        [on displayIfNeeded];
        [on setBounds: CGRectMake(0, 0, 30, 30)];
        printf("%-40s %d\n", "bounds changed, flag on",
               (int)[on needsDisplay]);
      }

      printf("\n=== the layout flag ===\n");
      {
        CALayer *l = [CALayer layer];

        printf("%-40s %d\n", "needsLayout on a fresh layer",
               (int)[l needsLayout]);

        [l setNeedsLayout];
        printf("%-40s %d\n", "after setNeedsLayout", (int)[l needsLayout]);

        [l layoutIfNeeded];
        printf("%-40s %d\n", "after layoutIfNeeded", (int)[l needsLayout]);

        [l setNeedsLayout];
        [l layoutSublayers];
        printf("%-40s %d\n", "after layoutSublayers", (int)[l needsLayout]);

        showObj("layoutManager", [l layoutManager]);
      }

      printf("\n=== adding a sublayer and the layout flag ===\n");
      {
        CALayer *root = [CALayer layer];

        [root layoutIfNeeded];
        printf("%-40s %d\n", "before adding", (int)[root needsLayout]);
        [root addSublayer: [CALayer layer]];
        printf("%-40s %d\n", "after adding a sublayer",
               (int)[root needsLayout]);
      }

      printf("\n=== CATransition ===\n");
      {
        CATransition *t = [CATransition animation];

        showObj("type", [t type]);
        showObj("subtype", [t subtype]);
        printf("%-40s %g\n", "startProgress", (double)[t startProgress]);
        printf("%-40s %g\n", "endProgress", (double)[t endProgress]);
        showObj("filter", [t filter]);
        printf("%-40s %g\n", "duration", (double)[t duration]);

        [t setType: kCATransitionPush];
        [t setSubtype: kCATransitionFromLeft];
        showObj("type after setting push", [t type]);
        showObj("subtype after setting fromLeft", [t subtype]);
      }
    }
  return 0;
}

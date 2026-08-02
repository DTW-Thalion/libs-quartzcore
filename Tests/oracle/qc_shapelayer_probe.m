/* Probe CAShapeLayer against Apple's QuartzCore.

   Run on a macOS runner:
     clang -framework QuartzCore -framework CoreGraphics -framework Foundation \
       Tests/oracle/qc_shapelayer_probe.m -o qc_shapelayer_probe
*/

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

static void showColor(const char *what, CGColorRef c)
{
  size_t i, n;
  const CGFloat *comp;

  if (c == NULL)
    {
      printf("%-34s NULL\n", what);
      return;
    }
  n = CGColorGetNumberOfComponents(c);
  comp = CGColorGetComponents(c);
  printf("%-34s %zu components:", what, n);
  for (i = 0; i < n; i++)
    printf(" %.4f", (double)comp[i]);
  printf("   alpha %.4f  model %d\n", (double)CGColorGetAlpha(c),
         (int)CGColorSpaceGetModel(CGColorGetColorSpace(c)));
}

static void showString(const char *what, NSString *s)
{
  printf("%-34s %s\n", what, s ? [[NSString stringWithFormat: @"\"%@\"", s]
                                    UTF8String] : "(nil)");
}

int main(int argc, char **argv)
{
  @autoreleasepool
    {
      CAShapeLayer *l = [CAShapeLayer layer];

      printf("=== CAShapeLayer defaults ===\n");
      printf("%-34s %s\n", "path", [l path] ? "(non-NULL)" : "NULL");
      showColor("fillColor", [l fillColor]);
      showString("fillRule", [l fillRule]);
      showColor("strokeColor", [l strokeColor]);
      printf("%-34s %.4f\n", "strokeStart", (double)[l strokeStart]);
      printf("%-34s %.4f\n", "strokeEnd", (double)[l strokeEnd]);
      printf("%-34s %.4f\n", "lineWidth", (double)[l lineWidth]);
      printf("%-34s %.4f\n", "miterLimit", (double)[l miterLimit]);
      showString("lineCap", [l lineCap]);
      showString("lineJoin", [l lineJoin]);
      printf("%-34s %.4f\n", "lineDashPhase", (double)[l lineDashPhase]);
      printf("%-34s %s\n", "lineDashPattern",
             [l lineDashPattern] ? "(non-nil)" : "(nil)");

      printf("\n=== inherited CALayer defaults on a shape layer ===\n");
      printf("%-34s %s\n", "bounds",
             [NSStringFromRect(NSRectFromCGRect([l bounds])) UTF8String]);
      printf("%-34s %.4f\n", "contentsScale", (double)[l contentsScale]);
      showString("contentsGravity", [l contentsGravity]);

      printf("\n=== +defaultValueForKey: ===\n");
      {
        NSArray *keys = [NSArray arrayWithObjects: @"lineWidth", @"miterLimit",
                         @"strokeEnd", @"fillRule", @"lineCap", @"lineJoin",
                         @"fillColor", nil];
        NSString *k;

        for (k in keys)
          {
            id v = [CAShapeLayer defaultValueForKey: k];

            printf("%-34s %s\n", [[NSString stringWithFormat:
              @"defaultValueForKey:%@", k] UTF8String],
              v ? [[v description] UTF8String] : "(nil)");
          }
      }

      printf("\n=== setters ===\n");
      [l setLineWidth: 4.5];
      [l setMiterLimit: 3.0];
      [l setStrokeStart: 0.25];
      [l setStrokeEnd: 0.75];
      [l setLineDashPhase: 2.0];
      [l setFillRule: kCAFillRuleEvenOdd];
      [l setLineCap: kCALineCapRound];
      [l setLineJoin: kCALineJoinBevel];
      printf("%-34s %.4f %.4f %.4f %.4f %.4f\n", "width miter start end phase",
             (double)[l lineWidth], (double)[l miterLimit],
             (double)[l strokeStart], (double)[l strokeEnd],
             (double)[l lineDashPhase]);
      showString("fillRule after set", [l fillRule]);
      showString("lineCap after set", [l lineCap]);
      showString("lineJoin after set", [l lineJoin]);

      printf("\n=== lineDashPattern copy semantics ===\n");
      {
        NSMutableArray *pattern = [NSMutableArray arrayWithObjects:
          [NSNumber numberWithInt: 4], [NSNumber numberWithInt: 2], nil];

        [l setLineDashPattern: pattern];
        [pattern addObject: [NSNumber numberWithInt: 9]];
        printf("%-34s %s\n", "pattern read back after mutating",
               [[[l lineDashPattern] description] UTF8String]);
        printf("%-34s %s\n", "same object as the one set",
               [l lineDashPattern] == pattern ? "YES" : "NO");
      }

      printf("\n=== a colour survives its own release ===\n");
      {
        CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
        CGFloat comps[4] = {1.0, 0.0, 0.0, 1.0};
        CGColorRef red = CGColorCreate(cs, comps);

        [l setFillColor: red];
        CGColorRelease(red);
        CGColorSpaceRelease(cs);
        showColor("fillColor after releasing it", [l fillColor]);
      }

      printf("\n=== is a shape layer a CALayer? ===\n");
      printf("%-34s %s\n", "isKindOfClass CALayer",
             [l isKindOfClass: [CALayer class]] ? "YES" : "NO");
      printf("%-34s %s\n", "needsDisplayForKey:path",
             [CAShapeLayer needsDisplayForKey: @"path"] ? "YES" : "NO");
      printf("%-34s %s\n", "needsDisplayForKey:lineWidth",
             [CAShapeLayer needsDisplayForKey: @"lineWidth"] ? "YES" : "NO");
    }
  return 0;
}

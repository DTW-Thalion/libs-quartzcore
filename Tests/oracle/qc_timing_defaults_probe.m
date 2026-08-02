/* Probe the CAMediaTiming properties on a layer and on an animation.

   Run on a macOS runner:
     clang -framework QuartzCore -framework CoreGraphics -framework Foundation \
       Tests/oracle/qc_timing_defaults_probe.m -o qc_timing_defaults_probe
*/

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

static void showTiming(const char *what, id<CAMediaTiming> t)
{
  printf("--- %s ---\n", what);
  printf("%-18s %g\n", "beginTime", (double)[t beginTime]);
  printf("%-18s %g\n", "timeOffset", (double)[t timeOffset]);
  printf("%-18s %g\n", "repeatCount", (double)[t repeatCount]);
  printf("%-18s %g\n", "repeatDuration", (double)[t repeatDuration]);
  printf("%-18s %d\n", "autoreverses", (int)[t autoreverses]);
  printf("%-18s %s\n", "fillMode",
         [t fillMode] ? [[t fillMode] UTF8String] : "(nil)");
  printf("%-18s %g\n", "duration", (double)[t duration]);
  printf("%-18s %g\n", "speed", (double)[t speed]);
}

static void showDefaults(const char *what, Class cls)
{
  NSArray *keys = [NSArray arrayWithObjects: @"beginTime", @"timeOffset",
                   @"repeatCount", @"repeatDuration", @"autoreverses",
                   @"fillMode", @"duration", @"speed", nil];
  NSString *k;

  printf("--- +defaultValueForKey: on %s ---\n", what);
  for (k in keys)
    {
      id v = [cls defaultValueForKey: k];

      printf("%-18s %s\n", [k UTF8String],
             v ? [[v description] UTF8String] : "(nil)");
    }
}

int main(int argc, char **argv)
{
  @autoreleasepool
    {
      printf("=== defaults ===\n");
      showTiming("CALayer", (id<CAMediaTiming>)[CALayer layer]);
      showTiming("CAAnimation", (id<CAMediaTiming>)[CAAnimation animation]);
      showTiming("CABasicAnimation",
                 (id<CAMediaTiming>)[CABasicAnimation animation]);
      showTiming("CAKeyframeAnimation",
                 (id<CAMediaTiming>)[CAKeyframeAnimation animation]);

      printf("\n=== class defaults ===\n");
      showDefaults("CALayer", [CALayer class]);
      showDefaults("CAAnimation", [CAAnimation class]);

      printf("\n=== round-trips on a layer ===\n");
      {
        CALayer *l = [CALayer layer];

        [l setBeginTime: 1.5];
        [l setTimeOffset: 0.25];
        [l setRepeatCount: 3.0];
        [l setRepeatDuration: 9.0];
        [l setAutoreverses: YES];
        [l setFillMode: kCAFillModeBoth];
        [l setDuration: 2.0];
        [l setSpeed: 0.5];
        showTiming("CALayer after setting each", (id<CAMediaTiming>)l);
      }

      printf("\n=== an infinite repeat count and duration ===\n");
      {
        CALayer *l = [CALayer layer];

        [l setRepeatCount: HUGE_VALF];
        printf("%-30s %g  isinf %d\n", "repeatCount HUGE_VALF",
               (double)[l repeatCount], (int)isinf([l repeatCount]));
        [l setDuration: 1.0 / 0.0];
        printf("%-30s %g  isinf %d\n", "duration inf",
               (double)[l duration], (int)isinf([l duration]));
      }

      printf("\n=== does a layer's fill mode reject an unknown string? ===\n");
      {
        CALayer *l = [CALayer layer];

        @try
          {
            [l setFillMode: @"nonsense"];
            printf("%-30s \"%s\"\n", "after setting nonsense",
                   [[l fillMode] UTF8String]);
          }
        @catch (NSException *e)
          {
            printf("%-30s RAISED %s\n", "setFillMode:nonsense",
                   [[e name] UTF8String]);
          }
      }

      printf("\n=== convertTime between layers ===\n");
      {
        CALayer *parent = [CALayer layer];
        CALayer *child = [CALayer layer];

        [parent addSublayer: child];
        [child setBeginTime: 1.0];
        [child setSpeed: 2.0];
        [child setTimeOffset: 0.5];
        printf("%-34s %g\n", "child convertTime:10 fromLayer:parent",
               (double)[child convertTime: 10.0 fromLayer: parent]);
        printf("%-34s %g\n", "child convertTime:10 toLayer:parent",
               (double)[child convertTime: 10.0 toLayer: parent]);
        printf("%-34s %g\n", "convertTime:10 fromLayer:nil",
               (double)[child convertTime: 10.0 fromLayer: nil]);
      }
    }
  return 0;
}

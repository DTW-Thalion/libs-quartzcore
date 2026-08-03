/* CAKeyframeAnimation's properties, their defaults, and the constants.

   Run on a macOS runner:
     clang -framework QuartzCore -framework CoreGraphics -framework Foundation \
       Tests/oracle/qc_keyframe_probe.m -o qc_keyframe_probe
*/

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

static void o(const char *what, id v)
{
  printf("%-38s %s\n", what, v ? [[v description] UTF8String] : "(nil)");
}

int main(int argc, char **argv)
{
  @autoreleasepool
    {
      CAKeyframeAnimation *k =
        [CAKeyframeAnimation animationWithKeyPath: @"opacity"];

      printf("--- the class ---\n");
      o("superclass", NSStringFromClass([CAKeyframeAnimation superclass]));

      printf("\n--- defaults ---\n");
      o("values", [k values]);
      o("keyTimes", [k keyTimes]);
      o("timingFunctions", [k timingFunctions]);
      o("calculationMode", [k calculationMode]);
      o("rotationMode", [k rotationMode]);
      printf("%-38s %s\n", "path", [k path] ? "not null" : "null");
      o("tensionValues", [k tensionValues]);
      o("continuityValues", [k continuityValues]);
      o("biasValues", [k biasValues]);
      printf("%-38s %g\n", "duration", (double)[k duration]);

      printf("\n--- what the class answers for ---\n");
      o("+defaultValueForKey: calculationMode",
        [CAKeyframeAnimation defaultValueForKey: @"calculationMode"]);
      o("+defaultValueForKey: values",
        [CAKeyframeAnimation defaultValueForKey: @"values"]);
      o("+defaultValueForKey: keyTimes",
        [CAKeyframeAnimation defaultValueForKey: @"keyTimes"]);
      o("+defaultValueForKey: rotationMode",
        [CAKeyframeAnimation defaultValueForKey: @"rotationMode"]);

      printf("\n--- the calculation modes ---\n");
      o("kCAAnimationLinear", kCAAnimationLinear);
      o("kCAAnimationDiscrete", kCAAnimationDiscrete);
      o("kCAAnimationPaced", kCAAnimationPaced);
      o("kCAAnimationCubic", kCAAnimationCubic);
      o("kCAAnimationCubicPaced", kCAAnimationCubicPaced);

      printf("\n--- the rotation modes ---\n");
      o("kCAAnimationRotateAuto", kCAAnimationRotateAuto);
      o("kCAAnimationRotateAutoReverse", kCAAnimationRotateAutoReverse);

      printf("\n--- setting values keeps them ---\n");
      {
        NSMutableArray *m = [NSMutableArray arrayWithObjects:
          [NSNumber numberWithFloat: 0.0],
          [NSNumber numberWithFloat: 1.0], nil];

        [k setValues: m];
        [m removeAllObjects];
        printf("%-38s %lu\n", "count after emptying the array",
               (unsigned long)[[k values] count]);
      }
      {
        [k setKeyTimes: [NSArray arrayWithObjects:
          [NSNumber numberWithFloat: 0.0],
          [NSNumber numberWithFloat: 1.0], nil]];
        printf("%-38s %lu\n", "keyTimes count",
               (unsigned long)[[k keyTimes] count]);
        [k setCalculationMode: kCAAnimationDiscrete];
        o("calculationMode after setting", [k calculationMode]);
        [k setCalculationMode: @"nonsense"];
        o("calculationMode set to nonsense", [k calculationMode]);
      }
    }
  return 0;
}

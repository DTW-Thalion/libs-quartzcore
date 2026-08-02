/* Probe the animation family against Apple's QuartzCore.

   Run on a macOS runner:
     clang -framework QuartzCore -framework CoreGraphics -framework Foundation \
       Tests/oracle/qc_animation_probe.m -o qc_animation_probe
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
      printf("=== CAAnimation ===\n");
      {
        CAAnimation *a = [CAAnimation animation];

        showObj("delegate", [a delegate]);
        showObj("timingFunction", [a timingFunction]);
        printf("%-40s %d\n", "removedOnCompletion",
               (int)[a isRemovedOnCompletion]);
      }

      printf("\n=== CAPropertyAnimation ===\n");
      {
        CAPropertyAnimation *p = [CAPropertyAnimation animation];

        showObj("keyPath", [p keyPath]);
        printf("%-40s %d\n", "additive", (int)[p isAdditive]);
        printf("%-40s %d\n", "cumulative", (int)[p isCumulative]);
        showObj("valueFunction", [p valueFunction]);

        CAPropertyAnimation *k =
          [CAPropertyAnimation animationWithKeyPath: @"opacity"];
        showObj("animationWithKeyPath: keyPath", [k keyPath]);
        printf("%-40s %s\n", "animationWithKeyPath: class",
               [[k className] UTF8String]);
      }

      printf("\n=== CABasicAnimation ===\n");
      {
        CABasicAnimation *b = [CABasicAnimation animation];

        showObj("fromValue", [b fromValue]);
        showObj("toValue", [b toValue]);
        showObj("byValue", [b byValue]);
        showObj("keyPath", [b keyPath]);
        printf("%-40s %g\n", "duration", (double)[b duration]);
      }

      printf("\n=== CAKeyframeAnimation ===\n");
      {
        CAKeyframeAnimation *k = [CAKeyframeAnimation animation];

        showObj("calculationMode", [k calculationMode]);
        showObj("values", [k values]);
        showObj("keyTimes", [k keyTimes]);
        showObj("timingFunctions", [k timingFunctions]);
        showObj("path", (id)[k path]);
        showObj("rotationMode", [k rotationMode]);
      }

      printf("\n=== CASpringAnimation ===\n");
      {
        CASpringAnimation *s = [CASpringAnimation animation];

        printf("%-40s %g\n", "mass", (double)[s mass]);
        printf("%-40s %g\n", "stiffness", (double)[s stiffness]);
        printf("%-40s %g\n", "damping", (double)[s damping]);
        printf("%-40s %g\n", "initialVelocity", (double)[s initialVelocity]);
        printf("%-40s %g\n", "settlingDuration",
               (double)[s settlingDuration]);
        printf("%-40s %g\n", "duration", (double)[s duration]);
      }

      printf("\n=== the delegate is retained ===\n");
      {
        NSObject *d = [[NSObject alloc] init];
        CAAnimation *a = [CAAnimation animation];

        printf("%-40s %lu\n", "delegate retain count before",
               (unsigned long)[d retainCount]);
        [a setDelegate: d];
        printf("%-40s %lu\n", "delegate retain count after",
               (unsigned long)[d retainCount]);
        [a setDelegate: nil];
        printf("%-40s %lu\n", "after setting it back to nil",
               (unsigned long)[d retainCount]);
        [d release];
      }

      printf("\n=== copying an animation ===\n");
      {
        CABasicAnimation *b = [CABasicAnimation animation];
        CABasicAnimation *c;

        [b setKeyPath: @"position"];
        [b setDuration: 3.0];
        [b setToValue: [NSNumber numberWithInt: 7]];
        [b setRepeatCount: 2.0];
        c = [b copy];
        showObj("copy keyPath", [c keyPath]);
        printf("%-40s %g\n", "copy duration", (double)[c duration]);
        showObj("copy toValue", [c toValue]);
        printf("%-40s %g\n", "copy repeatCount", (double)[c repeatCount]);
        printf("%-40s %s\n", "copy is a distinct object",
               c == b ? "NO" : "YES");
        [c release];
      }

      printf("\n=== archiving an animation ===\n");
      {
        CABasicAnimation *b = [CABasicAnimation animation];
        NSData *d;

        [b setKeyPath: @"position"];
        [b setDuration: 3.0];
        @try
          {
            d = [NSKeyedArchiver archivedDataWithRootObject: b
                                      requiringSecureCoding: NO
                                                      error: NULL];
            printf("%-40s %lu bytes\n", "archived", (unsigned long)[d length]);
            {
              CABasicAnimation *r = [NSKeyedUnarchiver
                unarchivedObjectOfClass: [CABasicAnimation class]
                               fromData: d
                                  error: NULL];
              showObj("unarchived keyPath", [r keyPath]);
              printf("%-40s %g\n", "unarchived duration",
                     (double)[r duration]);
            }
          }
        @catch (NSException *e)
          {
            printf("%-40s RAISED %s\n", "archiving", [[e name] UTF8String]);
          }
      }
    }
  return 0;
}

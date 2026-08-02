/* What a nil layer means to -convertTime:fromLayer: and -convertTime:toLayer:.
   A three-deep tree tells a root from an immediate parent, which a two-deep
   one cannot.

   Run on a macOS runner:
     clang -framework QuartzCore -framework CoreGraphics -framework Foundation \
       Tests/oracle/qc_converttime_probe.m -o qc_converttime_probe
*/

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

int main(int argc, char **argv)
{
  @autoreleasepool
    {
      CALayer *root = [CALayer layer];
      CALayer *mid = [CALayer layer];
      CALayer *leaf = [CALayer layer];

      [root addSublayer: mid];
      [mid addSublayer: leaf];

      [mid setBeginTime: 2.0];
      [mid setSpeed: 3.0];
      [mid setTimeOffset: 0.25];

      [leaf setBeginTime: 1.0];
      [leaf setSpeed: 2.0];
      [leaf setTimeOffset: 0.5];

      printf("root has a superlayer: %s\n",
             [root superlayer] ? "YES" : "NO");
      printf("%-38s %g\n", "leaf convertTime:10 fromLayer:mid",
             (double)[leaf convertTime: 10.0 fromLayer: mid]);
      printf("%-38s %g\n", "leaf convertTime:10 fromLayer:root",
             (double)[leaf convertTime: 10.0 fromLayer: root]);
      printf("%-38s %g\n", "leaf convertTime:10 fromLayer:nil",
             (double)[leaf convertTime: 10.0 fromLayer: nil]);
      printf("%-38s %g\n", "leaf convertTime:10 toLayer:mid",
             (double)[leaf convertTime: 10.0 toLayer: mid]);
      printf("%-38s %g\n", "leaf convertTime:10 toLayer:root",
             (double)[leaf convertTime: 10.0 toLayer: root]);
      printf("%-38s %g\n", "leaf convertTime:10 toLayer:nil",
             (double)[leaf convertTime: 10.0 toLayer: nil]);

      printf("\n--- an unrelated layer, in no tree ---\n");
      {
        CALayer *stranger = [CALayer layer];

        [stranger setBeginTime: 5.0];
        printf("%-38s %g\n", "leaf convertTime:10 fromLayer:stranger",
               (double)[leaf convertTime: 10.0 fromLayer: stranger]);
      }

      printf("\n--- the same leaf detached from any tree ---\n");
      {
        CALayer *lone = [CALayer layer];

        [lone setBeginTime: 1.0];
        [lone setSpeed: 2.0];
        [lone setTimeOffset: 0.5];
        printf("%-38s %g\n", "lone convertTime:10 fromLayer:nil",
               (double)[lone convertTime: 10.0 fromLayer: nil]);
      }
    }
  return 0;
}

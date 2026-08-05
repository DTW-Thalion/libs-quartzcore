/* What class is a presentation layer, and when does one exist at all?  The
   recorded ground truth says presentationLayer is nil before display; this
   asks what comes back afterwards, and whether a subclass keeps its class and
   its own properties in the copy.

   Run on a macOS runner:
     clang -framework QuartzCore -framework CoreGraphics -framework Foundation \
       Tests/oracle/qc_presentation_probe.m -o qc_presentation_probe
*/

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>

static void report(const char *what, CALayer *layer)
{
  CALayer *presentation = [layer presentationLayer];

  printf("%-44s %s\n", what,
         presentation == nil ? "(nil)"
                             : [NSStringFromClass([presentation class])
                                 UTF8String]);
}

int main(void)
{
  @autoreleasepool
    {
      printf("=== before anything is done to them ===\n");
      report("CALayer", [CALayer layer]);
      report("CAShapeLayer", [CAShapeLayer layer]);
      report("CAGradientLayer", [CAGradientLayer layer]);
      report("CATextLayer", [CATextLayer layer]);
      report("CAReplicatorLayer", [CAReplicatorLayer layer]);

      printf("\n=== after -display ===\n");
      {
        CAShapeLayer *shape = [CAShapeLayer layer];

        [shape setBounds: CGRectMake(0, 0, 40, 30)];
        [shape display];
        report("CAShapeLayer displayed", shape);
      }

      printf("\n=== inside a tree, with an animation running ===\n");
      {
        CALayer *root = [CALayer layer];
        CAShapeLayer *shape = [CAShapeLayer layer];
        CABasicAnimation *animation =
          [CABasicAnimation animationWithKeyPath: @"opacity"];

        [root setBounds: CGRectMake(0, 0, 100, 100)];
        [shape setBounds: CGRectMake(0, 0, 40, 30)];
        [root addSublayer: shape];

        [animation setFromValue: [NSNumber numberWithFloat: 1.0]];
        [animation setToValue: [NSNumber numberWithFloat: 0.0]];
        [animation setDuration: 10.0];
        [shape addAnimation: animation forKey: @"fade"];
        report("CAShapeLayer animating in a tree", shape);

        [shape display];
        report("the same after -display", shape);
      }

      printf("\n=== what -initWithLayer: copies ===\n");
      {
        CAShapeLayer *shape = [CAShapeLayer layer];
        CGColorRef red = CGColorCreateGenericRGB(1, 0, 0, 1);
        CGMutablePathRef path = CGPathCreateMutable();
        CAShapeLayer *copy;

        CGPathAddRect(path, NULL, CGRectMake(0, 0, 10, 10));
        [shape setBounds: CGRectMake(0, 0, 40, 30)];
        [shape setPath: path];
        [shape setFillColor: red];
        [shape setLineWidth: 7];

        copy = [[CAShapeLayer alloc] initWithLayer: shape];
        printf("%-44s %s\n", "the copy's class",
               [NSStringFromClass([copy class]) UTF8String]);
        printf("%-44s %g %g\n", "its bounds size",
               (double)[copy bounds].size.width,
               (double)[copy bounds].size.height);
        printf("%-44s %s\n", "its path", [copy path] ? "set" : "(null)");
        printf("%-44s %s\n", "its fill colour",
               [copy fillColor] ? "set" : "(null)");
        printf("%-44s %g\n", "its line width", (double)[copy lineWidth]);
        printf("%-44s %s\n", "modelLayer of the copy",
               [copy modelLayer] == shape ? "the layer it came from"
                                          : "something else");

        [copy release];
        CGPathRelease(path);
        CGColorRelease(red);
      }
    }
  return 0;
}

/* Does a CAShapeLayer's dash pattern reach the sublayers drawn after it?

   Run on a macOS runner:
     clang -framework QuartzCore -framework CoreGraphics -framework Foundation \
       Tests/oracle/qc_dash_probe.m -o qc_dash_probe
*/

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>

#define W 100
#define H 100

static CGContextRef newContext(void)
{
  CGColorSpaceRef space = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
  CGContextRef c = CGBitmapContextCreate(NULL, W, H, 8, W * 4, space,
                                         kCGImageAlphaPremultipliedLast);
  CGColorSpaceRelease(space);
  memset(CGBitmapContextGetData(c), 0, W * H * 4);
  return c;
}

static int painted(CGContextRef c, const char *what)
{
  unsigned char *d = CGBitmapContextGetData(c);
  int x, y, n = 0;

  for (y = 0; y < H; y++)
    for (x = 0; x < W; x++)
      {
        unsigned char *p = d + (y * W + x) * 4;

        if (p[0] || p[1] || p[2] || p[3])
          n++;
      }
  printf("%-46s %d points\n", what, n);
  return n;
}

static CGPathRef rectPath(void)
{
  CGMutablePathRef p = CGPathCreateMutable();

  CGPathAddRect(p, NULL, CGRectMake(10, 10, 40, 30));
  return p;
}

static CAShapeLayer *stroked(CGPathRef path, CGColorRef colour)
{
  CAShapeLayer *s = [CAShapeLayer layer];

  [s setBounds: CGRectMake(0, 0, 80, 60)];
  [s setPath: path];
  [s setFillColor: NULL];
  [s setStrokeColor: colour];
  [s setLineWidth: 4];
  return s;
}

static NSArray *sixOnSixOff(void)
{
  return [NSArray arrayWithObjects: [NSNumber numberWithFloat: 6],
                                    [NSNumber numberWithFloat: 6], nil];
}

int main(void)
{
  @autoreleasepool
    {
      CGPathRef path = rectPath();
      CGColorRef blue = CGColorCreateGenericRGB(0, 0, 1, 1);
      int solid, dashed, both;

      {
        CGContextRef c = newContext();

        [stroked(path, blue) renderInContext: c];
        solid = painted(c, "a solid stroke alone");
        CGContextRelease(c);
      }
      {
        CGContextRef c = newContext();
        CAShapeLayer *s = stroked(path, blue);

        [s setLineDashPattern: sixOnSixOff()];
        [s renderInContext: c];
        dashed = painted(c, "a dashed stroke alone");
        CGContextRelease(c);
      }
      {
        CGContextRef c = newContext();
        CAShapeLayer *parent = stroked(path, blue);
        CAShapeLayer *child = stroked(path, blue);

        [parent setLineDashPattern: sixOnSixOff()];
        [child setPosition: CGPointMake(40, 30)];
        [parent addSublayer: child];
        [parent renderInContext: c];
        both = painted(c, "a dashed layer holding a solid sublayer");
        CGContextRelease(c);
      }

      printf("solid %d, dashed %d, together %d\n", solid, dashed, both);
      printf("the dash %s the sublayer\n",
             both == solid ? "does NOT reach" : "REACHES");

      /* And the other way round: a solid parent holding a dashed child. */
      {
        CGContextRef c = newContext();
        CAShapeLayer *parent = stroked(path, blue);
        CAShapeLayer *child = stroked(path, blue);

        [child setLineDashPattern: sixOnSixOff()];
        [child setPosition: CGPointMake(40, 30)];
        [parent addSublayer: child];
        [parent renderInContext: c];
        painted(c, "a solid layer holding a dashed sublayer");
        CGContextRelease(c);
      }

      CGColorRelease(blue);
      CGPathRelease(path);
    }
  return 0;
}

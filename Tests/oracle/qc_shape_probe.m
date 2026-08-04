/* What a CAShapeLayer actually draws through -renderInContext:.
   The layer is 80x60 at the context origin and the path is a rectangle
   (10,10,40,30) in the layer's own coordinates. */
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#include <stdio.h>
#include <string.h>

#define SIDE 100

static CGContextRef newContext(void)
{
  CGColorSpaceRef space = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
  CGContextRef c = CGBitmapContextCreate(NULL, SIDE, SIDE, 8, SIDE * 4, space,
                                         kCGImageAlphaPremultipliedLast);
  CGColorSpaceRelease(space);
  if (c)
    memset(CGBitmapContextGetData(c), 0, SIDE * SIDE * 4);
  return c;
}

static int painted(CGContextRef c, int x, int y)
{
  unsigned char *data = CGBitmapContextGetData(c);
  unsigned char *p = data + ((SIDE - 1 - y) * SIDE + x) * 4;
  return p[0] || p[1] || p[2] || p[3];
}

static void box(CGContextRef c, const char *label)
{
  int x, y, minX = SIDE, minY = SIDE, maxX = -1, maxY = -1, n = 0;

  for (y = 0; y < SIDE; y++)
    for (x = 0; x < SIDE; x++)
      if (painted(c, x, y))
        {
          n++;
          if (x < minX) minX = x;
          if (y < minY) minY = y;
          if (x > maxX) maxX = x;
          if (y > maxY) maxY = y;
        }
  if (maxX < 0)
    printf("  %-40s nothing drawn\n", label);
  else
    printf("  %-40s x %2d..%-2d y %2d..%-2d count %d\n", label,
           minX, maxX, minY, maxY, n);
}

static CGPathRef rectPath(CGRect r)
{
  CGMutablePathRef p = CGPathCreateMutable();
  CGPathAddRect(p, NULL, r);
  return p;
}

static CAShapeLayer *shape(CGPathRef path)
{
  CAShapeLayer *s = [CAShapeLayer layer];
  [s setBounds: CGRectMake(0, 0, 80, 60)];
  [s setPath: path];
  return s;
}

int main(void)
{
  @autoreleasepool {
    CGPathRef path = rectPath(CGRectMake(10, 10, 40, 30));
    CGColorRef blue = CGColorCreateGenericRGB(0, 0, 1, 1);

    printf("=== does renderInContext draw a shape layer at all? ===\n");
    {
      CGContextRef c = newContext();
      CAShapeLayer *s = shape(path);
      [s renderInContext: c];
      box(c, "default fill (opaque black), no stroke");
      CGContextRelease(c);
    }

    printf("\n=== no fill colour ===\n");
    {
      CGContextRef c = newContext();
      CAShapeLayer *s = shape(path);
      [s setFillColor: NULL];
      [s renderInContext: c];
      box(c, "fillColor NULL");
      CGContextRelease(c);
    }

    printf("\n=== stroke only, width 4 ===\n");
    {
      CGContextRef c = newContext();
      CAShapeLayer *s = shape(path);
      [s setFillColor: NULL];
      [s setStrokeColor: blue];
      [s setLineWidth: 4];
      [s renderInContext: c];
      box(c, "stroke 4, no fill");
      CGContextRelease(c);
    }

    printf("\n=== stroke width 1, the default ===\n");
    {
      CGContextRef c = newContext();
      CAShapeLayer *s = shape(path);
      [s setFillColor: NULL];
      [s setStrokeColor: blue];
      [s renderInContext: c];
      box(c, "stroke at the default width");
      CGContextRelease(c);
    }

    printf("\n=== strokeEnd 0.5 ===\n");
    {
      CGContextRef c = newContext();
      CAShapeLayer *s = shape(path);
      [s setFillColor: NULL];
      [s setStrokeColor: blue];
      [s setLineWidth: 4];
      [s setStrokeEnd: 0.5];
      [s renderInContext: c];
      box(c, "strokeEnd 0.5");
      CGContextRelease(c);
    }

    printf("\n=== a dash pattern ===\n");
    {
      CGContextRef c = newContext();
      CAShapeLayer *s = shape(path);
      [s setFillColor: NULL];
      [s setStrokeColor: blue];
      [s setLineWidth: 4];
      [s setLineDashPattern: [NSArray arrayWithObjects:
                               [NSNumber numberWithInt: 6],
                               [NSNumber numberWithInt: 6], nil]];
      [s renderInContext: c];
      box(c, "dashed 6 on 6 off");
      CGContextRelease(c);
    }

    printf("\n=== a path that runs outside the bounds ===\n");
    {
      CGPathRef big = rectPath(CGRectMake(60, 40, 30, 30));
      CGContextRef c = newContext();
      CAShapeLayer *s = shape(big);
      [s renderInContext: c];
      box(c, "path (60,40,30,30) in bounds 80x60");
      CGContextRelease(c);

      c = newContext();
      CAShapeLayer *m = shape(big);
      [m setMasksToBounds: YES];
      [m renderInContext: c];
      box(c, "the same, masksToBounds YES");
      CGContextRelease(c);
      CGPathRelease(big);
    }

    printf("\n=== fill and stroke together ===\n");
    {
      CGContextRef c = newContext();
      CAShapeLayer *s = shape(path);
      [s setStrokeColor: blue];
      [s setLineWidth: 4];
      [s renderInContext: c];
      box(c, "filled and stroked");
      CGContextRelease(c);
    }

    printf("\n=== no path at all ===\n");
    {
      CGContextRef c = newContext();
      CAShapeLayer *s = [CAShapeLayer layer];
      [s setBounds: CGRectMake(0, 0, 80, 60)];
      [s renderInContext: c];
      box(c, "path NULL");
      CGContextRelease(c);
    }

    printf("\n=== does a background colour still draw under it? ===\n");
    {
      CGContextRef c = newContext();
      CAShapeLayer *s = shape(path);
      CGColorRef red = CGColorCreateGenericRGB(1, 0, 0, 1);
      [s setBackgroundColor: red];
      [s renderInContext: c];
      box(c, "shape with a background colour");
      CGColorRelease(red);
      CGContextRelease(c);
    }

    CGColorRelease(blue);
    CGPathRelease(path);
  }
  return 0;
}

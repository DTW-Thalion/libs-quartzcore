/* Where a subclass's own drawing sits against the contents and the border.
   Each layer is 80x60 at the context origin. */
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

static void sample(CGContextRef c, int x, int y, const char *label)
{
  unsigned char *data = CGBitmapContextGetData(c);
  unsigned char *p = data + ((SIDE - 1 - y) * SIDE + x) * 4;

  printf("  %-38s (%2d,%2d) r %3d g %3d b %3d a %3d\n",
         label, x, y, p[0], p[1], p[2], p[3]);
}

static CGImageRef greenImage(int w, int h)
{
  CGColorSpaceRef space = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
  CGContextRef c = CGBitmapContextCreate(NULL, w, h, 8, w * 4, space,
                                         kCGImageAlphaPremultipliedLast);
  CGColorRef green = CGColorCreateGenericRGB(0, 1, 0, 1);
  CGImageRef image;

  CGColorSpaceRelease(space);
  memset(CGBitmapContextGetData(c), 0, w * h * 4);
  CGContextSetFillColorWithColor(c, green);
  CGContextFillRect(c, CGRectMake(0, 0, w, h));
  image = CGBitmapContextCreateImage(c);
  CGColorRelease(green);
  CGContextRelease(c);
  return image;
}

int main(void)
{
  @autoreleasepool {
    CGColorRef red = CGColorCreateGenericRGB(1, 0, 0, 1);
    CGColorRef blue = CGColorCreateGenericRGB(0, 0, 1, 1);
    CGImageRef image = greenImage(20, 10);

    printf("=== a shape layer with contents as well ===\n");
    {
      CGMutablePathRef path = CGPathCreateMutable();
      CGContextRef c = newContext();
      CAShapeLayer *s = [CAShapeLayer layer];

      CGPathAddRect(path, NULL, CGRectMake(10, 10, 60, 40));
      [s setBounds: CGRectMake(0, 0, 80, 60)];
      [s setPath: path];
      [s setFillColor: red];
      [s setContents: (id)image];
      [s setContentsGravity: kCAGravityCenter];
      [s renderInContext: c];
      sample(c, 40, 30, "over the contents, which are green");
      sample(c, 15, 15, "the fill away from the contents");
      CGContextRelease(c);
      CGPathRelease(path);
    }

    printf("\n=== a gradient layer with a border ===\n");
    {
      CGContextRef c = newContext();
      CAGradientLayer *g = [CAGradientLayer layer];

      [g setBounds: CGRectMake(0, 0, 80, 60)];
      [g setColors: [NSArray arrayWithObjects: (id)red, (id)blue, nil]];
      [g setBorderWidth: 6];
      [g setBorderColor: [[NSColor greenColor] CGColor]];
      [g renderInContext: c];
      sample(c, 2, 30, "on the border");
      sample(c, 40, 30, "inside it");
      CGContextRelease(c);
    }

    printf("\n=== a shape layer with a border ===\n");
    {
      CGMutablePathRef path = CGPathCreateMutable();
      CGContextRef c = newContext();
      CAShapeLayer *s = [CAShapeLayer layer];

      CGPathAddRect(path, NULL, CGRectMake(0, 0, 80, 60));
      [s setBounds: CGRectMake(0, 0, 80, 60)];
      [s setPath: path];
      [s setFillColor: red];
      [s setBorderWidth: 6];
      [s setBorderColor: [[NSColor greenColor] CGColor]];
      [s renderInContext: c];
      sample(c, 2, 30, "on the border");
      sample(c, 40, 30, "inside it");
      CGContextRelease(c);
      CGPathRelease(path);
    }

    CGImageRelease(image);
    CGColorRelease(red);
    CGColorRelease(blue);
  }
  return 0;
}

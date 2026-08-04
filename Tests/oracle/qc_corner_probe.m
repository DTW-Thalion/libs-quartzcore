/* What -renderInContext: does with cornerRadius, borderWidth and borderColor.
   The layer is 80x60 at the context origin, so its corners are at (0,0),
   (79,0), (0,59) and (79,59). */
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

static unsigned char *at(CGContextRef c, int x, int y)
{
  unsigned char *data = CGBitmapContextGetData(c);
  return data + ((SIDE - 1 - y) * SIDE + x) * 4;
}

static int painted(CGContextRef c, int x, int y)
{
  unsigned char *p = at(c, x, y);
  return p[0] || p[1] || p[2] || p[3];
}

static int paintedCount(CGContextRef c)
{
  int x, y, n = 0;
  for (y = 0; y < SIDE; y++)
    for (x = 0; x < SIDE; x++)
      if (painted(c, x, y))
        n++;
  return n;
}

static void show(CGContextRef c, const char *label)
{
  printf("  %-34s count %4d; corner(0,0) %d (1,1) %d (3,3) %d; "
         "mid-left(0,30) %d; centre(40,30) %d\n",
         label, paintedCount(c), painted(c, 0, 0), painted(c, 1, 1),
         painted(c, 3, 3), painted(c, 0, 30), painted(c, 40, 30));
}

static void pixel(CGContextRef c, int x, int y, const char *label)
{
  unsigned char *p = at(c, x, y);
  printf("  %-26s (%2d,%2d) = %3d %3d %3d %3d\n", label, x, y,
         p[0], p[1], p[2], p[3]);
}

int main(void)
{
  @autoreleasepool {
    CGColorRef red = CGColorCreateGenericRGB(1, 0, 0, 1);
    CGColorRef blue = CGColorCreateGenericRGB(0, 0, 1, 1);

    printf("=== background only, no radius, no border ===\n");
    {
      CGContextRef c = newContext();
      CALayer *l = [CALayer layer];
      [l setBounds: CGRectMake(0, 0, 80, 60)];
      [l setBackgroundColor: red];
      [l renderInContext: c];
      show(c, "plain");
      CGContextRelease(c);
    }

    printf("\n=== cornerRadius 20 ===\n");
    {
      CGContextRef c = newContext();
      CALayer *l = [CALayer layer];
      [l setBounds: CGRectMake(0, 0, 80, 60)];
      [l setBackgroundColor: red];
      [l setCornerRadius: 20];
      [l renderInContext: c];
      show(c, "radius 20");
      CGContextRelease(c);
    }

    printf("\n=== borderWidth 5, borderColor blue, no radius ===\n");
    {
      CGContextRef c = newContext();
      CALayer *l = [CALayer layer];
      [l setBounds: CGRectMake(0, 0, 80, 60)];
      [l setBackgroundColor: red];
      [l setBorderWidth: 5];
      [l setBorderColor: blue];
      [l renderInContext: c];
      show(c, "border 5");
      pixel(c, 2, 30, "inside the border");
      pixel(c, 10, 30, "inside the fill");
      pixel(c, 40, 30, "centre");
      CGContextRelease(c);
    }

    printf("\n=== border with no background at all ===\n");
    {
      CGContextRef c = newContext();
      CALayer *l = [CALayer layer];
      [l setBounds: CGRectMake(0, 0, 80, 60)];
      [l setBorderWidth: 5];
      [l setBorderColor: blue];
      [l renderInContext: c];
      show(c, "border only");
      pixel(c, 2, 30, "on the border");
      pixel(c, 40, 30, "in the middle");
      CGContextRelease(c);
    }

    printf("\n=== border 5 and radius 20 together ===\n");
    {
      CGContextRef c = newContext();
      CALayer *l = [CALayer layer];
      [l setBounds: CGRectMake(0, 0, 80, 60)];
      [l setBackgroundColor: red];
      [l setBorderWidth: 5];
      [l setBorderColor: blue];
      [l setCornerRadius: 20];
      [l renderInContext: c];
      show(c, "both");
      CGContextRelease(c);
    }

    printf("\n=== does the radius clip a sublayer? ===\n");
    {
      CGContextRef c = newContext();
      CALayer *l = [CALayer layer];
      CALayer *k = [CALayer layer];
      [l setBounds: CGRectMake(0, 0, 80, 60)];
      [l setCornerRadius: 20];
      [k setFrame: CGRectMake(0, 0, 10, 10)];
      [k setBackgroundColor: red];
      [l addSublayer: k];
      [l renderInContext: c];
      show(c, "sublayer in the corner, no mask");
      CGContextRelease(c);

      c = newContext();
      [l setMasksToBounds: YES];
      [l renderInContext: c];
      show(c, "the same, masksToBounds YES");
      CGContextRelease(c);
    }

    printf("\n=== a radius larger than half the shorter side ===\n");
    {
      CGContextRef c = newContext();
      CALayer *l = [CALayer layer];
      [l setBounds: CGRectMake(0, 0, 80, 60)];
      [l setBackgroundColor: red];
      [l setCornerRadius: 100];
      [l renderInContext: c];
      show(c, "radius 100 on 80x60");
      printf("  cornerRadius reads back as %g\n", (double)[l cornerRadius]);
      CGContextRelease(c);
    }

    printf("\n=== a negative radius and a negative width ===\n");
    {
      CALayer *l = [CALayer layer];
      [l setCornerRadius: -5];
      printf("  cornerRadius after -5 = %g\n", (double)[l cornerRadius]);
      [l setBorderWidth: -5];
      printf("  borderWidth after -5 = %g\n", (double)[l borderWidth]);
    }

    printf("\n=== defaults ===\n");
    {
      CALayer *l = [CALayer layer];
      printf("  cornerRadius %g, borderWidth %g, borderColor %s\n",
             (double)[l cornerRadius], (double)[l borderWidth],
             [l borderColor] ? "non-nil" : "nil");
    }

    CGColorRelease(red);
    CGColorRelease(blue);
  }
  return 0;
}

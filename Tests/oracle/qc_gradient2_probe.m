/* Radial and conic geometry for CAGradientLayer, and where the gradient
   sits against the contents.  The layer is 80x60 at the context origin,
   red to blue.  Pixel y counts up from the bottom. */
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

static unsigned char *pixel(CGContextRef c, int x, int y)
{
  unsigned char *data = CGBitmapContextGetData(c);
  return data + ((SIDE - 1 - y) * SIDE + x) * 4;
}

static int painted(CGContextRef c, int x, int y)
{
  unsigned char *p = pixel(c, x, y);
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
    printf("  %-38s nothing drawn\n", label);
  else
    printf("  %-38s x %2d..%-2d y %2d..%-2d count %d\n", label,
           minX, maxX, minY, maxY, n);
}

static void sample(CGContextRef c, int x, int y, const char *label)
{
  unsigned char *p = pixel(c, x, y);

  printf("  %-38s (%2d,%2d) r %3d g %3d b %3d a %3d\n",
         label, x, y, p[0], p[1], p[2], p[3]);
}

static CAGradientLayer *gradient(NSArray *colors)
{
  CAGradientLayer *g = [CAGradientLayer layer];

  [g setBounds: CGRectMake(0, 0, 80, 60)];
  [g setColors: colors];
  return g;
}

/* The four points around the middle and the middle itself. */
static void compass(CGContextRef c)
{
  sample(c, 40, 30, "centre");
  sample(c, 77, 30, "right");
  sample(c, 40, 57, "top");
  sample(c, 2, 30, "left");
  sample(c, 40, 2, "bottom");
}

int main(void)
{
  @autoreleasepool {
    CGColorRef red = CGColorCreateGenericRGB(1, 0, 0, 1);
    CGColorRef blue = CGColorCreateGenericRGB(0, 0, 1, 1);
    NSArray *twoColors = [NSArray arrayWithObjects: (id)red, (id)blue, nil];

    printf("=== radial: which points make it draw ===\n");
    {
      struct { CGPoint s; CGPoint e; const char *label; } cases[] = {
        {{0.5, 0.0}, {0.5, 1.0}, "start (0.5,0) end (0.5,1), the default"},
        {{0.5, 0.5}, {0.5, 1.0}, "centre to the top edge"},
        {{0.5, 0.5}, {1.0, 1.0}, "centre to the corner"},
        {{0.5, 0.5}, {1.0, 0.5}, "centre to the right edge"},
        {{0.0, 0.0}, {1.0, 1.0}, "corner to corner"},
        {{0.5, 0.5}, {0.5, 0.5}, "centre to itself"},
      };
      int i;

      for (i = 0; i < 6; i++)
        {
          CGContextRef c = newContext();
          CAGradientLayer *g = gradient(twoColors);

          [g setType: kCAGradientLayerRadial];
          [g setStartPoint: cases[i].s];
          [g setEndPoint: cases[i].e];
          [g renderInContext: c];
          box(c, cases[i].label);
          CGContextRelease(c);
        }
    }

    printf("\n=== radial, centre to the corner, sampled ===\n");
    {
      CGContextRef c = newContext();
      CAGradientLayer *g = gradient(twoColors);

      [g setType: kCAGradientLayerRadial];
      [g setStartPoint: CGPointMake(0.5, 0.5)];
      [g setEndPoint: CGPointMake(1.0, 1.0)];
      [g renderInContext: c];
      compass(c);
      sample(c, 60, 45, "half way to the corner");
      CGContextRelease(c);
    }

    printf("\n=== conic geometry, default points ===\n");
    {
      CGContextRef c = newContext();
      CAGradientLayer *g = gradient(twoColors);

      [g setType: kCAGradientLayerConic];
      [g renderInContext: c];
      compass(c);
      CGContextRelease(c);
    }

    printf("\n=== conic, centre to the right edge ===\n");
    {
      CGContextRef c = newContext();
      CAGradientLayer *g = gradient(twoColors);

      [g setType: kCAGradientLayerConic];
      [g setStartPoint: CGPointMake(0.5, 0.5)];
      [g setEndPoint: CGPointMake(1.0, 0.5)];
      [g renderInContext: c];
      compass(c);
      CGContextRelease(c);
    }

    printf("\n=== axial oddities ===\n");
    {
      CGContextRef c = newContext();
      CAGradientLayer *g = gradient(twoColors);

      [g setLocations: [NSArray arrayWithObjects:
                          [NSNumber numberWithFloat: 0.5],
                          [NSNumber numberWithFloat: 0.5], nil]];
      [g renderInContext: c];
      box(c, "both colours at 0.5, a hard stop");
      sample(c, 40, 25, "just below the middle");
      sample(c, 40, 35, "just above it");
      CGContextRelease(c);

      c = newContext();
      g = gradient(twoColors);
      [g setLocations: [NSArray arrayWithObjects:
                          [NSNumber numberWithFloat: 0.8],
                          [NSNumber numberWithFloat: 0.2], nil]];
      [g renderInContext: c];
      box(c, "locations out of order");
      sample(c, 40, 2, "bottom");
      sample(c, 40, 57, "top");
      CGContextRelease(c);

      c = newContext();
      g = gradient(twoColors);
      [g setStartPoint: CGPointMake(0.5, 1.0)];
      [g setEndPoint: CGPointMake(0.5, 0.0)];
      [g renderInContext: c];
      box(c, "start above end");
      sample(c, 40, 2, "bottom");
      sample(c, 40, 57, "top");
      CGContextRelease(c);
    }

    printf("\n=== the gradient against the contents ===\n");
    {
      CGColorSpaceRef space
        = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
      CGContextRef ic = CGBitmapContextCreate(NULL, 20, 10, 8, 20 * 4, space,
                                              kCGImageAlphaPremultipliedLast);
      CGColorRef greenColor = CGColorCreateGenericRGB(0, 1, 0, 1);
      CGImageRef image;
      CGContextRef c;
      CAGradientLayer *g;

      CGColorSpaceRelease(space);
      memset(CGBitmapContextGetData(ic), 0, 20 * 10 * 4);
      CGContextSetFillColorWithColor(ic, greenColor);
      CGContextFillRect(ic, CGRectMake(0, 0, 20, 10));
      image = CGBitmapContextCreateImage(ic);

      c = newContext();
      g = gradient(twoColors);
      [g setContents: (id)image];
      [g setContentsGravity: kCAGravityCenter];
      [g renderInContext: c];
      box(c, "a gradient with contents as well");
      sample(c, 40, 30, "where the contents are");
      sample(c, 5, 30, "where they are not");

      CGImageRelease(image);
      CGColorRelease(greenColor);
      CGContextRelease(ic);
      CGContextRelease(c);
    }

    CGColorRelease(red);
    CGColorRelease(blue);
  }
  return 0;
}

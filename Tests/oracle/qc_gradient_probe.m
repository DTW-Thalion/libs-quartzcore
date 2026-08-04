/* What a CAGradientLayer actually draws through -renderInContext:.
   The layer is 80x60 at the context origin, red to blue unless said
   otherwise.  Pixel y counts up from the bottom, the way layer geometry
   does. */
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
    printf("  %-34s nothing drawn\n", label);
  else
    printf("  %-34s x %2d..%-2d y %2d..%-2d count %d\n", label,
           minX, maxX, minY, maxY, n);
}

static void sample(CGContextRef c, int x, int y, const char *label)
{
  unsigned char *p = pixel(c, x, y);

  printf("  %-34s (%2d,%2d) r %3d g %3d b %3d a %3d\n",
         label, x, y, p[0], p[1], p[2], p[3]);
}

/* The three points down the middle, and the three across it. */
static void down(CGContextRef c)
{
  sample(c, 40, 2, "bottom");
  sample(c, 40, 30, "middle");
  sample(c, 40, 57, "top");
}

static void across(CGContextRef c)
{
  sample(c, 2, 30, "left");
  sample(c, 40, 30, "centre");
  sample(c, 77, 30, "right");
}

static CAGradientLayer *gradient(NSArray *colors)
{
  CAGradientLayer *g = [CAGradientLayer layer];

  [g setBounds: CGRectMake(0, 0, 80, 60)];
  [g setColors: colors];
  return g;
}

int main(void)
{
  @autoreleasepool {
    CGColorRef red = CGColorCreateGenericRGB(1, 0, 0, 1);
    CGColorRef blue = CGColorCreateGenericRGB(0, 0, 1, 1);
    CGColorRef green = CGColorCreateGenericRGB(0, 1, 0, 1);
    NSArray *twoColors = [NSArray arrayWithObjects: (id)red, (id)blue, nil];
    NSArray *threeColors = [NSArray arrayWithObjects: (id)red, (id)green,
                                    (id)blue, nil];

    printf("=== does renderInContext draw a gradient at all ===\n");
    {
      CGContextRef c = newContext();
      CAGradientLayer *g = gradient(twoColors);

      [g renderInContext: c];
      box(c, "two colours, default points");
      down(c);
      CGContextRelease(c);
    }

    printf("\n=== the defaults it starts with ===\n");
    {
      CAGradientLayer *g = [CAGradientLayer layer];

      printf("  colors %s locations %s type %s\n",
             [g colors] ? "set" : "nil",
             [g locations] ? "set" : "nil",
             [[g type] UTF8String]);
      printf("  startPoint (%g,%g) endPoint (%g,%g)\n",
             [g startPoint].x, [g startPoint].y,
             [g endPoint].x, [g endPoint].y);
      printf("  +defaultValueForKey type %s startPoint %s colors %s\n",
             [[CAGradientLayer defaultValueForKey: @"type"] description].UTF8String,
             [[CAGradientLayer defaultValueForKey: @"startPoint"] description].UTF8String,
             [[CAGradientLayer defaultValueForKey: @"colors"] description].UTF8String);
    }

    printf("\n=== nothing to draw ===\n");
    {
      CGContextRef c = newContext();
      CAGradientLayer *g = gradient(nil);

      [g renderInContext: c];
      box(c, "no colours");
      CGContextRelease(c);

      c = newContext();
      g = gradient([NSArray arrayWithObject: (id)red]);
      [g renderInContext: c];
      box(c, "one colour");
      sample(c, 40, 30, "one colour, middle");
      CGContextRelease(c);

      c = newContext();
      g = gradient([NSArray array]);
      [g renderInContext: c];
      box(c, "an empty array");
      CGContextRelease(c);
    }

    printf("\n=== which way it runs ===\n");
    {
      CGContextRef c = newContext();
      CAGradientLayer *g = gradient(twoColors);

      [g setStartPoint: CGPointMake(0, 0.5)];
      [g setEndPoint: CGPointMake(1, 0.5)];
      [g renderInContext: c];
      box(c, "left to right");
      across(c);
      CGContextRelease(c);

      c = newContext();
      g = gradient(twoColors);
      [g setStartPoint: CGPointMake(0, 0)];
      [g setEndPoint: CGPointMake(1, 1)];
      [g renderInContext: c];
      box(c, "corner to corner");
      sample(c, 2, 2, "bottom left");
      sample(c, 77, 57, "top right");
      CGContextRelease(c);
    }

    printf("\n=== past the ends ===\n");
    {
      CGContextRef c = newContext();
      CAGradientLayer *g = gradient(twoColors);

      [g setStartPoint: CGPointMake(0.5, 0.25)];
      [g setEndPoint: CGPointMake(0.5, 0.75)];
      [g renderInContext: c];
      box(c, "a gradient over the middle half");
      down(c);
      CGContextRelease(c);
    }

    printf("\n=== locations ===\n");
    {
      CGContextRef c = newContext();
      CAGradientLayer *g = gradient(threeColors);

      [g setLocations: [NSArray arrayWithObjects:
                          [NSNumber numberWithFloat: 0.0],
                          [NSNumber numberWithFloat: 0.25],
                          [NSNumber numberWithFloat: 1.0], nil]];
      [g renderInContext: c];
      box(c, "three colours at 0, 0.25, 1");
      sample(c, 40, 15, "a quarter up");
      down(c);
      CGContextRelease(c);

      c = newContext();
      g = gradient(threeColors);
      [g setLocations: [NSArray arrayWithObject:
                          [NSNumber numberWithFloat: 0.5]]];
      [g renderInContext: c];
      box(c, "three colours, one location");
      down(c);
      CGContextRelease(c);
    }

    printf("\n=== the type ===\n");
    {
      CAGradientLayer *g = [CAGradientLayer layer];

      [g setType: kCAGradientLayerRadial];
      printf("  radial kept as %s\n", [[g type] UTF8String]);
      [g setType: @"not a type"];
      printf("  an unknown type becomes %s\n", [[g type] UTF8String]);

      CGContextRef c = newContext();
      CAGradientLayer *r = gradient(twoColors);
      [r setType: kCAGradientLayerRadial];
      [r renderInContext: c];
      box(c, "radial, default points");
      sample(c, 40, 30, "radial centre");
      sample(c, 2, 2, "radial corner");
      CGContextRelease(c);

      c = newContext();
      CAGradientLayer *n = gradient(twoColors);
      [n setType: kCAGradientLayerConic];
      [n renderInContext: c];
      box(c, "conic, default points");
      sample(c, 40, 30, "conic centre");
      sample(c, 77, 30, "conic right");
      CGContextRelease(c);
    }

    printf("\n=== with the rest of the layer ===\n");
    {
      CGContextRef c = newContext();
      CAGradientLayer *g = gradient(twoColors);

      [g setBackgroundColor: green];
      [g renderInContext: c];
      box(c, "a background colour as well");
      sample(c, 40, 30, "over the background");
      CGContextRelease(c);

      c = newContext();
      g = gradient(twoColors);
      [g setCornerRadius: 20];
      [g renderInContext: c];
      box(c, "a corner radius, no masking");
      printf("  corner (0,0) painted: %d\n", painted(c, 0, 0));
      CGContextRelease(c);

      c = newContext();
      g = gradient(twoColors);
      [g setCornerRadius: 20];
      [g setMasksToBounds: YES];
      [g renderInContext: c];
      box(c, "the same, masked to the bounds");
      printf("  corner (0,0) painted: %d\n", painted(c, 0, 0));
      CGContextRelease(c);
    }

    printf("\n=== does it ask to be redrawn ===\n");
    {
      CAGradientLayer *g = [CAGradientLayer layer];

      [g setBounds: CGRectMake(0, 0, 80, 60)];
      [g display];
      printf("  needsDisplay after a display: %d\n", [g needsDisplay]);
      [g setColors: twoColors];
      printf("  after setColors: %d\n", [g needsDisplay]);
      [g display];
      [g setStartPoint: CGPointMake(0, 0)];
      printf("  after setStartPoint: %d\n", [g needsDisplay]);
      [g display];
      [g setType: kCAGradientLayerRadial];
      printf("  after setType: %d\n", [g needsDisplay]);
      printf("  contents after a display: %s\n",
             [g contents] ? "set" : "nil");
    }

    CGColorRelease(red);
    CGColorRelease(blue);
    CGColorRelease(green);
  }
  return 0;
}

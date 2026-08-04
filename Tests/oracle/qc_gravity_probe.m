/* Where the contents land inside the bounds for each contentsGravity, and
   whether -renderInContext: honours gravity at all.

   The layer bounds are 80x60 and the contents image is 20x10, so the two
   aspect ratios differ (4:3 against 2:1) and the aspect modes are told apart
   from the plain resize. */
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#include <stdio.h>
#include <string.h>

#define SIDE 140

static CGContextRef newContext(void)
{
  CGColorSpaceRef space = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
  CGContextRef context = CGBitmapContextCreate(NULL, SIDE, SIDE, 8, SIDE * 4,
                                               space,
                                               kCGImageAlphaPremultipliedLast);
  CGColorSpaceRelease(space);
  if (context)
    memset(CGBitmapContextGetData(context), 0, SIDE * SIDE * 4);
  return context;
}

static int painted(CGContextRef c, int x, int y)
{
  unsigned char *data = CGBitmapContextGetData(c);
  unsigned char *p;

  if (!data || x < 0 || y < 0 || x >= SIDE || y >= SIDE)
    return 0;
  p = data + ((SIDE - 1 - y) * SIDE + x) * 4;
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
    printf("  %-22s nothing painted\n", label);
  else
    printf("  %-22s x %3d..%-3d  y %3d..%-3d  w %3d h %3d  count %d\n",
           label, minX, maxX, minY, maxY, maxX - minX + 1, maxY - minY + 1, n);
}

static CGImageRef makeImage(int w, int h)
{
  CGColorSpaceRef space = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
  CGContextRef c = CGBitmapContextCreate(NULL, w, h, 8, w * 4, space,
                                         kCGImageAlphaPremultipliedLast);
  CGColorRef blue = CGColorCreateGenericRGB(0, 0, 1, 1);
  CGImageRef image;

  CGColorSpaceRelease(space);
  memset(CGBitmapContextGetData(c), 0, w * h * 4);
  CGContextSetFillColorWithColor(c, blue);
  CGContextFillRect(c, CGRectMake(0, 0, w, h));
  image = CGBitmapContextCreateImage(c);
  CGColorRelease(blue);
  CGContextRelease(c);
  return image;
}

int main(void)
{
  @autoreleasepool {
    CGImageRef image = makeImage(20, 10);
    NSString *names[] = { kCAGravityResize, kCAGravityResizeAspect,
                          kCAGravityResizeAspectFill, kCAGravityCenter,
                          kCAGravityTop, kCAGravityBottom, kCAGravityLeft,
                          kCAGravityRight, kCAGravityTopLeft,
                          kCAGravityTopRight, kCAGravityBottomLeft,
                          kCAGravityBottomRight };
    int i;

    printf("=== bounds 80x60, contents image 20x10, through "
           "-renderInContext: ===\n");
    for (i = 0; i < 12; i++)
      {
        CGContextRef c = newContext();
        CALayer *l = [CALayer layer];

        [l setBounds: CGRectMake(0, 0, 80, 60)];
        [l setContents: (id)image];
        [l setContentsGravity: names[i]];
        [l renderInContext: c];
        box(c, [names[i] UTF8String]);
        CGContextRelease(c);
      }

    printf("\n=== the same, with masksToBounds so any overflow is cut ===\n");
    for (i = 0; i < 12; i++)
      {
        CGContextRef c = newContext();
        CALayer *l = [CALayer layer];

        [l setBounds: CGRectMake(0, 0, 80, 60)];
        [l setContents: (id)image];
        [l setContentsGravity: names[i]];
        [l setMasksToBounds: YES];
        [l renderInContext: c];
        box(c, [names[i] UTF8String]);
        CGContextRelease(c);
      }

    printf("\n=== a bogus gravity name ===\n");
    {
      CGContextRef c = newContext();
      CALayer *l = [CALayer layer];

      [l setBounds: CGRectMake(0, 0, 80, 60)];
      [l setContents: (id)image];
      [l setContentsGravity: @"not a gravity"];
      printf("  reads back as \"%s\"\n", [[l contentsGravity] UTF8String]);
      [l renderInContext: c];
      box(c, "bogus");
      CGContextRelease(c);
    }

    printf("\n=== contentsScale 2 with resize ===\n");
    {
      CGContextRef c = newContext();
      CALayer *l = [CALayer layer];

      [l setBounds: CGRectMake(0, 0, 80, 60)];
      [l setContents: (id)image];
      [l setContentsGravity: kCAGravityResize];
      [l setContentsScale: 2];
      [l renderInContext: c];
      box(c, "resize, scale 2");
      CGContextRelease(c);
    }

    printf("\n=== contentsRect (0.5,0,0.5,1) with resize ===\n");
    {
      CGContextRef c = newContext();
      CALayer *l = [CALayer layer];

      [l setBounds: CGRectMake(0, 0, 80, 60)];
      [l setContents: (id)image];
      [l setContentsGravity: kCAGravityResize];
      [l setContentsRect: CGRectMake(0.5, 0, 0.5, 1)];
      [l renderInContext: c];
      box(c, "resize, half the source");
      CGContextRelease(c);
    }

    CGImageRelease(image);
  }
  return 0;
}

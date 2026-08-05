/* Whether a transparency layer's contents cast the context's shadow as one
   shape, which is what a layer's shadow needs. */
#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#include <stdio.h>

static CGContextRef makeContext(size_t w, size_t h)
{
  CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
  CGContextRef ctx = CGBitmapContextCreate(NULL, w, h, 8, w * 4, space,
                                           kCGImageAlphaPremultipliedLast);

  CGColorSpaceRelease(space);
  CGContextClearRect(ctx, CGRectMake(0, 0, w, h));
  return ctx;
}

static void reportBlue(const char *what, CGContextRef ctx)
{
  unsigned char *p = CGBitmapContextGetData(ctx);
  size_t w = CGBitmapContextGetWidth(ctx);
  size_t h = CGBitmapContextGetHeight(ctx);
  size_t stride = CGBitmapContextGetBytesPerRow(ctx);
  int minX = (int)w, minY = (int)h, maxX = -1, maxY = -1, count = 0, peak = 0;
  size_t x, y;

  for (y = 0; y < h; y++)
    for (x = 0; x < w; x++)
      {
        unsigned char *q = p + y * stride + x * 4;

        if (q[2] > q[0] && q[3] > 0)
          {
            count++;
            if (q[3] > peak) peak = q[3];
            if ((int)x < minX) minX = (int)x;
            if ((int)x > maxX) maxX = (int)x;
            if ((int)y < minY) minY = (int)y;
            if ((int)y > maxY) maxY = (int)y;
          }
      }
  printf("%s: blue %d px, box %d,%d..%d,%d, peak alpha %d\n",
         what, count, minX, minY, maxX, maxY, peak);
}

static void twoRects(CGContextRef ctx)
{
  CGContextSetRGBFillColor(ctx, 1, 0, 0, 1);
  CGContextFillRect(ctx, CGRectMake(40, 40, 40, 40));
  CGContextFillRect(ctx, CGRectMake(60, 60, 40, 40));
}

int main(void)
{
  CGColorRef blue = CGColorCreateGenericRGB(0, 0, 1, 1);

  /* 1. Two overlapping rects with a shadow set, drawn plainly.  Each casts
        its own, so the second one's shadow falls over the first rect. */
  {
    CGContextRef ctx = makeContext(200, 200);

    CGContextSetShadowWithColor(ctx, CGSizeMake(30, 30), 0, blue);
    twoRects(ctx);
    reportBlue("1 two rects, no transparency layer", ctx);
    CGContextRelease(ctx);
  }

  /* 2. The same inside a transparency layer.  If the layer's contents cast
        one shadow, no shadow falls between the two rects. */
  {
    CGContextRef ctx = makeContext(200, 200);

    CGContextSetShadowWithColor(ctx, CGSizeMake(30, 30), 0, blue);
    CGContextBeginTransparencyLayer(ctx, NULL);
    twoRects(ctx);
    CGContextEndTransparencyLayer(ctx);
    reportBlue("2 two rects in a transparency layer", ctx);
    CGContextRelease(ctx);
  }

  /* 3. A transparency layer with a shadow set inside it as well, to see
        whether the outer shadow still applies to the whole. */
  {
    CGContextRef ctx = makeContext(200, 200);
    CGColorRef green = CGColorCreateGenericRGB(0, 1, 0, 1);

    CGContextSetShadowWithColor(ctx, CGSizeMake(30, 30), 0, blue);
    CGContextBeginTransparencyLayer(ctx, NULL);
    CGContextSetShadowWithColor(ctx, CGSizeMake(-30, -30), 0, green);
    twoRects(ctx);
    CGContextEndTransparencyLayer(ctx);
    reportBlue("3 a shadow set inside the transparency layer", ctx);
    CGColorRelease(green);
    CGContextRelease(ctx);
  }

  CGColorRelease(blue);
  return 0;
}

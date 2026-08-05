/* What CoreGraphics does with a shadow, and what CALayer's shadowPath does
   through -renderInContext:. */
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
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

/* Counts pixels where blue dominates red, and reports their bounding box and
   the strongest alpha found. */
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
  printf("%s: bluish %d px, box %d,%d..%d,%d, peak alpha %d\n",
         what, count, minX, minY, maxX, maxY, peak);
}

/* Counts pixels with any coverage at all, for the cases where the shadow is
   left at its default colour. */
static void reportInk(const char *what, CGContextRef ctx)
{
  unsigned char *p = CGBitmapContextGetData(ctx);
  size_t w = CGBitmapContextGetWidth(ctx);
  size_t h = CGBitmapContextGetHeight(ctx);
  size_t stride = CGBitmapContextGetBytesPerRow(ctx);
  int minX = (int)w, minY = (int)h, maxX = -1, maxY = -1, count = 0;
  size_t x, y;

  for (y = 0; y < h; y++)
    for (x = 0; x < w; x++)
      {
        unsigned char *q = p + y * stride + x * 4;

        if (q[3] > 0)
          {
            count++;
            if ((int)x < minX) minX = (int)x;
            if ((int)x > maxX) maxX = (int)x;
            if ((int)y < minY) minY = (int)y;
            if ((int)y > maxY) maxY = (int)y;
          }
      }
  printf("%s: inked %d px, box %d,%d..%d,%d\n",
         what, count, minX, minY, maxX, maxY);
}

static void fillRect(CGContextRef ctx, CGRect r)
{
  CGContextSetRGBFillColor(ctx, 1, 0, 0, 1);
  CGContextBeginPath(ctx);
  CGContextAddRect(ctx, r);
  CGContextFillPath(ctx);
}

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];
  CGColorRef blue = CGColorCreateGenericRGB(0, 0, 1, 1);
  CGColorRef red = CGColorCreateGenericRGB(1, 0, 0, 1);

  /* 1. A blue shadow under a red rect.  Does the set colour reach the
        shadow, and how far does the blur spread past the rect? */
  {
    CGContextRef ctx = makeContext(200, 200);

    CGContextSetShadowWithColor(ctx, CGSizeMake(20, 20), 5, blue);
    fillRect(ctx, CGRectMake(60, 60, 40, 40));
    reportBlue("1 blue shadow, offset 20,20 radius 5, rect 60,60,40,40", ctx);
    CGContextRelease(ctx);
  }

  /* 2. The same at radius 0 and at radius 20, to see what the radius does to
        the spread. */
  {
    CGContextRef ctx = makeContext(200, 200);

    CGContextSetShadowWithColor(ctx, CGSizeMake(20, 20), 0, blue);
    fillRect(ctx, CGRectMake(60, 60, 40, 40));
    reportBlue("2a radius 0", ctx);
    CGContextRelease(ctx);

    ctx = makeContext(200, 200);
    CGContextSetShadowWithColor(ctx, CGSizeMake(20, 20), 20, blue);
    fillRect(ctx, CGRectMake(60, 60, 40, 40));
    reportBlue("2b radius 20", ctx);
    CGContextRelease(ctx);
  }

  /* 3. Far from the origin, past any fixed-size intermediate buffer. */
  {
    CGContextRef ctx = makeContext(600, 600);

    CGContextSetShadowWithColor(ctx, CGSizeMake(20, 20), 5, blue);
    fillRect(ctx, CGRectMake(450, 450, 40, 40));
    reportBlue("3 rect at 450,450 in a 600x600 context", ctx);
    CGContextRelease(ctx);
  }

  /* 4. Is the offset in the user space where the shadow was set, or where the
        drawing happens?  Scale by 2 either before or after setting it. */
  {
    CGContextRef ctx = makeContext(200, 200);

    CGContextScaleCTM(ctx, 2, 2);
    CGContextSetShadowWithColor(ctx, CGSizeMake(20, 20), 5, blue);
    fillRect(ctx, CGRectMake(30, 30, 20, 20));
    reportBlue("4a scale 2 then set shadow, rect 30,30,20,20", ctx);
    CGContextRelease(ctx);

    ctx = makeContext(200, 200);
    CGContextSetShadowWithColor(ctx, CGSizeMake(20, 20), 5, blue);
    CGContextScaleCTM(ctx, 2, 2);
    fillRect(ctx, CGRectMake(30, 30, 20, 20));
    reportBlue("4b set shadow then scale 2, rect 30,30,20,20", ctx);
    CGContextRelease(ctx);
  }

  /* 5. Does anything other than a filled path cast one?  An image, a stroke,
        and text. */
  {
    CGContextRef ctx = makeContext(200, 200);
    CGContextRef small = makeContext(20, 20);
    CGImageRef image;

    CGContextSetRGBFillColor(small, 1, 0, 0, 1);
    CGContextFillRect(small, CGRectMake(0, 0, 20, 20));
    image = CGBitmapContextCreateImage(small);

    CGContextSetShadowWithColor(ctx, CGSizeMake(20, 20), 5, blue);
    CGContextDrawImage(ctx, CGRectMake(60, 60, 40, 40), image);
    reportBlue("5a image", ctx);
    CGImageRelease(image);
    CGContextRelease(small);
    CGContextRelease(ctx);

    ctx = makeContext(200, 200);
    CGContextSetShadowWithColor(ctx, CGSizeMake(20, 20), 5, blue);
    CGContextSetRGBStrokeColor(ctx, 1, 0, 0, 1);
    CGContextSetLineWidth(ctx, 4);
    CGContextBeginPath(ctx);
    CGContextAddRect(ctx, CGRectMake(60, 60, 40, 40));
    CGContextStrokePath(ctx);
    reportBlue("5b stroke", ctx);
    CGContextRelease(ctx);
  }

  /* 6. The default colour of CGContextSetShadow, and whether the shadow is
        part of the graphics state. */
  {
    CGContextRef ctx = makeContext(200, 200);
    unsigned char *p;
    size_t stride;

    CGContextSetShadow(ctx, CGSizeMake(20, 20), 5);
    fillRect(ctx, CGRectMake(60, 60, 40, 40));
    p = CGBitmapContextGetData(ctx);
    stride = CGBitmapContextGetBytesPerRow(ctx);
    /* Well inside the shadow and outside the rect. */
    printf("6a default shadow colour at 110,110: %d %d %d %d\n",
           p[110 * stride + 110 * 4 + 0], p[110 * stride + 110 * 4 + 1],
           p[110 * stride + 110 * 4 + 2], p[110 * stride + 110 * 4 + 3]);
    reportInk("6a default shadow", ctx);
    CGContextRelease(ctx);

    ctx = makeContext(200, 200);
    CGContextSaveGState(ctx);
    CGContextSetShadowWithColor(ctx, CGSizeMake(20, 20), 5, blue);
    CGContextRestoreGState(ctx);
    fillRect(ctx, CGRectMake(60, 60, 40, 40));
    reportBlue("6b shadow set inside a saved state, restored before drawing",
               ctx);
    CGContextRelease(ctx);
  }

  /* 7. Does -renderInContext: draw a layer's shadow at all? */
  {
    CGContextRef ctx = makeContext(200, 200);
    CALayer *layer = [CALayer layer];

    [layer setBounds: CGRectMake(0, 0, 40, 40)];
    [layer setPosition: CGPointMake(100, 100)];
    [layer setBackgroundColor: red];
    [layer setShadowColor: blue];
    [layer setShadowOpacity: 1.0];
    [layer setShadowOffset: CGSizeMake(20, 20)];
    [layer setShadowRadius: 5];

    CGContextTranslateCTM(ctx, 80, 80);
    [layer renderInContext: ctx];
    reportBlue("7 renderInContext with a shadow, no shadowPath", ctx);
    CGContextRelease(ctx);
  }

  /* 8. The same layer with a shadowPath: a 20x20 circle in the middle of a
        40x40 layer.  A smaller, rounder shadow means the path was used. */
  {
    CGContextRef ctx = makeContext(200, 200);
    CALayer *layer = [CALayer layer];
    CGMutablePathRef path = CGPathCreateMutable();

    CGPathAddEllipseInRect(path, NULL, CGRectMake(10, 10, 20, 20));
    [layer setBounds: CGRectMake(0, 0, 40, 40)];
    [layer setPosition: CGPointMake(100, 100)];
    [layer setBackgroundColor: red];
    [layer setShadowColor: blue];
    [layer setShadowOpacity: 1.0];
    [layer setShadowOffset: CGSizeMake(20, 20)];
    [layer setShadowRadius: 5];
    [layer setShadowPath: path];

    CGContextTranslateCTM(ctx, 80, 80);
    [layer renderInContext: ctx];
    reportBlue("8 renderInContext with a 20x20 circular shadowPath", ctx);
    CGPathRelease(path);
    CGContextRelease(ctx);
  }

  /* 9. A shadowPath that reaches outside the layer's bounds, and an empty
        path. */
  {
    CGContextRef ctx = makeContext(200, 200);
    CALayer *layer = [CALayer layer];
    CGMutablePathRef path = CGPathCreateMutable();

    CGPathAddRect(path, NULL, CGRectMake(-20, -20, 80, 80));
    [layer setBounds: CGRectMake(0, 0, 40, 40)];
    [layer setPosition: CGPointMake(100, 100)];
    [layer setBackgroundColor: red];
    [layer setShadowColor: blue];
    [layer setShadowOpacity: 1.0];
    [layer setShadowOffset: CGSizeMake(0, 0)];
    [layer setShadowRadius: 2];
    [layer setShadowPath: path];

    CGContextTranslateCTM(ctx, 80, 80);
    [layer renderInContext: ctx];
    reportBlue("9a shadowPath larger than the bounds, offset 0", ctx);
    CGPathRelease(path);
    CGContextRelease(ctx);

    ctx = makeContext(200, 200);
    layer = [CALayer layer];
    path = CGPathCreateMutable();
    [layer setBounds: CGRectMake(0, 0, 40, 40)];
    [layer setPosition: CGPointMake(100, 100)];
    [layer setBackgroundColor: red];
    [layer setShadowColor: blue];
    [layer setShadowOpacity: 1.0];
    [layer setShadowOffset: CGSizeMake(20, 20)];
    [layer setShadowRadius: 5];
    [layer setShadowPath: path];

    CGContextTranslateCTM(ctx, 80, 80);
    [layer renderInContext: ctx];
    reportBlue("9b an empty shadowPath", ctx);
    CGPathRelease(path);
    CGContextRelease(ctx);
  }

  CGColorRelease(blue);
  CGColorRelease(red);
  [pool release];
  return 0;
}

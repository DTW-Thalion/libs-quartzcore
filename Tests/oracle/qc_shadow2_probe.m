/* What -renderInContext: does with a layer's shadow: what casts it, what
   shape it takes, and what shadowOpacity does to it. */
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

/* Pixels where blue dominates red: the shadow, never the red layer. */
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

static CALayer *base(CGColorRef red, CGColorRef blue, CGFloat opacity)
{
  CALayer *layer = [CALayer layer];

  [layer setBounds: CGRectMake(0, 0, 40, 40)];
  [layer setPosition: CGPointMake(100, 100)];
  [layer setBackgroundColor: red];
  [layer setShadowColor: blue];
  [layer setShadowOpacity: opacity];
  [layer setShadowOffset: CGSizeMake(20, 20)];
  [layer setShadowRadius: 5];
  return layer;
}

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];
  CGColorRef blue = CGColorCreateGenericRGB(0, 0, 1, 1);
  CGColorRef red = CGColorCreateGenericRGB(1, 0, 0, 1);
  CGColorRef green = CGColorCreateGenericRGB(0, 1, 0, 1);

  /* 1. What shadowOpacity does to the shadow's alpha. */
  {
    CGContextRef ctx = makeContext(200, 200);

    CGContextTranslateCTM(ctx, 80, 80);
    [base(red, blue, 0.5) renderInContext: ctx];
    reportBlue("1 shadowOpacity 0.5", ctx);
    CGContextRelease(ctx);
  }

  /* 2. A sublayer sticking out of the layer.  If the shadow is cast by
        everything drawn, it covers the sublayer too. */
  {
    CGContextRef ctx = makeContext(200, 200);
    CALayer *layer = base(red, blue, 1.0);
    CALayer *out = [CALayer layer];

    [out setBounds: CGRectMake(0, 0, 20, 20)];
    [out setPosition: CGPointMake(50, 20)];
    [out setBackgroundColor: green];
    [layer addSublayer: out];

    CGContextTranslateCTM(ctx, 80, 80);
    [layer renderInContext: ctx];
    reportBlue("2 a sublayer reaching past the layer", ctx);
    CGContextRelease(ctx);
  }

  /* 3. A sublayer with a shadow of its own, inside a layer with none. */
  {
    CGContextRef ctx = makeContext(200, 200);
    CALayer *layer = [CALayer layer];
    CALayer *in = [CALayer layer];

    [layer setBounds: CGRectMake(0, 0, 40, 40)];
    [layer setPosition: CGPointMake(100, 100)];
    [layer setBackgroundColor: red];
    [in setBounds: CGRectMake(0, 0, 16, 16)];
    [in setPosition: CGPointMake(20, 20)];
    [in setBackgroundColor: green];
    [in setShadowColor: blue];
    [in setShadowOpacity: 1.0];
    [in setShadowOffset: CGSizeMake(20, 20)];
    [in setShadowRadius: 5];
    [layer addSublayer: in];

    CGContextTranslateCTM(ctx, 80, 80);
    [layer renderInContext: ctx];
    reportBlue("3 a sublayer with its own shadow", ctx);
    CGContextRelease(ctx);
  }

  /* 4. A rounded layer: is the shadow rounded too? */
  {
    CGContextRef ctx = makeContext(200, 200);
    CALayer *layer = base(red, blue, 1.0);

    [layer setCornerRadius: 20];
    CGContextTranslateCTM(ctx, 80, 80);
    [layer renderInContext: ctx];
    reportBlue("4 cornerRadius 20 on a 40x40 layer", ctx);
    CGContextRelease(ctx);
  }

  /* 5. A layer with no background at all, and one drawn only by a border. */
  {
    CGContextRef ctx = makeContext(200, 200);
    CALayer *layer = base(red, blue, 1.0);

    [layer setBackgroundColor: NULL];
    CGContextTranslateCTM(ctx, 80, 80);
    [layer renderInContext: ctx];
    reportBlue("5a nothing drawn", ctx);
    CGContextRelease(ctx);

    ctx = makeContext(200, 200);
    layer = base(red, blue, 1.0);
    [layer setBackgroundColor: NULL];
    [layer setBorderColor: red];
    [layer setBorderWidth: 4];
    CGContextTranslateCTM(ctx, 80, 80);
    [layer renderInContext: ctx];
    reportBlue("5b only a border", ctx);
    CGContextRelease(ctx);
  }

  /* 6. Where the layer is see-through, does the shadow show through it? */
  {
    CGContextRef ctx = makeContext(200, 200);
    CALayer *layer = base(red, blue, 1.0);

    [layer setShadowOffset: CGSizeMake(0, 0)];
    [layer setOpacity: 0.5];
    CGContextTranslateCTM(ctx, 80, 80);
    [layer renderInContext: ctx];
    reportBlue("6 opacity 0.5, shadow directly under it", ctx);
    CGContextRelease(ctx);
  }

  CGColorRelease(blue);
  CGColorRelease(red);
  CGColorRelease(green);
  [pool release];
  return 0;
}

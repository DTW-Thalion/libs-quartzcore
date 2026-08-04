#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#include <stdio.h>
#include <string.h>

#define SIDE 100

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

static int painted(CGContextRef context, int x, int y)
{
  unsigned char *data = CGBitmapContextGetData(context);
  unsigned char *pixel;

  if (!data || x < 0 || y < 0 || x >= SIDE || y >= SIDE)
    return 0;
  pixel = data + ((SIDE - 1 - y) * SIDE + x) * 4;
  return pixel[0] || pixel[1] || pixel[2] || pixel[3];
}

static int paintedCount(CGContextRef context)
{
  int x, y, n = 0;
  for (y = 0; y < SIDE; y++)
    for (x = 0; x < SIDE; x++)
      if (painted(context, x, y))
        n++;
  return n;
}

static int fullyPaintedCount(CGContextRef context)
{
  unsigned char *data = CGBitmapContextGetData(context);
  int i, n = 0;
  for (i = 0; i < SIDE * SIDE; i++)
    {
      unsigned char *p = data + i * 4;
      if (p[0] == 255 || p[1] == 255 || p[2] == 255 || p[3] == 255)
        n++;
    }
  return n;
}

static CGColorRef opaque(CGFloat r, CGFloat g, CGFloat b)
{
  return CGColorCreateGenericRGB(r, g, b, 1.0);
}

@interface Painter : NSObject
@end
@implementation Painter
- (void) drawLayer: (CALayer *)layer inContext: (CGContextRef)context
{
  CGColorRef green = CGColorCreateGenericRGB(0, 1, 0, 1);
  printf("  (the delegate was asked to draw)\n");
  CGContextSetFillColorWithColor(context, green);
  CGContextFillRect(context, CGRectMake(0, 0, 10, 10));
  CGColorRelease(green);
}
@end

@interface Displayer : NSObject
@end
@implementation Displayer
- (void) displayLayer: (CALayer *)layer
{
  printf("  (displayLayer: was called)\n");
}
@end

int main(void)
{
  @autoreleasepool {
    CGColorRef red = opaque(1, 0, 0);
    CGColorRef blue = opaque(0, 0, 1);

    printf("=== a single layer, frame (10,20,30,40), red ===\n");
    {
      CGContextRef c = newContext();
      CALayer *l = [CALayer layer];
      [l setFrame: CGRectMake(10, 20, 30, 40)];
      [l setBackgroundColor: red];
      [l renderInContext: c];
      printf("painted %d (30x40 is %d), fully %d\n", paintedCount(c), 30 * 40,
             fullyPaintedCount(c));
      printf("inside (20,30) %d, left (5,30) %d, right (50,30) %d, "
             "below (20,10) %d, above (20,70) %d\n",
             painted(c, 20, 30), painted(c, 5, 30), painted(c, 50, 30),
             painted(c, 20, 10), painted(c, 20, 70));
      CGContextRelease(c);
    }

    printf("=== nothing to draw ===\n");
    {
      CGContextRef c = newContext();
      CALayer *l = [CALayer layer];
      [l setFrame: CGRectMake(10, 20, 30, 40)];
      [l renderInContext: c];
      printf("no colour and no contents: painted %d\n", paintedCount(c));
      CGContextRelease(c);
    }
    {
      CGContextRef c = newContext();
      CALayer *l = [CALayer layer];
      [l setFrame: CGRectMake(10, 20, 30, 40)];
      [l setBackgroundColor: red];
      [l setHidden: YES];
      [l renderInContext: c];
      printf("hidden: painted %d\n", paintedCount(c));
      CGContextRelease(c);
    }
    {
      CGContextRef c = newContext();
      CALayer *l = [CALayer layer];
      [l setFrame: CGRectMake(10, 20, 30, 40)];
      [l setBackgroundColor: red];
      [l setOpacity: 0.0];
      [l renderInContext: c];
      printf("opacity 0: painted %d\n", paintedCount(c));
      CGContextRelease(c);
    }
    {
      CGContextRef c = newContext();
      CALayer *l = [CALayer layer];
      [l setFrame: CGRectMake(10, 20, 30, 40)];
      [l setBackgroundColor: red];
      [l setOpacity: 0.5];
      [l renderInContext: c];
      printf("opacity 0.5: painted %d, fully %d\n", paintedCount(c),
             fullyPaintedCount(c));
      CGContextRelease(c);
    }

    printf("=== sublayers ===\n");
    {
      CGContextRef c = newContext();
      CALayer *p = [CALayer layer];
      CALayer *k = [CALayer layer];
      [p setFrame: CGRectMake(10, 10, 40, 40)];
      [p setBackgroundColor: red];
      [k setFrame: CGRectMake(5, 5, 10, 10)];
      [k setBackgroundColor: blue];
      [p addSublayer: k];
      [p renderInContext: c];
      printf("parent+child inside: painted %d (40x40 is %d)\n",
             paintedCount(c), 40 * 40);
      printf("at (20,20) painted %d\n", painted(c, 20, 20));
      CGContextRelease(c);
    }
    {
      CGContextRef c = newContext();
      CALayer *p = [CALayer layer];
      CALayer *k = [CALayer layer];
      [p setFrame: CGRectMake(10, 10, 20, 20)];
      [k setFrame: CGRectMake(10, 10, 20, 20)];
      [k setBackgroundColor: red];
      [p addSublayer: k];
      [p renderInContext: c];
      printf("child sticking out, no mask: painted %d (20x20 is %d)\n",
             paintedCount(c), 20 * 20);
      CGContextRelease(c);

      c = newContext();
      [p setMasksToBounds: YES];
      [p renderInContext: c];
      printf("child sticking out, masked: painted %d (10x10 is %d)\n",
             paintedCount(c), 10 * 10);
      CGContextRelease(c);
    }

    printf("=== a bounds origin on the superlayer ===\n");
    {
      CGContextRef c = newContext();
      CALayer *p = [CALayer layer];
      CALayer *k = [CALayer layer];
      [p setFrame: CGRectMake(0, 0, 60, 60)];
      [p setBounds: CGRectMake(10, 10, 60, 60)];
      [k setFrame: CGRectMake(10, 10, 20, 20)];
      [k setBackgroundColor: red];
      [p addSublayer: k];
      [p renderInContext: c];
      printf("painted %d; at (5,5) %d, at (15,15) %d\n", paintedCount(c),
             painted(c, 5, 5), painted(c, 15, 15));
      CGContextRelease(c);
    }

    printf("=== through the delegate ===\n");
    {
      CGContextRef c = newContext();
      CALayer *l = [CALayer layer];
      [l setFrame: CGRectMake(20, 20, 40, 40)];
      [l setDelegate: [[Painter new] autorelease]];
      [l renderInContext: c];
      printf("painted %d (10x10 is %d); at (25,25) %d, at (35,35) %d\n",
             paintedCount(c), 10 * 10, painted(c, 25, 25),
             painted(c, 35, 35));
      CGContextRelease(c);
    }
    {
      CGContextRef c = newContext();
      CALayer *l = [CALayer layer];
      [l setFrame: CGRectMake(20, 20, 40, 40)];
      [l setDelegate: [[Displayer new] autorelease]];
      [l renderInContext: c];
      printf("with a displayLayer: delegate, painted %d\n", paintedCount(c));
      CGContextRelease(c);
    }

    printf("=== transforms ===\n");
    {
      CGContextRef c = newContext();
      CALayer *l = [CALayer layer];
      [l setFrame: CGRectMake(10, 10, 20, 20)];
      [l setBackgroundColor: red];
      [l setTransform: CATransform3DMakeTranslation(30, 0, 0)];
      [l renderInContext: c];
      printf("translated: painted %d; at (45,15) %d, at (15,15) %d\n",
             paintedCount(c), painted(c, 45, 15), painted(c, 15, 15));
      CGContextRelease(c);
    }
    {
      CGContextRef c = newContext();
      CALayer *p = [CALayer layer];
      CALayer *k = [CALayer layer];
      [p setFrame: CGRectMake(0, 0, 100, 100)];
      [k setFrame: CGRectMake(10, 10, 20, 20)];
      [k setBackgroundColor: red];
      [p addSublayer: k];
      [p setSublayerTransform: CATransform3DMakeTranslation(30, 0, 0)];
      [p renderInContext: c];
      printf("sublayerTransform: painted %d; at (45,15) %d, at (15,15) %d\n",
             paintedCount(c), painted(c, 45, 15), painted(c, 15, 15));
      CGContextRelease(c);
    }

    printf("=== a null context ===\n");
    {
      CALayer *l = [CALayer layer];
      [l setFrame: CGRectMake(0, 0, 10, 10)];
      @try {
        [l renderInContext: NULL];
        printf("rendering into NULL did not raise\n");
      } @catch (NSException *e) {
        printf("rendering into NULL RAISED %s\n", [[e name] UTF8String]);
      }
    }

    CGColorRelease(red);
    CGColorRelease(blue);
  }
  return 0;
}

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

/* The bounding box of everything painted. */
static void box(CGContextRef c, const char *label)
{
  int x, y, minX = SIDE, minY = SIDE, maxX = -1, maxY = -1;

  for (y = 0; y < SIDE; y++)
    for (x = 0; x < SIDE; x++)
      if (painted(c, x, y))
        {
          if (x < minX) minX = x;
          if (y < minY) minY = y;
          if (x > maxX) maxX = x;
          if (y > maxY) maxY = y;
        }
  if (maxX < 0)
    printf("%-52s nothing painted\n", label);
  else
    printf("%-52s x %d..%d  y %d..%d  count %d\n", label, minX, maxX,
           minY, maxY, paintedCount(c));
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
  printf("  (drawLayer:inContext: was called)\n");
  CGContextSetFillColorWithColor(context, green);
  CGContextFillRect(context, CGRectMake(0, 0, 10, 10));
  CGColorRelease(green);
}
@end

int main(void)
{
  @autoreleasepool {
    CGColorRef red = opaque(1, 0, 0);

    printf("=== does the receiver's own bounds origin move its fill? ===\n");
    {
      CGContextRef c = newContext();
      CALayer *l = [CALayer layer];
      [l setBounds: CGRectMake(10, 10, 20, 20)];
      [l setPosition: CGPointMake(50, 50)];
      [l setBackgroundColor: red];
      [l renderInContext: c];
      box(c, "bounds (10,10,20,20), position (50,50)");
      CGContextRelease(c);
    }
    {
      CGContextRef c = newContext();
      CALayer *l = [CALayer layer];
      [l setBounds: CGRectMake(0, 0, 20, 20)];
      [l setPosition: CGPointMake(50, 50)];
      [l setAnchorPoint: CGPointMake(0, 0)];
      [l setBackgroundColor: red];
      [l renderInContext: c];
      box(c, "anchorPoint (0,0), position (50,50)");
      CGContextRelease(c);
    }

    printf("=== a sublayer's own transform and anchor point ===\n");
    {
      CGContextRef c = newContext();
      CALayer *p = [CALayer layer];
      CALayer *k = [CALayer layer];
      [p setFrame: CGRectMake(0, 0, 100, 100)];
      [k setFrame: CGRectMake(10, 10, 20, 20)];
      [k setBackgroundColor: red];
      [k setTransform: CATransform3DMakeTranslation(30, 0, 0)];
      [p addSublayer: k];
      [p renderInContext: c];
      box(c, "sublayer translated by 30");
      CGContextRelease(c);
    }
    {
      CGContextRef c = newContext();
      CALayer *p = [CALayer layer];
      CALayer *k = [CALayer layer];
      [p setFrame: CGRectMake(0, 0, 100, 100)];
      [k setBounds: CGRectMake(0, 0, 20, 20)];
      [k setPosition: CGPointMake(50, 50)];
      [k setAnchorPoint: CGPointMake(0, 0)];
      [k setBackgroundColor: red];
      [p addSublayer: k];
      [p renderInContext: c];
      box(c, "sublayer anchorPoint (0,0) position (50,50)");
      CGContextRelease(c);
    }
    {
      CGContextRef c = newContext();
      CALayer *p = [CALayer layer];
      CALayer *k = [CALayer layer];
      [p setFrame: CGRectMake(0, 0, 100, 100)];
      [k setBounds: CGRectMake(0, 0, 20, 20)];
      [k setPosition: CGPointMake(50, 50)];
      [k setBackgroundColor: red];
      [p addSublayer: k];
      [p renderInContext: c];
      box(c, "sublayer anchorPoint (0.5,0.5) position (50,50)");
      CGContextRelease(c);
    }

    printf("=== a bounds origin one level down ===\n");
    {
      CGContextRef c = newContext();
      CALayer *p = [CALayer layer];
      CALayer *mid = [CALayer layer];
      CALayer *k = [CALayer layer];
      [p setFrame: CGRectMake(0, 0, 100, 100)];
      [mid setFrame: CGRectMake(0, 0, 60, 60)];
      [mid setBounds: CGRectMake(10, 10, 60, 60)];
      [k setFrame: CGRectMake(10, 10, 20, 20)];
      [k setBackgroundColor: red];
      [mid addSublayer: k];
      [p addSublayer: mid];
      [p renderInContext: c];
      box(c, "middle layer with bounds origin (10,10)");
      CGContextRelease(c);
    }

    printf("=== contents, and whether display is run ===\n");
    {
      CGContextRef c = newContext();
      CALayer *l = [CALayer layer];
      [l setFrame: CGRectMake(0, 0, 40, 40)];
      [l setDelegate: [[Painter new] autorelease]];
      [l renderInContext: c];
      box(c, "delegate that draws, never displayed");
      CGContextRelease(c);

      c = newContext();
      [l display];
      printf("after -display, contents is %s\n",
             [l contents] ? "set" : "nil");
      [l renderInContext: c];
      box(c, "the same layer after -display");
      CGContextRelease(c);
    }
    {
      /* An image put in contents by hand. */
      CGContextRef image = newContext();
      CGColorRef blue = opaque(0, 0, 1);
      CGContextSetFillColorWithColor(image, blue);
      CGContextFillRect(image, CGRectMake(0, 0, SIDE, SIDE));
      CGImageRef made = CGBitmapContextCreateImage(image);

      CGContextRef c = newContext();
      CALayer *l = [CALayer layer];
      [l setFrame: CGRectMake(0, 0, 30, 30)];
      [l setContents: (id)made];
      [l renderInContext: c];
      box(c, "a CGImage set as contents");
      CGContextRelease(c);
      CGImageRelease(made);
      CGContextRelease(image);
      CGColorRelease(blue);
    }

    printf("=== a sublayer that is hidden ===\n");
    {
      CGContextRef c = newContext();
      CALayer *p = [CALayer layer];
      CALayer *k = [CALayer layer];
      [p setFrame: CGRectMake(0, 0, 100, 100)];
      [k setFrame: CGRectMake(10, 10, 20, 20)];
      [k setBackgroundColor: red];
      [k setHidden: YES];
      [p addSublayer: k];
      [p renderInContext: c];
      box(c, "hidden sublayer");
      CGContextRelease(c);
    }

    printf("=== the order two sublayers are drawn in ===\n");
    {
      CGContextRef c = newContext();
      CALayer *p = [CALayer layer];
      CALayer *first = [CALayer layer];
      CALayer *second = [CALayer layer];
      CGColorRef blue = opaque(0, 0, 1);
      unsigned char *px;

      [p setFrame: CGRectMake(0, 0, 100, 100)];
      [first setFrame: CGRectMake(10, 10, 20, 20)];
      [first setBackgroundColor: red];
      [second setFrame: CGRectMake(10, 10, 20, 20)];
      [second setBackgroundColor: blue];
      [p addSublayer: first];
      [p addSublayer: second];
      [p renderInContext: c];
      px = (unsigned char *)CGBitmapContextGetData(c)
           + ((SIDE - 1 - 15) * SIDE + 15) * 4;
      printf("pixel at (15,15) is %d %d %d %d; red is first, blue second\n",
             px[0], px[1], px[2], px[3]);
      CGContextRelease(c);
      CGColorRelease(blue);
    }

    CGColorRelease(red);
  }
  return 0;
}

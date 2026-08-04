/* How does Apple composite a CAReplicatorLayer, and what does a
   CATransformLayer do differently?  Everything here is measured through
   -renderInContext: into a bitmap, which is the path both witnesses of the
   rendering work assert against.

   Run on a macOS runner:
     clang -framework QuartzCore -framework CoreGraphics -framework Foundation \
       Tests/oracle/qc_replicator_probe.m -o qc_replicator_probe
*/

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>

#define W 200
#define H 200

static CGContextRef newContext(void)
{
  CGColorSpaceRef space = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
  CGContextRef c = CGBitmapContextCreate(NULL, W, H, 8, W * 4, space,
                                         kCGImageAlphaPremultipliedLast);
  CGColorSpaceRelease(space);
  memset(CGBitmapContextGetData(c), 0, W * H * 4);
  return c;
}

/* Bounding box of everything painted, y counting up from the bottom. */
static void box(CGContextRef c, const char *what)
{
  unsigned char *d = CGBitmapContextGetData(c);
  int x, y, x0 = W, y0 = H, x1 = -1, y1 = -1, n = 0;

  for (y = 0; y < H; y++)
    for (x = 0; x < W; x++)
      {
        unsigned char *p = d + ((H - 1 - y) * W + x) * 4;
        if (p[0] || p[1] || p[2] || p[3])
          {
            n++;
            if (x < x0) x0 = x;
            if (y < y0) y0 = y;
            if (x > x1) x1 = x;
            if (y > y1) y1 = y;
          }
      }
  printf("%-38s x %d..%d y %d..%d  %d points\n", what, x0, x1, y0, y1, n);
}

static void pixel(CGContextRef c, int x, int y, const char *what)
{
  unsigned char *p = CGBitmapContextGetData(c) + ((H - 1 - y) * W + x) * 4;

  printf("  %-36s %d %d %d %d\n", what, p[0], p[1], p[2], p[3]);
}

/* A 20x20 child at the origin of the parent's bounds. */
static CALayer *child(CGFloat r, CGFloat g, CGFloat b)
{
  CALayer *l = [CALayer layer];
  CGColorRef colour = CGColorCreateGenericRGB(r, g, b, 1);

  [l setBounds: CGRectMake(0, 0, 20, 20)];
  [l setPosition: CGPointMake(10, 10)];
  [l setBackgroundColor: colour];
  CGColorRelease(colour);
  return l;
}

static CAReplicatorLayer *replicator(void)
{
  CAReplicatorLayer *r = [CAReplicatorLayer layer];

  [r setBounds: CGRectMake(0, 0, 100, 100)];
  return r;
}

int main(void)
{
  @autoreleasepool
    {
      printf("=== what a replicator layer composites ===\n");

      /* 1. a replicator with the default instanceCount */
      {
        CGContextRef c = newContext();
        CAReplicatorLayer *r = replicator();

        [r addSublayer: child(1, 0, 0)];
        [r renderInContext: c];
        box(c, "instanceCount 1 (the default)");
        CGContextRelease(c);
      }

      /* 2. three instances offset 30 along x */
      {
        CGContextRef c = newContext();
        CAReplicatorLayer *r = replicator();

        [r addSublayer: child(1, 0, 0)];
        [r setInstanceCount: 3];
        [r setInstanceTransform: CATransform3DMakeTranslation(30, 0, 0)];
        [r renderInContext: c];
        box(c, "3 instances, +30x");
        pixel(c, 10, 10, "first instance");
        pixel(c, 40, 10, "second, if translation accumulates");
        pixel(c, 70, 10, "third, if translation accumulates");
        CGContextRelease(c);
      }

      /* 3. does instanceTransform accumulate, or apply once? */
      {
        CGContextRef c = newContext();
        CAReplicatorLayer *r = replicator();

        [r addSublayer: child(1, 0, 0)];
        [r setInstanceCount: 2];
        [r setInstanceTransform: CATransform3DMakeScale(2, 2, 1)];
        [r renderInContext: c];
        box(c, "2 instances, scale 2");
        CGContextRelease(c);
      }

      /* 4. no instances at all */
      {
        CGContextRef c = newContext();
        CAReplicatorLayer *r = replicator();

        [r addSublayer: child(1, 0, 0)];
        [r setInstanceCount: 0];
        [r renderInContext: c];
        box(c, "instanceCount 0");
        CGContextRelease(c);
      }

      /* 5. is the replicator's OWN background repeated with the instances? */
      {
        CGContextRef c = newContext();
        CAReplicatorLayer *r = replicator();
        CGColorRef green = CGColorCreateGenericRGB(0, 1, 0, 1);

        [r setBackgroundColor: green];
        [r setBounds: CGRectMake(0, 0, 40, 40)];
        [r addSublayer: child(1, 0, 0)];
        [r setInstanceCount: 3];
        [r setInstanceTransform: CATransform3DMakeTranslation(60, 0, 0)];
        [r renderInContext: c];
        box(c, "own background, 3 instances +60x");
        pixel(c, 30, 30, "its own background");
        pixel(c, 90, 30, "where a repeated background would be");
        CGColorRelease(green);
        CGContextRelease(c);
      }

      /* 6. instanceColor against a white child, so a multiply shows. */
      {
        CGContextRef c = newContext();
        CAReplicatorLayer *r = replicator();
        CGColorRef blue = CGColorCreateGenericRGB(0, 0, 1, 1);

        [r addSublayer: child(1, 1, 1)];
        [r setInstanceCount: 2];
        [r setInstanceTransform: CATransform3DMakeTranslation(30, 0, 0)];
        [r setInstanceColor: blue];
        [r renderInContext: c];
        box(c, "instanceColor blue, white child");
        pixel(c, 10, 10, "first instance");
        pixel(c, 40, 10, "second instance");
        CGColorRelease(blue);
        CGContextRelease(c);
      }

      /* 7. does a colour offset accumulate per instance? */
      {
        CGContextRef c = newContext();
        CAReplicatorLayer *r = replicator();

        [r addSublayer: child(1, 1, 1)];
        [r setInstanceCount: 3];
        [r setInstanceTransform: CATransform3DMakeTranslation(30, 0, 0)];
        [r setInstanceRedOffset: -0.25];
        [r renderInContext: c];
        box(c, "instanceRedOffset -0.25, white child");
        pixel(c, 10, 10, "first instance");
        pixel(c, 40, 10, "second instance");
        pixel(c, 70, 10, "third instance");
        CGContextRelease(c);
      }

      printf("\n=== what a transform layer does ===\n");

      /* 8. a CATransformLayer with a child */
      {
        CGContextRef c = newContext();
        CATransformLayer *t = [CATransformLayer layer];

        [t setBounds: CGRectMake(0, 0, 100, 100)];
        [t addSublayer: child(1, 0, 0)];
        [t renderInContext: c];
        box(c, "transform layer with a child");
        CGContextRelease(c);
      }

      /* 9. the same tree under a plain CALayer, for comparison */
      {
        CGContextRef c = newContext();
        CALayer *l = [CALayer layer];

        [l setBounds: CGRectMake(0, 0, 100, 100)];
        [l addSublayer: child(1, 0, 0)];
        [l renderInContext: c];
        box(c, "plain layer with the same child");
        CGContextRelease(c);
      }

      /* 10. does a transform layer draw its own background? */
      {
        CGContextRef c = newContext();
        CATransformLayer *t = [CATransformLayer layer];
        CGColorRef green = CGColorCreateGenericRGB(0, 1, 0, 1);

        [t setBounds: CGRectMake(0, 0, 100, 100)];
        [t setBackgroundColor: green];
        [t renderInContext: c];
        box(c, "transform layer, background only");
        CGColorRelease(green);
        CGContextRelease(c);
      }

      /* 11. and a border, which is the other thing drawn without a seam. */
      {
        CGContextRef c = newContext();
        CATransformLayer *t = [CATransformLayer layer];
        CGColorRef white = CGColorCreateGenericRGB(1, 1, 1, 1);

        [t setBounds: CGRectMake(0, 0, 100, 100)];
        [t setBorderWidth: 5];
        [t setBorderColor: white];
        [t renderInContext: c];
        box(c, "transform layer, border only");
        CGColorRelease(white);
        CGContextRelease(c);
      }

      /* 12. the same border on a plain layer, for comparison */
      {
        CGContextRef c = newContext();
        CALayer *l = [CALayer layer];
        CGColorRef white = CGColorCreateGenericRGB(1, 1, 1, 1);

        [l setBounds: CGRectMake(0, 0, 100, 100)];
        [l setBorderWidth: 5];
        [l setBorderColor: white];
        [l renderInContext: c];
        box(c, "plain layer, border only");
        CGColorRelease(white);
        CGContextRelease(c);
      }

      /* 13. does a transform layer honour masksToBounds? */
      {
        CGContextRef c = newContext();
        CATransformLayer *t = [CATransformLayer layer];
        CALayer *big = child(1, 0, 0);

        [big setBounds: CGRectMake(0, 0, 400, 400)];
        [t setBounds: CGRectMake(0, 0, 50, 50)];
        [t setMasksToBounds: YES];
        [t addSublayer: big];
        [t renderInContext: c];
        box(c, "transform layer, masksToBounds YES");
        CGContextRelease(c);
      }

      /* 14. the same clip on a plain layer, for comparison */
      {
        CGContextRef c = newContext();
        CALayer *l = [CALayer layer];
        CALayer *big = child(1, 0, 0);

        [big setBounds: CGRectMake(0, 0, 400, 400)];
        [l setBounds: CGRectMake(0, 0, 50, 50)];
        [l setMasksToBounds: YES];
        [l addSublayer: big];
        [l renderInContext: c];
        box(c, "plain layer, masksToBounds YES");
        CGContextRelease(c);
      }

      /* 15. does opacity on a transform layer still reach its sublayers? */
      {
        CGContextRef c = newContext();
        CATransformLayer *t = [CATransformLayer layer];

        [t setBounds: CGRectMake(0, 0, 100, 100)];
        [t setOpacity: 0.5];
        [t addSublayer: child(1, 0, 0)];
        [t renderInContext: c];
        box(c, "transform layer, opacity 0.5");
        pixel(c, 10, 10, "inside the child");
        CGContextRelease(c);
      }
    }
  return 0;
}

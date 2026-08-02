/* The frame lifecycle of a renderer: what updateBounds answers inside a
   frame as against outside one, and what nextFrameTime says.

   Run on a macOS runner:
     clang -framework QuartzCore -framework CoreGraphics -framework Foundation \
       -framework OpenGL Tests/oracle/qc_renderer2_probe.m -o qc_renderer2_probe
*/

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>

static void showRect(const char *what, CGRect r)
{
  if (CGRectIsNull(r))
    {
      printf("%-46s (null)\n", what);
      return;
    }
  printf("%-46s %g %g %g %g\n", what,
         (double)r.origin.x, (double)r.origin.y,
         (double)r.size.width, (double)r.size.height);
}

static CARenderer *makeRenderer(void)
{
  CGLPixelFormatAttribute soft[] = {
    kCGLPFARendererID, (CGLPixelFormatAttribute)kCGLRendererGenericFloatID,
    kCGLPFAColorSize, (CGLPixelFormatAttribute)24,
    (CGLPixelFormatAttribute)0
  };
  CGLPixelFormatObj pix = NULL;
  GLint npix = 0;
  CGLContextObj ctx = NULL;

  if (CGLChoosePixelFormat(soft, &pix, &npix) != kCGLNoError || pix == NULL)
    return nil;
  if (CGLCreateContext(pix, NULL, &ctx) != kCGLNoError || ctx == NULL)
    return nil;
  CGLSetCurrentContext(ctx);
  return [CARenderer rendererWithCGLContext: ctx options: nil];
}

int main(int argc, char **argv)
{
  @autoreleasepool
    {
      CARenderer *r = makeRenderer();
      CALayer *layer;

      if (r == nil)
        {
          printf("no renderer\n");
          return 0;
        }

      layer = [CALayer layer];
      [layer setBounds: CGRectMake(0, 0, 40, 30)];
      [layer setPosition: CGPointMake(20, 15)];
      [layer setBackgroundColor:
        [(id)CGColorCreateGenericRGB(1, 0, 0, 1) autorelease]];
      [r setLayer: layer];
      [r setBounds: CGRectMake(0, 0, 64, 48)];

      printf("=== an update rect added OUTSIDE a frame ===\n");
      [r addUpdateRect: CGRectMake(0, 0, 10, 10)];
      showRect("updateBounds outside", [r updateBounds]);

      printf("\n=== and INSIDE a frame ===\n");
      [r beginFrameAtTime: 0.0 timeStamp: NULL];
      showRect("updateBounds just after beginning", [r updateBounds]);
      [r addUpdateRect: CGRectMake(0, 0, 10, 10)];
      showRect("after adding 0,0,10,10", [r updateBounds]);
      [r addUpdateRect: CGRectMake(50, 40, 5, 5)];
      showRect("after adding 50,40,5,5 as well", [r updateBounds]);
      [r render];
      showRect("after rendering", [r updateBounds]);
      [r endFrame];
      showRect("after ending the frame", [r updateBounds]);

      printf("\n=== a second frame, nothing added ===\n");
      [r beginFrameAtTime: 1.0 timeStamp: NULL];
      showRect("updateBounds", [r updateBounds]);
      [r endFrame];

      printf("\n=== when the layer changes between frames ===\n");
      [r beginFrameAtTime: 2.0 timeStamp: NULL];
      showRect("before the change", [r updateBounds]);
      [r endFrame];
      [layer setBackgroundColor:
        [(id)CGColorCreateGenericRGB(0, 1, 0, 1) autorelease]];
      [r beginFrameAtTime: 3.0 timeStamp: NULL];
      showRect("after a background colour change", [r updateBounds]);
      [r endFrame];

      printf("\n=== nextFrameTime ===\n");
      printf("%-46s %g\n", "with a still layer", (double)[r nextFrameTime]);
      {
        CABasicAnimation *a = [CABasicAnimation animationWithKeyPath: @"opacity"];

        [a setFromValue: [NSNumber numberWithFloat: 0.0]];
        [a setToValue: [NSNumber numberWithFloat: 1.0]];
        [a setDuration: 10.0];
        [layer addAnimation: a forKey: @"fade"];
        printf("%-46s %g\n", "with an animation on the layer",
               (double)[r nextFrameTime]);
        printf("%-46s %d\n", "is it infinite",
               (int)isinf([r nextFrameTime]));
      }

      printf("\n=== a renderer with no layer at all ===\n");
      {
        CARenderer *empty = makeRenderer();

        if (empty != nil)
          {
            showRect("bounds", [empty bounds]);
            showRect("updateBounds", [empty updateBounds]);
            printf("%-46s %g\n", "nextFrameTime",
                   (double)[empty nextFrameTime]);
            [empty beginFrameAtTime: 0.0 timeStamp: NULL];
            showRect("updateBounds in a frame", [empty updateBounds]);
            [empty endFrame];
          }
      }
    }
  return 0;
}

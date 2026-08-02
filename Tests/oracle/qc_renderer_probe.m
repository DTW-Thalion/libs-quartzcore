/* Is CARenderer reachable without a window on macOS, and what does its
   value API do?  Apple's factory takes a CGL context, so this makes one
   off-screen.

   Run on a macOS runner:
     clang -framework QuartzCore -framework CoreGraphics -framework Foundation \
       -framework OpenGL Tests/oracle/qc_renderer_probe.m -o qc_renderer_probe
*/

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>

static void showRect(const char *what, CGRect r)
{
  printf("%-44s %g %g %g %g\n", what,
         (double)r.origin.x, (double)r.origin.y,
         (double)r.size.width, (double)r.size.height);
}

int main(int argc, char **argv)
{
  @autoreleasepool
    {
      CGLPixelFormatAttribute attrs[] = {
        kCGLPFAAccelerated,
        kCGLPFAColorSize, (CGLPixelFormatAttribute)24,
        kCGLPFADepthSize, (CGLPixelFormatAttribute)16,
        (CGLPixelFormatAttribute)0
      };
      CGLPixelFormatObj pix = NULL;
      GLint npix = 0;
      CGLContextObj ctx = NULL;
      CGLError err;
      CARenderer *renderer;

      err = CGLChoosePixelFormat(attrs, &pix, &npix);
      printf("%-44s %d (0 is fine), %d formats\n",
             "CGLChoosePixelFormat, accelerated", (int)err, (int)npix);

      if (err != kCGLNoError || pix == NULL)
        {
          /* Fall back to software, which is what a runner without a GPU
             would need. */
          CGLPixelFormatAttribute soft[] = {
            kCGLPFARendererID, (CGLPixelFormatAttribute)kCGLRendererGenericFloatID,
            kCGLPFAColorSize, (CGLPixelFormatAttribute)24,
            (CGLPixelFormatAttribute)0
          };

          err = CGLChoosePixelFormat(soft, &pix, &npix);
          printf("%-44s %d, %d formats\n",
                 "falling back to software", (int)err, (int)npix);
        }

      if (pix == NULL)
        {
          printf("no pixel format at all, giving up\n");
          return 0;
        }

      err = CGLCreateContext(pix, NULL, &ctx);
      printf("%-44s %d\n", "CGLCreateContext", (int)err);
      if (ctx == NULL)
        {
          printf("no context, giving up\n");
          return 0;
        }

      CGLSetCurrentContext(ctx);
      printf("%-44s %s\n", "GL_RENDERER", glGetString(GL_RENDERER));
      printf("%-44s %s\n", "GL_VERSION", glGetString(GL_VERSION));

      renderer = [CARenderer rendererWithCGLContext: ctx options: nil];
      printf("%-44s %s\n", "CARenderer with no window",
             renderer ? "built" : "(nil)");
      if (renderer == nil)
        {
          return 0;
        }

      printf("\n=== what it starts with ===\n");
      printf("%-44s %s\n", "layer", [renderer layer] ? "(non-nil)" : "(nil)");
      showRect("bounds", [renderer bounds]);
      showRect("updateBounds", [renderer updateBounds]);
      printf("%-44s %g\n", "nextFrameTime", (double)[renderer nextFrameTime]);

      printf("\n=== setting a layer and bounds ===\n");
      {
        CALayer *l = [CALayer layer];

        [l setBounds: CGRectMake(0, 0, 40, 30)];
        [renderer setLayer: l];
        printf("%-44s %d\n", "the layer reads back",
               [renderer layer] == l);

        [renderer setBounds: CGRectMake(0, 0, 64, 48)];
        showRect("bounds after setting", [renderer bounds]);
        showRect("updateBounds after setting bounds",
                 [renderer updateBounds]);
      }

      printf("\n=== adding update rects ===\n");
      {
        [renderer beginFrameAtTime: 0.0 timeStamp: NULL];
        [renderer endFrame];
        showRect("updateBounds after a frame", [renderer updateBounds]);

        [renderer addUpdateRect: CGRectMake(0, 0, 10, 10)];
        showRect("after adding 0,0,10,10", [renderer updateBounds]);

        [renderer addUpdateRect: CGRectMake(50, 40, 5, 5)];
        showRect("after adding 50,40,5,5", [renderer updateBounds]);

        [renderer beginFrameAtTime: 1.0 timeStamp: NULL];
        showRect("after beginning another frame", [renderer updateBounds]);
        [renderer endFrame];
        showRect("and ending it", [renderer updateBounds]);
      }

      printf("\n=== next frame time ===\n");
      printf("%-44s %g\n", "with a still layer",
             (double)[renderer nextFrameTime]);

      CGLDestroyContext(ctx);
      CGLDestroyPixelFormat(pix);
    }
  return 0;
}

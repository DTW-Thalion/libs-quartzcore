/* Round 2.  Round 1 measured -renderInContext:, which is a simplified path:
   it showed a transform layer drawing its own background and a replicator
   ignoring instanceColor.  This asks the real compositor the same questions,
   through CARenderer into an off-screen framebuffer.

   Run on a macOS runner:
     clang -framework QuartzCore -framework CoreGraphics -framework Foundation \
       -framework OpenGL Tests/oracle/qc_replicator2_probe.m -o qc_replicator2_probe
*/

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>

#define W 200
#define H 200

static CGLContextObj ctx;
static GLuint fbo, rbo;
static unsigned char pixels[W * H * 4];

static int startGL(void)
{
  CGLPixelFormatAttribute soft[] = {
    kCGLPFARendererID, (CGLPixelFormatAttribute)kCGLRendererGenericFloatID,
    kCGLPFAColorSize, (CGLPixelFormatAttribute)24,
    (CGLPixelFormatAttribute)0
  };
  CGLPixelFormatObj pix = NULL;
  GLint npix = 0;
  CGLError err;

  err = CGLChoosePixelFormat(soft, &pix, &npix);
  if (err != kCGLNoError || pix == NULL)
    {
      printf("no software pixel format (%d), giving up\n", (int)err);
      return 0;
    }
  err = CGLCreateContext(pix, NULL, &ctx);
  CGLDestroyPixelFormat(pix);
  if (err != kCGLNoError || ctx == NULL)
    {
      printf("no context (%d), giving up\n", (int)err);
      return 0;
    }
  CGLSetCurrentContext(ctx);
  printf("GL_RENDERER %s\n", glGetString(GL_RENDERER));

  glGenFramebuffersEXT(1, &fbo);
  glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, fbo);
  glGenRenderbuffersEXT(1, &rbo);
  glBindRenderbufferEXT(GL_RENDERBUFFER_EXT, rbo);
  glRenderbufferStorageEXT(GL_RENDERBUFFER_EXT, GL_RGBA8, W, H);
  glFramebufferRenderbufferEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT,
                               GL_RENDERBUFFER_EXT, rbo);
  printf("framebuffer status %s\n",
         glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT)
           == GL_FRAMEBUFFER_COMPLETE_EXT ? "complete" : "INCOMPLETE");
  glViewport(0, 0, W, H);
  return 1;
}

/* Render one layer tree and read the drawable back. */
static void draw(CALayer *layer)
{
  CARenderer *renderer;

  glClearColor(0, 0, 0, 0);
  glClear(GL_COLOR_BUFFER_BIT);

  renderer = [CARenderer rendererWithCGLContext: ctx options: nil];
  [renderer setLayer: layer];
  [renderer setBounds: CGRectMake(0, 0, W, H)];
  [renderer addUpdateRect: CGRectMake(0, 0, W, H)];
  [renderer beginFrameAtTime: 0.0 timeStamp: NULL];
  [renderer render];
  [renderer endFrame];
  glFinish();

  memset(pixels, 0, sizeof(pixels));
  glReadPixels(0, 0, W, H, GL_RGBA, GL_UNSIGNED_BYTE, pixels);
}

/* glReadPixels already counts y up from the bottom. */
static void box(const char *what)
{
  int x, y, x0 = W, y0 = H, x1 = -1, y1 = -1, n = 0;

  for (y = 0; y < H; y++)
    for (x = 0; x < W; x++)
      {
        unsigned char *p = pixels + (y * W + x) * 4;

        if (p[0] || p[1] || p[2])
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

static void pixel(int x, int y, const char *what)
{
  unsigned char *p = pixels + (y * W + x) * 4;

  printf("  %-36s %d %d %d %d\n", what, p[0], p[1], p[2], p[3]);
}

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

int main(void)
{
  @autoreleasepool
    {
      if (!startGL())
        {
          return 0;
        }

      [CATransaction begin];
      [CATransaction setDisableActions: YES];

      printf("\n=== a plain layer, for comparison ===\n");
      {
        CALayer *l = [CALayer layer];
        CGColorRef green = CGColorCreateGenericRGB(0, 1, 0, 1);

        [l setBounds: CGRectMake(0, 0, 100, 100)];
        [l setPosition: CGPointMake(50, 50)];
        [l setBackgroundColor: green];
        draw(l);
        box("plain layer, green background");
        pixel(50, 50, "in the middle of it");
        CGColorRelease(green);
      }

      printf("\n=== does the compositor draw a transform layer? ===\n");
      {
        CATransformLayer *t = [CATransformLayer layer];
        CGColorRef green = CGColorCreateGenericRGB(0, 1, 0, 1);

        [t setBounds: CGRectMake(0, 0, 100, 100)];
        [t setPosition: CGPointMake(50, 50)];
        [t setBackgroundColor: green];
        draw(t);
        box("transform layer, green background");
        pixel(50, 50, "in the middle of it");
        CGColorRelease(green);
      }
      {
        CATransformLayer *t = [CATransformLayer layer];
        CGColorRef white = CGColorCreateGenericRGB(1, 1, 1, 1);

        [t setBounds: CGRectMake(0, 0, 100, 100)];
        [t setPosition: CGPointMake(50, 50)];
        [t setBorderWidth: 5];
        [t setBorderColor: white];
        draw(t);
        box("transform layer, border only");
        CGColorRelease(white);
      }
      {
        CALayer *l = [CALayer layer];
        CGColorRef white = CGColorCreateGenericRGB(1, 1, 1, 1);

        [l setBounds: CGRectMake(0, 0, 100, 100)];
        [l setPosition: CGPointMake(50, 50)];
        [l setBorderWidth: 5];
        [l setBorderColor: white];
        draw(l);
        box("plain layer, border only");
        CGColorRelease(white);
      }
      {
        CATransformLayer *t = [CATransformLayer layer];

        [t setBounds: CGRectMake(0, 0, 100, 100)];
        [t setPosition: CGPointMake(50, 50)];
        [t addSublayer: child(1, 0, 0)];
        draw(t);
        box("transform layer, a red child");
      }
      {
        CALayer *l = [CALayer layer];

        [l setBounds: CGRectMake(0, 0, 100, 100)];
        [l setPosition: CGPointMake(50, 50)];
        [l addSublayer: child(1, 0, 0)];
        draw(l);
        box("plain layer, the same child");
      }

      printf("\n=== does the compositor replicate? ===\n");
      {
        CAReplicatorLayer *r = [CAReplicatorLayer layer];

        [r setBounds: CGRectMake(0, 0, 100, 100)];
        [r setPosition: CGPointMake(50, 50)];
        [r addSublayer: child(1, 0, 0)];
        [r setInstanceCount: 3];
        [r setInstanceTransform: CATransform3DMakeTranslation(30, 0, 0)];
        draw(r);
        box("3 instances, +30x");
        pixel(10, 10, "first instance");
        pixel(40, 10, "second instance");
        pixel(70, 10, "third instance");
      }
      {
        CAReplicatorLayer *r = [CAReplicatorLayer layer];
        CGColorRef blue = CGColorCreateGenericRGB(0, 0, 1, 1);

        [r setBounds: CGRectMake(0, 0, 100, 100)];
        [r setPosition: CGPointMake(50, 50)];
        [r addSublayer: child(1, 1, 1)];
        [r setInstanceCount: 2];
        [r setInstanceTransform: CATransform3DMakeTranslation(30, 0, 0)];
        [r setInstanceColor: blue];
        draw(r);
        box("instanceColor blue, white child");
        pixel(10, 10, "first instance");
        pixel(40, 10, "second instance");
        CGColorRelease(blue);
      }
      {
        CAReplicatorLayer *r = [CAReplicatorLayer layer];

        [r setBounds: CGRectMake(0, 0, 100, 100)];
        [r setPosition: CGPointMake(50, 50)];
        [r addSublayer: child(1, 1, 1)];
        [r setInstanceCount: 3];
        [r setInstanceTransform: CATransform3DMakeTranslation(30, 0, 0)];
        [r setInstanceRedOffset: -0.25];
        draw(r);
        box("instanceRedOffset -0.25, white child");
        pixel(10, 10, "first instance");
        pixel(40, 10, "second instance");
        pixel(70, 10, "third instance");
      }
      {
        CAReplicatorLayer *r = [CAReplicatorLayer layer];
        CGColorRef green = CGColorCreateGenericRGB(0, 1, 0, 1);

        [r setBounds: CGRectMake(0, 0, 40, 40)];
        [r setPosition: CGPointMake(20, 20)];
        [r setBackgroundColor: green];
        [r addSublayer: child(1, 0, 0)];
        [r setInstanceCount: 3];
        [r setInstanceTransform: CATransform3DMakeTranslation(60, 0, 0)];
        draw(r);
        box("own background, 3 instances +60x");
        pixel(30, 30, "its own background");
        pixel(90, 30, "where a repeated background would be");
        CGColorRelease(green);
      }

      [CATransaction commit];
      CGLDestroyContext(ctx);
    }
  return 0;
}

/* What a CATextLayer draws through -renderInContext:.  The layer is 160x60
   at the context origin of a 200x100 context, white text unless said
   otherwise.  Pixel y counts up from the bottom, the way layer geometry
   does. */
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#include <stdio.h>
#include <string.h>

#define W 200
#define H 100

static CGContextRef newContext(void)
{
  CGColorSpaceRef space = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
  CGContextRef c = CGBitmapContextCreate(NULL, W, H, 8, W * 4, space,
                                         kCGImageAlphaPremultipliedLast);
  CGColorSpaceRelease(space);
  if (c)
    memset(CGBitmapContextGetData(c), 0, W * H * 4);
  return c;
}

static unsigned char *pixel(CGContextRef c, int x, int y)
{
  return (unsigned char *)CGBitmapContextGetData(c) + ((H - 1 - y) * W + x) * 4;
}

static void box(CGContextRef c, const char *label)
{
  int x, y, minX = W, minY = H, maxX = -1, maxY = -1, n = 0;

  for (y = 0; y < H; y++)
    for (x = 0; x < W; x++)
      {
        unsigned char *p = pixel(c, x, y);

        if (p[0] || p[1] || p[2] || p[3])
          {
            n++;
            if (x < minX) minX = x;
            if (y < minY) minY = y;
            if (x > maxX) maxX = x;
            if (y > maxY) maxY = y;
          }
      }
  if (maxX < 0)
    printf("  %-36s nothing drawn\n", label);
  else
    printf("  %-36s x %3d..%-3d y %2d..%-2d count %d\n", label,
           minX, maxX, minY, maxY, n);
}

static CATextLayer *text(id string)
{
  CATextLayer *t = [CATextLayer layer];

  [t setBounds: CGRectMake(0, 0, 160, 60)];
  [t setString: string];
  return t;
}

static void render(CATextLayer *t, const char *label)
{
  CGContextRef c = newContext();

  [t renderInContext: c];
  box(c, label);
  CGContextRelease(c);
}

int main(void)
{
  @autoreleasepool {
    printf("=== does renderInContext draw text at all ===\n");
    render(text(@"Hg"), "default: Helvetica 36, white");

    printf("\n=== the defaults ===\n");
    {
      CATextLayer *t = [CATextLayer layer];

      printf("  string %s fontSize %g wrapped %d\n",
             [t string] ? "set" : "nil", [t fontSize], [t isWrapped]);
      printf("  alignmentMode %s truncationMode %s\n",
             [[t alignmentMode] UTF8String], [[t truncationMode] UTF8String]);
      printf("  font %s\n",
             [[(id)[t font] description] UTF8String]);
    }

    printf("\n=== nothing to draw ===\n");
    render(text(nil), "no string");
    render(text(@""), "an empty string");

    printf("\n=== where the line sits, and the size ===\n");
    render(text(@"Hg"), "at the default size");
    {
      CATextLayer *small = text(@"Hg");
      [small setFontSize: 12];
      render(small, "fontSize 12");
    }
    {
      CATextLayer *tall = text(@"Hg");
      [tall setBounds: CGRectMake(0, 0, 160, 90)];
      render(tall, "the same in a taller layer");
    }

    printf("\n=== alignment ===\n");
    {
      NSString *names[5] = { @"natural", @"left", @"right", @"center",
                             @"justified" };
      NSString *modes[5] = { kCAAlignmentNatural, kCAAlignmentLeft,
                             kCAAlignmentRight, kCAAlignmentCenter,
                             kCAAlignmentJustified };
      int i;

      for (i = 0; i < 5; i++)
        {
          CATextLayer *t = text(@"Hg");

          [t setAlignmentMode: modes[i]];
          render(t, [names[i] UTF8String]);
        }
    }

    printf("\n=== a string too long for the layer ===\n");
    {
      NSString *longer = @"Hamburgefonstiv Hamburgefonstiv";
      CATextLayer *plain = text(longer);

      render(plain, "wrapped NO, truncation none");

      CATextLayer *wrapped = text(longer);
      [wrapped setWrapped: YES];
      render(wrapped, "wrapped YES");

      CATextLayer *cut = text(longer);
      [cut setTruncationMode: kCATruncationEnd];
      render(cut, "truncation end");

      CATextLayer *middle = text(longer);
      [middle setTruncationMode: kCATruncationMiddle];
      render(middle, "truncation middle");
    }

    printf("\n=== the colour ===\n");
    {
      CGColorRef red = CGColorCreateGenericRGB(1, 0, 0, 1);
      CATextLayer *t = text(@"Hg");
      CGContextRef c = newContext();
      int x, y;

      [t setForegroundColor: red];
      [t renderInContext: c];
      box(c, "foregroundColor red");
      for (y = H - 1; y >= 0; y--)
        for (x = 0; x < W; x++)
          {
            unsigned char *p = pixel(c, x, y);

            if (p[3] > 200)
              {
                printf("  %-36s (%3d,%2d) r %3d g %3d b %3d a %3d\n",
                       "a solid pixel of it", x, y, p[0], p[1], p[2], p[3]);
                y = -1;
                break;
              }
          }
      CGColorRelease(red);
      CGContextRelease(c);
    }

    printf("\n=== an attributed string ===\n");
    {
      CGColorRef blue = CGColorCreateGenericRGB(0, 0, 1, 1);
      NSMutableAttributedString *as = [[[NSMutableAttributedString alloc]
        initWithString: @"Hg"] autorelease];
      CATextLayer *t;
      CGContextRef c = newContext();
      int x, y;

      [as addAttribute: (NSString *)kCTForegroundColorAttributeName
                 value: (id)blue
                 range: NSMakeRange(0, 2)];
      t = text(as);
      [t setForegroundColor: CGColorCreateGenericRGB(1, 0, 0, 1)];
      [t renderInContext: c];
      box(c, "an attributed string, red foregroundColor");
      for (y = H - 1; y >= 0; y--)
        for (x = 0; x < W; x++)
          {
            unsigned char *p = pixel(c, x, y);

            if (p[3] > 200)
              {
                printf("  %-36s (%3d,%2d) r %3d g %3d b %3d\n",
                       "a solid pixel of it", x, y, p[0], p[1], p[2]);
                y = -1;
                break;
              }
          }
      CGColorRelease(blue);
      CGContextRelease(c);
    }

    printf("\n=== against the contents and the background ===\n");
    {
      CGColorSpaceRef space
        = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
      CGContextRef ic = CGBitmapContextCreate(NULL, 160, 60, 8, 160 * 4, space,
                                              kCGImageAlphaPremultipliedLast);
      CGColorRef green = CGColorCreateGenericRGB(0, 1, 0, 1);
      CGImageRef image;
      CGContextRef c;
      CATextLayer *t;
      int x, y;

      CGColorSpaceRelease(space);
      memset(CGBitmapContextGetData(ic), 0, 160 * 60 * 4);
      CGContextSetFillColorWithColor(ic, green);
      CGContextFillRect(ic, CGRectMake(0, 0, 160, 60));
      image = CGBitmapContextCreateImage(ic);

      c = newContext();
      t = text(@"Hg");
      [t setContents: (id)image];
      [t setContentsGravity: kCAGravityResize];
      [t renderInContext: c];
      box(c, "text with contents as well");
      for (y = 59; y >= 0; y--)
        {
          unsigned char *p = pixel(c, 20, y);

          if (p[0] > 200 && p[1] > 200 && p[2] > 200)
            {
              printf("  %-36s white text is visible at (20,%d)\n", "", y);
              break;
            }
          if (y == 0)
            printf("  %-36s no white anywhere: the contents cover it\n", "");
        }

      CGImageRelease(image);
      CGColorRelease(green);
      CGContextRelease(ic);
      CGContextRelease(c);
    }

    printf("\n=== does it ask to be redrawn ===\n");
    {
      CATextLayer *t = text(@"Hg");

      [t display];
      printf("  needsDisplay after a display: %d\n", [t needsDisplay]);
      [t setString: @"Other"];
      printf("  after setString: %d\n", [t needsDisplay]);
      [t display];
      [t setFontSize: 12];
      printf("  after setFontSize: %d\n", [t needsDisplay]);
    }
  }
  return 0;
}

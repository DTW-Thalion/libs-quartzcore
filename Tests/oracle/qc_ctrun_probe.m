/* Where does CTRunDraw put the glyphs of a SUB-RANGE?  Opal offsets the glyph
   pointer by range.location and leaves the position pointer alone, which would
   paint the right glyphs at the places of the first ones.

   Run on a macOS runner:
     clang -framework CoreText -framework CoreGraphics -framework Foundation \
       Tests/oracle/qc_ctrun_probe.m -o qc_ctrun_probe
*/

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>
#import <CoreGraphics/CoreGraphics.h>

#define W 220
#define H 60

static CGContextRef newContext(void)
{
  CGColorSpaceRef space = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
  CGContextRef c = CGBitmapContextCreate(NULL, W, H, 8, W * 4, space,
                                         kCGImageAlphaPremultipliedLast);
  CGColorSpaceRelease(space);
  memset(CGBitmapContextGetData(c), 0, W * H * 4);
  return c;
}

static void box(CGContextRef c, const char *what)
{
  unsigned char *d = CGBitmapContextGetData(c);
  int x, y, x0 = W, x1 = -1, n = 0;

  for (y = 0; y < H; y++)
    for (x = 0; x < W; x++)
      {
        unsigned char *p = d + (y * W + x) * 4;

        if (p[0] || p[1] || p[2] || p[3])
          {
            n++;
            if (x < x0) x0 = x;
            if (x > x1) x1 = x;
          }
      }
  printf("%-40s x %d..%d  %d points\n", what, x0, x1, n);
}

int main(void)
{
  @autoreleasepool
    {
      CTFontRef font = CTFontCreateWithName(CFSTR("Helvetica"), 24, NULL);
      NSDictionary *attributes =
        [NSDictionary dictionaryWithObject: (id)font
                                    forKey: (id)kCTFontAttributeName];
      NSAttributedString *as =
        [[NSAttributedString alloc] initWithString: @"HHHH"
                                        attributes: attributes];
      CTLineRef line = CTLineCreateWithAttributedString((CFAttributedStringRef)as);
      CFArrayRef runs = CTLineGetGlyphRuns(line);
      CTRunRef run = CFArrayGetValueAtIndex(runs, 0);
      const CGPoint *positions = CTRunGetPositionsPtr(run);
      CFIndex i, count = CTRunGetGlyphCount(run);

      printf("%ld runs, %ld glyphs\n", (long)CFArrayGetCount(runs), (long)count);
      for (i = 0; i < count; i++)
        {
          printf("  position %ld: %.2f\n", (long)i, (double)positions[i].x);
        }

      {
        CGContextRef c = newContext();

        CGContextSetTextPosition(c, 10, 20);
        CTRunDraw(run, c, CFRangeMake(0, 0));
        box(c, "the whole run, range (0,0)");
        CGContextRelease(c);
      }
      {
        CGContextRef c = newContext();

        CGContextSetTextPosition(c, 10, 20);
        CTRunDraw(run, c, CFRangeMake(0, 4));
        box(c, "the whole run, range (0,4)");
        CGContextRelease(c);
      }
      {
        CGContextRef c = newContext();

        CGContextSetTextPosition(c, 10, 20);
        CTRunDraw(run, c, CFRangeMake(2, 2));
        box(c, "the last two glyphs, range (2,2)");
        CGContextRelease(c);
      }
      {
        CGContextRef c = newContext();

        CGContextSetTextPosition(c, 10, 20);
        CTRunDraw(run, c, CFRangeMake(3, 1));
        box(c, "the last glyph alone, range (3,1)");
        CGContextRelease(c);
      }

      CFRelease(line);
      [as release];
      CFRelease(font);
    }
  return 0;
}

/* The boundaries the first truncation probe left open: a width that only the
   token fits in, and a line of more than one run.

   Run on a macOS runner:
     clang -framework CoreText -framework CoreGraphics -framework Foundation \
       Tests/oracle/qc_truncate2_probe.m -o qc_truncate2_probe
*/

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>
#import <CoreGraphics/CoreGraphics.h>

static CTLineRef lineOf(NSString *string, const char *name, CGFloat size)
{
  CTFontRef font = CTFontCreateWithName((CFStringRef)
                                          [NSString stringWithUTF8String: name],
                                        size, NULL);
  NSDictionary *attributes =
    [NSDictionary dictionaryWithObject: (id)font
                                forKey: (id)kCTFontAttributeName];
  NSAttributedString *as =
    [[NSAttributedString alloc] initWithString: string
                                    attributes: attributes];
  CTLineRef line = CTLineCreateWithAttributedString((CFAttributedStringRef)as);

  [as release];
  CFRelease(font);
  return line;
}

static void report(const char *what, CTLineRef line)
{
  if (line == NULL)
    {
      printf("%-44s (null)\n", what);
      return;
    }
  printf("%-44s %ld glyphs, %ld runs, width %.2f\n", what,
         (long)CTLineGetGlyphCount(line),
         (long)CFArrayGetCount(CTLineGetGlyphRuns(line)),
         CTLineGetTypographicBounds(line, NULL, NULL, NULL));
}

int main(void)
{
  @autoreleasepool
    {
      CTLineRef full = lineOf(@"HHHHHHHHHHHHHHHH", "Helvetica", 24);
      CTLineRef token = lineOf(@"…", "Helvetica", 24);
      double tokenWidth = CTLineGetTypographicBounds(token, NULL, NULL, NULL);
      int w;

      printf("token width %.2f\n", tokenWidth);
      for (w = 22; w <= 46; w += 3)
        {
          CTLineRef cut = CTLineCreateTruncatedLine(full, w,
                                                    kCTLineTruncationEnd,
                                                    token);
          char what[64];

          snprintf(what, sizeof(what), "end, width %d", w);
          report(what, cut);
          if (cut) CFRelease(cut);
        }

      printf("\n=== an odd number of glyphs, truncated in the middle ===\n");
      {
        CTLineRef five = lineOf(@"HHHHH", "Helvetica", 24);
        double whole = CTLineGetTypographicBounds(five, NULL, NULL, NULL);
        CTLineRef cut = CTLineCreateTruncatedLine(five, whole - 20,
                                                 kCTLineTruncationMiddle,
                                                 token);

        printf("five glyphs are %.2f wide, truncating to %.2f\n",
               whole, whole - 20);
        report("middle", cut);
        if (cut) CFRelease(cut);
        CFRelease(five);
      }

      printf("\n=== a line of two runs ===\n");
      {
        CTFontRef small = CTFontCreateWithName(CFSTR("Helvetica"), 12, NULL);
        CTFontRef big = CTFontCreateWithName(CFSTR("Helvetica"), 36, NULL);
        NSMutableAttributedString *mixed =
          [[NSMutableAttributedString alloc] initWithString: @"HHHHHHHH"];
        CTLineRef line;
        double whole;

        [mixed addAttribute: (id)kCTFontAttributeName
                      value: (id)small
                      range: NSMakeRange(0, 4)];
        [mixed addAttribute: (id)kCTFontAttributeName
                      value: (id)big
                      range: NSMakeRange(4, 4)];
        line = CTLineCreateWithAttributedString((CFAttributedStringRef)mixed);
        whole = CTLineGetTypographicBounds(line, NULL, NULL, NULL);
        report("the mixed line", line);

        {
          CTLineRef cut = CTLineCreateTruncatedLine(line, whole / 2,
                                                    kCTLineTruncationEnd,
                                                    token);

          printf("truncating %.2f to %.2f\n", whole, whole / 2);
          report("end", cut);
          if (cut) CFRelease(cut);
        }
        {
          CTLineRef cut = CTLineCreateTruncatedLine(line, whole / 2,
                                                    kCTLineTruncationStart,
                                                    token);

          report("start", cut);
          if (cut) CFRelease(cut);
        }

        CFRelease(line);
        [mixed release];
        CFRelease(small);
        CFRelease(big);
      }

      CFRelease(full);
      CFRelease(token);
    }
  return 0;
}

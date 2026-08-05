/* What CTLineCreateTruncatedLine answers, for the Opal implementation to
   match: what comes back when the line already fits, what a NULL token does,
   which glyphs each truncation type keeps, and how the width relates to the
   width asked for.

   Run on a macOS runner:
     clang -framework CoreText -framework CoreGraphics -framework Foundation \
       Tests/oracle/qc_truncate_probe.m -o qc_truncate_probe
*/

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>
#import <CoreGraphics/CoreGraphics.h>

static CTFontRef theFont(void)
{
  return CTFontCreateWithName(CFSTR("Helvetica"), 24, NULL);
}

static CTLineRef lineOf(NSString *string)
{
  CTFontRef font = theFont();
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
  CGFloat ascent = 0, descent = 0, leading = 0;
  double width;

  if (line == NULL)
    {
      printf("%-44s (null)\n", what);
      return;
    }
  width = CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
  printf("%-44s %ld glyphs, %ld runs, width %.2f, range %ld+%ld\n", what,
         (long)CTLineGetGlyphCount(line),
         (long)CFArrayGetCount(CTLineGetGlyphRuns(line)),
         width,
         (long)CTLineGetStringRange(line).location,
         (long)CTLineGetStringRange(line).length);
}

int main(void)
{
  @autoreleasepool
    {
      CTLineRef full = lineOf(@"HHHHHHHHHHHHHHHH");
      CTLineRef token = lineOf(@"…");
      double whole = CTLineGetTypographicBounds(full, NULL, NULL, NULL);
      double half = whole / 2.0;

      report("the whole line", full);
      report("the ellipsis token", token);
      printf("whole width %.2f, truncating to %.2f\n", whole, half);

      printf("\n=== with an ellipsis token ===\n");
      {
        CTLineRef end = CTLineCreateTruncatedLine(full, half,
                                                  kCTLineTruncationEnd, token);
        CTLineRef start = CTLineCreateTruncatedLine(full, half,
                                                    kCTLineTruncationStart,
                                                    token);
        CTLineRef middle = CTLineCreateTruncatedLine(full, half,
                                                     kCTLineTruncationMiddle,
                                                     token);

        report("end", end);
        report("start", start);
        report("middle", middle);
        if (end) CFRelease(end);
        if (start) CFRelease(start);
        if (middle) CFRelease(middle);
      }

      printf("\n=== with no token ===\n");
      {
        CTLineRef end = CTLineCreateTruncatedLine(full, half,
                                                  kCTLineTruncationEnd, NULL);

        report("end, token NULL", end);
        if (end) CFRelease(end);
      }

      printf("\n=== when it already fits ===\n");
      {
        CTLineRef same = CTLineCreateTruncatedLine(full, whole + 50,
                                                   kCTLineTruncationEnd,
                                                   token);

        report("truncated to more than it needs", same);
        printf("%-44s %s\n", "and it is the line that went in",
               same == full ? "yes" : "no");
        if (same) CFRelease(same);
      }

      printf("\n=== the awkward widths ===\n");
      {
        CTLineRef none = CTLineCreateTruncatedLine(full, 0,
                                                   kCTLineTruncationEnd,
                                                   token);
        CTLineRef tiny = CTLineCreateTruncatedLine(full, 5,
                                                   kCTLineTruncationEnd,
                                                   token);
        CTLineRef negative = CTLineCreateTruncatedLine(full, -10,
                                                       kCTLineTruncationEnd,
                                                       token);

        report("width 0", none);
        report("width 5, narrower than the token", tiny);
        report("width -10", negative);
        if (none) CFRelease(none);
        if (tiny) CFRelease(tiny);
        if (negative) CFRelease(negative);
      }

      printf("\n=== a line of one glyph ===\n");
      {
        CTLineRef one = lineOf(@"H");
        CTLineRef cut = CTLineCreateTruncatedLine(one, 5,
                                                  kCTLineTruncationEnd, token);

        report("one glyph truncated to 5", cut);
        if (cut) CFRelease(cut);
        CFRelease(one);
      }

      CFRelease(full);
      CFRelease(token);
    }
  return 0;
}

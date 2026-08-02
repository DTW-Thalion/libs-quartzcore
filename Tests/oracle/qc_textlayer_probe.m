/* CATextLayer: the values left open by the first layer-class probe, and the
 * alignment and truncation names. */

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

int main(void)
{
  setbuf(stdout, NULL);

  @autoreleasepool
    {
      CATextLayer *t = [CATextLayer layer];

      printf("== defaults ==\n");
      {
        CGColorRef c = [t foregroundColor];

        if (c == NULL)
          {
            printf("foregroundColor            (null)\n");
          }
        else
          {
            size_t i, n = CGColorGetNumberOfComponents(c);
            const CGFloat *comps = CGColorGetComponents(c);

            printf("foregroundColor            %zu components:", n);
            for (i = 0; i < n; i++)
              {
                printf(" %g", (double)comps[i]);
              }
            printf("  alpha=%g\n", (double)CGColorGetAlpha(c));
          }
      }

      printf("font                       %s\n",
             [t font] ? [[(id)[t font] description] UTF8String] : "(nil)");
      printf("font class                 %s\n",
             [t font] ? [NSStringFromClass([(id)[t font] class]) UTF8String]
                      : "(nil)");
      printf("font type id               %lu\n",
             (unsigned long)CFGetTypeID([t font]));
      printf("CGFontRef type id          %lu\n", (unsigned long)CGFontGetTypeID());
      printf("fontSize                   %g\n", (double)[t fontSize]);
      printf("wrapped                    %d\n", (int)[t isWrapped]);
      printf("alignmentMode              %s\n", [[t alignmentMode] UTF8String]);
      printf("truncationMode             %s\n", [[t truncationMode] UTF8String]);
      printf("allowsFontSubpixelQuant.   %d\n",
             (int)[t allowsFontSubpixelQuantization]);

      printf("\n== the names ==\n");
      printf("alignment  natural=%s left=%s right=%s center=%s justified=%s\n",
             [kCAAlignmentNatural UTF8String], [kCAAlignmentLeft UTF8String],
             [kCAAlignmentRight UTF8String], [kCAAlignmentCenter UTF8String],
             [kCAAlignmentJustified UTF8String]);
      printf("truncation none=%s start=%s end=%s middle=%s\n",
             [kCATruncationNone UTF8String], [kCATruncationStart UTF8String],
             [kCATruncationEnd UTF8String], [kCATruncationMiddle UTF8String]);

      printf("\n== what the setters keep ==\n");
      [t setString: @"hello"];
      printf("string kept                %s (class %s)\n",
             [[[t string] description] UTF8String],
             [NSStringFromClass([(id)[t string] class]) UTF8String]);

      [t setFontSize: 12.0];
      printf("fontSize kept              %g\n", (double)[t fontSize]);

      [t setWrapped: YES];
      printf("wrapped kept               %d\n", (int)[t isWrapped]);

      [t setAlignmentMode: kCAAlignmentCenter];
      printf("alignmentMode kept         %s\n", [[t alignmentMode] UTF8String]);

      [t setTruncationMode: kCATruncationEnd];
      printf("truncationMode kept        %s\n", [[t truncationMode] UTF8String]);

      [t setAlignmentMode: @"notAnAlignment"];
      printf("bogus alignment kept       %s\n",
             [t alignmentMode] ? [[t alignmentMode] UTF8String] : "(nil)");

      [t setFont: (__bridge CFTypeRef)@"Times"];
      printf("font set to a name         %s\n",
             [t font] ? [[(id)[t font] description] UTF8String] : "(nil)");

      {
        CGColorSpaceRef sp = CGColorSpaceCreateDeviceRGB();
        CGFloat vals[4] = {1.0, 0.0, 0.0, 1.0};
        CGColorRef red = CGColorCreate(sp, vals);

        [t setForegroundColor: red];
        printf("foregroundColor same ptr   %d\n",
               (int)([t foregroundColor] == red));
        CGColorRelease(red);
        CGColorSpaceRelease(sp);
      }

      [t setString: nil];
      printf("string set to nil          %s\n",
             [t string] ? "not nil" : "(nil)");
    }
  return 0;
}

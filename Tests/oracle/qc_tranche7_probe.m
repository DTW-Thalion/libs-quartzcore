/* The constants and round trips needed to implement the tranche 6
   properties.  String constants go through dlsym so that a name guessed
   wrong costs a printed ABSENT rather than a build failure; the corner mask
   is a plain enum, so its members are referenced directly. */
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#include <stdio.h>
#include <dlfcn.h>

static void str(const char *name)
{
  void *sym = dlsym(RTLD_DEFAULT, name);

  if (sym)
    printf("  %-46s = \"%s\"\n", name, [(NSString *)*(void **)sym UTF8String]);
  else
    printf("  %-46s ABSENT\n", name);
}

static void roundTrip(CALayer *l, const char *key, id value)
{
  NSString *k = [NSString stringWithUTF8String: key];
  id back = nil;

  @try {
    [l setValue: value forKey: k];
  } @catch (NSException *e) {
    printf("  set %-34s RAISED %s\n", key, [[e name] UTF8String]);
    return;
  }
  back = [l valueForKey: k];
  printf("  set %-34s -> %s   (archived %s)\n", key,
         back ? [[back description] UTF8String] : "nil",
         [l shouldArchiveValueForKey: k] ? "YES" : "NO");
}

int main(void)
{
  @autoreleasepool {
    CALayer *l = [CALayer layer];

    printf("=== the corner mask enum ===\n");
    printf("  kCALayerMinXMinYCorner %lu\n",
           (unsigned long)kCALayerMinXMinYCorner);
    printf("  kCALayerMaxXMinYCorner %lu\n",
           (unsigned long)kCALayerMaxXMinYCorner);
    printf("  kCALayerMinXMaxYCorner %lu\n",
           (unsigned long)kCALayerMinXMaxYCorner);
    printf("  kCALayerMaxXMaxYCorner %lu\n",
           (unsigned long)kCALayerMaxXMaxYCorner);

    printf("\n=== dynamic range constants ===\n");
    str("kCADynamicRangeStandard");
    str("kCADynamicRangeConstrainedHigh");
    str("kCADynamicRangeHigh");

    printf("\n=== tone map mode constants, several spellings ===\n");
    str("kCAToneMapModeAutomatic");
    str("kCAToneMapModeNever");
    str("kCAToneMapModeIfSupported");
    str("CAToneMapModeAutomatic");
    str("kCALayerToneMapModeAutomatic");
    str("kCAContentsFormatAutomatic");

    printf("\n=== round trips ===\n");
    roundTrip(l, "cornerCurve", @"continuous");
    roundTrip(l, "cornerCurve", @"not a curve");
    roundTrip(l, "maskedCorners", [NSNumber numberWithUnsignedInt: 5]);
    roundTrip(l, "contentsFormat", @"RGBAh");
    roundTrip(l, "contentsFormat", @"not a format");
    roundTrip(l, "preferredDynamicRange", @"high");
    roundTrip(l, "contentsHeadroom", [NSNumber numberWithFloat: 2.5]);
    roundTrip(l, "wantsExtendedDynamicRangeContent",
              [NSNumber numberWithBool: YES]);
    roundTrip(l, "toneMapMode", @"never");
    roundTrip(l, "wantsDynamicContentScaling", [NSNumber numberWithBool: YES]);

    printf("\n=== needsDisplayForKey ===\n");
    {
      const char *keys[] = { "cornerCurve", "maskedCorners", "contentsFormat",
                             "preferredDynamicRange", "contentsHeadroom",
                             "wantsExtendedDynamicRangeContent",
                             "toneMapMode", "wantsDynamicContentScaling" };
      int i;
      for (i = 0; i < 8; i++)
        {
          NSString *k = [NSString stringWithUTF8String: keys[i]];
          printf("  %-34s %s\n", keys[i],
                 [CALayer needsDisplayForKey: k] ? "YES" : "NO");
        }
    }

    printf("\n=== the expansion factor for a name that is not a curve ===\n");
    {
      SEL sel = NSSelectorFromString(@"cornerCurveExpansionFactor:");
      NSMethodSignature *sig = [CALayer methodSignatureForSelector: sel];
      NSInvocation *inv = [NSInvocation invocationWithMethodSignature: sig];
      NSString *names[] = { @"circular", @"continuous", @"nonsense", nil };
      int i;

      [inv setSelector: sel];
      [inv setTarget: [CALayer class]];
      for (i = 0; i < 4; i++)
        {
          CGFloat out = 0;
          NSString *n = names[i];

          @try {
            [inv setArgument: &n atIndex: 2];
            [inv invoke];
            [inv getReturnValue: &out];
            printf("  %-12s %g\n", n ? [n UTF8String] : "(nil)", (double)out);
          } @catch (NSException *e) {
            printf("  %-12s RAISED %s\n", n ? [n UTF8String] : "(nil)",
                   [[e name] UTF8String]);
          }
        }
    }
  }
  return 0;
}

/* Which of the tranche 6 symbols this runner's SDK declares at all, and what
   they answer.  Everything goes through -respondsToSelector: and KVC rather
   than through a direct message, so that a symbol the SDK does not declare
   costs a printed "absent" instead of a build failure. */
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#include <stdio.h>
#include <dlfcn.h>

static void reportProperty(CALayer *l, const char *name, const char *getter)
{
  SEL sel = NSSelectorFromString([NSString stringWithUTF8String: getter]);
  NSString *key = [NSString stringWithUTF8String: name];
  id value = nil;

  if (![l respondsToSelector: sel])
    {
      printf("%-34s ABSENT from this SDK\n", name);
      return;
    }
  @try {
    value = [l valueForKey: key];
  } @catch (NSException *e) {
    printf("%-34s present, valueForKey RAISED %s\n", name,
           [[e name] UTF8String]);
    return;
  }
  printf("%-34s present, value %s\n", name,
         value ? [[value description] UTF8String] : "nil");
}

static void reportDefault(const char *name)
{
  NSString *key = [NSString stringWithUTF8String: name];
  id v = nil;

  @try {
    v = [CALayer defaultValueForKey: key];
  } @catch (NSException *e) {
    printf("  defaultValueForKey %-28s RAISED\n", name);
    return;
  }
  printf("  defaultValueForKey %-28s %s\n", name,
         v ? [[v description] UTF8String] : "nil");
}

int main(void)
{
  @autoreleasepool {
    CALayer *l = [CALayer layer];

    printf("=== macOS version ===\n");
    printf("%s\n", [[[NSProcessInfo processInfo]
                      operatingSystemVersionString] UTF8String]);

    printf("\n=== the corner group ===\n");
    reportProperty(l, "cornerCurve", "cornerCurve");
    reportProperty(l, "maskedCorners", "maskedCorners");
    reportProperty(l, "cornerRadius", "cornerRadius");
    printf("+cornerCurveExpansionFactor: %s\n",
           [CALayer respondsToSelector:
             NSSelectorFromString(@"cornerCurveExpansionFactor:")]
             ? "present" : "ABSENT");
    reportDefault("cornerCurve");
    reportDefault("maskedCorners");

    printf("\n=== contentsFormat ===\n");
    reportProperty(l, "contentsFormat", "contentsFormat");
    reportDefault("contentsFormat");

    printf("\n=== the dynamic range group ===\n");
    reportProperty(l, "preferredDynamicRange", "preferredDynamicRange");
    reportProperty(l, "contentsHeadroom", "contentsHeadroom");
    reportProperty(l, "wantsExtendedDynamicRangeContent",
                   "wantsExtendedDynamicRangeContent");
    reportProperty(l, "toneMapMode", "toneMapMode");
    reportProperty(l, "wantsDynamicContentScaling",
                   "wantsDynamicContentScaling");
    reportDefault("preferredDynamicRange");
    reportDefault("contentsHeadroom");
    reportDefault("wantsExtendedDynamicRangeContent");
    reportDefault("toneMapMode");
    reportDefault("wantsDynamicContentScaling");

    printf("\n=== do they archive on a new layer? ===\n");
    {
      const char *keys[] = { "cornerCurve", "maskedCorners", "contentsFormat",
                             "preferredDynamicRange", "contentsHeadroom",
                             "wantsExtendedDynamicRangeContent",
                             "toneMapMode", "wantsDynamicContentScaling" };
      int i;
      for (i = 0; i < 8; i++)
        {
          NSString *k = [NSString stringWithUTF8String: keys[i]];
          @try {
            printf("  %-34s %s\n", keys[i],
                   [l shouldArchiveValueForKey: k] ? "YES" : "NO");
          } @catch (NSException *e) {
            printf("  %-34s RAISED\n", keys[i]);
          }
        }
    }

    printf("\n=== the string constants ===\n");
    {
      const char *names[] = { "kCACornerCurveCircular",
                              "kCACornerCurveContinuous",
                              "kCAContentsFormatRGBA8Uint",
                              "kCAContentsFormatRGBA16Float",
                              "kCAContentsFormatGray8Uint",
                              "kCAToneMapModeAutomatic",
                              "kCAToneMapModeNever",
                              "kCAToneMapModeIfSupported",
                              "kCAToneMapModeReferenceDisplayLuminance" };
      int i;
      for (i = 0; i < 9; i++)
        {
          void *sym = dlsym(RTLD_DEFAULT, names[i]);
          if (sym)
            printf("  %-42s = \"%s\"\n", names[i],
                   [(NSString *)*(void **)sym UTF8String]);
          else
            printf("  %-42s ABSENT\n", names[i]);
        }
    }

    printf("\n=== does a corner curve change what is drawn? ===\n");
    if ([l respondsToSelector: NSSelectorFromString(@"setCornerCurve:")])
      {
        printf("  cornerCurve can be set; expansion factors:\n");
        SEL sel = NSSelectorFromString(@"cornerCurveExpansionFactor:");
        if ([CALayer respondsToSelector: sel])
          {
            NSMethodSignature *sig
              = [CALayer methodSignatureForSelector: sel];
            NSInvocation *inv
              = [NSInvocation invocationWithMethodSignature: sig];
            NSString *curves[] = { @"circular", @"continuous" };
            int i;
            [inv setSelector: sel];
            [inv setTarget: [CALayer class]];
            for (i = 0; i < 2; i++)
              {
                CGFloat out = 0;
                NSString *c = curves[i];
                [inv setArgument: &c atIndex: 2];
                [inv invoke];
                [inv getReturnValue: &out];
                printf("    %-12s %g\n", [c UTF8String], (double)out);
              }
          }
      }
    else
      {
        printf("  cornerCurve is absent, nothing to try\n");
      }
  }
  return 0;
}

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

int main(void)
{
  @autoreleasepool {
    printf("=== tone map modes ===\n");
    str("CAToneMapModeAutomatic");
    str("CAToneMapModeNever");
    str("CAToneMapModeIfSupported");
    str("CAToneMapModeReferenceDisplayLuminance");

    printf("\n=== dynamic ranges ===\n");
    str("CADynamicRangeStandard");
    str("CADynamicRangeConstrainedHigh");
    str("CADynamicRangeHigh");

    printf("\n=== contents formats, both spellings ===\n");
    str("kCAContentsFormatAutomatic");
    str("kCAContentsFormatRGBA8Uint");
    str("kCAContentsFormatRGBA16Float");
    str("kCAContentsFormatGray8Uint");

    printf("\n=== a value that is not one of them ===\n");
    {
      CALayer *l = [CALayer layer];

      [l setValue: @"nonsense" forKey: @"preferredDynamicRange"];
      printf("  preferredDynamicRange after nonsense: %s\n",
             [[[l valueForKey: @"preferredDynamicRange"] description]
               UTF8String]);
      [l setValue: @"nonsense" forKey: @"toneMapMode"];
      printf("  toneMapMode after nonsense: %s\n",
             [[[l valueForKey: @"toneMapMode"] description] UTF8String]);
      [l setValue: [NSNumber numberWithFloat: -3] forKey: @"contentsHeadroom"];
      printf("  contentsHeadroom after -3: %s\n",
             [[[l valueForKey: @"contentsHeadroom"] description] UTF8String]);
      [l setValue: [NSNumber numberWithUnsignedInt: 255]
           forKey: @"maskedCorners"];
      printf("  maskedCorners after 255: %s\n",
             [[[l valueForKey: @"maskedCorners"] description] UTF8String]);
    }
  }
  return 0;
}

/* Print the value Apple's QuartzCore gives every string constant that
   GNUstep's QuartzCore headers declare.  Symbols are looked up by name so
   that constants which are not in Apple's public headers are covered too.

   Run on a macOS runner:
     clang -framework QuartzCore -framework CoreGraphics -framework Foundation \
       Tests/oracle/qc_constants_probe.m -o qc_constants_probe
*/

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#include <dlfcn.h>

static const char *names[] = {
  "kCAAnimationDiscrete",
  "kCAAnimationLinear",
  "kCAAnimationPaced",
  "kCAAnimationCubic",
  "kCAAnimationCubicPaced",
  "kCAFillModeRemoved",
  "kCAFillModeForwards",
  "kCAFillModeBackwards",
  "kCAFillModeBoth",
  "kCAFillModeFrozen",
  "kCAFillRuleNonZero",
  "kCAFillRuleEvenOdd",
  "kCALineJoinMiter",
  "kCALineJoinRound",
  "kCALineJoinBevel",
  "kCALineCapButt",
  "kCALineCapRound",
  "kCALineCapSquare",
  "kCAMediaTimingFunctionDefault",
  "kCAMediaTimingFunctionLinear",
  "kCAMediaTimingFunctionEaseIn",
  "kCAMediaTimingFunctionEaseOut",
  "kCAMediaTimingFunctionEaseInEaseOut",
  "kCAGravityResize",
  "kCAGravityResizeAspect",
  "kCAGravityResizeAspectFill",
  "kCAGravityCenter",
  "kCAGravityTop",
  "kCAGravityBottom",
  "kCAGravityLeft",
  "kCAGravityRight",
  "kCAGravityTopLeft",
  "kCAGravityTopRight",
  "kCAGravityBottomLeft",
  "kCAGravityBottomRight",
  "kCATransition",
  "kCATransitionFade",
  "kCATransitionMoveIn",
  "kCATransitionPush",
  "kCATransitionReveal",
  "kCATransitionFromRight",
  "kCATransitionFromLeft",
  "kCATransitionFromTop",
  "kCATransitionFromBottom",
  "kCAOnOrderIn",
  "kCAOnOrderOut",
  "kCAValueFunctionRotateX",
  "kCAValueFunctionRotateY",
  "kCAValueFunctionRotateZ",
  "kCAValueFunctionScale",
  "kCAValueFunctionScaleX",
  "kCAValueFunctionScaleY",
  "kCAValueFunctionScaleZ",
  "kCAValueFunctionTranslate",
  "kCAValueFunctionTranslateX",
  "kCAValueFunctionTranslateY",
  "kCAValueFunctionTranslateZ",
  "kCAFilterNearest",
  "kCAFilterLinear",
  "kCAFilterTrilinear",
  "kCAFilterClear",
  "kCAFilterCopy",
  "kCAFilterDestAtop",
  "kCAFilterDestIn",
  "kCAFilterDestOut",
  "kCAFilterDestOver",
  "kCAFilterFog",
  "kCAFilterGaussianBlur",
  "kCAFilterLanczos",
  "kCAFilterLighting",
  "kCAFilterMultiply",
  "kCAFilterMultiplyColor",
  "kCAFilterMultiplyGradient",
  "kCAFilterPageCurl",
  "kCAFilterPlusD",
  "kCAFilterPlusL",
  "kCAFilterSourceAtop",
  "kCAFilterSourceIn",
  "kCAFilterSourceOut",
  "kCAFilterSourceOver",
  "kCAFilterXor",
  "kCAFilterColorInvert",
  "kCAFilterColorMatrix",
  "kCAFilterColorMonochrome",
  "kCAFilterColorHueRotate",
  "kCAFilterColorSaturate",
  "kCAFilterNormalBlendMode",
  "kCAFilterMultiplyBlendMode",
  "kCAFilterScreenBlendMode",
  "kCAFilterOverlayBlendMode",
  "kCAFilterDarkenBlendMode",
  "kCAFilterLightenBlendMode",
  "kCAFilterColorDodgeBlendMode",
  "kCAFilterColorBurnBlendMode",
  "kCAFilterSoftLightBlendMode",
  "kCAFilterHardLightBlendMode",
  "kCAFilterDifferenceBlendMode",
  "kCAFilterExclusionBlendMode",
  "kCATransactionAnimationDuration",
  "kCATransactionDisableActions",
  "kCATransactionAnimationTimingFunction",
  "kCATransactionCompletionBlock",
  NULL
};

int main(int argc, char **argv)
{
  @autoreleasepool
    {
      int i;

      for (i = 0; names[i] != NULL; i++)
        {
          NSString **slot = (NSString **)dlsym(RTLD_DEFAULT, names[i]);

          if (slot == NULL)
            {
              printf("%-40s NOT EXPORTED\n", names[i]);
              continue;
            }
          if (*slot == nil)
            {
              printf("%-40s (nil)\n", names[i]);
              continue;
            }
          printf("%-40s \"%s\"\n", names[i], [*slot UTF8String]);
        }
    }
  return 0;
}

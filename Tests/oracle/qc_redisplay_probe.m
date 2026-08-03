/* What Apple QuartzCore does with +needsDisplayForKey: and
   -removeAllAnimations. */
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@interface RedisplayLayer : CALayer
@end

@implementation RedisplayLayer
+ (BOOL) needsDisplayForKey: (NSString *)key
{
  if ([key isEqualToString: @"opacity"])
    return YES;
  return [super needsDisplayForKey: key];
}
@end

int main(void)
{
  setbuf(stdout, NULL);
  @autoreleasepool
    {
      CALayer *l = [CALayer layer];

      printf("== the default answer ==\n");
      printf("bounds %d\n", (int)[CALayer needsDisplayForKey: @"bounds"]);
      printf("position %d\n", (int)[CALayer needsDisplayForKey: @"position"]);
      printf("opacity %d\n", (int)[CALayer needsDisplayForKey: @"opacity"]);
      printf("contents %d\n", (int)[CALayer needsDisplayForKey: @"contents"]);
      printf("backgroundColor %d\n",
             (int)[CALayer needsDisplayForKey: @"backgroundColor"]);
      printf("bogusKeyNobodyDefines %d\n",
             (int)[CALayer needsDisplayForKey: @"bogusKeyNobodyDefines"]);
      printf("nil key %d\n", (int)[CALayer needsDisplayForKey: nil]);

      printf("== does a plain layer redisplay when a property changes ==\n");
      [l displayIfNeeded];
      printf("after displayIfNeeded, needsDisplay %d\n", (int)[l needsDisplay]);
      [l setOpacity: 0.5];
      printf("after setOpacity, needsDisplay %d\n", (int)[l needsDisplay]);

      printf("== a subclass that says yes for opacity ==\n");
      RedisplayLayer *r = [RedisplayLayer layer];
      printf("subclass answers for opacity %d, for bounds %d\n",
             (int)[RedisplayLayer needsDisplayForKey: @"opacity"],
             (int)[RedisplayLayer needsDisplayForKey: @"bounds"]);
      [r displayIfNeeded];
      printf("after displayIfNeeded, needsDisplay %d\n", (int)[r needsDisplay]);
      [r setBounds: CGRectMake(0, 0, 10, 10)];
      printf("after setBounds, needsDisplay %d\n", (int)[r needsDisplay]);
      [r setOpacity: 0.25];
      printf("after setOpacity, needsDisplay %d\n", (int)[r needsDisplay]);

      printf("== setting the same value again ==\n");
      RedisplayLayer *same = [RedisplayLayer layer];
      [same setOpacity: 0.25];
      [same displayIfNeeded];
      printf("settled, needsDisplay %d\n", (int)[same needsDisplay]);
      [same setOpacity: 0.25];
      printf("after setting the same opacity, needsDisplay %d\n",
             (int)[same needsDisplay]);

      printf("== does it work through setValue:forKey: ==\n");
      RedisplayLayer *kvc = [RedisplayLayer layer];
      [kvc displayIfNeeded];
      [kvc setValue: [NSNumber numberWithFloat: 0.75] forKey: @"opacity"];
      printf("after setValue:forKey:, needsDisplay %d\n",
             (int)[kvc needsDisplay]);

      printf("== removeAllAnimations ==\n");
      CALayer *a = [CALayer layer];
      CABasicAnimation *one = [CABasicAnimation animationWithKeyPath: @"opacity"];
      CABasicAnimation *two = [CABasicAnimation animationWithKeyPath: @"position"];

      printf("animationKeys with none: %s\n",
             [a animationKeys] == nil ? "nil"
               : [[[a animationKeys] description] UTF8String]);
      [a addAnimation: one forKey: @"first"];
      [a addAnimation: two forKey: @"second"];
      printf("after adding two: %s\n",
             [[[a animationKeys] description] UTF8String]);
      [a removeAllAnimations];
      printf("after removeAllAnimations: %s\n",
             [a animationKeys] == nil ? "nil"
               : [[[a animationKeys] description] UTF8String]);
      printf("animationForKey first afterwards: %s\n",
             [a animationForKey: @"first"] == nil ? "nil" : "still there");
      [a removeAllAnimations];
      printf("removing again did not raise\n");

      printf("== does removing an animation redisplay ==\n");
      CALayer *rem = [CALayer layer];
      [rem addAnimation: one forKey: @"first"];
      [rem displayIfNeeded];
      printf("settled, needsDisplay %d\n", (int)[rem needsDisplay]);
      [rem removeAllAnimations];
      printf("after removeAllAnimations, needsDisplay %d\n",
             (int)[rem needsDisplay]);
    }
  return 0;
}

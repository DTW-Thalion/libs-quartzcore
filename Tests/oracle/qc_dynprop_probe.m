/* qc_dynprop_probe.m -- what a CALayer subclass gets from @dynamic.
 *
 * Which types can be synthesised, what a fresh instance reads, whether the
 * values round-trip through the accessors and through KVC, and whether a
 * presentation-layer copy carries them.
 */

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

#define TRY(label, body) \
  @try { body } \
  @catch (NSException *e) { printf("%-34s RAISED %s: %s\n", label, \
    [[e name] UTF8String], [[e reason] UTF8String]); }

@interface ProbeLayer : CALayer
@property (nonatomic, retain) NSString *objectProp;
@property (nonatomic, assign) BOOL boolProp;
@property (nonatomic, assign) int intProp;
@property (nonatomic, assign) unsigned int uintProp;
@property (nonatomic, assign) short shortProp;
@property (nonatomic, assign) NSInteger integerProp;
@property (nonatomic, assign) NSUInteger uintegerProp;
@property (nonatomic, assign) long long longLongProp;
@property (nonatomic, assign) float floatProp;
@property (nonatomic, assign) double doubleProp;
@property (nonatomic, assign) CGPoint pointProp;
@property (nonatomic, assign) CGRect rectProp;
@end

@implementation ProbeLayer
@dynamic objectProp, boolProp, intProp, uintProp, shortProp;
@dynamic integerProp, uintegerProp, longLongProp;
@dynamic floatProp, doubleProp, pointProp, rectProp;
@end

int main(int argc, char **argv)
{
  @autoreleasepool
    {
      printf("== @dynamic on a CALayer subclass ==\n");

      printf("encodings: long=%s ulong=%s NSInteger=%s BOOL=%s "
             "longlong=%s CGPoint=%s\n",
             @encode(long), @encode(unsigned long), @encode(NSInteger),
             @encode(BOOL), @encode(long long), @encode(CGPoint));

      ProbeLayer *l = nil;
      TRY("creating the subclass", l = [ProbeLayer layer];
          printf("%-34s ok (%s)\n", "creating the subclass",
                 [[l description] UTF8String]);)

      if (l == nil)
        {
          printf("no instance, stopping\n");
          return 0;
        }

      /* what a fresh instance reads */
      TRY("fresh objectProp", printf("%-34s %s\n", "fresh objectProp",
            [l objectProp] ? [[l objectProp] UTF8String] : "(nil)");)
      TRY("fresh boolProp", printf("%-34s %d\n", "fresh boolProp",
            (int)[l boolProp]);)
      TRY("fresh intProp", printf("%-34s %d\n", "fresh intProp",
            [l intProp]);)
      TRY("fresh integerProp", printf("%-34s %ld\n", "fresh integerProp",
            (long)[l integerProp]);)
      TRY("fresh uintegerProp", printf("%-34s %lu\n", "fresh uintegerProp",
            (unsigned long)[l uintegerProp]);)
      TRY("fresh longLongProp", printf("%-34s %lld\n", "fresh longLongProp",
            [l longLongProp]);)
      TRY("fresh floatProp", printf("%-34s %f\n", "fresh floatProp",
            [l floatProp]);)
      TRY("fresh doubleProp", printf("%-34s %f\n", "fresh doubleProp",
            [l doubleProp]);)
      TRY("fresh pointProp", printf("%-34s %f %f\n", "fresh pointProp",
            [l pointProp].x, [l pointProp].y);)
      TRY("fresh rectProp", printf("%-34s %f %f %f %f\n", "fresh rectProp",
            [l rectProp].origin.x, [l rectProp].origin.y,
            [l rectProp].size.width, [l rectProp].size.height);)

      /* round trip through the accessors */
      TRY("set/get objectProp", [l setObjectProp: @"hello"];
          printf("%-34s %s\n", "set/get objectProp",
                 [[l objectProp] UTF8String]);)
      TRY("set/get boolProp", [l setBoolProp: YES];
          printf("%-34s %d\n", "set/get boolProp", (int)[l boolProp]);)
      TRY("set/get intProp", [l setIntProp: -42];
          printf("%-34s %d\n", "set/get intProp", [l intProp]);)
      TRY("set/get uintProp", [l setUintProp: 42u];
          printf("%-34s %u\n", "set/get uintProp", [l uintProp]);)
      TRY("set/get shortProp", [l setShortProp: 7];
          printf("%-34s %d\n", "set/get shortProp", (int)[l shortProp]);)
      TRY("set/get integerProp", [l setIntegerProp: -1234567890123LL];
          printf("%-34s %ld\n", "set/get integerProp",
                 (long)[l integerProp]);)
      TRY("set/get uintegerProp", [l setUintegerProp: 1234567890123ULL];
          printf("%-34s %lu\n", "set/get uintegerProp",
                 (unsigned long)[l uintegerProp]);)
      TRY("set/get longLongProp", [l setLongLongProp: -9007199254740993LL];
          printf("%-34s %lld\n", "set/get longLongProp",
                 [l longLongProp]);)
      TRY("set/get floatProp", [l setFloatProp: 1.5f];
          printf("%-34s %f\n", "set/get floatProp", [l floatProp]);)
      TRY("set/get doubleProp", [l setDoubleProp: 2.25];
          printf("%-34s %f\n", "set/get doubleProp", [l doubleProp]);)
      TRY("set/get pointProp", [l setPointProp: CGPointMake(3, 4)];
          printf("%-34s %f %f\n", "set/get pointProp",
                 [l pointProp].x, [l pointProp].y);)
      TRY("set/get rectProp", [l setRectProp: CGRectMake(1, 2, 3, 4)];
          printf("%-34s %f %f %f %f\n", "set/get rectProp",
                 [l rectProp].origin.x, [l rectProp].origin.y,
                 [l rectProp].size.width, [l rectProp].size.height);)

      /* through KVC */
      TRY("valueForKey: intProp", printf("%-34s %s\n", "valueForKey: intProp",
            [[[l valueForKey: @"intProp"] description] UTF8String]);)
      TRY("setValue:forKey: intProp",
          [l setValue: [NSNumber numberWithInt: 99] forKey: @"intProp"];
          printf("%-34s %d\n", "setValue:forKey: intProp", [l intProp]);)
      TRY("valueForKey: objectProp",
          printf("%-34s %s\n", "valueForKey: objectProp",
            [[[l valueForKey: @"objectProp"] description] UTF8String]);)
      TRY("valueForKey: pointProp",
          printf("%-34s %s\n", "valueForKey: pointProp",
            [[[l valueForKey: @"pointProp"] description] UTF8String]);)

      /* setting an object property back to nil */
      TRY("objectProp set to nil", [l setObjectProp: nil];
          printf("%-34s %s\n", "objectProp set to nil",
                 [l objectProp] ? "not nil" : "(nil)");)

      /* does a second instance start clean? */
      TRY("second instance intProp", {
            ProbeLayer *l2 = [ProbeLayer layer];
            printf("%-34s %d\n", "second instance intProp", [l2 intProp]);
          })

      /* does a copy for the presentation layer carry the values? */
      TRY("initWithLayer: carries intProp", {
            [l setIntProp: 77];
            ProbeLayer *copy = [[ProbeLayer alloc] initWithLayer: l];
            printf("%-34s %d\n", "initWithLayer: carries intProp",
                   [copy intProp]);
          })

      /* is a dynamic property animatable / does it want display? */
      TRY("needsDisplayForKey: intProp", printf("%-34s %d\n",
            "needsDisplayForKey: intProp",
            (int)[ProbeLayer needsDisplayForKey: @"intProp"]);)
      TRY("defaultValueForKey: intProp", printf("%-34s %s\n",
            "defaultValueForKey: intProp",
            [[[ProbeLayer defaultValueForKey: @"intProp"] description]
              UTF8String]);)
      TRY("actionForKey: intProp", printf("%-34s %s\n",
            "actionForKey: intProp",
            [[[l actionForKey: @"intProp"] description] UTF8String]);)
    }
  return 0;
}

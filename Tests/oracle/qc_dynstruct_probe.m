/* Which structure-typed @dynamic properties Apple QuartzCore synthesises on
   a CALayer subclass, and what a fresh one reads. */
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

#define DYNAMIC_LAYER(name, type) \
@interface name : CALayer \
@property (nonatomic, assign) type p; \
@end \
@implementation name \
@dynamic p; \
@end

DYNAMIC_LAYER(DynPointLayer, CGPoint)
DYNAMIC_LAYER(DynSizeLayer, CGSize)
DYNAMIC_LAYER(DynRectLayer, CGRect)
DYNAMIC_LAYER(DynTransformLayer, CATransform3D)

int main(void)
{
  setbuf(stdout, NULL);
  @autoreleasepool
    {
      @try
        {
          DynPointLayer *l = [DynPointLayer layer];
          CGPoint fresh = [l p];
          printf("point fresh (%g,%g)\n", fresh.x, fresh.y);
          [l setP: CGPointMake(3, 4)];
          printf("point kept (%g,%g)\n", [l p].x, [l p].y);
        }
      @catch (NSException *e) { printf("point raised %s\n", [[e name] UTF8String]); }

      @try
        {
          DynSizeLayer *l = [DynSizeLayer layer];
          CGSize fresh = [l p];
          printf("size fresh (%g,%g)\n", fresh.width, fresh.height);
          [l setP: CGSizeMake(5, 6)];
          printf("size kept (%g,%g)\n", [l p].width, [l p].height);
        }
      @catch (NSException *e) { printf("size raised %s\n", [[e name] UTF8String]); }

      @try
        {
          DynRectLayer *l = [DynRectLayer layer];
          CGRect fresh = [l p];
          printf("rect fresh (%g,%g,%g,%g)\n", fresh.origin.x, fresh.origin.y,
                 fresh.size.width, fresh.size.height);
          [l setP: CGRectMake(1, 2, 3, 4)];
          printf("rect kept (%g,%g,%g,%g)\n", [l p].origin.x, [l p].origin.y,
                 [l p].size.width, [l p].size.height);
        }
      @catch (NSException *e) { printf("rect raised %s\n", [[e name] UTF8String]); }

      @try
        {
          DynTransformLayer *l = [DynTransformLayer layer];
          CATransform3D fresh = [l p];
          printf("transform fresh m11 %g m44 %g, identity %d\n",
                 fresh.m11, fresh.m44, (int)CATransform3DIsIdentity(fresh));
          [l setP: CATransform3DMakeScale(2, 3, 4)];
          printf("transform kept m11 %g m22 %g m33 %g\n",
                 [l p].m11, [l p].m22, [l p].m33);
        }
      @catch (NSException *e) { printf("transform raised %s\n", [[e name] UTF8String]); }

      printf("== through the key ==\n");
      @try
        {
          DynPointLayer *l = [DynPointLayer layer];
          CGPoint p = CGPointMake(7, 8);
          [l setValue: [NSValue valueWithBytes: &p objCType: @encode(CGPoint)]
               forKey: @"p"];
          printf("point set by key (%g,%g)\n", [l p].x, [l p].y);
          id back = [l valueForKey: @"p"];
          printf("point read by key is %s\n",
                 back == nil ? "nil" : [[back description] UTF8String]);
        }
      @catch (NSException *e) { printf("by key raised %s\n", [[e name] UTF8String]); }
    }
  return 0;
}

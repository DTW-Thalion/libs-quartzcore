/* Apple oracle: how many change notifications a CALayer setter posts, and the
   sublayer tree bookkeeping. */
#import <QuartzCore/QuartzCore.h>
#include <stdio.h>

@interface Watcher : NSObject
{
@public
  NSMutableDictionary *counts;
}
@end

@implementation Watcher
- (id) init
{
  if ((self = [super init]) != nil)
    counts = [[NSMutableDictionary alloc] init];
  return self;
}
- (void) observeValueForKeyPath: (NSString *)keyPath
                       ofObject: (id)object
                         change: (NSDictionary *)change
                        context: (void *)context
{
  NSNumber *n = [counts objectForKey: keyPath];
  [counts setObject: [NSNumber numberWithInt: [n intValue] + 1]
             forKey: keyPath];
}
@end

static void kvoCounts(void)
{
  printf("--- notification counts ---\n");
  NSArray *keys = @[ @"bounds", @"position", @"anchorPoint", @"anchorPointZ",
                     @"zPosition", @"transform", @"sublayerTransform",
                     @"opacity", @"contentsScale", @"masksToBounds",
                     @"backgroundColor", @"shadowOffset", @"frame" ];
  Watcher *w = [[Watcher alloc] init];
  CALayer *l = [CALayer layer];
  for (NSString *k in keys)
    [l addObserver: w forKeyPath: k options: NSKeyValueObservingOptionOld
           context: NULL];

  [l setBounds: CGRectMake(0, 0, 10, 20)];
  [l setPosition: CGPointMake(1, 2)];
  [l setAnchorPoint: CGPointMake(0, 0)];
  [l setAnchorPointZ: 3];
  [l setZPosition: 4];
  [l setTransform: CATransform3DMakeScale(2, 2, 2)];
  [l setSublayerTransform: CATransform3DMakeTranslation(1, 1, 1)];
  [l setOpacity: 0.5];
  [l setContentsScale: 2];
  [l setMasksToBounds: YES];
  [l setBackgroundColor: CGColorCreateGenericRGB(1, 0, 0, 1)];
  [l setShadowOffset: CGSizeMake(1, 1)];

  for (NSString *k in keys)
    printf("count.%s = %d\n", [k UTF8String],
           [[w->counts objectForKey: k] intValue]);

  for (NSString *k in keys)
    [l removeObserver: w forKeyPath: k];

  /* setFrame: is expected to move through bounds and position */
  Watcher *w2 = [[Watcher alloc] init];
  CALayer *f = [CALayer layer];
  NSArray *fkeys = @[ @"bounds", @"position", @"frame" ];
  for (NSString *k in fkeys)
    [f addObserver: w2 forKeyPath: k options: NSKeyValueObservingOptionOld
           context: NULL];
  [f setFrame: CGRectMake(10, 20, 100, 50)];
  for (NSString *k in fkeys)
    printf("setFrameCount.%s = %d\n", [k UTF8String],
           [[w2->counts objectForKey: k] intValue]);
  for (NSString *k in fkeys)
    [f removeObserver: w2 forKeyPath: k];

  /* setting a value equal to the current one */
  Watcher *w3 = [[Watcher alloc] init];
  CALayer *s = [CALayer layer];
  [s setPosition: CGPointMake(5, 6)];
  [s addObserver: w3 forKeyPath: @"position"
         options: NSKeyValueObservingOptionOld context: NULL];
  [s setPosition: CGPointMake(5, 6)];
  printf("sameValueCount.position = %d\n",
         [[w3->counts objectForKey: @"position"] intValue]);
  [s removeObserver: w3 forKeyPath: @"position"];
}

static void sublayerTree(void)
{
  printf("--- sublayer tree ---\n");
  CALayer *p = [CALayer layer];
  CALayer *a = [CALayer layer];
  CALayer *b = [CALayer layer];
  CALayer *c = [CALayer layer];

  printf("empty.sublayers = %s\n", [p sublayers] ? "non-nil" : "nil");
  [p addSublayer: a];
  printf("afterAdd.count = %lu\n", (unsigned long)[[p sublayers] count]);
  printf("afterAdd.superlayer = %d\n", [a superlayer] == p);
  [p addSublayer: b];
  [p insertSublayer: c atIndex: 1];
  printf("order = %d %d %d\n",
         [[p sublayers] objectAtIndex: 0] == a,
         [[p sublayers] objectAtIndex: 1] == c,
         [[p sublayers] objectAtIndex: 2] == b);
  [c removeFromSuperlayer];
  printf("afterRemove.count = %lu\n", (unsigned long)[[p sublayers] count]);
  printf("afterRemove.superlayer = %s\n", [c superlayer] ? "non-nil" : "nil");

  [p insertSublayer: c below: a];
  printf("belowA = %d\n", [[p sublayers] objectAtIndex: 0] == c);
  [c removeFromSuperlayer];
  [p insertSublayer: c above: a];
  printf("aboveA = %d\n", [[p sublayers] objectAtIndex: 1] == c);

  /* re-adding a layer that already has a superlayer */
  CALayer *q = [CALayer layer];
  [q addSublayer: a];
  printf("reparent.oldCount = %lu\n", (unsigned long)[[p sublayers] count]);
  printf("reparent.newSuperlayer = %d\n", [a superlayer] == q);
}

static void roundTrips(void)
{
  printf("--- setter round trips ---\n");
  CALayer *l = [CALayer layer];
  [l setMasksToBounds: YES];
  printf("masksToBounds = %d\n", (int)[l masksToBounds]);
  [l setContentsScale: 2];
  printf("contentsScale = %g\n", (double)[l contentsScale]);
  [l setZPosition: -5];
  printf("zPosition = %g\n", (double)[l zPosition]);
  [l setAnchorPointZ: 7];
  printf("anchorPointZ = %g\n", (double)[l anchorPointZ]);
  [l setSublayerTransform: CATransform3DMakeScale(3, 3, 3)];
  CATransform3D t = [l sublayerTransform];
  printf("sublayerTransform = %g %g %g\n", t.m11, t.m22, t.m33);
  [l setGeometryFlipped: YES];
  printf("geometryFlipped = %d\n", (int)[l isGeometryFlipped]);
  [l setHidden: YES];
  printf("hidden = %d\n", (int)[l isHidden]);
}

int main(void)
{
  @autoreleasepool {
    setvbuf(stdout, NULL, _IONBF, 0);
    kvoCounts();
    sublayerTree();
    roundTrips();
  }
  return 0;
}

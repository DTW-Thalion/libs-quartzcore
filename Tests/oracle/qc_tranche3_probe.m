#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#include <stdio.h>

@interface CALayer (ProbeInstanceArchiving)
- (BOOL) shouldArchiveValueForKey: (NSString *)key;
@end

static void archiving(void)
{
  printf("=== -[CALayer shouldArchiveValueForKey:] ===\n");
  const char *keys[] = { "position", "bounds", "frame", "name", "delegate",
                         "superlayer", "sublayers", "contents", "opacity",
                         "hidden", "transform", "sublayerTransform", "mask",
                         "filters", "compositingFilter", "backgroundFilters",
                         "style", "actions", "anchorPoint", "zPosition",
                         "backgroundColor", "borderColor", "borderWidth",
                         "cornerRadius", "contentsScale", "contentsRect",
                         "contentsCenter", "masksToBounds", "doubleSided",
                         "shadowColor", "shadowOpacity", "shadowRadius",
                         "shadowOffset", "shadowPath", "autoresizingMask",
                         "allowsEdgeAntialiasing", "allowsGroupOpacity",
                         "edgeAntialiasingMask", "drawsAsynchronously",
                         "minificationFilter", "minificationFilterBias",
                         "magnificationFilter", "needsDisplayOnBoundsChange",
                         "shouldRasterize", "rasterizationScale",
                         "geometryFlipped", "opaque", "beginTime", "duration",
                         "speed", "timeOffset", "repeatCount",
                         "repeatDuration", "autoreverses", "fillMode",
                         "layoutManager", "notAKeyAtAll", "" };
  CALayer *l = [CALayer layer];
  int i;
  for (i = 0; i < 58; i++)
    {
      NSString *k = [NSString stringWithUTF8String: keys[i]];
      @try {
        printf("%-28s = %s\n", keys[i][0] ? keys[i] : "(empty string)",
               [l shouldArchiveValueForKey: k] ? "YES" : "NO");
      } @catch (NSException *e) {
        printf("%-28s RAISED %s: %s\n", keys[i], [[e name] UTF8String],
               [[e reason] UTF8String]);
      }
    }
  @try {
    printf("nil key = %s\n", [l shouldArchiveValueForKey: nil] ? "YES" : "NO");
  } @catch (NSException *e) {
    printf("nil key RAISED %s: %s\n", [[e name] UTF8String],
           [[e reason] UTF8String]);
  }
  printf("--- does the answer change with the value set? ---\n");
  CALayer *m = [CALayer layer];
  [m setName: @"named"];
  [m setOpacity: 0.5];
  [m setHidden: YES];
  printf("name after setting = %s\n",
         [m shouldArchiveValueForKey: @"name"] ? "YES" : "NO");
  printf("opacity after setting = %s\n",
         [m shouldArchiveValueForKey: @"opacity"] ? "YES" : "NO");
  printf("hidden after setting = %s\n",
         [m shouldArchiveValueForKey: @"hidden"] ? "YES" : "NO");
  printf("--- on a subclass and on other classes ---\n");
  printf("CAShapeLayer path = %s\n",
         [(CALayer *)[CAShapeLayer layer] shouldArchiveValueForKey: @"path"]
           ? "YES" : "NO");
  printf("CAGradientLayer colors = %s\n",
         [(CALayer *)[CAGradientLayer layer] shouldArchiveValueForKey: @"colors"]
           ? "YES" : "NO");
  printf("CAScrollLayer scrollMode = %s\n",
         [(CALayer *)[CAScrollLayer layer]
           shouldArchiveValueForKey: @"scrollMode"] ? "YES" : "NO");
}

/* One application only: build the tree, then change the superlayer bounds
   once.  Nothing else is sent. */
static void resized(const char *label, CGRect subFrame, unsigned mask,
                    CGSize oldSize, CGSize newSize)
{
  CALayer *sup = [CALayer layer];
  [sup setBounds: CGRectMake(0, 0, oldSize.width, oldSize.height)];
  CALayer *sub = [CALayer layer];
  [sub setFrame: subFrame];
  [sub setAutoresizingMask: mask];
  [sup addSublayer: sub];
  [sup setBounds: CGRectMake(0, 0, newSize.width, newSize.height)];
  CGRect r = [sub frame];
  printf("%-46s mask %2u -> (%g, %g, %g, %g)\n", label, mask,
         r.origin.x, r.origin.y, r.size.width, r.size.height);
}

static void distribution(void)
{
  printf("\n=== how the delta is distributed ===\n");
  CGSize s100 = CGSizeMake(100, 100);

  printf("--- a zero minX margin: is the share size independent? ---\n");
  resized("frame (0,20,50,40), 100->200 wide", CGRectMake(0, 20, 50, 40), 3,
          s100, CGSizeMake(200, 100));
  resized("frame (0,20,50,40), 100->200 wide", CGRectMake(0, 20, 50, 40), 7,
          s100, CGSizeMake(200, 100));
  printf("--- a zero width ---\n");
  resized("frame (10,20,0,40), 100->200 wide", CGRectMake(10, 20, 0, 40), 3,
          s100, CGSizeMake(200, 100));
  resized("frame (10,20,0,40), 100->200 wide", CGRectMake(10, 20, 0, 40), 7,
          s100, CGSizeMake(200, 100));
  printf("--- a zero maxX margin (frame fills to the right edge) ---\n");
  resized("frame (10,20,90,40), 100->200 wide", CGRectMake(10, 20, 90, 40), 3,
          s100, CGSizeMake(200, 100));
  resized("frame (10,20,90,40), 100->200 wide", CGRectMake(10, 20, 90, 40), 7,
          s100, CGSizeMake(200, 100));

  printf("--- a delta divisible by three: 100 -> 400 (dw 300) ---\n");
  resized("frame (10,20,50,40)", CGRectMake(10, 20, 50, 40), 3, s100,
          CGSizeMake(400, 100));
  resized("frame (10,20,50,40)", CGRectMake(10, 20, 50, 40), 5, s100,
          CGSizeMake(400, 100));
  resized("frame (10,20,50,40)", CGRectMake(10, 20, 50, 40), 6, s100,
          CGSizeMake(400, 100));
  resized("frame (10,20,50,40)", CGRectMake(10, 20, 50, 40), 7, s100,
          CGSizeMake(400, 100));

  printf("--- a small delta: 100 -> 110 (dw 10) ---\n");
  resized("frame (10,20,50,40)", CGRectMake(10, 20, 50, 40), 3, s100,
          CGSizeMake(110, 100));
  resized("frame (10,20,50,40)", CGRectMake(10, 20, 50, 40), 7, s100,
          CGSizeMake(110, 100));
  printf("--- a fractional delta: 100 -> 100.5 ---\n");
  resized("frame (10,20,50,40)", CGRectMake(10, 20, 50, 40), 3, s100,
          CGSizeMake(100.5, 100));
  resized("frame (10,20,50,40)", CGRectMake(10, 20, 50, 40), 7, s100,
          CGSizeMake(100.5, 100));

  printf("--- very unequal parts: frame (80,20,10,40), margins 80 / 10 ---\n");
  resized("frame (80,20,10,40)", CGRectMake(80, 20, 10, 40), 3, s100,
          CGSizeMake(200, 100));
  resized("frame (80,20,10,40)", CGRectMake(80, 20, 10, 40), 5, s100,
          CGSizeMake(200, 100));
  resized("frame (80,20,10,40)", CGRectMake(80, 20, 10, 40), 6, s100,
          CGSizeMake(200, 100));
  resized("frame (80,20,10,40)", CGRectMake(80, 20, 10, 40), 7, s100,
          CGSizeMake(200, 100));

  printf("--- a sublayer wider than its superlayer ---\n");
  resized("frame (-20,20,200,40)", CGRectMake(-20, 20, 200, 40), 3, s100,
          CGSizeMake(200, 100));
  resized("frame (-20,20,200,40)", CGRectMake(-20, 20, 200, 40), 7, s100,
          CGSizeMake(200, 100));

  printf("\n--- a non-default anchor point ---\n");
  {
    CALayer *sup = [CALayer layer];
    [sup setBounds: CGRectMake(0, 0, 100, 100)];
    CALayer *sub = [CALayer layer];
    [sub setAnchorPoint: CGPointMake(0, 0)];
    [sub setFrame: CGRectMake(10, 20, 50, 40)];
    [sub setAutoresizingMask: 3];
    [sup addSublayer: sub];
    [sup setBounds: CGRectMake(0, 0, 200, 300)];
    CGRect r = [sub frame];
    printf("anchorPoint (0,0), mask 3 -> frame (%g, %g, %g, %g) "
           "position (%g, %g) bounds (%g, %g, %g, %g)\n",
           r.origin.x, r.origin.y, r.size.width, r.size.height,
           [sub position].x, [sub position].y,
           [sub bounds].origin.x, [sub bounds].origin.y,
           [sub bounds].size.width, [sub bounds].size.height);
  }
  printf("--- a rotated sublayer: does it work on the frame? ---\n");
  {
    CALayer *sup = [CALayer layer];
    [sup setBounds: CGRectMake(0, 0, 100, 100)];
    CALayer *sub = [CALayer layer];
    [sub setFrame: CGRectMake(10, 20, 50, 40)];
    [sub setTransform: CATransform3DMakeRotation(M_PI / 4, 0, 0, 1)];
    [sub setAutoresizingMask: 2];
    [sup addSublayer: sub];
    printf("rotated, frame before (%g, %g, %g, %g) bounds (%g, %g)\n",
           [sub frame].origin.x, [sub frame].origin.y,
           [sub frame].size.width, [sub frame].size.height,
           [sub bounds].size.width, [sub bounds].size.height);
    [sup setBounds: CGRectMake(0, 0, 200, 100)];
    printf("rotated, frame after  (%g, %g, %g, %g) bounds (%g, %g)\n",
           [sub frame].origin.x, [sub frame].origin.y,
           [sub frame].size.width, [sub frame].size.height,
           [sub bounds].size.width, [sub bounds].size.height);
  }
  printf("--- does the superlayer's own mask matter? ---\n");
  {
    CALayer *sup = [CALayer layer];
    [sup setBounds: CGRectMake(0, 0, 100, 100)];
    [sup setAutoresizingMask: 63];
    CALayer *sub = [CALayer layer];
    [sub setFrame: CGRectMake(10, 20, 50, 40)];
    [sub setAutoresizingMask: 2];
    [sup addSublayer: sub];
    [sup setBounds: CGRectMake(0, 0, 200, 100)];
    CGRect r = [sub frame];
    printf("superlayer mask 63 -> sublayer (%g, %g, %g, %g)\n",
           r.origin.x, r.origin.y, r.size.width, r.size.height);
  }
  printf("--- is the mask kept verbatim, including unknown bits? ---\n");
  {
    CALayer *l = [CALayer layer];
    [l setAutoresizingMask: 255];
    printf("set 255 -> %u\n", (unsigned)[l autoresizingMask]);
    [l setAutoresizingMask: 0];
    printf("set 0 -> %u\n", (unsigned)[l autoresizingMask]);
  }
}

int main(void)
{
  @autoreleasepool {
    archiving();
    distribution();
  }
  return 0;
}

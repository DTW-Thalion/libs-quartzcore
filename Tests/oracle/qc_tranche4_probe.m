#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#include <stdio.h>

@interface CALayer (ProbeInstanceArchiving)
- (BOOL) shouldArchiveValueForKey: (NSString *)key;
@end

static void resized(const char *label, CGRect subFrame, unsigned mask,
                    CGFloat oldW, CGFloat newW)
{
  CALayer *sup = [CALayer layer];
  [sup setBounds: CGRectMake(0, 0, oldW, 100)];
  CALayer *sub = [CALayer layer];
  [sub setFrame: subFrame];
  [sub setAutoresizingMask: mask];
  [sup addSublayer: sub];
  [sup setBounds: CGRectMake(0, 0, newW, 100)];
  CGRect r = [sub frame];
  printf("%-34s mask %2u -> x %.4f w %.4f maxX %.4f\n", label, mask,
         (double)r.origin.x, (double)r.size.width,
         (double)(newW - r.origin.x - r.size.width));
}

static void sweep(const char *label, CGRect f, CGFloat oldW, CGFloat newW)
{
  unsigned masks[] = { 1, 2, 4, 3, 5, 6, 7 };
  int i;
  printf("\n--- %s ---\n", label);
  for (i = 0; i < 7; i++)
    resized(label, f, masks[i], oldW, newW);
}

static void rounding(void)
{
  printf("=== is there a rounding step, and where? ===\n");
  CGRect f = CGRectMake(10, 20, 50, 40);
  sweep("100 -> 101 (d 1)", f, 100, 101);
  sweep("100 -> 102 (d 2)", f, 100, 102);
  sweep("100 -> 100.5 (d 0.5)", f, 100, 100.5);
  sweep("100 -> 110.5 (d 10.5)", f, 100, 110.5);
  sweep("100 -> 400 (d 300, exact thirds)", f, 100, 400);

  printf("\n=== a fractional STARTING frame, exact-thirds delta ===\n");
  CGRect g = CGRectMake(10.5, 20, 50.25, 40);
  sweep("frame (10.5,20,50.25,40), 100 -> 400", g, 100, 400);
  sweep("frame (10.5,20,50.25,40), 100 -> 200", g, 100, 200);

  printf("\n=== shrinking with an odd delta ===\n");
  sweep("100 -> 99 (d -1)", f, 100, 99);
  sweep("100 -> 90 (d -10)", f, 100, 90);
}

static void archiving(void)
{
  printf("\n=== is it 'has been set' or 'differs from the default'? ===\n");
  {
    CALayer *l = [CALayer layer];
    printf("fresh opacity = %s\n",
           [l shouldArchiveValueForKey: @"opacity"] ? "YES" : "NO");
    [l setOpacity: 1.0];   /* the default value, set explicitly */
    printf("opacity set to its own default 1.0 = %s\n",
           [l shouldArchiveValueForKey: @"opacity"] ? "YES" : "NO");
  }
  {
    CALayer *l = [CALayer layer];
    [l setHidden: NO];     /* the default value, set explicitly */
    printf("hidden set to its own default NO = %s\n",
           [l shouldArchiveValueForKey: @"hidden"] ? "YES" : "NO");
  }
  {
    CALayer *l = [CALayer layer];
    [l setOpacity: 0.5];
    printf("opacity 0.5 = %s\n",
           [l shouldArchiveValueForKey: @"opacity"] ? "YES" : "NO");
    [l setOpacity: 1.0];
    printf("opacity set back to 1.0 = %s\n",
           [l shouldArchiveValueForKey: @"opacity"] ? "YES" : "NO");
  }
  {
    CALayer *l = [CALayer layer];
    [l setName: @"a"];
    printf("name set = %s\n",
           [l shouldArchiveValueForKey: @"name"] ? "YES" : "NO");
    [l setName: nil];
    printf("name set back to nil = %s\n",
           [l shouldArchiveValueForKey: @"name"] ? "YES" : "NO");
  }
  {
    CALayer *l = [CALayer layer];
    [l setBounds: CGRectMake(0, 0, 10, 10)];
    printf("bounds set = %s\n",
           [l shouldArchiveValueForKey: @"bounds"] ? "YES" : "NO");
    printf("position, untouched, after a bounds change = %s\n",
           [l shouldArchiveValueForKey: @"position"] ? "YES" : "NO");
    [l setFrame: CGRectMake(1, 2, 3, 4)];
    printf("after setFrame: bounds = %s, position = %s, frame = %s\n",
           [l shouldArchiveValueForKey: @"bounds"] ? "YES" : "NO",
           [l shouldArchiveValueForKey: @"position"] ? "YES" : "NO",
           [l shouldArchiveValueForKey: @"frame"] ? "YES" : "NO");
  }
  {
    CALayer *l = [CALayer layer];
    printf("set through KVC: ");
    [l setValue: [NSNumber numberWithFloat: 0.25] forKey: @"opacity"];
    printf("opacity = %s\n",
           [l shouldArchiveValueForKey: @"opacity"] ? "YES" : "NO");
  }
  {
    CALayer *l = [CALayer layer];
    [l setAllowsEdgeAntialiasing: YES];
    printf("allowsEdgeAntialiasing after setting YES = %s\n",
           [l shouldArchiveValueForKey: @"allowsEdgeAntialiasing"]
             ? "YES" : "NO");
    [l setAllowsGroupOpacity: NO];
    printf("allowsGroupOpacity after setting NO = %s\n",
           [l shouldArchiveValueForKey: @"allowsGroupOpacity"] ? "YES" : "NO");
  }
  {
    CALayer *l = [CALayer layer];
    [l setMask: [CALayer layer]];
    [l setFilters: [NSArray array]];
    [l setContentsCenter: CGRectMake(0, 0, 0.5, 0.5)];
    [l setAutoresizingMask: kCALayerWidthSizable];
    printf("mask set = %s, filters set = %s, contentsCenter set = %s, "
           "autoresizingMask set = %s\n",
           [l shouldArchiveValueForKey: @"mask"] ? "YES" : "NO",
           [l shouldArchiveValueForKey: @"filters"] ? "YES" : "NO",
           [l shouldArchiveValueForKey: @"contentsCenter"] ? "YES" : "NO",
           [l shouldArchiveValueForKey: @"autoresizingMask"] ? "YES" : "NO");
  }
  {
    CALayer *l = [CALayer layer];
    CALayer *s = [CALayer layer];
    [l addSublayer: s];
    printf("sublayers after addSublayer: = %s, superlayer on the child = %s\n",
           [l shouldArchiveValueForKey: @"sublayers"] ? "YES" : "NO",
           [s shouldArchiveValueForKey: @"superlayer"] ? "YES" : "NO");
  }
}

int main(void)
{
  @autoreleasepool {
    rounding();
    archiving();
  }
  return 0;
}

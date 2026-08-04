#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#include <stdio.h>

static const char *B(BOOL b) { return b ? "YES" : "NO"; }

static void rect(const char *label, CGRect r)
{
  printf("%s = (%g, %g, %g, %g)\n", label, r.origin.x, r.origin.y,
         r.size.width, r.size.height);
}

static void tranche1(void)
{
  printf("=== TRANCHE 1: defaults ===\n");
  CALayer *l = [CALayer layer];
  printf("allowsEdgeAntialiasing = %s\n", B([l allowsEdgeAntialiasing]));
  printf("allowsGroupOpacity = %s\n", B([l allowsGroupOpacity]));
  printf("edgeAntialiasingMask = %u\n", (unsigned)[l edgeAntialiasingMask]);
  printf("drawsAsynchronously = %s\n", B([l drawsAsynchronously]));
  printf("minificationFilterBias = %g\n", (double)[l minificationFilterBias]);
  printf("filters = %s\n", [l filters] ? "non-nil" : "nil");
  printf("compositingFilter = %s\n", [l compositingFilter] ? "non-nil" : "nil");
  printf("backgroundFilters = %s\n", [l backgroundFilters] ? "non-nil" : "nil");
  rect("contentsCenter", [l contentsCenter]);
  printf("mask = %s\n", [l mask] ? "non-nil" : "nil");

  printf("--- edge antialiasing mask constants ---\n");
  printf("kCALayerLeftEdge = %u\n", (unsigned)kCALayerLeftEdge);
  printf("kCALayerRightEdge = %u\n", (unsigned)kCALayerRightEdge);
  printf("kCALayerBottomEdge = %u\n", (unsigned)kCALayerBottomEdge);
  printf("kCALayerTopEdge = %u\n", (unsigned)kCALayerTopEdge);

  printf("--- setters keep what they are given ---\n");
  [l setAllowsEdgeAntialiasing: YES];
  printf("allowsEdgeAntialiasing after YES = %s\n", B([l allowsEdgeAntialiasing]));
  [l setAllowsGroupOpacity: NO];
  printf("allowsGroupOpacity after NO = %s\n", B([l allowsGroupOpacity]));
  [l setEdgeAntialiasingMask: kCALayerLeftEdge | kCALayerTopEdge];
  printf("edgeAntialiasingMask after left|top = %u\n",
         (unsigned)[l edgeAntialiasingMask]);
  [l setDrawsAsynchronously: YES];
  printf("drawsAsynchronously after YES = %s\n", B([l drawsAsynchronously]));
  [l setMinificationFilterBias: 0.25f];
  printf("minificationFilterBias after 0.25 = %g\n",
         (double)[l minificationFilterBias]);
  [l setContentsCenter: CGRectMake(0.25, 0.25, 0.5, 0.5)];
  rect("contentsCenter after (0.25,0.25,0.5,0.5)", [l contentsCenter]);

  printf("--- contentsCenter out of the unit square ---\n");
  @try {
    [l setContentsCenter: CGRectMake(-1, -1, 4, 4)];
    rect("contentsCenter after (-1,-1,4,4)", [l contentsCenter]);
  } @catch (NSException *e) {
    printf("contentsCenter (-1,-1,4,4) RAISED %s\n", [[e name] UTF8String]);
  }

  printf("--- the filter arrays ---\n");
  CALayer *f = [CALayer layer];
  NSMutableArray *ma = [NSMutableArray arrayWithObject: @"placeholder"];
  @try {
    [f setFilters: ma];
    printf("setFilters: with a string element did NOT raise\n");
    printf("filters count = %lu\n", (unsigned long)[[f filters] count]);
    printf("filters is the same object = %s\n", B([f filters] == ma));
    [ma addObject: @"second"];
    printf("filters count after mutating the original = %lu\n",
           (unsigned long)[[f filters] count]);
    printf("filters element class = %s\n",
           [[f filters] count] ? [NSStringFromClass([[[f filters] objectAtIndex: 0] class]) UTF8String] : "none");
  } @catch (NSException *e) {
    printf("setFilters: RAISED %s\n", [[e name] UTF8String]);
  }
  @try {
    [f setBackgroundFilters: [NSArray arrayWithObject: @"placeholder"]];
    printf("setBackgroundFilters: did NOT raise, count = %lu\n",
           (unsigned long)[[f backgroundFilters] count]);
  } @catch (NSException *e) {
    printf("setBackgroundFilters: RAISED %s\n", [[e name] UTF8String]);
  }
  @try {
    [f setCompositingFilter: @"placeholder"];
    printf("setCompositingFilter: did NOT raise, reads back %s\n",
           [f compositingFilter] ? "non-nil" : "nil");
  } @catch (NSException *e) {
    printf("setCompositingFilter: RAISED %s\n", [[e name] UTF8String]);
  }
  [f setFilters: nil];
  printf("filters set back to nil = %s\n", [f filters] ? "non-nil" : "nil");

  printf("--- the mask ---\n");
  CALayer *host = [CALayer layer];
  CALayer *m = [CALayer layer];
  [host setMask: m];
  printf("mask is the same object = %s\n", B([host mask] == m));
  printf("mask superlayer == host = %s\n", B([m superlayer] == host));
  printf("mask superlayer is nil = %s\n", B([m superlayer] == nil));
  printf("host sublayers count = %lu\n",
         (unsigned long)[[host sublayers] count]);
  printf("host sublayers is nil = %s\n", B([host sublayers] == nil));
  [host setMask: nil];
  printf("mask after nil = %s\n", [host mask] ? "non-nil" : "nil");
  printf("old mask superlayer after unset is nil = %s\n", B([m superlayer] == nil));

  CALayer *parent = [CALayer layer];
  CALayer *child = [CALayer layer];
  [parent addSublayer: child];
  CALayer *other = [CALayer layer];
  @try {
    [other setMask: child];
    printf("a layer that already had a superlayer as a mask: superlayer is %s\n",
           [child superlayer] == parent ? "still the parent"
             : ([child superlayer] == other ? "the mask host" : "nil"));
    printf("parent sublayers count after = %lu\n",
           (unsigned long)[[parent sublayers] count]);
  } @catch (NSException *e) {
    printf("setMask: on an attached layer RAISED %s\n", [[e name] UTF8String]);
  }

  printf("--- +defaultValueForKey: for the new keys ---\n");
  const char *keys1[] = { "allowsEdgeAntialiasing", "allowsGroupOpacity",
                          "edgeAntialiasingMask", "drawsAsynchronously",
                          "minificationFilterBias", "filters",
                          "compositingFilter", "backgroundFilters",
                          "contentsCenter", "mask" };
  int i;
  for (i = 0; i < 10; i++)
    {
      NSString *k = [NSString stringWithUTF8String: keys1[i]];
      id v = [CALayer defaultValueForKey: k];
      printf("defaultValueForKey %-24s = %s\n", keys1[i],
             v ? [[v description] UTF8String] : "nil");
      printf("needsDisplayForKey %-24s = %s\n", keys1[i],
             B([CALayer needsDisplayForKey: k]));
    }
}

static void tranche2(void)
{
  printf("\n=== TRANCHE 2: shouldArchiveValueForKey / contentsAreFlipped ===\n");
  const char *keys[] = { "position", "bounds", "name", "delegate", "superlayer",
                         "sublayers", "contents", "opacity", "hidden",
                         "transform", "mask", "filters", "style", "actions",
                         "notAKeyAtAll" };
  int i;
  CALayer *l = [CALayer layer];
  for (i = 0; i < 15; i++)
    {
      NSString *k = [NSString stringWithUTF8String: keys[i]];
      @try {
        printf("+shouldArchiveValueForKey %-14s = %s\n", keys[i],
               B([CALayer shouldArchiveValueForKey: k]));
      } @catch (NSException *e) {
        printf("+shouldArchiveValueForKey %-14s RAISED %s\n", keys[i],
               [[e name] UTF8String]);
      }
    }
  printf("--- contentsAreFlipped ---\n");
  printf("contentsAreFlipped fresh = %s\n", B([l contentsAreFlipped]));
  [l setGeometryFlipped: YES];
  printf("geometryFlipped YES -> contentsAreFlipped = %s\n",
         B([l contentsAreFlipped]));
  [l setGeometryFlipped: NO];
  CALayer *sup = [CALayer layer];
  CALayer *sub = [CALayer layer];
  [sup addSublayer: sub];
  printf("sublayer of a plain superlayer: contentsAreFlipped = %s\n",
         B([sub contentsAreFlipped]));
  [sup setGeometryFlipped: YES];
  printf("superlayer geometryFlipped YES -> sublayer contentsAreFlipped = %s\n",
         B([sub contentsAreFlipped]));
  printf("superlayer geometryFlipped YES -> its own contentsAreFlipped = %s\n",
         B([sup contentsAreFlipped]));
  [sub setGeometryFlipped: YES];
  printf("both flipped -> sublayer contentsAreFlipped = %s\n",
         B([sub contentsAreFlipped]));
}

static void resizeCase(const char *label, unsigned mask, BOOL callDirectly)
{
  CALayer *sup = [CALayer layer];
  [sup setBounds: CGRectMake(0, 0, 100, 100)];
  CALayer *sub = [CALayer layer];
  [sub setFrame: CGRectMake(10, 20, 50, 40)];
  [sub setAutoresizingMask: mask];
  [sup addSublayer: sub];
  CGSize old = [sup bounds].size;
  [sup setBounds: CGRectMake(0, 0, 200, 300)];
  if (callDirectly)
    [sup resizeSublayersWithOldSize: old];
  [sup layoutIfNeeded];
  CGRect r = [sub frame];
  printf("%-34s mask %2u -> frame (%g, %g, %g, %g)\n", label, mask,
         r.origin.x, r.origin.y, r.size.width, r.size.height);
}

static void tranche3(void)
{
  printf("\n=== TRANCHE 3: autoresizing ===\n");
  CALayer *l = [CALayer layer];
  printf("autoresizingMask default = %u\n", (unsigned)[l autoresizingMask]);
  printf("kCALayerNotSizable = %u\n", (unsigned)kCALayerNotSizable);
  printf("kCALayerMinXMargin = %u\n", (unsigned)kCALayerMinXMargin);
  printf("kCALayerWidthSizable = %u\n", (unsigned)kCALayerWidthSizable);
  printf("kCALayerMaxXMargin = %u\n", (unsigned)kCALayerMaxXMargin);
  printf("kCALayerMinYMargin = %u\n", (unsigned)kCALayerMinYMargin);
  printf("kCALayerHeightSizable = %u\n", (unsigned)kCALayerHeightSizable);
  printf("kCALayerMaxYMargin = %u\n", (unsigned)kCALayerMaxYMargin);
  printf("defaultValue autoresizingMask = %s\n",
         [CALayer defaultValueForKey: @"autoresizingMask"]
           ? [[[CALayer defaultValueForKey: @"autoresizingMask"] description] UTF8String]
           : "nil");

  printf("\n-- superlayer bounds 100x100 -> 200x300, sublayer frame (10,20,50,40)\n");
  printf("-- A: bounds change only, no explicit call\n");
  resizeCase("auto", kCALayerNotSizable, NO);
  resizeCase("auto", kCALayerWidthSizable, NO);
  resizeCase("auto", kCALayerHeightSizable, NO);

  printf("-- B: -resizeSublayersWithOldSize: called explicitly\n");
  resizeCase("explicit", kCALayerNotSizable, YES);
  resizeCase("explicit", kCALayerMinXMargin, YES);
  resizeCase("explicit", kCALayerWidthSizable, YES);
  resizeCase("explicit", kCALayerMaxXMargin, YES);
  resizeCase("explicit", kCALayerMinYMargin, YES);
  resizeCase("explicit", kCALayerHeightSizable, YES);
  resizeCase("explicit", kCALayerMaxYMargin, YES);
  resizeCase("explicit", kCALayerWidthSizable | kCALayerHeightSizable, YES);
  resizeCase("explicit", kCALayerMinXMargin | kCALayerWidthSizable, YES);
  resizeCase("explicit", kCALayerMinXMargin | kCALayerMaxXMargin, YES);
  resizeCase("explicit", kCALayerMinXMargin | kCALayerWidthSizable
                         | kCALayerMaxXMargin, YES);
  resizeCase("explicit", kCALayerMinYMargin | kCALayerMaxYMargin, YES);
  resizeCase("explicit", 63, YES);

  printf("-- C: -resizeWithOldSuperlayerSize: sent to the sublayer itself\n");
  {
    CALayer *sup = [CALayer layer];
    [sup setBounds: CGRectMake(0, 0, 200, 300)];
    CALayer *sub = [CALayer layer];
    [sub setFrame: CGRectMake(10, 20, 50, 40)];
    [sub setAutoresizingMask: kCALayerWidthSizable | kCALayerHeightSizable];
    [sup addSublayer: sub];
    [sub resizeWithOldSuperlayerSize: CGSizeMake(100, 100)];
    rect("direct resizeWithOldSuperlayerSize (100,100), width+height sizable",
         [sub frame]);
  }
  {
    CALayer *sup = [CALayer layer];
    [sup setBounds: CGRectMake(0, 0, 200, 300)];
    CALayer *sub = [CALayer layer];
    [sub setFrame: CGRectMake(10, 20, 50, 40)];
    [sub setAutoresizingMask: kCALayerNotSizable];
    [sup addSublayer: sub];
    [sub resizeWithOldSuperlayerSize: CGSizeMake(100, 100)];
    rect("direct resizeWithOldSuperlayerSize (100,100), not sizable",
         [sub frame]);
  }
  {
    printf("-- D: a SHRINKING superlayer, 100x100 -> 50x25\n");
    CALayer *sup = [CALayer layer];
    [sup setBounds: CGRectMake(0, 0, 100, 100)];
    CALayer *sub = [CALayer layer];
    [sub setFrame: CGRectMake(10, 20, 50, 40)];
    [sub setAutoresizingMask: kCALayerWidthSizable | kCALayerHeightSizable];
    [sup addSublayer: sub];
    [sup setBounds: CGRectMake(0, 0, 50, 25)];
    [sup resizeSublayersWithOldSize: CGSizeMake(100, 100)];
    rect("shrunk, width+height sizable", [sub frame]);
  }
  {
    printf("-- E: does a sublayer with no superlayer survive the message?\n");
    CALayer *orphan = [CALayer layer];
    [orphan setFrame: CGRectMake(10, 20, 50, 40)];
    [orphan setAutoresizingMask: kCALayerWidthSizable];
    @try {
      [orphan resizeWithOldSuperlayerSize: CGSizeMake(100, 100)];
      rect("orphan after resizeWithOldSuperlayerSize", [orphan frame]);
    } @catch (NSException *e) {
      printf("orphan RAISED %s\n", [[e name] UTF8String]);
    }
  }
}

static void tranche4(void)
{
  printf("\n=== TRANCHE 4: the scrolling category on CALayer ===\n");
  printf("-- a plain layer with no scroll ancestor\n");
  CALayer *plain = [CALayer layer];
  [plain setBounds: CGRectMake(0, 0, 100, 80)];
  rect("plain visibleRect", [plain visibleRect]);
  [plain scrollPoint: CGPointMake(30, 40)];
  rect("plain bounds after scrollPoint:(30,40)", [plain bounds]);
  rect("plain visibleRect after scrollPoint:", [plain visibleRect]);
  [plain scrollRectToVisible: CGRectMake(200, 200, 10, 10)];
  rect("plain bounds after scrollRectToVisible:", [plain bounds]);

  printf("-- a layer inside a CAScrollLayer\n");
  CAScrollLayer *scroll = [CAScrollLayer layer];
  [scroll setBounds: CGRectMake(0, 0, 100, 80)];
  CALayer *content = [CALayer layer];
  [content setFrame: CGRectMake(0, 0, 500, 400)];
  [scroll addSublayer: content];
  rect("scroll bounds", [scroll bounds]);
  rect("scroll visibleRect", [scroll visibleRect]);
  rect("content visibleRect", [content visibleRect]);

  [content scrollPoint: CGPointMake(50, 60)];
  rect("scroll bounds after content scrollPoint:(50,60)", [scroll bounds]);
  rect("content visibleRect after", [content visibleRect]);

  [scroll setBounds: CGRectMake(0, 0, 100, 80)];
  [content scrollRectToVisible: CGRectMake(200, 150, 20, 10)];
  rect("scroll bounds after content scrollRectToVisible:(200,150,20,10)",
       [scroll bounds]);

  [scroll setBounds: CGRectMake(0, 0, 100, 80)];
  [content scrollRectToVisible: CGRectMake(10, 10, 20, 10)];
  rect("scroll bounds after a rect already visible", [scroll bounds]);

  [scroll setBounds: CGRectMake(0, 0, 100, 80)];
  [content scrollRectToVisible: CGRectMake(200, 150, 400, 400)];
  rect("scroll bounds after a rect too big to fit", [scroll bounds]);

  printf("-- scrollPoint: sent to the CAScrollLayer itself\n");
  [scroll setBounds: CGRectMake(0, 0, 100, 80)];
  [scroll scrollPoint: CGPointMake(50, 60)];
  rect("scroll bounds after scroll scrollPoint:(50,60)", [scroll bounds]);

  printf("-- a deeper descendant\n");
  [scroll setBounds: CGRectMake(0, 0, 100, 80)];
  CALayer *deep = [CALayer layer];
  [deep setFrame: CGRectMake(30, 40, 20, 20)];
  [content addSublayer: deep];
  rect("deep visibleRect before", [deep visibleRect]);
  [deep scrollPoint: CGPointMake(5, 5)];
  rect("scroll bounds after deep scrollPoint:(5,5)", [scroll bounds]);
  rect("deep visibleRect after", [deep visibleRect]);

  printf("-- scrollMode honoured for the category too?\n");
  [scroll setBounds: CGRectMake(0, 0, 100, 80)];
  [scroll setScrollMode: kCAScrollHorizontally];
  [content scrollPoint: CGPointMake(50, 60)];
  rect("horizontal only, after content scrollPoint:(50,60)", [scroll bounds]);
  [scroll setScrollMode: kCAScrollNone];
  [scroll setBounds: CGRectMake(0, 0, 100, 80)];
  [content scrollPoint: CGPointMake(50, 60)];
  rect("scrollMode none, after content scrollPoint:(50,60)", [scroll bounds]);
}

int main(void)
{
  @autoreleasepool {
    tranche1();
    tranche2();
    tranche3();
    tranche4();
  }
  return 0;
}

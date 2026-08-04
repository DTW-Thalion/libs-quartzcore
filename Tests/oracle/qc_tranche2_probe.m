#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#include <stdio.h>

/* Superlayer 100x100 becomes 200x300.  The sublayer starts at frame
   (10, 20, 50, 40), so the three horizontal parts are 10 / 50 / 40 and the
   three vertical parts are 20 / 40 / 40.  Every part is a different size, so
   an equal split and a proportional split cannot be confused. */

static void one(const char *how, unsigned mask, int useLayout,
                int explicitCall, int changeBounds)
{
  CALayer *sup = [CALayer layer];
  [sup setBounds: CGRectMake(0, 0, 100, 100)];
  CALayer *sub = [CALayer layer];
  [sub setFrame: CGRectMake(10, 20, 50, 40)];
  [sub setAutoresizingMask: mask];
  [sup addSublayer: sub];

  if (changeBounds)
    [sup setBounds: CGRectMake(0, 0, 200, 300)];
  if (explicitCall)
    [sup resizeSublayersWithOldSize: CGSizeMake(100, 100)];
  if (useLayout)
    [sup layoutIfNeeded];

  CGRect r = [sub frame];
  printf("%-28s mask %2u -> (%g, %g, %g, %g)   minX %g w %g maxX %g | "
         "minY %g h %g maxY %g\n",
         how, mask, r.origin.x, r.origin.y, r.size.width, r.size.height,
         r.origin.x, r.size.width,
         [sup bounds].size.width - r.origin.x - r.size.width,
         r.origin.y, r.size.height,
         [sup bounds].size.height - r.origin.y - r.size.height);
}

static void sweep(const char *how, int useLayout, int explicitCall,
                  int changeBounds)
{
  unsigned masks[] = { 0, 1, 2, 4, 8, 16, 32, 3, 5, 6, 7, 18, 24, 40, 48, 56,
                       63 };
  int i;
  printf("\n--- %s ---\n", how);
  for (i = 0; i < 17; i++)
    one(how, masks[i], useLayout, explicitCall, changeBounds);
}

static void autoresizing(void)
{
  printf("=== autoresizing, one application per case ===\n");
  sweep("setBounds only", 0, 0, 1);
  sweep("setBounds + layoutIfNeeded", 1, 0, 1);
  sweep("explicit only, no bounds change", 0, 1, 0);
  sweep("setBounds + explicit + layout", 1, 1, 1);

  printf("\n--- shrinking: 100x100 -> 50x25, setBounds only ---\n");
  {
    unsigned masks[] = { 0, 2, 16, 18, 3, 7, 63 };
    int i;
    for (i = 0; i < 7; i++)
      {
        CALayer *sup = [CALayer layer];
        [sup setBounds: CGRectMake(0, 0, 100, 100)];
        CALayer *sub = [CALayer layer];
        [sub setFrame: CGRectMake(10, 20, 50, 40)];
        [sub setAutoresizingMask: masks[i]];
        [sup addSublayer: sub];
        [sup setBounds: CGRectMake(0, 0, 50, 25)];
        CGRect r = [sub frame];
        printf("shrunk mask %2u -> (%g, %g, %g, %g)\n", masks[i],
               r.origin.x, r.origin.y, r.size.width, r.size.height);
      }
  }

  printf("\n--- does anything but a size change trigger it? ---\n");
  {
    CALayer *sup = [CALayer layer];
    [sup setBounds: CGRectMake(0, 0, 100, 100)];
    CALayer *sub = [CALayer layer];
    [sub setFrame: CGRectMake(10, 20, 50, 40)];
    [sub setAutoresizingMask: 2 | 16];
    [sup addSublayer: sub];
    [sup setBounds: CGRectMake(30, 40, 100, 100)];
    CGRect r = [sub frame];
    printf("bounds ORIGIN moved only -> (%g, %g, %g, %g)\n",
           r.origin.x, r.origin.y, r.size.width, r.size.height);
  }
  {
    CALayer *sup = [CALayer layer];
    [sup setBounds: CGRectMake(0, 0, 100, 100)];
    CALayer *sub = [CALayer layer];
    [sub setFrame: CGRectMake(10, 20, 50, 40)];
    [sub setAutoresizingMask: 2 | 16];
    [sup addSublayer: sub];
    [sup setFrame: CGRectMake(0, 0, 200, 300)];
    CGRect r = [sub frame];
    printf("superlayer FRAME set instead -> (%g, %g, %g, %g)\n",
           r.origin.x, r.origin.y, r.size.width, r.size.height);
  }
  {
    printf("\n--- a mask set AFTER the size change ---\n");
    CALayer *sup = [CALayer layer];
    [sup setBounds: CGRectMake(0, 0, 100, 100)];
    CALayer *sub = [CALayer layer];
    [sub setFrame: CGRectMake(10, 20, 50, 40)];
    [sup addSublayer: sub];
    [sup setBounds: CGRectMake(0, 0, 200, 300)];
    [sub setAutoresizingMask: 2 | 16];
    CGRect r = [sub frame];
    printf("mask set after -> (%g, %g, %g, %g)\n",
           r.origin.x, r.origin.y, r.size.width, r.size.height);
  }
  {
    printf("\n--- a layer added to an already resized superlayer ---\n");
    CALayer *sup = [CALayer layer];
    [sup setBounds: CGRectMake(0, 0, 200, 300)];
    CALayer *sub = [CALayer layer];
    [sub setFrame: CGRectMake(10, 20, 50, 40)];
    [sub setAutoresizingMask: 2 | 16];
    [sup addSublayer: sub];
    CGRect r = [sub frame];
    printf("added after -> (%g, %g, %g, %g)\n",
           r.origin.x, r.origin.y, r.size.width, r.size.height);
  }
  {
    printf("\n--- -resizeWithOldSuperlayerSize: sent directly, once ---\n");
    unsigned masks[] = { 0, 1, 2, 3, 5, 7, 18, 63 };
    int i;
    for (i = 0; i < 8; i++)
      {
        CALayer *sup = [CALayer layer];
        [sup setBounds: CGRectMake(0, 0, 200, 300)];
        CALayer *sub = [CALayer layer];
        [sub setFrame: CGRectMake(10, 20, 50, 40)];
        [sub setAutoresizingMask: masks[i]];
        [sup addSublayer: sub];
        [sub resizeWithOldSuperlayerSize: CGSizeMake(100, 100)];
        CGRect r = [sub frame];
        printf("direct mask %2u -> (%g, %g, %g, %g)\n", masks[i],
               r.origin.x, r.origin.y, r.size.width, r.size.height);
      }
  }
  {
    printf("\n--- a sublayer of a sublayer, both sizable ---\n");
    CALayer *sup = [CALayer layer];
    [sup setBounds: CGRectMake(0, 0, 100, 100)];
    CALayer *mid = [CALayer layer];
    [mid setFrame: CGRectMake(0, 0, 100, 100)];
    [mid setAutoresizingMask: 2 | 16];
    [sup addSublayer: mid];
    CALayer *leaf = [CALayer layer];
    [leaf setFrame: CGRectMake(10, 20, 50, 40)];
    [leaf setAutoresizingMask: 2 | 16];
    [mid addSublayer: leaf];
    [sup setBounds: CGRectMake(0, 0, 200, 300)];
    printf("mid  -> (%g, %g, %g, %g)\n", [mid frame].origin.x,
           [mid frame].origin.y, [mid frame].size.width,
           [mid frame].size.height);
    printf("leaf -> (%g, %g, %g, %g)\n", [leaf frame].origin.x,
           [leaf frame].origin.y, [leaf frame].size.width,
           [leaf frame].size.height);
  }
}

static void archiving(void)
{
  printf("\n=== shouldArchiveValueForKey ===\n");
  printf("CALayer responds to +shouldArchiveValueForKey: = %s\n",
         [CALayer respondsToSelector: @selector(shouldArchiveValueForKey:)]
           ? "YES" : "NO");
  printf("a CALayer instance responds to -shouldArchiveValueForKey: = %s\n",
         [[CALayer layer] respondsToSelector:
           @selector(shouldArchiveValueForKey:)] ? "YES" : "NO");
  printf("CAAnimation responds to +shouldArchiveValueForKey: = %s\n",
         [CAAnimation respondsToSelector: @selector(shouldArchiveValueForKey:)]
           ? "YES" : "NO");
  const char *keys[] = { "position", "bounds", "name", "delegate", "contents",
                         "notAKeyAtAll" };
  int i;
  for (i = 0; i < 6; i++)
    {
      NSString *k = [NSString stringWithUTF8String: keys[i]];
      @try {
        BOOL b = [CALayer shouldArchiveValueForKey: k];
        printf("+[CALayer shouldArchiveValueForKey: %s] = %s\n", keys[i],
               b ? "YES" : "NO");
      } @catch (NSException *e) {
        printf("+[CALayer shouldArchiveValueForKey: %s] RAISED %s: %s\n",
               keys[i], [[e name] UTF8String], [[e reason] UTF8String]);
      }
      @try {
        BOOL b = [CAAnimation shouldArchiveValueForKey: k];
        printf("+[CAAnimation shouldArchiveValueForKey: %s] = %s\n", keys[i],
               b ? "YES" : "NO");
      } @catch (NSException *e) {
        printf("+[CAAnimation shouldArchiveValueForKey: %s] RAISED %s: %s\n",
               keys[i], [[e name] UTF8String], [[e reason] UTF8String]);
      }
    }
  @try {
    printf("+[CALayer shouldArchiveValueForKey: nil] = %s\n",
           [CALayer shouldArchiveValueForKey: nil] ? "YES" : "NO");
  } @catch (NSException *e) {
    printf("+[CALayer shouldArchiveValueForKey: nil] RAISED %s: %s\n",
           [[e name] UTF8String], [[e reason] UTF8String]);
  }
}

static void flipped(void)
{
  printf("\n=== contentsAreFlipped, three deep ===\n");
  CALayer *a = [CALayer layer];
  CALayer *b = [CALayer layer];
  CALayer *c = [CALayer layer];
  [a addSublayer: b];
  [b addSublayer: c];
  int i;
  for (i = 0; i < 8; i++)
    {
      [a setGeometryFlipped: (i & 1) ? YES : NO];
      [b setGeometryFlipped: (i & 2) ? YES : NO];
      [c setGeometryFlipped: (i & 4) ? YES : NO];
      printf("a %d b %d c %d -> a %s b %s c %s\n",
             (i & 1) ? 1 : 0, (i & 2) ? 1 : 0, (i & 4) ? 1 : 0,
             [a contentsAreFlipped] ? "Y" : "N",
             [b contentsAreFlipped] ? "Y" : "N",
             [c contentsAreFlipped] ? "Y" : "N");
    }
  printf("an orphan with geometryFlipped YES -> %s\n",
         [c contentsAreFlipped] ? "Y" : "N");
  [c removeFromSuperlayer];
  [c setGeometryFlipped: YES];
  printf("after removeFromSuperlayer, flipped YES -> %s\n",
         [c contentsAreFlipped] ? "Y" : "N");
}

int main(void)
{
  @autoreleasepool {
    autoresizing();
    archiving();
    flipped();
  }
  return 0;
}

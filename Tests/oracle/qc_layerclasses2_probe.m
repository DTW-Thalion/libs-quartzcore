/* The values the first layer-class probe left open: the actual colour a
 * replicator layer starts with, its instance transform, and what a tiled
 * layer's class-level fade duration is on the class itself. */

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

static void showColor(const char *label, CGColorRef c)
{
  size_t i, n;
  const CGFloat *comps;

  if (c == NULL)
    {
      printf("%-26s (null)\n", label);
      return;
    }
  n = CGColorGetNumberOfComponents(c);
  comps = CGColorGetComponents(c);
  printf("%-26s %zu components:", label, n);
  for (i = 0; i < n; i++)
    {
      printf(" %g", (double)comps[i]);
    }
  printf("  alpha=%g\n", (double)CGColorGetAlpha(c));
}

int main(void)
{
  setbuf(stdout, NULL);

  @autoreleasepool
    {
      printf("== CAReplicatorLayer, the open questions ==\n");
      {
        CAReplicatorLayer *r = [CAReplicatorLayer layer];
        CATransform3D t = [r instanceTransform];

        showColor("instanceColor", [r instanceColor]);
        printf("instanceTransform identity %d\n",
               (int)CATransform3DIsIdentity(t));
        printf("instanceTransform m11=%g m22=%g m33=%g m44=%g\n",
               (double)t.m11, (double)t.m22, (double)t.m33, (double)t.m44);
        printf("instanceGreenOffset %g  instanceBlueOffset %g\n",
               (double)[r instanceGreenOffset], (double)[r instanceBlueOffset]);

        /* does it keep a colour it is given */
        CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
        CGFloat vals[4] = {1.0, 0.0, 0.0, 1.0};
        CGColorRef red = CGColorCreate(cs, vals);
        [r setInstanceColor: red];
        printf("instanceColor kept same pointer %d\n",
               (int)([r instanceColor] == red));
        showColor("instanceColor after set", [r instanceColor]);
        CGColorRelease(red);
        CGColorSpaceRelease(cs);

        [r setInstanceCount: 5];
        printf("instanceCount kept %ld\n", (long)[r instanceCount]);
      }

      printf("\n== CATiledLayer ==\n");
      {
        printf("class fadeDuration %g\n", (double)[CATiledLayer fadeDuration]);
        CATiledLayer *t = [CATiledLayer layer];
        [t setTileSize: CGSizeMake(64, 32)];
        printf("tileSize kept %g %g\n",
               (double)[t tileSize].width, (double)[t tileSize].height);
        [t setLevelsOfDetail: 3];
        printf("levelsOfDetail kept %lu\n", (unsigned long)[t levelsOfDetail]);
      }

      printf("\n== CAScrollLayer behaviour ==\n");
      {
        CAScrollLayer *s = [CAScrollLayer layer];
        CALayer *child = [CALayer layer];

        [s setBounds: CGRectMake(0, 0, 100, 100)];
        [child setFrame: CGRectMake(0, 0, 400, 400)];
        [s addSublayer: child];

        printf("visibleRect before %g %g %g %g\n",
               (double)[s visibleRect].origin.x,
               (double)[s visibleRect].origin.y,
               (double)[s visibleRect].size.width,
               (double)[s visibleRect].size.height);

        [s scrollToPoint: CGPointMake(50, 60)];
        printf("bounds after scrollToPoint %g %g %g %g\n",
               (double)[s bounds].origin.x, (double)[s bounds].origin.y,
               (double)[s bounds].size.width, (double)[s bounds].size.height);
        printf("visibleRect after  %g %g %g %g\n",
               (double)[s visibleRect].origin.x,
               (double)[s visibleRect].origin.y,
               (double)[s visibleRect].size.width,
               (double)[s visibleRect].size.height);

        [s scrollToRect: CGRectMake(200, 200, 10, 10)];
        printf("bounds after scrollToRect  %g %g\n",
               (double)[s bounds].origin.x, (double)[s bounds].origin.y);

        /* the category on CALayer */
        printf("child visibleRect  %g %g %g %g\n",
               (double)[child visibleRect].origin.x,
               (double)[child visibleRect].origin.y,
               (double)[child visibleRect].size.width,
               (double)[child visibleRect].size.height);
        [child scrollPoint: CGPointMake(10, 10)];
        printf("after child scrollPoint, scroll layer bounds %g %g\n",
               (double)[s bounds].origin.x, (double)[s bounds].origin.y);

        /* scrollMode honoured? */
        [s setBounds: CGRectMake(0, 0, 100, 100)];
        [s setScrollMode: kCAScrollVertically];
        [s scrollToPoint: CGPointMake(70, 80)];
        printf("vertically only, bounds %g %g\n",
               (double)[s bounds].origin.x, (double)[s bounds].origin.y);

        [s setBounds: CGRectMake(0, 0, 100, 100)];
        [s setScrollMode: kCAScrollNone];
        [s scrollToPoint: CGPointMake(70, 80)];
        printf("no scrolling, bounds    %g %g\n",
               (double)[s bounds].origin.x, (double)[s bounds].origin.y);
      }
    }
  return 0;
}

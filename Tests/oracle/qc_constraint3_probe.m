/* Third constraint probe: when an axis carries three constraints, which pair
   decides the frame?  Plus what a constraint may name as its source, and how
   the layer holds its constraints.

   Run on a macOS runner:
     clang -framework QuartzCore -framework CoreGraphics -framework Foundation \
       Tests/oracle/qc_constraint3_probe.m -o qc_constraint3_probe
*/

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

static CAConstraint *c3(CAConstraintAttribute a, NSString *src,
                        CAConstraintAttribute sa)
{
  return [CAConstraint constraintWithAttribute: a relativeTo: src attribute: sa];
}

static CAConstraint *c4(CAConstraintAttribute a, NSString *src,
                        CAConstraintAttribute sa, CGFloat offset)
{
  return [CAConstraint constraintWithAttribute: a relativeTo: src
                                     attribute: sa offset: offset];
}

static CAConstraint *c5(CAConstraintAttribute a, NSString *src,
                        CAConstraintAttribute sa, CGFloat scale, CGFloat offset)
{
  return [CAConstraint constraintWithAttribute: a relativeTo: src
                                     attribute: sa scale: scale offset: offset];
}

/* Superlayer bounds (0,0,200,100): minX 0, midX 100, maxX 200, width 200. */
static void axis(const char *what, NSArray *constraints)
{
  CALayer *r = [CALayer layer];
  CALayer *l = [CALayer layer];
  CGRect f;

  [r setBounds: CGRectMake(0, 0, 200, 100)];
  [r setLayoutManager: [CAConstraintLayoutManager layoutManager]];
  [l setName: @"child"];
  [l setFrame: CGRectMake(3, 5, 40, 20)];
  [r addSublayer: l];
  [l setConstraints: constraints];
  [r layoutSublayers];
  f = [l frame];
  printf("%-52s %8g %8g\n", what, (double)f.origin.x, (double)f.size.width);
}

int main(int argc, char **argv)
{
  @autoreleasepool
    {
      printf("--- three on one axis: which pair decides it? ---\n");
      printf("%-52s %8s %8s\n", "start x=3 w=40", "x", "w");
      axis("maxX(200), minX(0), width(50)",
           [NSArray arrayWithObjects:
             c3(kCAConstraintMaxX, @"superlayer", kCAConstraintMaxX),
             c3(kCAConstraintMinX, @"superlayer", kCAConstraintMinX),
             c5(kCAConstraintWidth, @"superlayer", kCAConstraintWidth, 0.25, 0), nil]);
      axis("maxX(200), midX(70), width(50)",
           [NSArray arrayWithObjects:
             c3(kCAConstraintMaxX, @"superlayer", kCAConstraintMaxX),
             c4(kCAConstraintMidX, @"superlayer", kCAConstraintMidX, -30),
             c5(kCAConstraintWidth, @"superlayer", kCAConstraintWidth, 0.25, 0), nil]);
      axis("width(50), maxX(200), midX(70)",
           [NSArray arrayWithObjects:
             c5(kCAConstraintWidth, @"superlayer", kCAConstraintWidth, 0.25, 0),
             c3(kCAConstraintMaxX, @"superlayer", kCAConstraintMaxX),
             c4(kCAConstraintMidX, @"superlayer", kCAConstraintMidX, -30), nil]);
      axis("maxX(200), midX(70), minX(0)",
           [NSArray arrayWithObjects:
             c3(kCAConstraintMaxX, @"superlayer", kCAConstraintMaxX),
             c4(kCAConstraintMidX, @"superlayer", kCAConstraintMidX, -30),
             c3(kCAConstraintMinX, @"superlayer", kCAConstraintMinX), nil]);
      axis("width(50), midX(70), maxX(200)",
           [NSArray arrayWithObjects:
             c5(kCAConstraintWidth, @"superlayer", kCAConstraintWidth, 0.25, 0),
             c4(kCAConstraintMidX, @"superlayer", kCAConstraintMidX, -30),
             c3(kCAConstraintMaxX, @"superlayer", kCAConstraintMaxX), nil]);
      axis("all four: minX(0) midX(70) maxX(200) width(50)",
           [NSArray arrayWithObjects:
             c3(kCAConstraintMinX, @"superlayer", kCAConstraintMinX),
             c4(kCAConstraintMidX, @"superlayer", kCAConstraintMidX, -30),
             c3(kCAConstraintMaxX, @"superlayer", kCAConstraintMaxX),
             c5(kCAConstraintWidth, @"superlayer", kCAConstraintWidth, 0.25, 0), nil]);

      printf("\n--- a size constraint reading the other axis ---\n");
      axis("minX(0) and width = superlayer height (100)",
           [NSArray arrayWithObjects:
             c3(kCAConstraintMinX, @"superlayer", kCAConstraintMinX),
             c3(kCAConstraintWidth, @"superlayer", kCAConstraintHeight), nil]);
      axis("minX = superlayer maxY (100)",
           [NSArray arrayWithObject:
             c3(kCAConstraintMinX, @"superlayer", kCAConstraintMaxY)]);

      printf("\n--- what may a source name refer to? ---\n");
      {
        /* A layer of that name that is not a sibling. */
        CALayer *r = [CALayer layer];
        CALayer *l = [CALayer layer];
        CALayer *outsider = [CALayer layer];
        CGRect f;

        [r setBounds: CGRectMake(0, 0, 200, 100)];
        [r setLayoutManager: [CAConstraintLayoutManager layoutManager]];
        [outsider setName: @"outsider"];
        [outsider setFrame: CGRectMake(70, 0, 10, 10)];
        [l setName: @"child"];
        [l setFrame: CGRectMake(3, 5, 40, 20)];
        [r addSublayer: l];
        [l setConstraints: [NSArray arrayWithObject:
          c3(kCAConstraintMinX, @"outsider", kCAConstraintMinX)]];
        [r layoutSublayers];
        f = [l frame];
        printf("%-52s %8g %8g\n", "a named layer that is not in the tree",
               (double)f.origin.x, (double)f.size.width);
      }
      {
        /* Two siblings with the same name. */
        CALayer *r = [CALayer layer];
        CALayer *a1 = [CALayer layer];
        CALayer *a2 = [CALayer layer];
        CALayer *b = [CALayer layer];
        CGRect f;

        [r setBounds: CGRectMake(0, 0, 200, 100)];
        [r setLayoutManager: [CAConstraintLayoutManager layoutManager]];
        [a1 setName: @"a"];
        [a1 setFrame: CGRectMake(10, 0, 30, 20)];
        [a1 setConstraints: [NSArray arrayWithObject:
          c4(kCAConstraintMinX, @"superlayer", kCAConstraintMinX, 10)]];
        [a2 setName: @"a"];
        [a2 setFrame: CGRectMake(50, 0, 30, 20)];
        [a2 setConstraints: [NSArray arrayWithObject:
          c4(kCAConstraintMinX, @"superlayer", kCAConstraintMinX, 50)]];
        [b setName: @"b"];
        [b setFrame: CGRectMake(0, 0, 40, 20)];
        [b setConstraints: [NSArray arrayWithObject:
          c3(kCAConstraintMinX, @"a", kCAConstraintMinX)]];
        [r addSublayer: a1];
        [r addSublayer: a2];
        [r addSublayer: b];
        [r layoutSublayers];
        f = [b frame];
        printf("%-52s %8g\n", "two siblings both named a, b takes minX from",
               (double)f.origin.x);
      }

      printf("\n--- the layout manager and the layer's own hooks ---\n");
      {
        CALayer *r = [CALayer layer];
        CALayer *l = [CALayer layer];
        CGRect f;

        [r setBounds: CGRectMake(0, 0, 200, 100)];
        [l setName: @"child"];
        [l setFrame: CGRectMake(3, 5, 40, 20)];
        [r addSublayer: l];
        [l setConstraints: [NSArray arrayWithObject:
          c3(kCAConstraintMidX, @"superlayer", kCAConstraintMidX)]];
        [[CAConstraintLayoutManager layoutManager] layoutSublayersOfLayer: r];
        f = [l frame];
        printf("%-52s %8g\n", "manager asked directly, layer has no manager set",
               (double)f.origin.x);
      }
      {
        CAConstraint *c = c3(kCAConstraintMinX, @"superlayer", kCAConstraintMinX);

        printf("%-52s %d\n", "CAConstraint conforms to NSCoding",
               [c conformsToProtocol: @protocol(NSCoding)]);
        printf("%-52s %d\n", "CAConstraint conforms to NSSecureCoding",
               [c conformsToProtocol: @protocol(NSSecureCoding)]);
        printf("%-52s %d\n", "CAConstraint conforms to NSCopying",
               [c conformsToProtocol: @protocol(NSCopying)]);
        printf("%-52s %s\n", "CAConstraintLayoutManager superclass",
               [NSStringFromClass([CAConstraintLayoutManager superclass]) UTF8String]);
      }
      {
        CALayer *l = [CALayer layer];
        NSMutableArray *m = [NSMutableArray arrayWithObject:
          c3(kCAConstraintMinX, @"superlayer", kCAConstraintMinX)];

        [l setConstraints: m];
        [m removeAllObjects];
        printf("%-52s %lu\n", "constraints after emptying the array given",
               (unsigned long)[[l constraints] count]);
        [l setConstraints: nil];
        printf("%-52s %s\n", "constraints after setting nil",
               [l constraints] ? "not nil" : "nil");
        [l addConstraint: c3(kCAConstraintMinY, @"superlayer", kCAConstraintMinY)];
        printf("%-52s %lu\n", "addConstraint: after nil",
               (unsigned long)[[l constraints] count]);
      }
    }
  return 0;
}

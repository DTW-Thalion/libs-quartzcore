/* Follow up on qc_constraint_probe: when does a constraint on a SIBLING
   actually apply, and which constraint wins when an axis is over specified?

   Run on a macOS runner:
     clang -framework QuartzCore -framework CoreGraphics -framework Foundation \
       Tests/oracle/qc_constraint2_probe.m -o qc_constraint2_probe
*/

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

static void show(const char *what, CALayer *l)
{
  CGRect f = [l frame];

  printf("%-56s %8g %8g %8g %8g\n", what,
         (double)f.origin.x, (double)f.origin.y,
         (double)f.size.width, (double)f.size.height);
}

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

/* a is a plain sibling at (10,0,30,20); b reads one of its attributes. */
static void sibling(const char *what, CAConstraintAttribute sourceAttribute,
                    NSArray *constraintsOfA)
{
  CALayer *r = [CALayer layer];
  CALayer *a = [CALayer layer];
  CALayer *b = [CALayer layer];

  [r setBounds: CGRectMake(0, 0, 200, 100)];
  [r setLayoutManager: [CAConstraintLayoutManager layoutManager]];
  [a setName: @"a"];
  [b setName: @"b"];
  [a setFrame: CGRectMake(10, 0, 30, 20)];
  [b setFrame: CGRectMake(0, 0, 50, 20)];
  [r addSublayer: a];
  [r addSublayer: b];
  if (constraintsOfA)
    [a setConstraints: constraintsOfA];
  [b setConstraints: [NSArray arrayWithObject:
    c4(kCAConstraintMinX, @"a", sourceAttribute, 5)]];
  [r layoutSublayers];
  show(what, b);
}

int main(int argc, char **argv)
{
  @autoreleasepool
    {
      printf("--- b's minX is five past one of a's attributes ---\n");
      printf("%-56s %8s %8s %8s %8s\n", "a is at (10,0,30,20)", "x", "y", "w", "h");
      sibling("a has no constraints, source minX", kCAConstraintMinX, nil);
      sibling("a has no constraints, source midX", kCAConstraintMidX, nil);
      sibling("a has no constraints, source maxX", kCAConstraintMaxX, nil);
      sibling("a has no constraints, source width", kCAConstraintWidth, nil);
      sibling("a is pinned to its own minX, source minX", kCAConstraintMinX,
              [NSArray arrayWithObject:
                c4(kCAConstraintMinX, @"superlayer", kCAConstraintMinX, 10)]);
      sibling("a is pinned to its own minX, source maxX", kCAConstraintMaxX,
              [NSArray arrayWithObject:
                c4(kCAConstraintMinX, @"superlayer", kCAConstraintMinX, 10)]);
      sibling("a is pinned minX and width, source maxX", kCAConstraintMaxX,
              [NSArray arrayWithObjects:
                c4(kCAConstraintMinX, @"superlayer", kCAConstraintMinX, 10),
                c5(kCAConstraintWidth, @"superlayer", kCAConstraintWidth, 0.15, 0), nil]);
      sibling("a is pinned minY only, source maxX", kCAConstraintMaxX,
              [NSArray arrayWithObject:
                c3(kCAConstraintMinY, @"superlayer", kCAConstraintMinY)]);

      printf("\n--- which one wins when the axis is over specified ---\n");
      {
        /* Same three constraints as before, but the width first in the array
           and maxX before minX. */
        CALayer *r = [CALayer layer];
        CALayer *l = [CALayer layer];

        [r setBounds: CGRectMake(0, 0, 200, 100)];
        [r setLayoutManager: [CAConstraintLayoutManager layoutManager]];
        [l setName: @"child"];
        [l setFrame: CGRectMake(3, 5, 40, 20)];
        [r addSublayer: l];
        [l setConstraints: [NSArray arrayWithObjects:
          c5(kCAConstraintWidth, @"superlayer", kCAConstraintWidth, 0.25, 0),
          c3(kCAConstraintMaxX, @"superlayer", kCAConstraintMaxX),
          c3(kCAConstraintMinX, @"superlayer", kCAConstraintMinX), nil]];
        [r layoutSublayers];
        show("width, then maxX, then minX", l);
      }
      {
        CALayer *r = [CALayer layer];
        CALayer *l = [CALayer layer];

        [r setBounds: CGRectMake(0, 0, 200, 100)];
        [r setLayoutManager: [CAConstraintLayoutManager layoutManager]];
        [l setName: @"child"];
        [l setFrame: CGRectMake(3, 5, 40, 20)];
        [r addSublayer: l];
        [l setConstraints: [NSArray arrayWithObjects:
          c3(kCAConstraintMaxX, @"superlayer", kCAConstraintMaxX),
          c4(kCAConstraintMidX, @"superlayer", kCAConstraintMidX, -30), nil]];
        [r layoutSublayers];
        show("maxX then midX, no width", l);
      }
      {
        CALayer *r = [CALayer layer];
        CALayer *l = [CALayer layer];

        [r setBounds: CGRectMake(0, 0, 200, 100)];
        [r setLayoutManager: [CAConstraintLayoutManager layoutManager]];
        [l setName: @"child"];
        [l setFrame: CGRectMake(3, 5, 40, 20)];
        [r addSublayer: l];
        [l setConstraints: [NSArray arrayWithObjects:
          c3(kCAConstraintMinX, @"superlayer", kCAConstraintMinX),
          c3(kCAConstraintMidX, @"superlayer", kCAConstraintMidX),
          c3(kCAConstraintMaxX, @"superlayer", kCAConstraintMaxX), nil]];
        [r layoutSublayers];
        show("minX, midX and maxX, all three edges", l);
      }

      printf("\n--- a layer with no name of its own ---\n");
      {
        CALayer *r = [CALayer layer];
        CALayer *l = [CALayer layer];

        [r setBounds: CGRectMake(0, 0, 200, 100)];
        [r setLayoutManager: [CAConstraintLayoutManager layoutManager]];
        [l setFrame: CGRectMake(3, 5, 40, 20)];
        [r addSublayer: l];
        [l setConstraints: [NSArray arrayWithObject:
          c3(kCAConstraintMidX, @"superlayer", kCAConstraintMidX)]];
        [r layoutSublayers];
        show("nameless, pinned to the superlayer's midX", l);
      }

      printf("\n--- how far down does a layout reach ---\n");
      {
        CALayer *r = [CALayer layer];
        CALayer *mid = [CALayer layer];
        CALayer *deep = [CALayer layer];

        [r setBounds: CGRectMake(0, 0, 200, 100)];
        [r setLayoutManager: [CAConstraintLayoutManager layoutManager]];
        [mid setName: @"mid"];
        [mid setFrame: CGRectMake(0, 0, 100, 50)];
        [mid setLayoutManager: [CAConstraintLayoutManager layoutManager]];
        [deep setName: @"deep"];
        [deep setFrame: CGRectMake(1, 1, 10, 10)];
        [r addSublayer: mid];
        [mid addSublayer: deep];
        [deep setConstraints: [NSArray arrayWithObject:
          c3(kCAConstraintMaxX, @"superlayer", kCAConstraintMaxX)]];
        [r layoutSublayers];
        show("grandchild after layoutSublayers on the root", deep);
      }
      {
        CALayer *r = [CALayer layer];
        CALayer *mid = [CALayer layer];
        CALayer *deep = [CALayer layer];

        [r setBounds: CGRectMake(0, 0, 200, 100)];
        [r setLayoutManager: [CAConstraintLayoutManager layoutManager]];
        [mid setName: @"mid"];
        [mid setFrame: CGRectMake(0, 0, 100, 50)];
        [mid setLayoutManager: [CAConstraintLayoutManager layoutManager]];
        [deep setName: @"deep"];
        [deep setFrame: CGRectMake(1, 1, 10, 10)];
        [r addSublayer: mid];
        [mid addSublayer: deep];
        [deep setConstraints: [NSArray arrayWithObject:
          c3(kCAConstraintMaxX, @"superlayer", kCAConstraintMaxX)]];
        [r layoutIfNeeded];
        show("grandchild after layoutIfNeeded on the root", deep);
      }

      printf("\n--- what clears needsLayout ---\n");
      {
        CALayer *r = [CALayer layer];
        CALayer *l = [CALayer layer];

        [r setBounds: CGRectMake(0, 0, 200, 100)];
        [r setLayoutManager: [CAConstraintLayoutManager layoutManager]];
        [r addSublayer: l];
        printf("%-56s %d\n", "needsLayout of a fresh superlayer with a sublayer",
               (int)[r needsLayout]);
        [r layoutSublayers];
        printf("%-56s %d\n", "after layoutSublayers", (int)[r needsLayout]);
        [r setNeedsLayout];
        [r layoutIfNeeded];
        printf("%-56s %d\n", "after setNeedsLayout then layoutIfNeeded",
               (int)[r needsLayout]);
        [l setConstraints: [NSArray arrayWithObject:
          c3(kCAConstraintMidX, @"superlayer", kCAConstraintMidX)]];
        printf("%-56s %d %d\n", "after setConstraints: on the sublayer",
               (int)[r needsLayout], (int)[l needsLayout]);
        [r setBounds: CGRectMake(0, 0, 300, 100)];
        printf("%-56s %d\n", "after the superlayer's bounds change",
               (int)[r needsLayout]);
      }

      printf("\n--- does the layout manager touch bounds or position ---\n");
      {
        CALayer *r = [CALayer layer];
        CALayer *l = [CALayer layer];

        [r setBounds: CGRectMake(0, 0, 200, 100)];
        [r setLayoutManager: [CAConstraintLayoutManager layoutManager]];
        [l setName: @"child"];
        [l setFrame: CGRectMake(3, 5, 40, 20)];
        [l setAnchorPoint: CGPointMake(0, 0)];
        [r addSublayer: l];
        [l setConstraints: [NSArray arrayWithObjects:
          c3(kCAConstraintMinX, @"superlayer", kCAConstraintMinX),
          c5(kCAConstraintWidth, @"superlayer", kCAConstraintWidth, 0.5, 0), nil]];
        [r layoutSublayers];
        printf("%-56s %g %g %g %g\n", "anchor point 0,0: position and bounds size",
               (double)[l position].x, (double)[l position].y,
               (double)[l bounds].size.width, (double)[l bounds].size.height);
      }
    }
  return 0;
}

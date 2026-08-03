/* What CAConstraintLayoutManager actually does to a sublayer's frame.

   Run on a macOS runner:
     clang -framework QuartzCore -framework CoreGraphics -framework Foundation \
       Tests/oracle/qc_constraint_probe.m -o qc_constraint_probe
*/

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

static CALayer *root(void)
{
  CALayer *r = [CALayer layer];

  [r setBounds: CGRectMake(0, 0, 200, 100)];
  [r setLayoutManager: [CAConstraintLayoutManager layoutManager]];
  return r;
}

static CALayer *named(NSString *name, CGRect frame)
{
  CALayer *l = [CALayer layer];

  [l setName: name];
  [l setFrame: frame];
  return l;
}

static void show(const char *what, CALayer *l)
{
  CGRect f = [l frame];

  printf("%-52s %8g %8g %8g %8g\n", what,
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

/* One sublayer, laid out under the constraints given. */
static void one(const char *what, CGRect start, NSArray *constraints)
{
  CALayer *r = root();
  CALayer *l = named(@"child", start);

  [r addSublayer: l];
  [l setConstraints: constraints];
  [r layoutSublayers];
  show(what, l);
}

int main(int argc, char **argv)
{
  @autoreleasepool
    {
      printf("--- the constraint object itself ---\n");
      {
        CAConstraint *c = c3(kCAConstraintMidX, @"superlayer", kCAConstraintMidY);

        printf("%-52s %g %g\n", "scale and offset of the three argument form",
               (double)[c scale], (double)[c offset]);
        printf("%-52s %d %d %s\n", "attribute, sourceAttribute, sourceName",
               (int)[c attribute], (int)[c sourceAttribute],
               [[c sourceName] UTF8String]);
        printf("%-52s %d %d %d %d\n", "minX midX maxX width raw values",
               (int)kCAConstraintMinX, (int)kCAConstraintMidX,
               (int)kCAConstraintMaxX, (int)kCAConstraintWidth);
        printf("%-52s %d %d %d %d\n", "minY midY maxY height raw values",
               (int)kCAConstraintMinY, (int)kCAConstraintMidY,
               (int)kCAConstraintMaxY, (int)kCAConstraintHeight);
        printf("%-52s %g\n", "scale of the four argument form",
               (double)[c4(kCAConstraintMinX, @"superlayer", kCAConstraintMinX, 7) scale]);
        printf("%-52s %d\n", "the shared layout manager is one object",
               [CAConstraintLayoutManager layoutManager] ==
                 [CAConstraintLayoutManager layoutManager]);
        printf("%-52s %s\n", "a fresh layer's name",
               [[CALayer layer] name] ? "not nil" : "nil");
        printf("%-52s %s\n", "a fresh layer's constraints",
               [[CALayer layer] constraints] ? "not nil" : "nil");
      }

      printf("\n--- one constraint on an axis: what is the second relationship? ---\n");
      printf("%-52s %8s %8s %8s %8s\n", "", "x", "y", "w", "h");
      one("minX to superlayer minX", CGRectMake(3, 5, 40, 20),
          [NSArray arrayWithObject: c3(kCAConstraintMinX, @"superlayer", kCAConstraintMinX)]);
      one("midX to superlayer midX", CGRectMake(3, 5, 40, 20),
          [NSArray arrayWithObject: c3(kCAConstraintMidX, @"superlayer", kCAConstraintMidX)]);
      one("maxX to superlayer maxX", CGRectMake(3, 5, 40, 20),
          [NSArray arrayWithObject: c3(kCAConstraintMaxX, @"superlayer", kCAConstraintMaxX)]);
      one("width to superlayer width, half", CGRectMake(3, 5, 40, 20),
          [NSArray arrayWithObject: c5(kCAConstraintWidth, @"superlayer", kCAConstraintWidth, 0.5, 0)]);
      one("minY to superlayer minY", CGRectMake(3, 5, 40, 20),
          [NSArray arrayWithObject: c3(kCAConstraintMinY, @"superlayer", kCAConstraintMinY)]);
      one("maxY to superlayer maxY", CGRectMake(3, 5, 40, 20),
          [NSArray arrayWithObject: c3(kCAConstraintMaxY, @"superlayer", kCAConstraintMaxY)]);

      printf("\n--- two constraints on one axis ---\n");
      one("minX and maxX to the superlayer's",
          CGRectMake(3, 5, 40, 20),
          [NSArray arrayWithObjects:
            c3(kCAConstraintMinX, @"superlayer", kCAConstraintMinX),
            c3(kCAConstraintMaxX, @"superlayer", kCAConstraintMaxX), nil]);
      one("minX and half the width",
          CGRectMake(3, 5, 40, 20),
          [NSArray arrayWithObjects:
            c3(kCAConstraintMinX, @"superlayer", kCAConstraintMinX),
            c5(kCAConstraintWidth, @"superlayer", kCAConstraintWidth, 0.5, 0), nil]);
      one("maxX and half the width",
          CGRectMake(3, 5, 40, 20),
          [NSArray arrayWithObjects:
            c3(kCAConstraintMaxX, @"superlayer", kCAConstraintMaxX),
            c5(kCAConstraintWidth, @"superlayer", kCAConstraintWidth, 0.5, 0), nil]);
      one("midX and half the width",
          CGRectMake(3, 5, 40, 20),
          [NSArray arrayWithObjects:
            c3(kCAConstraintMidX, @"superlayer", kCAConstraintMidX),
            c5(kCAConstraintWidth, @"superlayer", kCAConstraintWidth, 0.5, 0), nil]);
      one("minX and midX",
          CGRectMake(3, 5, 40, 20),
          [NSArray arrayWithObjects:
            c4(kCAConstraintMinX, @"superlayer", kCAConstraintMinX, 20),
            c3(kCAConstraintMidX, @"superlayer", kCAConstraintMidX), nil]);
      one("midX and maxX",
          CGRectMake(3, 5, 40, 20),
          [NSArray arrayWithObjects:
            c3(kCAConstraintMidX, @"superlayer", kCAConstraintMidX),
            c4(kCAConstraintMaxX, @"superlayer", kCAConstraintMaxX, -20), nil]);

      printf("\n--- over specified: three on one axis ---\n");
      one("minX, maxX and a width that disagrees",
          CGRectMake(3, 5, 40, 20),
          [NSArray arrayWithObjects:
            c3(kCAConstraintMinX, @"superlayer", kCAConstraintMinX),
            c3(kCAConstraintMaxX, @"superlayer", kCAConstraintMaxX),
            c5(kCAConstraintWidth, @"superlayer", kCAConstraintWidth, 0.25, 0), nil]);
      one("the same attribute twice, 10 then 40",
          CGRectMake(3, 5, 40, 20),
          [NSArray arrayWithObjects:
            c4(kCAConstraintMinX, @"superlayer", kCAConstraintMinX, 10),
            c4(kCAConstraintMinX, @"superlayer", kCAConstraintMinX, 40), nil]);

      printf("\n--- scale and offset ---\n");
      one("minX = superlayer maxX * 0.25 + 7",
          CGRectMake(3, 5, 40, 20),
          [NSArray arrayWithObject:
            c5(kCAConstraintMinX, @"superlayer", kCAConstraintMaxX, 0.25, 7)]);
      one("width = superlayer height + 5",
          CGRectMake(3, 5, 40, 20),
          [NSArray arrayWithObject:
            c4(kCAConstraintWidth, @"superlayer", kCAConstraintHeight, 5)]);

      printf("\n--- a source that is not there ---\n");
      one("relative to a layer that does not exist",
          CGRectMake(3, 5, 40, 20),
          [NSArray arrayWithObject: c3(kCAConstraintMinX, @"nobody", kCAConstraintMinX)]);
      one("relative to itself",
          CGRectMake(3, 5, 40, 20),
          [NSArray arrayWithObject: c4(kCAConstraintMinX, @"child", kCAConstraintMinX, 10)]);

      printf("\n--- a sibling as the source ---\n");
      {
        CALayer *r = root();
        CALayer *a = named(@"a", CGRectMake(10, 0, 30, 20));
        CALayer *b = named(@"b", CGRectMake(0, 0, 50, 20));

        [r addSublayer: a];
        [r addSublayer: b];
        [b setConstraints: [NSArray arrayWithObject:
          c4(kCAConstraintMinX, @"a", kCAConstraintMaxX, 5)]];
        [r layoutSublayers];
        show("b's left edge five past a's right edge", b);
      }
      {
        /* The source comes after the layer that depends on it. */
        CALayer *r = root();
        CALayer *a = named(@"a", CGRectMake(0, 0, 50, 20));
        CALayer *b = named(@"b", CGRectMake(0, 0, 30, 20));

        [r addSublayer: b];
        [r addSublayer: a];
        [a setConstraints: [NSArray arrayWithObject:
          c3(kCAConstraintMinX, @"superlayer", kCAConstraintMidX)]];
        [b setConstraints: [NSArray arrayWithObject:
          c4(kCAConstraintMinX, @"a", kCAConstraintMinX, 10)]];
        [r layoutSublayers];
        show("a, laid out second in the array", a);
        show("b, which depends on a", b);
      }
      {
        /* Two layers that depend on each other. */
        CALayer *r = root();
        CALayer *a = named(@"a", CGRectMake(0, 0, 50, 20));
        CALayer *b = named(@"b", CGRectMake(0, 0, 30, 20));

        [r addSublayer: a];
        [r addSublayer: b];
        [a setConstraints: [NSArray arrayWithObject:
          c4(kCAConstraintMinX, @"b", kCAConstraintMaxX, 1)]];
        [b setConstraints: [NSArray arrayWithObject:
          c4(kCAConstraintMinX, @"a", kCAConstraintMaxX, 1)]];
        [r layoutSublayers];
        show("a, in a circle with b", a);
        show("b, in a circle with a", b);
      }

      printf("\n--- does the superlayer's bounds origin count? ---\n");
      {
        CALayer *r = [CALayer layer];
        CALayer *l = named(@"child", CGRectMake(3, 5, 40, 20));

        [r setBounds: CGRectMake(30, 70, 200, 100)];
        [r setLayoutManager: [CAConstraintLayoutManager layoutManager]];
        [r addSublayer: l];
        [l setConstraints: [NSArray arrayWithObjects:
          c3(kCAConstraintMinX, @"superlayer", kCAConstraintMinX),
          c3(kCAConstraintMinY, @"superlayer", kCAConstraintMinY), nil]];
        [r layoutSublayers];
        show("bounds origin 30,70, child pinned to minX minY", l);
      }

      printf("\n--- the two sublayer example from the documentation ---\n");
      {
        CALayer *r = root();
        CALayer *left = named(@"left", CGRectMake(0, 0, 20, 20));
        CALayer *right = named(@"right", CGRectMake(0, 0, 20, 20));
        CAConstraint *height = c3(kCAConstraintHeight, @"superlayer", kCAConstraintHeight);
        CAConstraint *width = c5(kCAConstraintWidth, @"superlayer", kCAConstraintWidth, 0.5, 0);
        CAConstraint *bottom = c3(kCAConstraintMinY, @"superlayer", kCAConstraintMinY);

        [r addSublayer: left];
        [r addSublayer: right];
        [left setConstraints: [NSArray arrayWithObjects: height, width, bottom,
          c3(kCAConstraintMinX, @"superlayer", kCAConstraintMinX), nil]];
        [right setConstraints: [NSArray arrayWithObjects: height, width, bottom,
          c3(kCAConstraintMaxX, @"superlayer", kCAConstraintMaxX), nil]];
        [r layoutSublayers];
        show("left", left);
        show("right", right);
      }

      printf("\n--- what asks for a layout, and does addConstraint: append? ---\n");
      {
        CALayer *r = root();
        CALayer *l = named(@"child", CGRectMake(3, 5, 40, 20));

        [r addSublayer: l];
        [r layoutIfNeeded];
        [l addConstraint: c3(kCAConstraintMinX, @"superlayer", kCAConstraintMinX)];
        printf("%-52s %lu\n", "constraints after addConstraint: on an empty set",
               (unsigned long)[[l constraints] count]);
        printf("%-52s %d %d\n", "needsLayout of the superlayer and the layer",
               (int)[r needsLayout], (int)[l needsLayout]);
        [l addConstraint: c3(kCAConstraintMinY, @"superlayer", kCAConstraintMinY)];
        printf("%-52s %lu\n", "and after a second one",
               (unsigned long)[[l constraints] count]);
        [r layoutIfNeeded];
        show("after layoutIfNeeded on the superlayer", l);
      }
      {
        CALayer *r = root();
        CALayer *l = named(@"child", CGRectMake(3, 5, 40, 20));

        [r addSublayer: l];
        [l setConstraints: [NSArray arrayWithObject:
          c3(kCAConstraintMidX, @"superlayer", kCAConstraintMidX)]];
        [r layoutIfNeeded];
        show("layoutIfNeeded rather than layoutSublayers", l);
      }
      {
        /* Is the manager needed at all, or do constraints work without one? */
        CALayer *r = [CALayer layer];
        CALayer *l = named(@"child", CGRectMake(3, 5, 40, 20));

        [r setBounds: CGRectMake(0, 0, 200, 100)];
        [r addSublayer: l];
        [l setConstraints: [NSArray arrayWithObject:
          c3(kCAConstraintMidX, @"superlayer", kCAConstraintMidX)]];
        [r layoutSublayers];
        show("with no layout manager set", l);
      }
    }
  return 0;
}

/* Probe a layer's non-geometry property defaults, its sublayer tree and its
   hit testing against Apple's QuartzCore.

   Run on a macOS runner:
     clang -framework QuartzCore -framework CoreGraphics -framework Foundation \
       Tests/oracle/qc_layer_state_probe.m -o qc_layer_state_probe
*/

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

static void showObj(const char *what, id v)
{
  printf("%-34s %s\n", what, v ? [[v description] UTF8String] : "(nil)");
}

int main(int argc, char **argv)
{
  @autoreleasepool
    {
      printf("=== a layer's property defaults ===\n");
      {
        CALayer *l = [CALayer layer];

        printf("%-34s %g\n", "opacity", (double)[l opacity]);
        printf("%-34s %d\n", "hidden", (int)[l isHidden]);
        printf("%-34s %d\n", "masksToBounds", (int)[l masksToBounds]);
        printf("%-34s %d\n", "doubleSided", (int)[l isDoubleSided]);
        printf("%-34s %d\n", "geometryFlipped", (int)[l isGeometryFlipped]);
        printf("%-34s %g\n", "zPosition", (double)[l zPosition]);
        printf("%-34s %g\n", "borderWidth", (double)[l borderWidth]);
        printf("%-34s %g\n", "cornerRadius", (double)[l cornerRadius]);
        printf("%-34s %g\n", "shadowOpacity", (double)[l shadowOpacity]);
        printf("%-34s %g\n", "shadowRadius", (double)[l shadowRadius]);
        printf("%-34s %g %g\n", "shadowOffset",
               (double)[l shadowOffset].width, (double)[l shadowOffset].height);
        printf("%-34s %g\n", "contentsScale", (double)[l contentsScale]);
        printf("%-34s %g %g %g %g\n", "contentsRect",
               (double)[l contentsRect].origin.x,
               (double)[l contentsRect].origin.y,
               (double)[l contentsRect].size.width,
               (double)[l contentsRect].size.height);
        showObj("contentsGravity", [l contentsGravity]);
        showObj("minificationFilter", [l minificationFilter]);
        showObj("magnificationFilter", [l magnificationFilter]);
        printf("%-34s %d\n", "needsDisplayOnBoundsChange",
               (int)[l needsDisplayOnBoundsChange]);
        printf("%-34s %d\n", "shouldRasterize", (int)[l shouldRasterize]);
        printf("%-34s %g\n", "rasterizationScale",
               (double)[l rasterizationScale]);
        showObj("name", [l name]);
        showObj("sublayers", [l sublayers]);
        showObj("superlayer", [l superlayer]);
        showObj("actions", [l actions]);
        showObj("style", [l style]);
        printf("%-34s %s\n", "backgroundColor",
               [l backgroundColor] ? "(non-NULL)" : "NULL");
        printf("%-34s %s\n", "borderColor",
               [l borderColor] ? "(non-NULL)" : "NULL");
        printf("%-34s %s\n", "contents",
               [l contents] ? "(non-nil)" : "(nil)");
      }

      printf("\n=== the sublayer tree ===\n");
      {
        CALayer *root = [CALayer layer];
        CALayer *a = [CALayer layer];
        CALayer *b = [CALayer layer];
        CALayer *c = [CALayer layer];

        [a setName: @"a"];
        [b setName: @"b"];
        [c setName: @"c"];

        [root addSublayer: a];
        printf("%-34s %lu\n", "after one add, count",
               (unsigned long)[[root sublayers] count]);
        printf("%-34s %d\n", "the sublayer's superlayer is the root",
               [a superlayer] == root);

        [root addSublayer: b];
        [root addSublayer: c];
        printf("%-34s %s %s %s\n", "order after three adds",
               [[[[root sublayers] objectAtIndex: 0] name] UTF8String],
               [[[[root sublayers] objectAtIndex: 1] name] UTF8String],
               [[[[root sublayers] objectAtIndex: 2] name] UTF8String]);

        [b removeFromSuperlayer];
        printf("%-34s %lu\n", "after removing one, count",
               (unsigned long)[[root sublayers] count]);
        printf("%-34s %s\n", "the removed one's superlayer",
               [b superlayer] ? "(non-nil)" : "(nil)");

        CALayer *d = [CALayer layer];
        [d setName: @"d"];
        [root insertSublayer: d atIndex: 0];
        printf("%-34s %s\n", "insertSublayer:atIndex:0 puts it first",
               [[[[root sublayers] objectAtIndex: 0] name] UTF8String]);

        CALayer *e = [CALayer layer];
        [e setName: @"e"];
        [root insertSublayer: e below: a];
        printf("%-34s %lu\n", "insertSublayer:below: index of e",
               (unsigned long)[[root sublayers] indexOfObject: e]);

        CALayer *f = [CALayer layer];
        [f setName: @"f"];
        [root insertSublayer: f above: a];
        printf("%-34s %lu\n", "insertSublayer:above: index of f",
               (unsigned long)[[root sublayers] indexOfObject: f]);

        CALayer *other = [CALayer layer];
        [other addSublayer: a];
        printf("%-34s %lu\n", "after reparenting, old count",
               (unsigned long)[[root sublayers] count]);
        printf("%-34s %d\n", "and the new superlayer is the other",
               [a superlayer] == other);

        CALayer *g = [CALayer layer];
        [g setName: @"g"];
        [root replaceSublayer: c with: g];
        printf("%-34s %d\n", "replaceSublayer: leaves the new one in",
               [[root sublayers] containsObject: g]);
        printf("%-34s %s\n", "and the old one's superlayer",
               [c superlayer] ? "(non-nil)" : "(nil)");
      }

      printf("\n=== setting the sublayers array wholesale ===\n");
      {
        CALayer *root = [CALayer layer];
        CALayer *a = [CALayer layer];
        CALayer *b = [CALayer layer];

        [root setSublayers: [NSArray arrayWithObjects: a, b, nil]];
        printf("%-34s %lu\n", "count after setSublayers:",
               (unsigned long)[[root sublayers] count]);
        printf("%-34s %d\n", "and each one's superlayer is set",
               [a superlayer] == root && [b superlayer] == root);
      }

      printf("\n=== hit testing ===\n");
      {
        CALayer *root = [CALayer layer];
        CALayer *child = [CALayer layer];

        [root setBounds: CGRectMake(0, 0, 100, 100)];
        [root setPosition: CGPointMake(50, 50)];
        [child setBounds: CGRectMake(0, 0, 20, 20)];
        [child setPosition: CGPointMake(50, 50)];
        [root addSublayer: child];

        printf("%-34s %d\n", "containsPoint 50,50",
               [root containsPoint: CGPointMake(50, 50)]);
        printf("%-34s %d\n", "containsPoint 0,0",
               [root containsPoint: CGPointMake(0, 0)]);
        printf("%-34s %d\n", "containsPoint -1,-1",
               [root containsPoint: CGPointMake(-1, -1)]);
        printf("%-34s %d\n", "containsPoint 100,100",
               [root containsPoint: CGPointMake(100, 100)]);

        showObj("hitTest at the centre", [root hitTest: CGPointMake(50, 50)]);
        printf("%-34s %d\n", "hitTest at the centre is the child",
               [root hitTest: CGPointMake(50, 50)] == child);
        printf("%-34s %d\n", "hitTest at a corner is the root",
               [root hitTest: CGPointMake(5, 5)] == root);
        printf("%-34s %s\n", "hitTest outside",
               [root hitTest: CGPointMake(500, 500)] ? "(non-nil)" : "(nil)");
      }

      printf("\n=== the model and presentation layers ===\n");
      {
        CALayer *l = [CALayer layer];

        printf("%-34s %s\n", "presentationLayer before display",
               [l presentationLayer] ? "(non-nil)" : "(nil)");
        printf("%-34s %d\n", "modelLayer is itself", [l modelLayer] == l);
      }
    }
  return 0;
}

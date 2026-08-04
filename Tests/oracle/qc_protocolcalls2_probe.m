/* Which sublayer changes send invalidateLayoutOfLayer:, and to which layer.
   A fresh manager class per case, since the delegate and manager capabilities
   look to be cached per class rather than per instance. */
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

static NSMutableArray *sent;

@interface Manager : NSObject
@end

@implementation Manager
- (void) layoutSublayersOfLayer: (CALayer *)layer
{
  [sent addObject: [NSString stringWithFormat: @"layoutSublayersOfLayer: %@",
                    [layer name] ? [layer name] : @"?"]];
}

- (void) invalidateLayoutOfLayer: (CALayer *)layer
{
  [sent addObject: [NSString stringWithFormat: @"invalidateLayoutOfLayer: %@",
                    [layer name] ? [layer name] : @"?"]];
}
@end

static CALayer *managedLayer(NSString *name)
{
  CALayer *l = [CALayer layer];

  [l setName: name];
  [l setBounds: CGRectMake(0, 0, 50, 50)];
  [l setLayoutManager: (id)[Manager new]];
  return l;
}

static void show(const char *what)
{
  printf("%s: %s\n", what,
         [sent count] ? [[sent componentsJoinedByString: @", "] UTF8String]
                      : "nothing");
  [sent removeAllObjects];
}

int main(void)
{
  setbuf(stdout, NULL);
  @autoreleasepool
    {
      CALayer *root = managedLayer(@"root");
      CALayer *first = [CALayer layer];
      CALayer *second = [CALayer layer];
      CALayer *third = [CALayer layer];

      sent = [NSMutableArray array];

      [root addSublayer: first];
      show("addSublayer");

      [root insertSublayer: second atIndex: 0];
      show("insertSublayer:atIndex:");

      [root insertSublayer: third above: first];
      show("insertSublayer:above:");

      [first removeFromSuperlayer];
      show("removeFromSuperlayer of a sublayer");

      [root replaceSublayer: second with: first];
      show("replaceSublayer:with:");

      [root setSublayers: [NSArray arrayWithObject: second]];
      show("setSublayers:");

      [root setNeedsLayout];
      show("setNeedsLayout");

      [root setPosition: CGPointMake(5, 5)];
      show("setPosition");

      printf("== a layer whose SUPERLAYER has the manager ==\n");
      CALayer *managedChild = managedLayer(@"child");

      [root addSublayer: managedChild];
      show("adding a managed layer to a managed root");

      [managedChild addSublayer: [CALayer layer]];
      show("adding to the managed child");

      printf("== needsLayout after each ==\n");
      CALayer *plain = [CALayer layer];

      [plain setBounds: CGRectMake(0, 0, 10, 10)];
      [plain layoutIfNeeded];
      printf("settled, needsLayout %d\n", (int)[plain needsLayout]);
      [plain setNeedsLayout];
      printf("after setNeedsLayout, needsLayout %d\n", (int)[plain needsLayout]);
    }
  return 0;
}

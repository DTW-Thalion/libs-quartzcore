/* Whether invalidateLayoutOfLayer: is sent only when a layout that was valid
   becomes invalid: each case lays the layer out first, then changes it. */
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

static NSMutableArray *sent;

@interface Manager : NSObject
@end

@implementation Manager
- (void) layoutSublayersOfLayer: (CALayer *)layer
{
  [sent addObject: @"layoutSublayersOfLayer:"];
}

- (void) invalidateLayoutOfLayer: (CALayer *)layer
{
  [sent addObject: @"invalidateLayoutOfLayer:"];
}

- (CGSize) preferredSizeOfLayer: (CALayer *)layer
{
  [sent addObject: @"preferredSizeOfLayer:"];
  return CGSizeMake(11, 22);
}
@end

static CALayer *root;

/* Lay the layer out so that its layout is valid, then forget what that sent. */
static void settle(void)
{
  [root layoutIfNeeded];
  [sent removeAllObjects];
}

static void show(const char *what)
{
  printf("%-32s %s\n", what,
         [sent count] ? [[sent componentsJoinedByString: @", "] UTF8String]
                      : "nothing");
  [sent removeAllObjects];
}

int main(void)
{
  setbuf(stdout, NULL);
  @autoreleasepool
    {
      CALayer *a = [CALayer layer];
      CALayer *b = [CALayer layer];
      CALayer *c = [CALayer layer];
      CALayer *d = [CALayer layer];

      sent = [NSMutableArray array];
      root = [CALayer layer];
      [root setBounds: CGRectMake(0, 0, 50, 50)];
      [root setLayoutManager: (id)[Manager new]];

      settle();
      [root addSublayer: a];
      show("addSublayer:");

      settle();
      [root insertSublayer: b atIndex: 0];
      show("insertSublayer:atIndex:");

      settle();
      [root insertSublayer: c above: a];
      show("insertSublayer:above:");

      settle();
      [root insertSublayer: d below: a];
      show("insertSublayer:below:");

      settle();
      [a removeFromSuperlayer];
      show("a sublayer removing itself");

      settle();
      [root replaceSublayer: b with: a];
      show("replaceSublayer:with:");

      settle();
      [root setSublayers: [NSArray arrayWithObject: c]];
      show("setSublayers:");

      settle();
      [root setNeedsLayout];
      show("setNeedsLayout");

      settle();
      [root setBounds: CGRectMake(0, 0, 60, 60)];
      show("setBounds:");

      settle();
      [root setPosition: CGPointMake(5, 5)];
      show("setPosition:");

      settle();
      [root addSublayer: [CALayer layer]];
      [root addSublayer: [CALayer layer]];
      show("two adds without laying out between");

      printf("--- and layoutIfNeeded on a settled layer ---\n");
      settle();
      [root layoutIfNeeded];
      show("layoutIfNeeded again");
    }
  return 0;
}

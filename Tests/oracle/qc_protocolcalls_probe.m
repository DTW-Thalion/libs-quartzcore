/* Which of the delegate and layout manager messages Apple QuartzCore
   actually sends, and when. */
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

static NSMutableArray *sent;

@interface Watcher : NSObject
@property (assign) BOOL drawsItself;
@end

@implementation Watcher
@synthesize drawsItself;

- (void) layerWillDraw: (CALayer *)layer
{
  [sent addObject: @"layerWillDraw:"];
}

- (void) drawLayer: (CALayer *)layer inContext: (CGContextRef)ctx
{
  [sent addObject: @"drawLayer:inContext:"];
}

- (void) displayLayer: (CALayer *)layer
{
  [sent addObject: @"displayLayer:"];
}

- (BOOL) respondsToSelector: (SEL)aSelector
{
  if (aSelector == @selector(displayLayer:) && !drawsItself)
    return NO;
  return [super respondsToSelector: aSelector];
}
@end

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
  return CGSizeMake(123, 456);
}
@end

static void show(const char *what)
{
  printf("%s: %s\n", what,
         [[sent componentsJoinedByString: @", "] UTF8String]);
  [sent removeAllObjects];
}

int main(void)
{
  setbuf(stdout, NULL);
  @autoreleasepool
    {
      sent = [NSMutableArray array];

      printf("== a delegate that draws into a context ==\n");
      CALayer *l = [CALayer layer];
      Watcher *w = [Watcher new];

      [l setBounds: CGRectMake(0, 0, 20, 20)];
      [l setDelegate: w];
      [l display];
      show("display");

      printf("== a delegate that displays the layer itself ==\n");
      CALayer *own = [CALayer layer];
      Watcher *drawer = [Watcher new];

      [drawer setDrawsItself: YES];
      [own setBounds: CGRectMake(0, 0, 20, 20)];
      [own setDelegate: drawer];
      [own display];
      show("display");

      printf("== the layout manager ==\n");
      CALayer *managed = [CALayer layer];
      Manager *m = [Manager new];

      [managed setBounds: CGRectMake(0, 0, 20, 20)];
      [managed setLayoutManager: (id)m];
      show("after setLayoutManager");

      [managed setNeedsLayout];
      show("setNeedsLayout");

      [managed layoutIfNeeded];
      show("layoutIfNeeded");

      CGSize preferred = [managed preferredFrameSize];
      printf("preferredFrameSize with a manager: (%g,%g)\n",
             preferred.width, preferred.height);
      show("preferredFrameSize");

      printf("== preferredFrameSize with no layout manager ==\n");
      CALayer *plain = [CALayer layer];

      [plain setBounds: CGRectMake(0, 0, 30, 40)];
      preferred = [plain preferredFrameSize];
      printf("plain layer of 30x40: (%g,%g)\n",
             preferred.width, preferred.height);

      printf("== does a sublayer change invalidate the manager ==\n");
      [managed addSublayer: [CALayer layer]];
      show("addSublayer");
      [managed setBounds: CGRectMake(0, 0, 40, 40)];
      show("setBounds");
    }
  return 0;
}

/* The formal protocols Apple's QuartzCore declares, and what is in them.

   Run on a macOS runner:
     clang -framework QuartzCore -framework CoreGraphics -framework Foundation \
       Tests/oracle/qc_protocols_probe.m -o qc_protocols_probe
*/

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

static void list(const char *name)
{
  Protocol *p = NSProtocolFromString([NSString stringWithUTF8String: name]);
  unsigned int count = 0;
  struct objc_method_description *m;
  Protocol * __unsafe_unretained *parents;

  printf("\n=== %s : %s\n", name, p ? "PRESENT" : "ABSENT");
  if (p == NULL)
    return;

  parents = protocol_copyProtocolList(p, &count);
  printf("  inherits from %u:", count);
  for (unsigned int i = 0; i < count; i++)
    printf(" %s", protocol_getName(parents[i]));
  printf("\n");
  free(parents);

  m = protocol_copyMethodDescriptionList(p, YES, YES, &count);
  printf("  required instance methods: %u\n", count);
  for (unsigned int i = 0; i < count; i++)
    printf("    %s\n", sel_getName(m[i].name));
  free(m);

  m = protocol_copyMethodDescriptionList(p, NO, YES, &count);
  printf("  optional instance methods: %u\n", count);
  for (unsigned int i = 0; i < count; i++)
    printf("    %s   %s\n", sel_getName(m[i].name), m[i].types);
  free(m);
}

/* A class that implements the whole of each one. */
@interface GSProbeDelegate : NSObject
@end
@implementation GSProbeDelegate
- (void) animationDidStart: (CAAnimation *)a {}
- (void) animationDidStop: (CAAnimation *)a finished: (BOOL)f {}
- (void) displayLayer: (CALayer *)l {}
- (void) drawLayer: (CALayer *)l inContext: (CGContextRef)c {}
- (void) layerWillDraw: (CALayer *)l {}
- (id<CAAction>) actionForLayer: (CALayer *)l forKey: (NSString *)k { return nil; }
- (void) layoutSublayersOfLayer: (CALayer *)l {}
@end

int main(int argc, char **argv)
{
  @autoreleasepool
    {
      printf("--- the protocol names ---\n");
      list("CAAnimationDelegate");
      list("CALayerDelegate");
      list("CALayoutManager");
      list("CAAction");
      list("CAMediaTiming");
      list("GSCAAnimationDelegate");

      printf("\n--- conformance is by declaration, not by implementing ---\n");
      {
        GSProbeDelegate *d = [[GSProbeDelegate alloc] init];

        printf("%-52s %d\n", "implements everything, conforms to CALayerDelegate",
               [d conformsToProtocol: NSProtocolFromString(@"CALayerDelegate")]);
        printf("%-52s %d\n", "responds to displayLayer:",
               [d respondsToSelector: @selector(displayLayer:)]);
      }

      printf("\n--- what Apple's own objects declare ---\n");
      printf("%-52s %d\n", "CAConstraintLayoutManager : CALayoutManager",
             [CAConstraintLayoutManager conformsToProtocol:
               NSProtocolFromString(@"CALayoutManager")]);
      printf("%-52s %d\n", "CAAnimation : CAAction",
             [CAAnimation conformsToProtocol: @protocol(CAAction)]);
      printf("%-52s %d\n", "CAAnimation : CAMediaTiming",
             [CAAnimation conformsToProtocol: @protocol(CAMediaTiming)]);
      printf("%-52s %d\n", "CALayer : CAMediaTiming",
             [CALayer conformsToProtocol: @protocol(CAMediaTiming)]);
    }
  return 0;
}

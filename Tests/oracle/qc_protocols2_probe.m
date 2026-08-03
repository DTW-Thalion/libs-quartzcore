/* Does Apple DECLARE CALayerDelegate, even though nothing references it?
   A protocol only reaches the binary when something mentions it, so
   @protocol() is the question to ask, not NSProtocolFromString().

   If the header does not declare it this file does not compile, which is
   itself the answer.

   Run on a macOS runner:
     clang -framework QuartzCore -framework CoreGraphics -framework Foundation \
       Tests/oracle/qc_protocols2_probe.m -o qc_protocols2_probe
*/

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

@interface GSProbeLayerDelegate : NSObject <CALayerDelegate>
@end
@implementation GSProbeLayerDelegate
@end

@interface GSProbeAnimationDelegate : NSObject <CAAnimationDelegate>
@end
@implementation GSProbeAnimationDelegate
@end

@interface GSProbeLayoutManager : NSObject <CALayoutManager>
@end
@implementation GSProbeLayoutManager
@end

static void list(Protocol *p, const char *name)
{
  unsigned int count = 0;
  struct objc_method_description *m;

  printf("\n=== %s\n", name);
  m = protocol_copyMethodDescriptionList(p, YES, YES, &count);
  printf("  required: %u\n", count);
  for (unsigned int i = 0; i < count; i++)
    printf("    %s\n", sel_getName(m[i].name));
  free(m);
  m = protocol_copyMethodDescriptionList(p, NO, YES, &count);
  printf("  optional: %u\n", count);
  for (unsigned int i = 0; i < count; i++)
    printf("    %s   %s\n", sel_getName(m[i].name), m[i].types);
  free(m);
}

int main(int argc, char **argv)
{
  @autoreleasepool
    {
      printf("--- naming them at compile time ---\n");
      list(@protocol(CALayerDelegate), "CALayerDelegate");
      list(@protocol(CAAnimationDelegate), "CAAnimationDelegate");
      list(@protocol(CALayoutManager), "CALayoutManager");

      printf("\n--- once named, is it in the runtime? ---\n");
      printf("%-52s %d\n", "NSProtocolFromString(CALayerDelegate)",
             NSProtocolFromString(@"CALayerDelegate") != nil);

      printf("\n--- a class that declares each one, implementing nothing ---\n");
      printf("%-52s %d\n", "declares CALayerDelegate",
             [GSProbeLayerDelegate conformsToProtocol: @protocol(CALayerDelegate)]);
      printf("%-52s %d\n", "declares CAAnimationDelegate",
             [GSProbeAnimationDelegate conformsToProtocol: @protocol(CAAnimationDelegate)]);
      printf("%-52s %d\n", "declares CALayoutManager",
             [GSProbeLayoutManager conformsToProtocol: @protocol(CALayoutManager)]);
      printf("%-52s %d\n", "and every method is optional, so it compiles",
             1);

      printf("\n--- can a layer take one? ---\n");
      {
        CALayer *l = [CALayer layer];
        GSProbeLayerDelegate *d = [[GSProbeLayerDelegate alloc] init];
        GSProbeLayoutManager *m = [[GSProbeLayoutManager alloc] init];

        [l setDelegate: d];
        [l setLayoutManager: m];
        printf("%-52s %d\n", "delegate and layoutManager assigned",
               [l delegate] == d && [l layoutManager] == m);
      }
      {
        CAAnimation *a = [CAAnimation animation];
        GSProbeAnimationDelegate *d = [[GSProbeAnimationDelegate alloc] init];

        [a setDelegate: d];
        printf("%-52s %d\n", "an animation delegate assigned", [a delegate] == d);
      }
    }
  return 0;
}

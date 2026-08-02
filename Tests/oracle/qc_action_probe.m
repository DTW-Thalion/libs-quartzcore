/* Probe how a layer looks up an action against Apple's QuartzCore.

   Run on a macOS runner:
     clang -framework QuartzCore -framework CoreGraphics -framework Foundation \
       Tests/oracle/qc_action_probe.m -o qc_action_probe
*/

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@interface QCMarker : CAAnimation
@property (retain) NSString *tag;
@end

@implementation QCMarker
@synthesize tag = _tag;
@end

@interface QCActionDelegate : NSObject <CALayerDelegate>
{
  id _answer;
}
- (void) setAnswer: (id)answer;
@end

@implementation QCActionDelegate
- (void) setAnswer: (id)answer
{
  _answer = answer;
}
- (id<CAAction>) actionForLayer: (CALayer *)layer forKey: (NSString *)key
{
  return _answer;
}
@end

static QCMarker *marker(NSString *tag)
{
  QCMarker *m = [QCMarker animation];

  [m setTag: tag];
  return m;
}

static const char *tagOf(id action)
{
  if (action == nil)
    return "(nil)";
  if ([action isKindOfClass: [QCMarker class]])
    return [[(QCMarker *)action tag] UTF8String];
  return [[action description] UTF8String];
}

int main(int argc, char **argv)
{
  @autoreleasepool
    {
      printf("=== a bare layer ===\n");
      {
        CALayer *l = [CALayer layer];

        printf("%-44s %s\n", "actionForKey:position", tagOf([l actionForKey: @"position"]));
        printf("%-44s %s\n", "actionForKey:aKeyNobodyDefined",
               tagOf([l actionForKey: @"aKeyNobodyDefined"]));
        printf("%-44s %s\n", "+defaultActionForKey:position",
               tagOf([CALayer defaultActionForKey: @"position"]));
        printf("%-44s %s\n", "+defaultActionForKey:onOrderIn",
               tagOf([CALayer defaultActionForKey: kCAOnOrderIn]));
      }

      printf("\n=== the delegate ===\n");
      {
        CALayer *l = [CALayer layer];
        QCActionDelegate *d = [[[QCActionDelegate alloc] init] autorelease];

        [l setDelegate: d];

        [d setAnswer: marker(@"fromDelegate")];
        printf("%-44s %s\n", "delegate answers an action",
               tagOf([l actionForKey: @"position"]));

        [d setAnswer: [NSNull null]];
        printf("%-44s %s\n", "delegate answers NSNull",
               tagOf([l actionForKey: @"position"]));

        [d setAnswer: nil];
        [l setActions: [NSDictionary dictionaryWithObject: marker(@"fromActions")
                                                   forKey: @"position"]];
        printf("%-44s %s\n", "delegate answers nil, actions has one",
               tagOf([l actionForKey: @"position"]));

        [d setAnswer: marker(@"fromDelegate")];
        printf("%-44s %s\n", "both, the delegate wins",
               tagOf([l actionForKey: @"position"]));
      }

      printf("\n=== the actions dictionary ===\n");
      {
        CALayer *l = [CALayer layer];

        [l setActions: [NSDictionary dictionaryWithObject: [NSNull null]
                                                   forKey: @"position"]];
        printf("%-44s %s\n", "actions holds NSNull",
               tagOf([l actionForKey: @"position"]));

        [l setActions: [NSDictionary dictionaryWithObject: marker(@"fromActions")
                                                   forKey: @"position"]];
        printf("%-44s %s\n", "actions holds an action",
               tagOf([l actionForKey: @"position"]));
        printf("%-44s %s\n", "and a key it does not hold",
               tagOf([l actionForKey: @"opacity"]));
      }

      printf("\n=== the style ===\n");
      {
        CALayer *l = [CALayer layer];
        NSDictionary *styleActions =
          [NSDictionary dictionaryWithObject: marker(@"fromStyle")
                                      forKey: @"position"];

        [l setStyle: [NSDictionary dictionaryWithObject: styleActions
                                                 forKey: @"actions"]];
        printf("%-44s %s\n", "style holds an action",
               tagOf([l actionForKey: @"position"]));

        [l setActions: [NSDictionary dictionaryWithObject: marker(@"fromActions")
                                                   forKey: @"position"]];
        printf("%-44s %s\n", "both, the actions dictionary wins",
               tagOf([l actionForKey: @"position"]));

        CALayer *n = [CALayer layer];
        NSDictionary *nullActions =
          [NSDictionary dictionaryWithObject: [NSNull null] forKey: @"position"];

        [n setStyle: [NSDictionary dictionaryWithObject: nullActions
                                                 forKey: @"actions"]];
        printf("%-44s %s\n", "style holds NSNull",
               tagOf([n actionForKey: @"position"]));
      }

      printf("\n=== does disabling actions change the lookup? ===\n");
      {
        CALayer *l = [CALayer layer];

        [l setActions: [NSDictionary dictionaryWithObject: marker(@"fromActions")
                                                   forKey: @"position"]];
        [CATransaction begin];
        [CATransaction setDisableActions: YES];
        printf("%-44s %s\n", "with actions disabled",
               tagOf([l actionForKey: @"position"]));
        [CATransaction commit];
        printf("%-44s %s\n", "and after the transaction",
               tagOf([l actionForKey: @"position"]));
      }

      printf("\n=== a style value that is not an actions dictionary ===\n");
      {
        CALayer *l = [CALayer layer];

        [l setStyle: [NSDictionary dictionaryWithObject: @"not a dictionary"
                                                 forKey: @"actions"]];
        @try
          {
            printf("%-44s %s\n", "style actions is a string",
                   tagOf([l actionForKey: @"position"]));
          }
        @catch (NSException *e)
          {
            printf("%-44s RAISED %s\n", "style actions is a string",
                   [[e name] UTF8String]);
          }
      }
    }
  return 0;
}

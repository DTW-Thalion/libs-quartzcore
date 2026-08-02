/* Can a Core Graphics valued layer property be reached by key on Apple?

   Run on a macOS runner:
     clang -framework QuartzCore -framework CoreGraphics -framework Foundation \
       Tests/oracle/qc_cgkvc_probe.m -o qc_cgkvc_probe
*/

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

static void tryKey(CALayer *l, NSString *key)
{
  @try
    {
      id v = [l valueForKey: key];

      printf("%-30s %s\n", [key UTF8String],
             v ? [[v description] UTF8String] : "(nil)");
    }
  @catch (NSException *e)
    {
      printf("%-30s RAISED %s\n", [key UTF8String], [[e name] UTF8String]);
    }
}

int main(int argc, char **argv)
{
  @autoreleasepool
    {
      CALayer *l = [CALayer layer];
      CGMutablePathRef path = CGPathCreateMutable();
      CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
      CGFloat comps[4] = {1.0, 0.0, 0.0, 1.0};
      CGColorRef red = CGColorCreate(cs, comps);

      CGPathAddRect(path, NULL, CGRectMake(0, 0, 10, 10));
      [l setShadowPath: path];
      [l setShadowColor: red];

      printf("=== reading a CG property by key ===\n");
      tryKey(l, @"shadowPath");
      tryKey(l, @"shadowColor");
      tryKey(l, @"backgroundColor");
      tryKey(l, @"borderColor");

      printf("\n=== the typed accessors, for comparison ===\n");
      printf("%-30s %s\n", "shadowPath == the path set",
             [l shadowPath] == path ? "YES" : "NO");
      printf("%-30s %s\n", "shadowColor == the colour set",
             [l shadowColor] == red ? "YES" : "NO");

      CGPathRelease(path);
      CGColorRelease(red);
      CGColorSpaceRelease(cs);
    }
  return 0;
}

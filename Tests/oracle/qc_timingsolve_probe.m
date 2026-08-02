/* What the named timing functions evaluate to, in particular at the ends of
 * the curve where the derivative of x(t) is zero. */

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@interface CAMediaTimingFunction (Solve)
- (float) _solveForInput: (float)x;
@end

static void show(NSString *label, CAMediaTimingFunction *f)
{
  float xs[] = {0.0, 0.1, 0.25, 0.5, 0.75, 0.9, 1.0};
  int i;

  if (f == nil)
    {
      printf("%-24s nil\n", [label UTF8String]);
      return;
    }
  if (![f respondsToSelector: @selector(_solveForInput:)])
    {
      printf("%-24s no _solveForInput:\n", [label UTF8String]);
      return;
    }
  printf("%-24s", [label UTF8String]);
  for (i = 0; i < 7; i++)
    {
      printf(" %9.6f", [f _solveForInput: xs[i]]);
    }
  printf("\n");
}

static void showName(NSString *name)
{
  show(name, [CAMediaTimingFunction functionWithName: name]);
}

int main(void)
{
  setbuf(stdout, NULL);

  @autoreleasepool
    {
      printf("%-24s %9s %9s %9s %9s %9s %9s %9s\n", "function",
             "x=0", "0.1", "0.25", "0.5", "0.75", "0.9", "x=1");
      showName(kCAMediaTimingFunctionLinear);
      showName(kCAMediaTimingFunctionEaseIn);
      showName(kCAMediaTimingFunctionEaseOut);
      showName(kCAMediaTimingFunctionEaseInEaseOut);
      showName(kCAMediaTimingFunctionDefault);

      show(@"custom 0,0,1,1",
           [CAMediaTimingFunction functionWithControlPoints: 0:0:1:1]);
      show(@"custom .5,0,.5,1",
           [CAMediaTimingFunction functionWithControlPoints: 0.5:0:0.5:1]);

      /* outside the unit interval */
      {
        CAMediaTimingFunction *f = [CAMediaTimingFunction functionWithName:
                                      kCAMediaTimingFunctionLinear];
        printf("linear at x=-0.5: %f\n", [f _solveForInput: -0.5]);
        printf("linear at x=1.5:  %f\n", [f _solveForInput: 1.5]);
      }
    }
  return 0;
}

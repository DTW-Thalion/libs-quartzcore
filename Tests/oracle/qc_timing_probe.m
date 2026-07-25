/* Apple oracle: CAMediaTimingFunction control points for the named
   functions and a custom function. */
#import <QuartzCore/QuartzCore.h>
#include <stdio.h>

static void dump(const char *label, CAMediaTimingFunction *f)
{
  float p[2];
  printf("%s:", label);
  for (size_t i = 0; i < 4; i++)
    {
      [f getControlPointAtIndex: i values: p];
      printf(" (%g,%g)", p[0], p[1]);
    }
  printf("\n");
}

int main(void)
{
  @autoreleasepool {
    setvbuf(stdout, NULL, _IONBF, 0);

    dump("Default",
      [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionDefault]);
    dump("Linear",
      [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionLinear]);
    dump("EaseIn",
      [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseIn]);
    dump("EaseOut",
      [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseOut]);
    dump("EaseInEaseOut",
      [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseInEaseOut]);
    dump("Custom(0.1,1.0,1.0,0.2)",
      [CAMediaTimingFunction functionWithControlPoints: 0.1 : 1.0 : 1.0 : 0.2]);
  }
  return 0;
}

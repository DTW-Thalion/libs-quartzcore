/* What CATransition's progress and filter properties do on Apple. */
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

int main(void)
{
  setbuf(stdout, NULL);
  @autoreleasepool
    {
      CATransition *t = [CATransition animation];

      printf("== what a transition starts with ==\n");
      printf("startProgress %g, endProgress %g\n",
             [t startProgress], [t endProgress]);
      printf("filter %s\n", [t filter] == nil ? "nil" : "something");

      printf("== what the setters keep ==\n");
      [t setStartProgress: 0.25];
      [t setEndProgress: 0.75];
      printf("after setting: %g to %g\n", [t startProgress], [t endProgress]);

      printf("== values outside nought to one ==\n");
      [t setStartProgress: -1.0];
      printf("start set to -1 reads %g\n", [t startProgress]);
      [t setEndProgress: 2.0];
      printf("end set to 2 reads %g\n", [t endProgress]);

      printf("== a start after the end ==\n");
      CATransition *crossed = [CATransition animation];

      [crossed setStartProgress: 0.8];
      [crossed setEndProgress: 0.2];
      printf("start %g, end %g\n",
             [crossed startProgress], [crossed endProgress]);

      printf("== the filter ==\n");
      CATransition *filtered = [CATransition animation];
      id thing = [NSNumber numberWithInt: 7];

      @try
        {
          [filtered setFilter: thing];
          printf("a plain object was accepted, reads back %s\n",
                 [filtered filter] == thing ? "the same object"
                   : ([filtered filter] == nil ? "nil" : "something else"));
        }
      @catch (NSException *e)
        {
          printf("setting a plain object raised %s\n", [[e name] UTF8String]);
        }

      printf("== is the transition still a fade ==\n");
      printf("type %s\n", [[t type] UTF8String]);
    }
  return 0;
}

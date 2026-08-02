/* The two scrollToRect: cases the first scroll probe did not cover. */
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

int main(void)
{
  setbuf(stdout, NULL);
  @autoreleasepool
    {
      CAScrollLayer *s = [CAScrollLayer layer];

      [s setBounds: CGRectMake(100, 100, 100, 100)];
      [s scrollToRect: CGRectMake(120, 120, 10, 10)];
      printf("already in view -> %g %g\n",
             (double)[s bounds].origin.x, (double)[s bounds].origin.y);

      [s setBounds: CGRectMake(100, 100, 100, 100)];
      [s scrollToRect: CGRectMake(20, 20, 10, 10)];
      printf("behind the view -> %g %g\n",
             (double)[s bounds].origin.x, (double)[s bounds].origin.y);

      [s setBounds: CGRectMake(0, 0, 100, 100)];
      [s scrollToRect: CGRectMake(20, 20, 400, 400)];
      printf("bigger than view -> %g %g\n",
             (double)[s bounds].origin.x, (double)[s bounds].origin.y);
    }
  return 0;
}

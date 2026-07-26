/* Apple oracle: the CATransform3D <-> CGAffineTransform bridge -
   CATransform3DMakeAffineTransform, CATransform3DIsAffine and
   CATransform3DGetAffineTransform. */
#import <QuartzCore/QuartzCore.h>
#include <stdio.h>

static void dump(const char *name, CATransform3D t)
{
  printf("%s: %g %g %g %g / %g %g %g %g / %g %g %g %g / %g %g %g %g\n",
    name,
    t.m11, t.m12, t.m13, t.m14, t.m21, t.m22, t.m23, t.m24,
    t.m31, t.m32, t.m33, t.m34, t.m41, t.m42, t.m43, t.m44);
}

int main(void)
{
  @autoreleasepool {
    setvbuf(stdout, NULL, _IONBF, 0);

    CGAffineTransform a = CGAffineTransformMake(2, 3, 4, 5, 6, 7);
    CATransform3D m = CATransform3DMakeAffineTransform(a);
    dump("MakeAffine(2,3,4,5,6,7)", m);

    printf("IsAffine(identity) = %d\n", CATransform3DIsAffine(CATransform3DIdentity));
    printf("IsAffine(fromAffine) = %d\n", CATransform3DIsAffine(m));
    printf("IsAffine(rotZ) = %d\n",
      CATransform3DIsAffine(CATransform3DMakeRotation(1, 0, 0, 1)));
    printf("IsAffine(rotX) = %d\n",
      CATransform3DIsAffine(CATransform3DMakeRotation(1, 1, 0, 0)));
    printf("IsAffine(scaleZ2) = %d\n",
      CATransform3DIsAffine(CATransform3DMakeScale(1, 1, 2)));
    printf("IsAffine(translateZ5) = %d\n",
      CATransform3DIsAffine(CATransform3DMakeTranslation(0, 0, 5)));

    CATransform3D pers = CATransform3DIdentity;
    pers.m34 = -1.0/500;
    printf("IsAffine(perspective m34) = %d\n", CATransform3DIsAffine(pers));

    CGAffineTransform back = CATransform3DGetAffineTransform(m);
    printf("GetAffine(fromAffine) = %g %g %g %g %g %g\n",
      back.a, back.b, back.c, back.d, back.tx, back.ty);

    /* GetAffine of a non-affine transform: which components come out. */
    CATransform3D rx = CATransform3DMakeRotation(1, 1, 0, 0);
    CGAffineTransform rxa = CATransform3DGetAffineTransform(rx);
    printf("GetAffine(rotX) = %g %g %g %g %g %g\n",
      rxa.a, rxa.b, rxa.c, rxa.d, rxa.tx, rxa.ty);
  }
  return 0;
}

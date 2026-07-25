/* Apple oracle: CATransform3D matrix layout, composition order, rotation,
   inversion and the identity/equality predicates. */
#import <QuartzCore/QuartzCore.h>
#include <stdio.h>

static void dump(const char *name, CATransform3D t)
{
  printf("%s:\n"
    "  %g %g %g %g\n  %g %g %g %g\n  %g %g %g %g\n  %g %g %g %g\n",
    name,
    t.m11, t.m12, t.m13, t.m14,
    t.m21, t.m22, t.m23, t.m24,
    t.m31, t.m32, t.m33, t.m34,
    t.m41, t.m42, t.m43, t.m44);
}

int main(void)
{
  @autoreleasepool {
    setvbuf(stdout, NULL, _IONBF, 0);

    dump("Identity", CATransform3DIdentity);
    dump("MakeTranslation(2,3,4)", CATransform3DMakeTranslation(2, 3, 4));
    dump("MakeScale(2,3,4)", CATransform3DMakeScale(2, 3, 4));
    dump("MakeRotation(pi/2, z)", CATransform3DMakeRotation(M_PI / 2, 0, 0, 1));
    dump("MakeRotation(pi/2, x)", CATransform3DMakeRotation(M_PI / 2, 1, 0, 0));

    CATransform3D tr = CATransform3DMakeTranslation(10, 0, 0);
    CATransform3D sc = CATransform3DMakeScale(2, 2, 2);
    dump("Concat(translate10,scale2)", CATransform3DConcat(tr, sc));
    dump("Concat(scale2,translate10)", CATransform3DConcat(sc, tr));
    dump("Translate(scale2, 10,0,0)", CATransform3DTranslate(sc, 10, 0, 0));
    dump("Scale(translate10, 2,2,2)", CATransform3DScale(tr, 2, 2, 2));
    dump("Invert(scale2)", CATransform3DInvert(sc));

    printf("IsIdentity(Identity)=%d IsIdentity(scale)=%d\n",
      CATransform3DIsIdentity(CATransform3DIdentity),
      CATransform3DIsIdentity(sc));
    printf("Equal(scale,scale)=%d Equal(scale,translate)=%d\n",
      CATransform3DEqualToTransform(sc, CATransform3DMakeScale(2, 2, 2)),
      CATransform3DEqualToTransform(sc, tr));

    CGAffineTransform aff = CGAffineTransformMakeScale(2, 3);
    dump("MakeAffineTransform(scale2,3)", CATransform3DMakeAffineTransform(aff));
    printf("IsAffine(MakeScale(2,3,1))=%d IsAffine(MakeScale(2,3,4))=%d\n",
      CATransform3DIsAffine(CATransform3DMakeScale(2, 3, 1)),
      CATransform3DIsAffine(CATransform3DMakeScale(2, 3, 4)));
    CGAffineTransform back =
      CATransform3DGetAffineTransform(CATransform3DMakeScale(2, 3, 1));
    printf("GetAffineTransform: a=%g b=%g c=%g d=%g tx=%g ty=%g\n",
      back.a, back.b, back.c, back.d, back.tx, back.ty);
  }
  return 0;
}

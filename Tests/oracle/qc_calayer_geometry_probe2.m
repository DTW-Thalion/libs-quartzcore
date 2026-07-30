/* Apple oracle, round 2: what -affineTransform does with a non-affine
   transform, the class default values for the geometry keys, KVC access, and
   the remaining edge cases. */
#import <QuartzCore/QuartzCore.h>
#include <stdio.h>
#include <math.h>

static void dumpRect(const char *name, CGRect r)
{
  printf("%s = %g %g %g %g\n", name, r.origin.x, r.origin.y,
         r.size.width, r.size.height);
}

static void dumpPoint(const char *name, CGPoint p)
{
  printf("%s = %g %g\n", name, p.x, p.y);
}

static void dumpAffine(const char *name, CGAffineTransform a)
{
  printf("%s = %g %g %g %g %g %g\n", name, a.a, a.b, a.c, a.d, a.tx, a.ty);
}

static void dump3D(const char *name, CATransform3D t)
{
  printf("%s = %g %g %g %g / %g %g %g %g / %g %g %g %g / %g %g %g %g\n",
    name,
    t.m11, t.m12, t.m13, t.m14, t.m21, t.m22, t.m23, t.m24,
    t.m31, t.m32, t.m33, t.m34, t.m41, t.m42, t.m43, t.m44);
}

static void affineOfNonAffine(void)
{
  printf("--- affineTransform vs the stored transform ---\n");

  struct { const char *name; CATransform3D t; } cases[] = {
    { "identity",     CATransform3DIdentity },
    { "scale231",     CATransform3DMakeScale(2, 3, 1) },
    { "scale234",     CATransform3DMakeScale(2, 3, 4) },
    { "rotZ45",       CATransform3DMakeRotation(M_PI / 4, 0, 0, 1) },
    { "rotX90",       CATransform3DMakeRotation(M_PI / 2, 1, 0, 0) },
    { "translateZ5",  CATransform3DMakeTranslation(0, 0, 5) },
    { "translateXY",  CATransform3DMakeTranslation(3, 4, 0) },
  };

  for (unsigned i = 0; i < sizeof(cases) / sizeof(cases[0]); i++)
    {
      CALayer *l = [CALayer layer];
      [l setTransform: cases[i].t];
      char buf[128];
      snprintf(buf, sizeof(buf), "%s.readBack", cases[i].name);
      dump3D(buf, [l transform]);
      snprintf(buf, sizeof(buf), "%s.isAffine", cases[i].name);
      printf("%s = %d\n", buf, CATransform3DIsAffine([l transform]));
      snprintf(buf, sizeof(buf), "%s.affineTransform", cases[i].name);
      dumpAffine(buf, [l affineTransform]);
    }

  CATransform3D pers = CATransform3DIdentity;
  pers.m34 = -1.0 / 500;
  CALayer *p = [CALayer layer];
  [p setTransform: pers];
  dump3D("perspective.readBack", [p transform]);
  dumpAffine("perspective.affineTransform", [p affineTransform]);

  /* setAffineTransform then read the 3D matrix back */
  CALayer *r = [CALayer layer];
  [r setAffineTransform: CGAffineTransformMakeRotation(M_PI / 4)];
  dump3D("setAffineRot45.transform", [r transform]);
  dumpAffine("setAffineRot45.affineTransform", [r affineTransform]);
}

static void classDefaults(void)
{
  printf("--- +defaultValueForKey: ---\n");
  const char *keys[] = { "bounds", "position", "anchorPoint", "anchorPointZ",
                         "zPosition", "frame", "transform", "sublayerTransform",
                         "masksToBounds", "contentsScale", "geometryFlipped",
                         "sublayers", "superlayer" };
  for (unsigned i = 0; i < sizeof(keys) / sizeof(keys[0]); i++)
    {
      NSString *k = [NSString stringWithUTF8String: keys[i]];
      id v = [CALayer defaultValueForKey: k];
      printf("defaultValueForKey.%s = %s\n", keys[i],
             v ? [[v description] UTF8String] : "nil");
    }
}

static void kvc(void)
{
  printf("--- KVC ---\n");
  CALayer *l = [CALayer layer];
  [l setBounds: CGRectMake(0, 0, 100, 50)];
  [l setPosition: CGPointMake(200, 300)];

  id b = [l valueForKey: @"bounds"];
  printf("kvc.bounds.class = %s\n", [NSStringFromClass([b class]) UTF8String]);
  printf("kvc.bounds = %s\n", [[b description] UTF8String]);
  id f = [l valueForKey: @"frame"];
  printf("kvc.frame = %s\n", f ? [[f description] UTF8String] : "nil");
  id ap = [l valueForKey: @"anchorPoint"];
  printf("kvc.anchorPoint = %s\n", [[ap description] UTF8String]);
  id z = [l valueForKey: @"zPosition"];
  printf("kvc.zPosition = %s\n", [[z description] UTF8String]);
  id apz = [l valueForKey: @"anchorPointZ"];
  printf("kvc.anchorPointZ = %s\n", apz ? [[apz description] UTF8String] : "nil");

  CALayer *s = [CALayer layer];
  [s setValue: [NSValue valueWithRect: NSMakeRect(1, 2, 3, 4)]
       forKey: @"bounds"];
  dumpRect("kvc.setBounds", [s bounds]);
  [s setValue: [NSNumber numberWithDouble: 9] forKey: @"zPosition"];
  printf("kvc.setZPosition = %g\n", (double)[s zPosition]);
}

static void edges(void)
{
  printf("--- edge cases ---\n");

  CALayer *z = [CALayer layer];
  [z setPosition: CGPointMake(10, 20)];
  dumpRect("zeroBounds.frame", [z frame]);

  CALayer *zf = [CALayer layer];
  [zf setFrame: CGRectMake(10, 20, 0, 0)];
  dumpRect("zeroFrame.bounds", [zf bounds]);
  dumpPoint("zeroFrame.position", [zf position]);

  CALayer *nb = [CALayer layer];
  [nb setBounds: CGRectMake(0, 0, -100, -50)];
  dumpRect("negativeBounds.readBack", [nb bounds]);
  dumpRect("negativeBounds.frame", [nb frame]);

  /* order independence: transform set before vs after bounds/position */
  CALayer *before = [CALayer layer];
  [before setTransform: CATransform3DMakeScale(2, 4, 1)];
  [before setBounds: CGRectMake(0, 0, 100, 50)];
  [before setPosition: CGPointMake(200, 300)];
  dumpRect("transformFirst.frame", [before frame]);

  /* geometryFlipped must not change the frame of a detached layer */
  CALayer *g = [CALayer layer];
  [g setBounds: CGRectMake(0, 0, 100, 50)];
  [g setPosition: CGPointMake(200, 300)];
  [g setGeometryFlipped: YES];
  printf("geometryFlipped.readBack = %d\n", (int)[g isGeometryFlipped]);
  dumpRect("geometryFlipped.frame", [g frame]);

  /* contentsScale must not change the frame */
  CALayer *cs = [CALayer layer];
  [cs setBounds: CGRectMake(0, 0, 100, 50)];
  [cs setPosition: CGPointMake(200, 300)];
  [cs setContentsScale: 2];
  dumpRect("contentsScale2.frame", [cs frame]);

  /* setBounds must not disturb the anchor point */
  CALayer *a = [CALayer layer];
  [a setAnchorPoint: CGPointMake(0.25, 0.75)];
  [a setBounds: CGRectMake(0, 0, 100, 50)];
  dumpPoint("setBoundsKeepsAnchor", [a anchorPoint]);

  /* frame under a rotation, then setFrame back to that same rect */
  CALayer *r = [CALayer layer];
  [r setBounds: CGRectMake(0, 0, 100, 100)];
  [r setPosition: CGPointMake(0, 0)];
  [r setTransform: CATransform3DMakeRotation(M_PI / 4, 0, 0, 1)];
  CGRect rf = [r frame];
  [r setFrame: rf];
  dumpRect("rotSetFrameSame.bounds", [r bounds]);
  dumpPoint("rotSetFrameSame.position", [r position]);
  dumpRect("rotSetFrameSame.frame", [r frame]);
}

static void moreConversions(void)
{
  printf("--- more conversions ---\n");

  CALayer *parent = [CALayer layer];
  [parent setBounds: CGRectMake(0, 0, 200, 200)];
  [parent setPosition: CGPointMake(100, 100)];

  /* a rotated child: convertRect must return a bounding box */
  CALayer *rc = [CALayer layer];
  [rc setBounds: CGRectMake(0, 0, 100, 100)];
  [rc setPosition: CGPointMake(100, 100)];
  [rc setTransform: CATransform3DMakeRotation(M_PI / 4, 0, 0, 1)];
  [parent addSublayer: rc];
  dumpRect("rotatedChild.rect.toParent",
           [rc convertRect: CGRectMake(0, 0, 100, 100) toLayer: parent]);
  dumpPoint("rotatedChild.center.toParent",
            [rc convertPoint: CGPointMake(50, 50) toLayer: parent]);

  /* child transform and parent sublayerTransform together */
  CALayer *sp = [CALayer layer];
  [sp setBounds: CGRectMake(0, 0, 200, 200)];
  [sp setPosition: CGPointMake(100, 100)];
  [sp setSublayerTransform: CATransform3DMakeScale(2, 2, 1)];
  CALayer *sc = [CALayer layer];
  [sc setBounds: CGRectMake(0, 0, 50, 50)];
  [sc setPosition: CGPointMake(100, 50)];
  [sc setTransform: CATransform3DMakeTranslation(5, 6, 0)];
  [sp addSublayer: sc];
  dumpPoint("bothTransforms.child00.toParent",
            [sc convertPoint: CGPointMake(0, 0) toLayer: sp]);

  /* removing a sublayer detaches it */
  CALayer *d = [CALayer layer];
  [d setBounds: CGRectMake(0, 0, 50, 50)];
  [d setPosition: CGPointMake(100, 50)];
  [parent addSublayer: d];
  dumpPoint("attached.00.toParent",
            [d convertPoint: CGPointMake(0, 0) toLayer: parent]);
  [d removeFromSuperlayer];
  printf("detached.superlayer = %s\n", [d superlayer] ? "non-nil" : "nil");
  dumpPoint("detachedFromParent.00.toParent",
            [d convertPoint: CGPointMake(0, 0) toLayer: parent]);
}

int main(void)
{
  @autoreleasepool {
    setvbuf(stdout, NULL, _IONBF, 0);
    affineOfNonAffine();
    classDefaults();
    kvc();
    edges();
    moreConversions();
  }
  return 0;
}

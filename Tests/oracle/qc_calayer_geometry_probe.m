/* Apple oracle: CALayer geometry - frame/bounds/position/anchorPoint,
   anchorPointZ, zPosition, affineTransform and the convertPoint/convertRect
   layer-space conversions. */
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

static void defaults(void)
{
  CALayer *l = [CALayer layer];
  printf("--- defaults ---\n");
  dumpRect("default.bounds", [l bounds]);
  dumpRect("default.frame", [l frame]);
  dumpPoint("default.position", [l position]);
  dumpPoint("default.anchorPoint", [l anchorPoint]);
  printf("default.anchorPointZ = %g\n", (double)[l anchorPointZ]);
  printf("default.zPosition = %g\n", (double)[l zPosition]);
  printf("default.masksToBounds = %d\n", (int)[l masksToBounds]);
  printf("default.geometryFlipped = %d\n", (int)[l isGeometryFlipped]);
  printf("default.contentsScale = %g\n", (double)[l contentsScale]);
  dump3D("default.transform", [l transform]);
  dump3D("default.sublayerTransform", [l sublayerTransform]);
  dumpAffine("default.affineTransform", [l affineTransform]);
  printf("default.superlayer = %s\n", [l superlayer] ? "non-nil" : "nil");
  printf("default.sublayers = %s\n", [l sublayers] ? "non-nil" : "nil");
}

static void frameFromBoundsPosition(void)
{
  printf("--- frame derived from bounds/position/anchorPoint ---\n");

  CALayer *l = [CALayer layer];
  [l setBounds: CGRectMake(0, 0, 100, 50)];
  [l setPosition: CGPointMake(200, 300)];
  dumpRect("anchor.5.5.frame", [l frame]);
  dumpPoint("anchor.5.5.position", [l position]);

  [l setAnchorPoint: CGPointMake(0, 0)];
  dumpRect("anchor00.frame", [l frame]);
  dumpPoint("anchor00.position", [l position]);
  dumpRect("anchor00.bounds", [l bounds]);

  [l setAnchorPoint: CGPointMake(1, 1)];
  dumpRect("anchor11.frame", [l frame]);
  dumpPoint("anchor11.position", [l position]);

  [l setAnchorPoint: CGPointMake(0.25, 0.75)];
  dumpRect("anchor2575.frame", [l frame]);

  /* bounds origin must not move the frame */
  CALayer *o = [CALayer layer];
  [o setBounds: CGRectMake(11, 22, 100, 50)];
  [o setPosition: CGPointMake(200, 300)];
  dumpRect("boundsOrigin.frame", [o frame]);
  dumpRect("boundsOrigin.bounds", [o bounds]);

  /* setting bounds must not move the position */
  CALayer *b = [CALayer layer];
  [b setPosition: CGPointMake(7, 9)];
  [b setBounds: CGRectMake(0, 0, 30, 40)];
  dumpPoint("setBoundsKeepsPosition.position", [b position]);
  dumpRect("setBoundsKeepsPosition.frame", [b frame]);

  /* an odd size with the default anchor point */
  CALayer *odd = [CALayer layer];
  [odd setBounds: CGRectMake(0, 0, 15, 25)];
  [odd setPosition: CGPointMake(0, 0)];
  dumpRect("oddSize.frame", [odd frame]);
}

static void setFrame(void)
{
  printf("--- setFrame ---\n");

  CALayer *l = [CALayer layer];
  [l setFrame: CGRectMake(10, 20, 100, 50)];
  dumpRect("setFrame.bounds", [l bounds]);
  dumpPoint("setFrame.position", [l position]);
  dumpPoint("setFrame.anchorPoint", [l anchorPoint]);
  dumpRect("setFrame.frame", [l frame]);

  CALayer *a = [CALayer layer];
  [a setAnchorPoint: CGPointMake(0, 0)];
  [a setFrame: CGRectMake(10, 20, 100, 50)];
  dumpRect("setFrameAnchor00.bounds", [a bounds]);
  dumpPoint("setFrameAnchor00.position", [a position]);

  CALayer *c = [CALayer layer];
  [c setAnchorPoint: CGPointMake(1, 1)];
  [c setFrame: CGRectMake(10, 20, 100, 50)];
  dumpRect("setFrameAnchor11.bounds", [c bounds]);
  dumpPoint("setFrameAnchor11.position", [c position]);

  /* does setFrame keep a non-zero bounds origin */
  CALayer *o = [CALayer layer];
  [o setBounds: CGRectMake(11, 22, 5, 5)];
  [o setFrame: CGRectMake(10, 20, 100, 50)];
  dumpRect("setFrameKeepsBoundsOrigin.bounds", [o bounds]);
  dumpPoint("setFrameKeepsBoundsOrigin.position", [o position]);

  /* a negative size */
  CALayer *n = [CALayer layer];
  [n setFrame: CGRectMake(0, 0, -100, -50)];
  dumpRect("setFrameNegative.bounds", [n bounds]);
  dumpPoint("setFrameNegative.position", [n position]);
  dumpRect("setFrameNegative.frame", [n frame]);

  /* frame round trips */
  CALayer *r = [CALayer layer];
  [r setFrame: CGRectMake(3, 7, 11, 13)];
  dumpRect("frameRoundTrip", [r frame]);
}

static void frameWithTransform(void)
{
  printf("--- frame with a transform ---\n");

  CALayer *s = [CALayer layer];
  [s setBounds: CGRectMake(0, 0, 100, 50)];
  [s setPosition: CGPointMake(200, 300)];
  [s setTransform: CATransform3DMakeScale(2, 4, 1)];
  dumpRect("scale24.frame", [s frame]);

  CALayer *t = [CALayer layer];
  [t setBounds: CGRectMake(0, 0, 100, 50)];
  [t setPosition: CGPointMake(200, 300)];
  [t setTransform: CATransform3DMakeTranslation(10, 20, 0)];
  dumpRect("translate1020.frame", [t frame]);

  CALayer *r = [CALayer layer];
  [r setBounds: CGRectMake(0, 0, 100, 100)];
  [r setPosition: CGPointMake(0, 0)];
  [r setTransform: CATransform3DMakeRotation(M_PI / 4, 0, 0, 1)];
  dumpRect("rot45.frame", [r frame]);

  /* setFrame while a scale transform is in force */
  CALayer *sf = [CALayer layer];
  [sf setTransform: CATransform3DMakeScale(2, 4, 1)];
  [sf setFrame: CGRectMake(10, 20, 100, 50)];
  dumpRect("setFrameUnderScale.bounds", [sf bounds]);
  dumpPoint("setFrameUnderScale.position", [sf position]);
  dumpRect("setFrameUnderScale.frame", [sf frame]);

  /* setFrame while a translation transform is in force */
  CALayer *tf = [CALayer layer];
  [tf setTransform: CATransform3DMakeTranslation(10, 20, 0)];
  [tf setFrame: CGRectMake(10, 20, 100, 50)];
  dumpRect("setFrameUnderTranslate.bounds", [tf bounds]);
  dumpPoint("setFrameUnderTranslate.position", [tf position]);
}

static void affine(void)
{
  printf("--- affineTransform ---\n");

  CALayer *l = [CALayer layer];
  [l setAffineTransform: CGAffineTransformMake(2, 3, 4, 5, 6, 7)];
  dump3D("setAffine.transform", [l transform]);
  dumpAffine("setAffine.affineTransform", [l affineTransform]);

  CALayer *s = [CALayer layer];
  [s setTransform: CATransform3DMakeScale(2, 3, 4)];
  dumpAffine("scale234.affineTransform", [s affineTransform]);

  CALayer *r = [CALayer layer];
  [r setTransform: CATransform3DMakeRotation(M_PI / 2, 1, 0, 0)];
  dumpAffine("rotX90.affineTransform", [r affineTransform]);

  /* setAffineTransform must replace, not concatenate */
  CALayer *c = [CALayer layer];
  [c setTransform: CATransform3DMakeScale(9, 9, 9)];
  [c setAffineTransform: CGAffineTransformMakeTranslation(5, 6)];
  dump3D("setAffineReplaces.transform", [c transform]);
}

static void conversions(void)
{
  printf("--- convertPoint / convertRect ---\n");

  CALayer *parent = [CALayer layer];
  [parent setBounds: CGRectMake(0, 0, 200, 200)];
  [parent setPosition: CGPointMake(100, 100)];

  CALayer *child = [CALayer layer];
  [child setBounds: CGRectMake(0, 0, 50, 50)];
  [child setPosition: CGPointMake(100, 50)];
  [parent addSublayer: child];

  dumpPoint("child00.toParent",
            [child convertPoint: CGPointMake(0, 0) toLayer: parent]);
  dumpPoint("child5050.toParent",
            [child convertPoint: CGPointMake(50, 50) toLayer: parent]);
  dumpPoint("parent00.toChild",
            [parent convertPoint: CGPointMake(0, 0) toLayer: child]);
  dumpPoint("child.fromParent00",
            [child convertPoint: CGPointMake(0, 0) fromLayer: parent]);
  dumpPoint("parent.fromChild00",
            [parent convertPoint: CGPointMake(0, 0) fromLayer: child]);

  dumpRect("childRect.toParent",
           [child convertRect: CGRectMake(0, 0, 10, 20) toLayer: parent]);
  dumpRect("parentRect.toChild",
           [parent convertRect: CGRectMake(0, 0, 10, 20) toLayer: child]);

  /* conversion to self */
  dumpPoint("child.toSelf",
            [child convertPoint: CGPointMake(3, 4) toLayer: child]);
  dumpRect("child.rectToSelf",
           [child convertRect: CGRectMake(3, 4, 5, 6) toLayer: child]);

  /* a non-zero bounds origin on the parent shifts its children */
  CALayer *op = [CALayer layer];
  [op setBounds: CGRectMake(10, 20, 200, 200)];
  [op setPosition: CGPointMake(100, 100)];
  CALayer *oc = [CALayer layer];
  [oc setBounds: CGRectMake(0, 0, 50, 50)];
  [oc setPosition: CGPointMake(100, 50)];
  [op addSublayer: oc];
  dumpPoint("boundsOriginParent.child00.toParent",
            [oc convertPoint: CGPointMake(0, 0) toLayer: op]);

  /* the child's own transform */
  CALayer *tp = [CALayer layer];
  [tp setBounds: CGRectMake(0, 0, 200, 200)];
  [tp setPosition: CGPointMake(100, 100)];
  CALayer *tc = [CALayer layer];
  [tc setBounds: CGRectMake(0, 0, 50, 50)];
  [tc setPosition: CGPointMake(100, 50)];
  [tc setTransform: CATransform3DMakeScale(2, 2, 1)];
  [tp addSublayer: tc];
  dumpPoint("childScaled.00.toParent",
            [tc convertPoint: CGPointMake(0, 0) toLayer: tp]);
  dumpPoint("childScaled.5050.toParent",
            [tc convertPoint: CGPointMake(50, 50) toLayer: tp]);
  dumpRect("childScaled.rect.toParent",
           [tc convertRect: CGRectMake(0, 0, 10, 20) toLayer: tp]);

  /* the parent's sublayerTransform */
  CALayer *sp = [CALayer layer];
  [sp setBounds: CGRectMake(0, 0, 200, 200)];
  [sp setPosition: CGPointMake(100, 100)];
  [sp setSublayerTransform: CATransform3DMakeTranslation(10, 20, 0)];
  CALayer *sc = [CALayer layer];
  [sc setBounds: CGRectMake(0, 0, 50, 50)];
  [sc setPosition: CGPointMake(100, 50)];
  [sp addSublayer: sc];
  dumpPoint("sublayerTransform.child00.toParent",
            [sc convertPoint: CGPointMake(0, 0) toLayer: sp]);

  /* two generations */
  CALayer *g0 = [CALayer layer];
  [g0 setBounds: CGRectMake(0, 0, 400, 400)];
  [g0 setPosition: CGPointMake(200, 200)];
  CALayer *g1 = [CALayer layer];
  [g1 setBounds: CGRectMake(0, 0, 200, 200)];
  [g1 setPosition: CGPointMake(100, 100)];
  CALayer *g2 = [CALayer layer];
  [g2 setBounds: CGRectMake(0, 0, 50, 50)];
  [g2 setPosition: CGPointMake(25, 25)];
  [g0 addSublayer: g1];
  [g1 addSublayer: g2];
  dumpPoint("grandchild00.toRoot",
            [g2 convertPoint: CGPointMake(0, 0) toLayer: g0]);
  dumpPoint("root00.toGrandchild",
            [g0 convertPoint: CGPointMake(0, 0) toLayer: g2]);

  /* siblings */
  CALayer *s1 = [CALayer layer];
  [s1 setBounds: CGRectMake(0, 0, 50, 50)];
  [s1 setPosition: CGPointMake(25, 25)];
  CALayer *s2 = [CALayer layer];
  [s2 setBounds: CGRectMake(0, 0, 50, 50)];
  [s2 setPosition: CGPointMake(125, 25)];
  [parent addSublayer: s1];
  [parent addSublayer: s2];
  dumpPoint("sibling00.toSibling",
            [s1 convertPoint: CGPointMake(0, 0) toLayer: s2]);

  /* unrelated layers - no common ancestor */
  CALayer *u1 = [CALayer layer];
  [u1 setBounds: CGRectMake(0, 0, 50, 50)];
  [u1 setPosition: CGPointMake(25, 25)];
  CALayer *u2 = [CALayer layer];
  [u2 setBounds: CGRectMake(0, 0, 50, 50)];
  [u2 setPosition: CGPointMake(500, 500)];
  dumpPoint("unrelated00.to",
            [u1 convertPoint: CGPointMake(0, 0) toLayer: u2]);

}

/* Run last: a nil layer argument is undocumented and may abort. */
static void nilLayerArgument(void)
{
  printf("--- nil layer argument ---\n");
  CALayer *parent = [CALayer layer];
  [parent setBounds: CGRectMake(0, 0, 200, 200)];
  [parent setPosition: CGPointMake(100, 100)];
  CALayer *child = [CALayer layer];
  [child setBounds: CGRectMake(0, 0, 50, 50)];
  [child setPosition: CGPointMake(100, 50)];
  [parent addSublayer: child];

  dumpPoint("child00.toNil",
            [child convertPoint: CGPointMake(0, 0) toLayer: nil]);
  dumpPoint("child00.fromNil",
            [child convertPoint: CGPointMake(0, 0) fromLayer: nil]);
  dumpRect("childRect.toNil",
           [child convertRect: CGRectMake(0, 0, 10, 20) toLayer: nil]);
}

static void anchorPointZAndZPosition(void)
{
  printf("--- anchorPointZ / zPosition ---\n");

  CALayer *l = [CALayer layer];
  [l setBounds: CGRectMake(0, 0, 100, 50)];
  [l setPosition: CGPointMake(200, 300)];
  [l setAnchorPointZ: 25];
  printf("anchorPointZ.readBack = %g\n", (double)[l anchorPointZ]);
  dumpRect("anchorPointZ.frame", [l frame]);

  [l setZPosition: 17];
  printf("zPosition.readBack = %g\n", (double)[l zPosition]);
  dumpRect("zPosition.frame", [l frame]);

  /* anchorPoint outside the unit square is accepted */
  CALayer *o = [CALayer layer];
  [o setBounds: CGRectMake(0, 0, 100, 50)];
  [o setPosition: CGPointMake(0, 0)];
  [o setAnchorPoint: CGPointMake(2, -1)];
  dumpPoint("anchorOutside.readBack", [o anchorPoint]);
  dumpRect("anchorOutside.frame", [o frame]);
}

static void modelPresentation(void)
{
  printf("--- presentation / model layer geometry ---\n");
  CALayer *l = [CALayer layer];
  [l setBounds: CGRectMake(0, 0, 100, 50)];
  [l setPosition: CGPointMake(200, 300)];
  printf("detached.presentationLayer = %s\n",
         [l presentationLayer] ? "non-nil" : "nil");
  printf("detached.modelLayer = %s\n",
         [l modelLayer] == l ? "self" : ([l modelLayer] ? "other" : "nil"));

  CALayer *copy = [[CALayer alloc] initWithLayer: l];
  dumpRect("initWithLayer.bounds", [copy bounds]);
  dumpPoint("initWithLayer.position", [copy position]);
  dumpRect("initWithLayer.frame", [copy frame]);
  [copy release];
}

int main(void)
{
  @autoreleasepool {
    setvbuf(stdout, NULL, _IONBF, 0);
    defaults();
    frameFromBoundsPosition();
    setFrame();
    frameWithTransform();
    affine();
    conversions();
    anchorPointZAndZPosition();
    modelPresentation();
    nilLayerArgument();
  }
  return 0;
}

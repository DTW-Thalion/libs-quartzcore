/* Defaults and constants of CAEmitterLayer and CAEmitterCell.

   Run on a macOS runner:
     clang -framework QuartzCore -framework CoreGraphics -framework Foundation \
       Tests/oracle/qc_emitter_probe.m -o qc_emitter_probe
*/

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

static void f(const char *what, double v)
{
  printf("%-34s %g\n", what, v);
}

static void s(const char *what, NSString *v)
{
  printf("%-34s %s\n", what, v ? [[v description] UTF8String] : "(nil)");
}

static void o(const char *what, id v)
{
  printf("%-34s %s\n", what, v ? [[v description] UTF8String] : "(nil)");
}

int main(int argc, char **argv)
{
  @autoreleasepool
    {
      CAEmitterLayer *l = [CAEmitterLayer layer];
      CAEmitterCell *c = [CAEmitterCell emitterCell];

      printf("--- the classes ---\n");
      s("CAEmitterLayer superclass", NSStringFromClass([CAEmitterLayer superclass]));
      s("CAEmitterCell superclass", NSStringFromClass([CAEmitterCell superclass]));
      printf("%-34s %d\n", "a cell is not a layer",
             [c isKindOfClass: [CALayer class]] == NO);
      printf("%-34s %d\n", "cell conforms to CAMediaTiming",
             [c conformsToProtocol: @protocol(CAMediaTiming)]);
      printf("%-34s %d\n", "cell conforms to NSCoding",
             [c conformsToProtocol: @protocol(NSCoding)]);
      printf("%-34s %d\n", "cell conforms to NSCopying",
             [c conformsToProtocol: @protocol(NSCopying)]);

      printf("\n--- CAEmitterLayer defaults ---\n");
      o("emitterCells", [l emitterCells]);
      printf("%-34s %g %g\n", "emitterPosition",
             (double)[l emitterPosition].x, (double)[l emitterPosition].y);
      f("emitterZPosition", [l emitterZPosition]);
      printf("%-34s %g %g\n", "emitterSize",
             (double)[l emitterSize].width, (double)[l emitterSize].height);
      f("emitterDepth", [l emitterDepth]);
      s("emitterShape", [l emitterShape]);
      s("emitterMode", [l emitterMode]);
      s("renderMode", [l renderMode]);
      f("scale", [l scale]);
      f("seed", (double)[l seed]);
      f("spin", [l spin]);
      f("velocity", [l velocity]);
      f("birthRate", [l birthRate]);
      f("lifetime", [l lifetime]);
      f("preservesDepth", [l preservesDepth]);

      printf("\n--- a second layer, is the seed the same? ---\n");
      f("seed of another layer", (double)[[CAEmitterLayer layer] seed]);

      printf("\n--- CAEmitterCell defaults ---\n");
      o("contents", [c contents]);
      printf("%-34s %g %g %g %g\n", "contentsRect",
             (double)[c contentsRect].origin.x, (double)[c contentsRect].origin.y,
             (double)[c contentsRect].size.width, (double)[c contentsRect].size.height);
      f("contentsScale", [c contentsScale]);
      o("emitterCells", [c emitterCells]);
      f("enabled", [c isEnabled]);
      printf("%-34s %s\n", "color", [c color] ? "not null" : "null");
      if ([c color] != NULL)
        {
          const CGFloat *comp = CGColorGetComponents([c color]);
          size_t n = CGColorGetNumberOfComponents([c color]);

          printf("%-34s %lu components:", "color components", (unsigned long)n);
          for (size_t i = 0; i < n; i++)
            printf(" %g", (double)comp[i]);
          printf("\n");
        }
      f("redRange", [c redRange]);
      f("greenRange", [c greenRange]);
      f("blueRange", [c blueRange]);
      f("alphaRange", [c alphaRange]);
      f("redSpeed", [c redSpeed]);
      f("greenSpeed", [c greenSpeed]);
      f("blueSpeed", [c blueSpeed]);
      f("alphaSpeed", [c alphaSpeed]);
      s("magnificationFilter", [c magnificationFilter]);
      s("minificationFilter", [c minificationFilter]);
      f("minificationFilterBias", [c minificationFilterBias]);
      f("scale", [c scale]);
      f("scaleRange", [c scaleRange]);
      f("scaleSpeed", [c scaleSpeed]);
      s("name", [c name]);
      o("style", [c style]);
      f("spin", [c spin]);
      f("spinRange", [c spinRange]);
      f("emissionLatitude", [c emissionLatitude]);
      f("emissionLongitude", [c emissionLongitude]);
      f("emissionRange", [c emissionRange]);
      f("lifetime", [c lifetime]);
      f("lifetimeRange", [c lifetimeRange]);
      f("birthRate", [c birthRate]);
      f("velocity", [c velocity]);
      f("velocityRange", [c velocityRange]);
      f("xAcceleration", [c xAcceleration]);
      f("yAcceleration", [c yAcceleration]);
      f("zAcceleration", [c zAcceleration]);

      printf("\n--- the constants ---\n");
      s("kCAEmitterLayerPoint", kCAEmitterLayerPoint);
      s("kCAEmitterLayerLine", kCAEmitterLayerLine);
      s("kCAEmitterLayerRectangle", kCAEmitterLayerRectangle);
      s("kCAEmitterLayerCuboid", kCAEmitterLayerCuboid);
      s("kCAEmitterLayerCircle", kCAEmitterLayerCircle);
      s("kCAEmitterLayerSphere", kCAEmitterLayerSphere);
      s("kCAEmitterLayerPoints", kCAEmitterLayerPoints);
      s("kCAEmitterLayerOutline", kCAEmitterLayerOutline);
      s("kCAEmitterLayerSurface", kCAEmitterLayerSurface);
      s("kCAEmitterLayerVolume", kCAEmitterLayerVolume);
      s("kCAEmitterLayerUnordered", kCAEmitterLayerUnordered);
      s("kCAEmitterLayerOldestFirst", kCAEmitterLayerOldestFirst);
      s("kCAEmitterLayerOldestLast", kCAEmitterLayerOldestLast);
      s("kCAEmitterLayerBackToFront", kCAEmitterLayerBackToFront);
      s("kCAEmitterLayerAdditive", kCAEmitterLayerAdditive);

      printf("\n--- what a cell answers for defaultValueForKey: ---\n");
      o("+defaultValueForKey: birthRate", [CAEmitterCell defaultValueForKey: @"birthRate"]);
      o("+defaultValueForKey: lifetime", [CAEmitterCell defaultValueForKey: @"lifetime"]);
      o("+defaultValueForKey: enabled", [CAEmitterCell defaultValueForKey: @"enabled"]);
      o("+defaultValueForKey: scale", [CAEmitterCell defaultValueForKey: @"scale"]);
      o("+defaultValueForKey: bogus", [CAEmitterCell defaultValueForKey: @"bogus"]);
      printf("%-34s %d\n", "cell shouldArchiveValueForKey: name",
             [c shouldArchiveValueForKey: @"name"]);

      printf("\n--- and what the layer answers ---\n");
      o("+defaultValueForKey: birthRate", [CAEmitterLayer defaultValueForKey: @"birthRate"]);
      o("+defaultValueForKey: emitterShape", [CAEmitterLayer defaultValueForKey: @"emitterShape"]);
      o("+defaultValueForKey: scale", [CAEmitterLayer defaultValueForKey: @"scale"]);

      printf("\n--- setting a cell on a layer ---\n");
      [l setEmitterCells: [NSArray arrayWithObject: c]];
      printf("%-34s %lu\n", "emitterCells count",
             (unsigned long)[[l emitterCells] count]);
      printf("%-34s %d\n", "the same cell object",
             [[l emitterCells] objectAtIndex: 0] == c);
      {
        NSMutableArray *m = [NSMutableArray arrayWithObject: [CAEmitterCell emitterCell]];

        [l setEmitterCells: m];
        [m removeAllObjects];
        printf("%-34s %lu\n", "count after emptying the array",
               (unsigned long)[[l emitterCells] count]);
      }
    }
  return 0;
}

/* Defaults for the CALayer subclasses this framework does not have yet. */

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

static void present(const char *name)
{
  Class c = NSClassFromString([NSString stringWithUTF8String: name]);

  printf("%-20s %s\n", name, c ? "present" : "ABSENT");
}

int main(void)
{
  setbuf(stdout, NULL);

  @autoreleasepool
    {
      printf("== which classes exist ==\n");
      present("CAGradientLayer");
      present("CAScrollLayer");
      present("CATextLayer");
      present("CATiledLayer");
      present("CAReplicatorLayer");
      present("CATransformLayer");
      present("CAOpenGLLayer");
      present("CAEAGLLayer");
      present("CADisplayLink");

      printf("\n== CAGradientLayer ==\n");
      {
        CAGradientLayer *g = [CAGradientLayer layer];

        printf("colors           %s\n",
               [g colors] ? [[[g colors] description] UTF8String] : "(nil)");
        printf("locations        %s\n",
               [g locations] ? [[[g locations] description] UTF8String]
                             : "(nil)");
        printf("startPoint       %g %g\n", [g startPoint].x, [g startPoint].y);
        printf("endPoint         %g %g\n", [g endPoint].x, [g endPoint].y);
        printf("type             %s\n",
               [g type] ? [[g type] UTF8String] : "(nil)");
        printf("type constants   axial=%s radial=%s conic=%s\n",
               [kCAGradientLayerAxial UTF8String],
               [kCAGradientLayerRadial UTF8String],
               [kCAGradientLayerConic UTF8String]);

        /* what the setters keep */
        NSArray *locs = [NSArray arrayWithObjects:
          [NSNumber numberWithFloat: 0.0],
          [NSNumber numberWithFloat: 1.0], nil];
        [g setLocations: locs];
        printf("locations kept   %s (same object %d)\n",
               [[[g locations] description] UTF8String],
               (int)([g locations] == locs));

        [g setStartPoint: CGPointMake(0.25, 0.75)];
        printf("startPoint kept  %g %g\n", [g startPoint].x, [g startPoint].y);

        [g setType: kCAGradientLayerRadial];
        printf("type kept        %s\n", [[g type] UTF8String]);

        [g setType: @"notAGradientType"];
        printf("bogus type kept  %s\n",
               [g type] ? [[g type] UTF8String] : "(nil)");

        printf("needsDisplayForKey colors=%d locations=%d startPoint=%d\n",
               (int)[CAGradientLayer needsDisplayForKey: @"colors"],
               (int)[CAGradientLayer needsDisplayForKey: @"locations"],
               (int)[CAGradientLayer needsDisplayForKey: @"startPoint"]);
        printf("is a CALayer     %d\n",
               (int)[g isKindOfClass: [CALayer class]]);
      }

      printf("\n== CAScrollLayer ==\n");
      {
        CAScrollLayer *s = [CAScrollLayer layer];

        printf("scrollMode       %s\n",
               [s scrollMode] ? [[s scrollMode] UTF8String] : "(nil)");
        printf("mode constants   none=%s v=%s h=%s both=%s\n",
               [kCAScrollNone UTF8String], [kCAScrollVertically UTF8String],
               [kCAScrollHorizontally UTF8String], [kCAScrollBoth UTF8String]);
        printf("visibleRect      %g %g %g %g\n",
               [s visibleRect].origin.x, [s visibleRect].origin.y,
               [s visibleRect].size.width, [s visibleRect].size.height);
      }

      printf("\n== CATextLayer ==\n");
      {
        CATextLayer *t = [CATextLayer layer];

        printf("string           %s\n",
               [t string] ? [[[t string] description] UTF8String] : "(nil)");
        printf("fontSize         %g\n", [t fontSize]);
        printf("foregroundColor  %s\n",
               [t foregroundColor] ? "not null" : "(null)");
        printf("alignmentMode    %s\n",
               [t alignmentMode] ? [[t alignmentMode] UTF8String] : "(nil)");
        printf("truncationMode   %s\n",
               [t truncationMode] ? [[t truncationMode] UTF8String] : "(nil)");
        printf("wrapped          %d\n", (int)[t isWrapped]);
        printf("font             %s\n",
               [t font] ? "not nil" : "(nil)");
      }

      printf("\n== CATiledLayer ==\n");
      {
        CATiledLayer *t = [CATiledLayer layer];

        printf("levelsOfDetail   %lu\n", (unsigned long)[t levelsOfDetail]);
        printf("levelsOfDetailBias %lu\n",
               (unsigned long)[t levelsOfDetailBias]);
        printf("tileSize         %g %g\n",
               [t tileSize].width, [t tileSize].height);
        printf("fadeDuration     %g\n", [CATiledLayer fadeDuration]);
      }

      printf("\n== CAReplicatorLayer ==\n");
      {
        CAReplicatorLayer *r = [CAReplicatorLayer layer];

        printf("instanceCount    %ld\n", (long)[r instanceCount]);
        printf("instanceDelay    %g\n", (double)[r instanceDelay]);
        printf("preservesDepth   %d\n", (int)[r preservesDepth]);
        printf("instanceColor    %s\n",
               [r instanceColor] ? "not null" : "(null)");
        printf("instanceRedOffset %g\n", (double)[r instanceRedOffset]);
        printf("instanceAlphaOffset %g\n", (double)[r instanceAlphaOffset]);
      }

      printf("\n== CATransformLayer ==\n");
      {
        CATransformLayer *t = [CATransformLayer layer];

        printf("is a CALayer     %d\n",
               (int)[t isKindOfClass: [CALayer class]]);
        printf("hitTest outside  %s\n",
               [t hitTest: CGPointMake(500, 500)] ? "self" : "(nil)");
      }
    }
  return 0;
}

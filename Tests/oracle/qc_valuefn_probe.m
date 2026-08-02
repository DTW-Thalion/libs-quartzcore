/* CAValueFunction and CAFilter: what the class methods answer, whether the
 * objects are shared, and what an unknown name gives. */

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

static void reportFunction(NSString *name)
{
  @try
    {
      CAValueFunction *f = [CAValueFunction functionWithName: name];

      if (f == nil)
        {
          printf("  %-22s -> nil\n", [name UTF8String]);
          return;
        }
      printf("  %-22s -> %-22s name=%s class=%s\n",
             [name UTF8String],
             [[f description] UTF8String],
             [[f name] UTF8String],
             [NSStringFromClass([f class]) UTF8String]);
    }
  @catch (NSException *e)
    {
      printf("  %-22s RAISED %s: %s\n", [name UTF8String],
             [[e name] UTF8String], [[e reason] UTF8String]);
    }
}

int main(void)
{
  /* Unbuffered: a crash otherwise takes the whole trail with it. */
  setbuf(stdout, NULL);

  @autoreleasepool
    {
      printf("== CAValueFunction ==\n");
      printf("constant values: RotateX=%s Scale=%s TranslateZ=%s\n",
             [kCAValueFunctionRotateX UTF8String],
             [kCAValueFunctionScale UTF8String],
             [kCAValueFunctionTranslateZ UTF8String]);

      NSArray *names = [NSArray arrayWithObjects:
        kCAValueFunctionRotateX, kCAValueFunctionRotateY,
        kCAValueFunctionRotateZ, kCAValueFunctionScale,
        kCAValueFunctionScaleX, kCAValueFunctionScaleY,
        kCAValueFunctionScaleZ, kCAValueFunctionTranslate,
        kCAValueFunctionTranslateX, kCAValueFunctionTranslateY,
        kCAValueFunctionTranslateZ, nil];
      NSString *n;

      for (n in names)
        {
          reportFunction(n);
        }

      printf("-- an unknown name --\n");
      reportFunction(@"notAValueFunction");
      printf("-- an empty name --\n");
      reportFunction(@"");

      @try
        {
          CAValueFunction *a = [CAValueFunction functionWithName:
                                  kCAValueFunctionRotateX];
          CAValueFunction *b = [CAValueFunction functionWithName:
                                  kCAValueFunctionRotateX];
          printf("same name twice is the same object: %s (%p %p)\n",
                 (a == b) ? "YES" : "no", a, b);
          printf("retainCount-ish: conforms to NSCoding %d, NSCopying %d\n",
                 (int)[a conformsToProtocol: @protocol(NSCoding)],
                 (int)[a conformsToProtocol: @protocol(NSCopying)]);
        }
      @catch (NSException *e)
        {
          printf("sharing check RAISED %s\n", [[e reason] UTF8String]);
        }

      @try
        {
          CAValueFunction *plain = [[CAValueFunction alloc] init];
          printf("alloc/init gives %s, name=%s\n",
                 [[plain description] UTF8String],
                 [plain name] ? [[plain name] UTF8String] : "(nil)");
        }
      @catch (NSException *e)
        {
          printf("alloc/init RAISED %s: %s\n", [[e name] UTF8String],
                 [[e reason] UTF8String]);
        }

      /* archiving */
      @try
        {
          CAValueFunction *f = [CAValueFunction functionWithName:
                                  kCAValueFunctionScale];
          NSData *d = [NSKeyedArchiver archivedDataWithRootObject: f];
          CAValueFunction *back = [NSKeyedUnarchiver
                                    unarchiveObjectWithData: d];
          printf("archive round trip: %lu bytes, name=%s\n",
                 (unsigned long)[d length],
                 [back name] ? [[back name] UTF8String] : "(nil)");
        }
      @catch (NSException *e)
        {
          printf("archiving RAISED %s: %s\n", [[e name] UTF8String],
                 [[e reason] UTF8String]);
        }

      /* how it is used */
      @try
        {
          CABasicAnimation *anim = [CABasicAnimation
                                     animationWithKeyPath: @"transform"];
          printf("animation valueFunction fresh: %s\n",
                 [anim valueFunction] ? "not nil" : "(nil)");
          [anim setValueFunction: [CAValueFunction functionWithName:
                                    kCAValueFunctionRotateZ]];
          printf("animation valueFunction set:   %s\n",
                 [[anim valueFunction] name] ?
                   [[[anim valueFunction] name] UTF8String] : "(nil)");
        }
      @catch (NSException *e)
        {
          printf("animation use RAISED %s: %s\n", [[e name] UTF8String],
                 [[e reason] UTF8String]);
        }

      printf("\n== CAFilter ==\n");
      {
        Class filterClass = NSClassFromString(@"CAFilter");

        printf("CAFilter class present: %s\n",
               filterClass ? "YES" : "no");
        if (filterClass)
          {
            printf("responds to filterWithName: %d\n",
                   (int)[filterClass respondsToSelector:
                           NSSelectorFromString(@"filterWithName:")]);
            @try
              {
                id f = [filterClass performSelector:
                          NSSelectorFromString(@"filterWithName:")
                                         withObject: @"multiplyColor"];
                printf("filterWithName: multiplyColor -> %s\n",
                       f ? [[f description] UTF8String] : "nil");
              }
            @catch (NSException *e)
              {
                printf("filterWithName: RAISED %s\n", [[e reason] UTF8String]);
              }
          }
      }
    }
  return 0;
}

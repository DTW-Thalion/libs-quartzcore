/* What Apple does with the character-sized dynamic property types, which
 * share an encoding with BOOL on some platforms. */

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

#define DYNAMIC_LAYER(name, type) \
@interface name : CALayer \
@property (nonatomic, assign) type p; \
@end \
@implementation name \
@dynamic p; \
@end

DYNAMIC_LAYER(PChar, char)
DYNAMIC_LAYER(PSChar, signed char)
DYNAMIC_LAYER(PUChar, unsigned char)
DYNAMIC_LAYER(PBool, BOOL)
DYNAMIC_LAYER(PUShort, unsigned short)

int main(void)
{
  @autoreleasepool
    {
      printf("encodings: char=%s schar=%s uchar=%s BOOL=%s ushort=%s\n",
             @encode(char), @encode(signed char), @encode(unsigned char),
             @encode(BOOL), @encode(unsigned short));

      @try {
        PChar *l = [PChar layer];
        printf("fresh char           = %d\n", (int)[l p]);
        [l setP: 'a'];
        printf("char after set 'a'   = %d\n", (int)[l p]);
        printf("valueForKey: p       = %s\n",
               [[[l valueForKey: @"p"] description] UTF8String]);
      } @catch (NSException *e) {
        printf("char                 RAISED %s\n", [[e reason] UTF8String]);
      }

      @try {
        PSChar *l = [PSChar layer];
        [l setP: -5];
        printf("signed char set -5   = %d\n", (int)[l p]);
      } @catch (NSException *e) {
        printf("signed char          RAISED %s\n", [[e reason] UTF8String]);
      }

      @try {
        PUChar *l = [PUChar layer];
        [l setP: 200];
        printf("unsigned char 200    = %d\n", (int)[l p]);
      } @catch (NSException *e) {
        printf("unsigned char        RAISED %s\n", [[e reason] UTF8String]);
      }

      @try {
        PBool *l = [PBool layer];
        printf("fresh BOOL           = %d\n", (int)[l p]);
        [l setP: YES];
        printf("BOOL after set YES   = %d\n", (int)[l p]);
      } @catch (NSException *e) {
        printf("BOOL                 RAISED %s\n", [[e reason] UTF8String]);
      }

      @try {
        PUShort *l = [PUShort layer];
        [l setP: 40000];
        printf("unsigned short 40000 = %d\n", (int)[l p]);
      } @catch (NSException *e) {
        printf("unsigned short       RAISED %s\n", [[e reason] UTF8String]);
      }
    }
  return 0;
}

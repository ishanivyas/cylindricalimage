#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@interface OCVStereo : NSObject
// Final external interface
- (instancetype)initStripWidth:(int)band_width forScale:(float)scale;
- (float)append:(UIImage*)src;
- (void)stitchPanos;
- (UIImage*)leftPano;
- (UIImage*)rightPano;

// Temporary(?) interface
- (UIImage*)stitch;
- (UIImage*)lastLeft;
- (UIImage*)lastRight;
@end
NS_ASSUME_NONNULL_END

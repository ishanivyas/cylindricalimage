#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@interface OCVStereo : NSObject
// Final external interface
- (instancetype)initStripWidth:(int)band_width forScale:(float)scale;
- (float)append:(UIImage*)src;
- (UIImage*)stitch;

// Temporary(?) interface
- (UIImage*)lastLeft;
- (UIImage*)lastRight;
- (UIImage*)stitchLeft;
- (UIImage*)stitchRight;
@end
NS_ASSUME_NONNULL_END

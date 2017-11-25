#import <UIKit/UIKit.h>

@interface UIImage (affine)
- (UIImage *)scaledBy:(float)s;
- (UIImage *)clippedBy:(CGRect)r;
- (UIImage *)rotatedBy90:(int)n;
- (UIImage *)rotatedBy180:(int)n;
@end

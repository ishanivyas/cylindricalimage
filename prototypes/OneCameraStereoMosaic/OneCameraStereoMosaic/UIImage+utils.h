#import <UIKit/UIKit.h>

typedef unsigned pixel;

@interface UIImage (utils)
+ (instancetype)imageFrom:(pixel*)pixels ofWidth:(int)w height:(int)h;
- (NSError*)write:(NSString*)filename;

- (int)width;
- (int)height;
- (CGRect)rect;

- (pixel*)pixels4;
- (pixel*)pixels4Of:(CGRect)r;

- (pixel*)pixels4Scaled:(CGFloat)s;
- (pixel*)pixels4Rotated90:(int)n;
- (pixel*)pixels4Scaled:(CGFloat)s rotated90:(int)n;
- (pixel*)pixels4Scaled:(CGFloat)s rotated90:(int)n translated:(CGVector)t;

- (pixel*)pixels4Of:(CGRect)r scaled:(CGFloat)s;
- (pixel*)pixels4Of:(CGRect)r rotated90:(int)n;
- (pixel*)pixels4Of:(CGRect)r scaled:(CGFloat)s rotated90:(int)n;
- (pixel*)pixels4Of:(CGRect)r scaled:(CGFloat)s rotated90:(int)n translated:(CGVector)t;

- (pixel*)pixels4Transposed; // helps with DTW

- (UIImage *)transposed;  // helps with DTW
- (UIImage *)scaledBy:(float)s;
- (UIImage *)clippedBy:(CGRect)r;
- (UIImage *)rotatedBy90:(int)n;
@end

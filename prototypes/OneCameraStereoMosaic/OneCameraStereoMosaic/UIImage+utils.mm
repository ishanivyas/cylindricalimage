#import "UIImage+utils.h"

@implementation UIImage (affine)
- (UIImage *)scaledBy:(float)s {
    CGSize ssz = CGSizeMake(s * self.size.width, s * self.size.height);
    UIGraphicsBeginImageContext(ssz);
    [self drawInRect:CGRectMake(0, 0, ssz.width, ssz.height)];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
}

- (UIImage *)clippedBy:(CGRect)r {
    UIGraphicsBeginImageContext(r.size);
    auto cgCtxRef = UIGraphicsGetCurrentContext();
    CGContextDrawImage(cgCtxRef,
                       CGRectMake(-r.origin.x, -r.origin.y,
                                  self.size.width, self.size.height),
                       self.CGImage);
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return result;
}

- (UIImage *)rotatedBy90:(int)n {
    return nil;
}
@end

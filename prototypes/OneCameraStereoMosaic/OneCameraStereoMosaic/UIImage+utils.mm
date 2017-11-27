#import "UIImage+utils.h"

@implementation UIImage (utils)
+ (instancetype)imageFrom:(pixel*)pixels ofWidth:(int)w height:(int)h {
//    CGContextRef ctx = CGBitmapContextCreate(pixels, // Pointer to data
//                                             w,      // Width of bitmap
//                                             h,      // Height of bitmap
//                                             8,      // Bits per component
//                                             0,      // Bytes per row (0 => auto)
//                                             CGColorSpaceCreateDeviceRGB(),
//                                             kCGImageAlphaNoneSkipLast
//                                             );
//    UIImage *i = [UIImage imageWithCGImage:CGBitmapContextCreateImage(ctx)];
//    //CGDataProviderCreateDirect(<#void * _Nullable info#>, <#off_t size#>, <#const CGDataProviderDirectCallbacks * _Nullable callbacks#>)
//    //CGDataProviderCreateWithData(<#void * _Nullable info#>, <#const void * _Nullable data#>, <#size_t size#>, <#CGDataProviderReleaseDataCallback  _Nullable releaseData#>)
//    //CGDataProviderCreateWithCFData(CFDataRef(...))
//    //CGImageCreate(<#size_t width#>, <#size_t height#>, <#size_t bitsPerComponent#>, <#size_t bitsPerPixel#>, <#size_t bytesPerRow#>, <#CGColorSpaceRef  _Nullable space#>, <#CGBitmapInfo bitmapInfo#>, <#CGDataProviderRef  _Nullable provider#>, <#const CGFloat * _Nullable decode#>, <#bool shouldInterpolate#>, <#CGColorRenderingIntent intent#>)
//    CGContextRelease(ctx);
//    return pixels;
    NSData *data = [NSData dataWithBytes:pixels length:w*h*sizeof(pixel)];
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    CGImageRef imageRef = CGImageCreate(w,                                          //width
                                        h,                                          //height
                                        8,                                          //bits per component
                                        8 * sizeof(pixel),                          //bits per pixel
                                        w * sizeof(pixel),                          //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNoneSkipLast|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    UIImage *img = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    return img;
}

- (size_t)width { return CGImageGetWidth(self.CGImage); }  // OR self.size.width?
- (size_t)height { return CGImageGetHeight(self.CGImage); }   // OR self.size.height?

- (CGRect)rect {
    CGImageRef i = self.CGImage;
    return CGRectMake(0, 0, CGImageGetWidth(i), CGImageGetHeight(i));
}

- (pixel*)pixels4 {
    CGImageRef i = self.CGImage;
    float w     = self.size.width;  unsigned long wi = CGImageGetWidth(i);
    float h     = self.size.height; unsigned long hi = CGImageGetHeight(i);
    pixel *pixels = new pixel[wi*hi];

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(
        pixels,                 // Pointer to data
        w,                      // Width of bitmap
        h,                      // Height of bitmap
        8,                      // Bits per component
        wi*sizeof(pixel),       // Bytes per row
        colorSpace,             //-CGImageGetColorSpace(i),
        kCGImageAlphaNoneSkipLast|kCGBitmapByteOrderDefault
    );
    CGContextDrawImage(ctx, CGRectMake(0, 0, w, h), i);
    CGContextRelease(ctx);
    CGColorSpaceRelease(colorSpace);
    return pixels;
}

- (pixel*)pixels4Of:(CGRect)r {
    return [self pixels4Of:r scaled:1 rotated90:0 translated:CGVectorMake(0, 0)];
}

- (pixel*)pixels4Scaled:(CGFloat)s {
    return [self pixels4Of:[self rect] scaled:s rotated90:0 translated:CGVectorMake(0, 0)];
}

- (pixel*)pixels4Rotated90:(int)n {
    return [self pixels4Of:[self rect] scaled:1 rotated90:n translated:CGVectorMake(0, 0)];
}

- (pixel*)pixels4Scaled:(CGFloat)s rotated90:(int)n {
    return [self pixels4Of:[self rect] scaled:s rotated90:n translated:CGVectorMake(0, 0)];
}

- (pixel*)pixels4Scaled:(CGFloat)s rotated90:(int)n translated:(CGVector)t {
    return [self pixels4Of:[self rect] scaled:s rotated90:n translated:t];
}

- (pixel*)pixels4Of:(CGRect)r scaled:(CGFloat)s {
    return [self pixels4Of:r scaled:s rotated90:0 translated:CGVectorMake(0, 0)];
}

- (pixel*)pixels4Of:(CGRect)r rotated90:(int)n {
    return [self pixels4Of:r scaled:1 rotated90:n translated:CGVectorMake(0, 0)];
}

- (pixel*)pixels4Of:(CGRect)r scaled:(CGFloat)s rotated90:(int)n {
    return [self pixels4Of:r scaled:s rotated90:n translated:CGVectorMake(0, 0)];
}

- (pixel*)pixels4Of:(CGRect)r scaled:(CGFloat)s rotated90:(int)n translated:(CGVector)t {
    if (s == 1.0 && (n & 0x3) == 0 && t.dx == 0 && t.dy == 0) {
        return [self pixels4];
    }

    CGImageRef i = self.CGImage;
    float w     = self.size.width;  unsigned long wi = CGImageGetWidth(i);
    float h     = self.size.height; unsigned long hi = CGImageGetHeight(i);
    pixel *pixels = new pixel[wi*hi];

    CGFloat C, S, dx = s*t.dx, dy = s*t.dy;
    switch(n & 0x3) {
        case 0: C =  s; S =  0; break;                       //  sx*cosT sx*sinT 0
        case 1: C =  0; S =  s; dx = -dx; break;             // -sy*sinT sy*cosT 0
        case 2: C = -s; S =  0; dx = -dx; dy = -dy; break;   //       dx      dy 1
        case 3: C =  0; S = -s; dy = -dy; break;
    }
    // https://developer.apple.com/library/content/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/dq_affine/dq_affine.html
    CGAffineTransform T = CGAffineTransformMake(C, S, -S, C, dx, dy);

#   if 0
    CGAffineTransform X = CGAffineTransformIdentity;
    X = CGAffineTransformRotate(X, n*M_PI_2);
    X = CGAffineTransformScale(X, s, s);
    X = CGAffineTransformTranslate(X, t.dx, t.dy);
    BOOL e = CGAffineTransformEqualToTransform(X, T);
#   endif

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(pixels, // Pointer to data
                                             w,      // Width of bitmap
                                             h,      // Height of bitmap
                                             8,      // Bits per component
                                             0,      // Bytes per row (0 => auto)
                                             colorSpace, //-CGImageGetColorSpace(i),
                                             kCGImageAlphaNoneSkipLast|kCGBitmapByteOrderDefault
                                             );
    CGContextConcatCTM(ctx, T);
    CGContextDrawImage(ctx, CGRectMake(0, 0, w, h), i);
    CGContextRelease(ctx);
    CGColorSpaceRelease(colorSpace);
    return pixels;
}

- (pixel*)pixels4Transposed {
    auto hai = self.height, wai = self.width;
    pixel *I = [self pixels4];
    pixel *T = new pixel[wai*hai];
    for(int i = 0; i < hai; i++)
        for(int j = 0; j < wai; j++)
            T[j*hai + i] = I[i*wai + j];
    return T;
}

- (UIImage *)transposed {
    auto hai = self.height, wai = self.width;
    return [UIImage imageFrom:[self pixels4Transposed]
                      ofWidth:hai
                       height:wai];
}

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
    CGSize ssz = (n&1) ? CGSizeMake(self.height, self.width) : [self size];
    CGRect rct = (n&1) ? CGRectMake(0, 0, self.height, self.width) : [self rect];

    CGFloat C, S;
    switch(n & 0x3) {
        case 0: C =  1.; S =  0.; break;   //  s*cosT s*sinT 0
        case 1: C =  0.; S =  1.; break;   // -s*sinT s*cosT 0
        case 2: C = -1.; S =  0.; break;   //      dx     dy 1
        case 3: C =  0.; S = -1.; break;
    }
    // https://developer.apple.com/library/content/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/dq_affine/dq_affine.html
    CGAffineTransform T = CGAffineTransformMake(C, S, -S, C, 0, 0);
    UIGraphicsBeginImageContext(ssz);
    auto ctx = UIGraphicsGetCurrentContext();
    CGContextConcatCTM(ctx, T);
    [self drawInRect:rct];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

@end

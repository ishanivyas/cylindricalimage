#import <vector>
#import "opencv2/opencv.hpp"

#import "UIImage+cvMat.h"
#import "UIImage+utils.h"
#import "OCVStereo.h"

@implementation OCVStereo {
    std::vector<cv::Mat> left, right;
    UIImage *lastLeft, *lastRight;
    int band_width;
    float scale;
}

- (instancetype)initStripWidth:(int)band_width forScale:(float)scale {
    self = [super init];
    if (self) {
        self->band_width = band_width;
        self->scale = scale;
        return self;
    }
    return nil;
}

- (float)append:(UIImage*)src {
    // Scale and save the images.
    UIImage *lft = [self leftBandOf:src];
    UIImage *l = self->lastLeft ? (self->lastLeft).copy : lft;
    UIImage *slimg = (self->scale == 1.0) ? lft : [lft scaledBy:self->scale];
    if (slimg) {
        //TODO// test to see if the image is not different enough before keeping it.
        left.push_back(slimg.cvMat3.t());
    }
    self->lastLeft = lft;

    UIImage *rgt = [self rightBandOf:src];
    UIImage *r = self->lastRight ? (self->lastRight).copy : rgt;
    UIImage *srimg = (self->scale == 1.0) ? rgt : [rgt scaledBy:self->scale];
    if (srimg) {
        //TODO// test to see if the image is not different enough before keeping it.
        right.push_back(srimg.cvMat3.t());
    }
    self->lastRight = rgt;

    return std::log2l(cv::norm(l.cvMat3, lft.cvMat3)
                      + cv::norm(r.cvMat3, rgt.cvMat3));
}

- (UIImage*)stitch {
    //TODO// find best way to return exactly 2 images
    return [self stitchSet:self->left];
}

- (UIImage *)lastLeft {
    return self->lastLeft;
}

- (UIImage *)lastRight {
    return self->lastRight;
}

- (UIImage*)stitchLeft {
    return [self stitchSet:self->left];
}

- (UIImage*)stitchRight {
    return [self stitchSet:self->right];
}

/* ************************************************************************** */
/* Private                                                                    */
/* ************************************************************************** */
- (UIImage*)stitchSet:(std::vector<cv::Mat>)images {
    // Build one big image from all the smaller ones.
    float width = images.size() * images[0].cols;
    float height = images[0].rows;
    auto size = CGSizeMake(width, height);
    
    UIGraphicsBeginImageContext(size);
    auto cgCtxRef = UIGraphicsGetCurrentContext();
    auto x = 0.0;
    for (auto imgMat : images) {
        UIImage *img = [UIImage imageFrom:imgMat];
        CGContextDrawImage(cgCtxRef,
                           CGRectMake(x, 0.0, img.size.width, img.size.height),
                           img.CGImage);
        x += img.size.width;
    }
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return result;
}

- (UIImage *)leftBandOf:(UIImage*)src {
//    return [src clippedBy:CGRectMake(0,
//                                     0,
//                                     self->band_width,
//                                     src.size.height)];
    return [src clippedBy:CGRectMake(0,
                                     0,
                                     src.size.width,
                                     self->band_width)];
}

- (UIImage *)rightBandOf:(UIImage*)src {
//    return [src clippedBy:CGRectMake(src.size.width - self->band_width,
//                                     0,
//                                     self->band_width,
//                                     src.size.height)];
    return [src clippedBy:CGRectMake(0,
                                     src.size.height - self->band_width,
                                     src.size.width,
                                     self->band_width)];
}
@end


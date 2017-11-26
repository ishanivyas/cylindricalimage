#import <vector>
#import "opencv2/opencv.hpp"

#import "UIImage+cvMat.h"
#import "UIImage+utils.h"
#import "OCVStereo.h"
#include "Stitcher.hpp"

@implementation OCVStereo {
#   if defined(FULL_HOMOGRAPHY_APPLIED_TO_STRIPS)
    std::vector<cv::Mat> Hs;                // Homographies computed from full images.
    cv::Mat last;                           // The last full image taken.
#   endif
    std::vector<cv::Mat> left, right;       // Image strips.
    UIImage *lastLeft, *lastRight;          // For live previews.
    UIImage *leftPano, *rightPano;          // The stitched panoramas.

    int band_width;                         // The width of the image bands.
    float scale;                            // The amount to rescale images by.
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
    if (!slimg) {
        return 0.0;
    }

    UIImage *rgt = [self rightBandOf:src];
    UIImage *r = self->lastRight ? (self->lastRight).copy : rgt;
    UIImage *srimg = (self->scale == 1.0) ? rgt : [rgt scaledBy:self->scale];
    if (!srimg) {
        return 0.0;
    }
    
    // Test to see if the image is not different enough before keeping it.
#   if 0
    double d = std::log2l(cv::norm(l.cvMat3, lft.cvMat3)
                          + cv::norm(r.cvMat3, rgt.cvMat3));
    double n = std::log2l(cv::norm(l.cvMat3)
                          + cv::norm(r.cvMat3));
#   else
    double d = cv::norm(l.cvMat3, lft.cvMat3) + cv::norm(r.cvMat3, rgt.cvMat3);
    double n = l.size.width*l.size.height + r.size.width*r.size.height;
#   endif

    if ((d/n) < 0.15
        && self->lastLeft
        && self->lastRight) {
        return 0.0;
    }

    // The change in view was signifcant enough to keep it.

#   if defined(FULL_HOMOGRAPHY_APPLIED_TO_STRIPS)
    // If this is not the first image, find a Homography that maps it to the
    // last image.
    cv::Mat next = src.cvMat3;
    if (!last.empty()) {
        cv::Mat H;
        Stitcher::findHomographyMatrix(last, next, H);
        if (H.empty()) return 0.0;
        std::cout << H << std::endl;
        Hs.push_back(H);
    }
    last = next; // Save the full image so we can calculate the next Homography.
#   endif

    // Save the image strip matrices for later stitching.
    left.push_back(slimg.cvMat3.t());
    right.push_back(srimg.cvMat3.t());
    
    // Save the un-scaled image strips for live previewing.
    self->lastLeft = lft;
    self->lastRight = rgt;

    return d / n;
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

- (UIImage *)leftPano {
    return self->leftPano;
}

- (UIImage *)rightPano {
    return self->rightPano;
}

//-#include "cvMat-utils.cpp"

- (void)stitchPanos {
#   if defined(FULL_HOMOGRAPHY_APPLIED_TO_STRIPS)
    // Setup the first strip of each pano.
    cv::Mat leftPanoM, rightPanoM;
    right[0].copyTo(leftPanoM);
    left[0].copyTo(rightPanoM);
    cv::Mat H = cv::Mat::eye(3, 3, CV_64F);

    // For each image:
    //  find the Warp matrix (Translation*Homography) and the size of the resulting image.
    //  warp the strip
    //  copy the pano into the result
    for(int i = 0; i < Hs.size(); i++) {
        std::cout << Hs[i].rows << "x" << Hs[i].cols << std::endl;
        H = Hs[i]; // The homographies from the full-size images
        
        cv::Mat lW, rW;         // Warps for the strips.
        cv::Size lS, rS;        // Sizes for the merging of strips.
        cv::Point lMIN, rMIN;   // Minima

        Stitcher::findWarpSizeAndMin(leftPanoM, right[i+1], H, lW, lS, lMIN);
        Stitcher::mergeImageIntoPano(leftPanoM, right[i+1], lW, lS, lMIN, leftPanoM);
        
        Stitcher::findWarpSizeAndMin(rightPanoM, left[i+1], H, rW, rS, rMIN);
        Stitcher::mergeImageIntoPano(rightPanoM, left[i+1], rW, rS, rMIN, rightPanoM);
    }
#   else
    cv::Mat leftPanoM, rightPanoM;
    Stitcher::stitch(left, rightPanoM);
    Stitcher::stitch(right, leftPanoM);
#   endif
    leftPano = [UIImage imageFrom:leftPanoM];
    rightPano = [UIImage imageFrom:rightPanoM];
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
    // The camera always produces images in landscape coordinates, i.e. the
    // x direction proceeds along the longest line.  We are taking the panorama
    // in portrait mode, so the "bands" will come from along the "y" axis.
    return [src clippedBy:CGRectMake(     /*x:*/0,
                                          /*y:*/0,
                                      /*width:*/src.size.width,
                                     /*height:*/self->band_width)];
}

- (UIImage *)rightBandOf:(UIImage*)src {
     // The camera always produces images in landscape coordinates, i.e. the
    // x direction proceeds along the longest line.  We are taking the panorama
    // in portrait mode, so the "bands" will come from along the "y" axis.
    return [src clippedBy:CGRectMake(     /*x:*/0,
                                          /*y:*/src.size.height - self->band_width,
                                      /*width:*/src.size.width,
                                     /*height:*/self->band_width)];
}
@end


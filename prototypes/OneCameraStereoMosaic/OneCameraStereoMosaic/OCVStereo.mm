#include "config.h"

#import <vector>
#import "opencv2/opencv.hpp"

#import "UIImage+cvMat.h"
#import "UIImage+utils.h"
#import "OCVStereo.h"
#include "Stitcher.hpp"
#import "dtw.h"

@implementation OCVStereo {
#   if STITCHER == FULL_HOMOGRAPHY_APPLIED_TO_STRIPS
    std::vector<cv::Mat> Hs;                // Homographies computed from full images.
    cv::Mat last;                           // The last full image taken.
#   endif
    std::vector<cv::Mat> left, right;       // Image strips.
    UIImage *lastLft, *lastRgt;             // For calculating alignment.
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
#   if SKIP_FALSE_MOTION
    double d = 1.0, n = 1.0;
    if (self->lastLeft && self->lastRight) {  // Only skip motion if there was a previous set of left and right images to compare to.
        d = cv::norm(l.cvMat3, left[left.size()-1]) + cv::norm(r.cvMat3, right[right.size()-1]);
        n = l.size.width*l.size.height + r.size.width*r.size.height;
#       if USE_LOG_OF_CHANGED_PIXELS_FOR_MOTION_DETECTION
        d = std::log2l(d);
        n = std::log2l(cv::norm(l.cvMat3) + cv::norm(r.cvMat3));
#       endif
        if ((d/n) < 0.15) {
            return 0.0;
        }
    }
#   endif
    
    // The change in view was signifcant enough to keep it.

#   if DRAW_MATCHES
    static int i = -1;
    i++;
    cv::Mat viz;
#   endif

#   if STITCHER == FULL_HOMOGRAPHY_APPLIED_TO_STRIPS
    // If this is not the first image, find a Homography that maps it to the
    // last image.
    cv::Mat H;
    cv::Mat next = src.cvMat3;
    if (!last.empty()) {
        Stitcher::findHomographyMatrix(last, next, H
#                                      if DRAW_MATCHES
                                       , &viz
#                                      endif
                                       );
        if (!H.empty()) {
            Hs.push_back(H);
            last = next; // Save the full image so we can calculate the next Homography.
            std::cout << H << std::endl;
        } else {
            std::cout << "H is empty." << std::endl;
#           if DRAW_MATCHES
            return 0.0; // Nothing to match up with and we are not saving the image.
#           endif
        }
    }
#   else
    // DTW align
    if (lastLft && lastRgt) {
        auto lftDelta = [self align:slimg relativeTo:lastLft];
        auto rgtDelta = [self align:srimg relativeTo:lastRgt];
    }
#   endif

#   if DRAW_MATCHES
    {
        [slimg write:[NSString stringWithFormat:@"_left%03d",  i]];
        [srimg write:[NSString stringWithFormat:@"_right%03d", i]];
        if (i < 30) {
            [src write:[NSString stringWithFormat:@"_full%03d", i]];
            if (!viz.empty()) {
                [[UIImage imageFrom:viz] write:[NSString stringWithFormat:@"_matches%03d", i]];
            }
        }
    }
#   endif

#   if STITCHER == FULL_HOMOGRAPHY_APPLIED_TO_STRIPS
    if (H.empty()) {
        return 0.0;
    }
#   endif

    // Save the image strips and their matrices for later stitching.
    lastLft = slimg;
    lastRgt = srimg;
    left.push_back(slimg.cvMat3.t());
    right.push_back(srimg.cvMat3.t());
    
    // Save the un-scaled image strips for live previewing.
    self->lastLeft = lft;
    self->lastRight = rgt;

#   if SKIP_FALSE_MOTION
    return d / n;
#   else
    return 1.0;
#   endif
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

- (UIImage *)leftPano {
    return self->leftPano;
}

- (UIImage *)rightPano {
    return self->rightPano;
}

//-#include "cvMat-utils.cpp"

- (void)stitchPanos {
#   if STITCHER == SIMPLE_STITCHER
    leftPano = [self stitchSet:self->left];
    rightPano = [self stitchSet:self->right];
#   elif STITCHER == FULL_HOMOGRAPHY_APPLIED_TO_STRIPS
    // Setup the first strip of each pano.
    cv::Mat leftPanoM, rightPanoM;
    right[0].copyTo(leftPanoM);
    left[0].copyTo(rightPanoM);
    cv::Mat H = cv::Mat::eye(3, 3, CV_64F);

    // For each Homography i connecting image i to image i+1:
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
    leftPano = [UIImage imageFrom:leftPanoM];
    rightPano = [UIImage imageFrom:rightPanoM];
#   elif STITCHER == PER_STRIP_HOMOGRAPHY_STITCHER || STITCHER == OPENCV_STITCHER
    cv::Mat leftPanoM, rightPanoM;
    Stitcher::stitch(left, rightPanoM);
    Stitcher::stitch(right, leftPanoM);
    leftPano = [UIImage imageFrom:leftPanoM];
    rightPano = [UIImage imageFrom:rightPanoM];
#   endif

    lastLeft = lastRight = nil;  // Recover some memory...
}

/* ************************************************************************** */
/* Private                                                                    */
/* ************************************************************************** */
- (UIImage*)stitchSet:(std::vector<cv::Mat>)images {
#   if STITCHER == SIMPLE_STITCHER
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
#   else
    return nil;
#   endif
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

- (CGPoint)align:(UIImage*)b relativeTo:(UIImage*)a {
    // The images arrive from the camera in Landscape mode but we are taking the
    // pictures in portrain mode, so CGImageGetHeight actually gets a width and
    // vice-versa.
    unsigned long wai = CGImageGetHeight(a.CGImage),
                  hai = CGImageGetWidth(a.CGImage),
                  wbi = CGImageGetHeight(b.CGImage),
                  hbi = CGImageGetWidth(b.CGImage);
    float         wa  = a.size.height,
                  ha  = a.size.width,
                  wb  = b.size.height,
                  hb  = b.size.width;

    pixel *pa = [a pixels4];
    pixel *pb = [[b clippedBy:CGRectMake(0, 0,  1, hb)] pixels4];

    // Try several different changes int X position, seeing what the DTW
    // distance is.  The dx with the minimum DTW distance is probably the best.
    int min_score = INT_MAX;
    int min_dx = 0;
    for(int dx = wai-1; dx >= 0; dx--) {
        int score = dtw_distance((unsigned int)hbi, pa, pb, 32);
        if (score < min_score) {
            min_score = score;
            min_dx = dx;
        }
        pa += hai;
    }
    return CGPointMake(min_dx, /* //TODO//: */0);
}

@end


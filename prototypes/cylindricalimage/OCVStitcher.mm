#import <vector>
//-#import "opencv2/opencv.hpp"
#import "opencv2/stitching.hpp"
//-#import "opencv2/imgcodecs/ios.h"
#import "opencv2/imgcodecs.hpp"

#import "UIImage+cvMat.h"
#import "OCVStitcher.h"
#import "StitcherWrapper.h"

#define COMPRESS_RATIO 0.95

@implementation OCVStitcher
+ (UIImage *)stitch:(NSArray*)images {
    NSMutableArray* compressedImages = [NSMutableArray new];
    for(UIImage *rawImage in images){
        UIImage *cimg = [self compressedToRatio:rawImage ratio:COMPRESS_RATIO];
        [compressedImages addObject:cimg];
    }

    if ([compressedImages count] == 0) {
        NSLog(@"imageArray is empty");
        return nil;
    }

    std::vector<cv::Mat> matArray;
    for (id image in compressedImages) {
        if (![image isKindOfClass: [UIImage class]]) continue;
        cv::Mat matImage = [(UIImage*)image cvMat3];
        matArray.push_back(matImage);
    }
    NSLog(@"Stitching...");
    cv::Mat result = stitch(matArray);
    if (result.empty()){
        NSLog(@"Stop working its empty");
        return nil;
    }
    NSLog(@"Stitched");
    return [UIImage imageFrom:result];
}

+ (UIImage *)compressedToRatio:(UIImage *)img ratio:(float)ratio {
    CGSize compressedSize;
    compressedSize.width=img.size.width*ratio;
    compressedSize.height=img.size.height*ratio;
    UIGraphicsBeginImageContext(compressedSize);
    [img drawInRect:CGRectMake(0, 0, compressedSize.width, compressedSize.height)];
    UIImage* compressedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return compressedImage;
}
@end

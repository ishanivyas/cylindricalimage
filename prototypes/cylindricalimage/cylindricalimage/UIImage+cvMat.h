#import <UIKit/UIKit.h>

namespace cv {
    class Mat;
}

@interface UIImage (OpenCV)
// cv::Mat to UIImage
+ (UIImage *)imageFrom:(const cv::Mat&)cvMat;
- (id)initWith:(const cv::Mat&)cvMat;

// UIImage to cv::Mat
- (cv::Mat)cvMat;
- (cv::Mat)cvMat3;  // no alpha channel
- (cv::Mat)cvGrayscaleMat;
@end


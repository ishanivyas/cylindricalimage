#include "StitcherWrapper.h"
#include "opencv2/highgui/highgui.hpp"
#include "opencv2/stitching.hpp"
#import "opencv2/imgcodecs.hpp"
cv::Mat stitch(const std::vector<cv::Mat> images) {
    cv::Mat result;
    cv::Stitcher stitcher = cv::Stitcher::createDefault(false);
    cv::Stitcher::Status status = stitcher.stitch(images, result);
    
    if (status != cv::Stitcher::OK) {
        return result;
    }
    return result;
}

#ifndef StitcherWrapper_h
#define StitcherWrapper_h

namespace cv { class Mat; }
#include <vector>

cv::Mat stitch(std::vector<cv::Mat> images);

#endif /* StitcherWrapper_h */

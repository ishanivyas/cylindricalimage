#ifndef Stitcher_hpp
#define Stitcher_hpp

#include <vector>
#include "opencv2/opencv.hpp"

typedef std::vector<std::vector<cv::DMatch> > DescriptorMatches;
typedef std::vector<cv::KeyPoint> KeyPoints;

typedef cv::Point2f ImgCoord;
typedef std::vector<cv::Point2f> ImgCoords;
typedef std::vector<cv::Mat> Mats;

struct Stitcher {
    void filterMatchesAndExtractPoints(KeyPoints &kp1, KeyPoints &kp2, DescriptorMatches &matches, double threshold, ImgCoords &p1, ImgCoords &p2);
    void warpTwoImages(cv::InputArray &img1, cv::InputArray &img2, cv::Mat &H, cv::OutputArray out);
    void findHomographyMatrix(cv::InputArray img1, cv::InputArray img2, cv::Mat &H);
    void stitch(Mats &images, cv::Mat &pano);
};

#endif /* Stitcher_hpp */

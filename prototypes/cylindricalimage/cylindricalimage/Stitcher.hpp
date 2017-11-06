#ifndef Stitcher_hpp
#define Stitcher_hpp

#include <vector>
//-#include "opencv2/opencv.hpp"
namespace cv {
    class Mat; class Point2f; class KeyPoint; class DMatch;
    class InputArray; class OutputArray;
}

namespace Stitcher {
    typedef std::vector<std::vector<cv::DMatch> > DescriptorMatches;
    typedef std::vector<cv::KeyPoint> KeyPoints;

    typedef cv::Point2f ImgCoord;
    typedef std::vector<cv::Point2f> ImgCoords;
    typedef std::vector<cv::Mat> Mats;

    void stitch(Mats &images, cv::Mat &pano);

    void filterMatchesAndExtractPoints(KeyPoints &kp1, KeyPoints &kp2, DescriptorMatches &matches, double threshold, ImgCoords &p1, ImgCoords &p2);
    void warpTwoImages(cv::InputArray &img1, cv::InputArray &img2, cv::Mat &H, cv::OutputArray out, int n);
    void findHomographyMatrix(cv::InputArray img1, cv::InputArray img2, cv::Mat &H);
};

#endif /* Stitcher_hpp */

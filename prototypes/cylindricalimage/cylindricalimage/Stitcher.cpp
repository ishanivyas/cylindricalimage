#include "Stitcher.hpp"
#include <vector>

#include <iostream>

void Stitcher::filterMatchesAndExtractPoints(KeyPoints &kp1, KeyPoints &kp2, DescriptorMatches &matches, double threshold, ImgCoords &p1, ImgCoords &p2) {
    auto n = fmin(kp1.size(), kp2.size());
    for(int i = 0; i < n; i++) {
        ImgCoord src = kp1[matches[i][0].queryIdx].pt,
        dst = kp2[matches[i][0].trainIdx].pt;
        //-auto diff = sqrt(fabs(src.x - dst.x) + fabs(src.y - dst.y));
        auto diff = fabs(src.y - dst.y);
        if (diff < threshold) {
            // Save the image coordinates from the keypoints.
            p1.push_back(src);
            p2.push_back(dst);
        }
    }
}

#define len(array) ((sizeof(array) / sizeof(array[0])))

void Stitcher::findWarpSizeAndMin(cv::InputArray img1, cv::InputArray img2, cv::Mat &H,
                                  cv::Mat &W, cv::Size &S, cv::Point &MIN) {
    double h1 = img1.rows(); double w1 = img1.cols();
    double h2 = img2.rows(); double w2 = img2.cols();
    
    // Warp the extrema of img2 to find out where its points would be in
    // a merged image (in img1's coordinates).
    const int dims[] = {4,1};
    double pts1d[] = {0,0,0,h1,w1,h1,w1,0},
    pts2d[] = {0,0,0,h2,w2,h2,w2,0},
    pts2_in_perspective_data[8];
    cv::Mat pts1(len(dims), dims, CV_64FC2, pts1d),
    pts2(len(dims), dims, CV_64FC2, pts2d),
    pts2_in_perspective(len(dims), dims, CV_64F, pts2_in_perspective_data);
    cv::perspectiveTransform(pts2, pts2_in_perspective, H);
    
    // Find the extrema of img1 and and the transformed-extrema of img2.
    double max_x = w1, max_y = h1,
    min_x = 0,  min_y = 0;
    for(int i = 0; i < 4; i++) {
        double py = pts2_in_perspective.at<double>(i,0); // row / y (does Mat.at(..) use 0 == row index and 1 == col??)
        double px = pts2_in_perspective.at<double>(i,1); // col / x
        if(px < min_x) min_x = px;  if(py < min_y) min_y = py;
        if(px > max_x) max_x = px;  if(py > max_y) max_y = py;
    }
    // WARNING: may have to round min/max away from 0!  The python code
    // appears to have approximated this by subtracting .5 from min_* and
    // adding it to max_*:
    min_y = round(min_y - .5); min_x = round(min_x - .5);
    max_y = round(max_y + .5); max_x = round(max_x + .5);
    
    // Build a translation matrix in homogenous coordinates.
    const int Tdims[] = {3,3};
    double Tdata[] =  {1, 0, -min_x, 0, 1, -min_y, 0, 0, 1};
    cv::Mat T(2, Tdims, CV_64F, Tdata);
    W = T*H;  // Combine the homography and translation into a "Warp".
    S = cv::Size(max_x - min_x, max_y - min_y);
    MIN = cv::Point2d(min_x, min_y);
}

void Stitcher::mergeImageIntoPano(cv::InputArray img, cv::InputArray pano,
                                  cv::Mat &W, cv::Size &S, cv::Point &MIN,
                                  cv::OutputArray out) {
    // Translate and warp pano so that its pixels align with img1.
    cv::Mat warped;
    cv::warpPerspective(pano, warped, W, S);
    
    // Copy the pixels of img1 over warped-img2
    double wi = img.cols(), hi = img.rows();
    img.copyTo(warped(cv::Rect(-MIN.x, -MIN.y, wi, hi)));
    warped.copyTo(out);
}

void Stitcher::findHomographyMatrix(cv::InputArray img1, cv::InputArray img2, cv::Mat &H) {
    // Find keypoints and their descriptors for each image using ORB.
    cv::Ptr<cv::ORB> detector = cv::ORB::create(800, 1.1414, 14);
    KeyPoints kp1, kp2;
    cv::Mat des1, des2;
    detector->detectAndCompute(img1, /*mask:*/ cv::noArray(), kp1, des1);
    detector->detectAndCompute(img2, /*mask:*/ cv::noArray(), kp2, des2);
    
    // Find correspondence between the descriptors using k-nearest-neighbors.
    cv::BFMatcher bf;
    DescriptorMatches matches;
    bf.knnMatch(des1, des2, matches, 2);
    
    // Filter the matches and extract their image coordinates.
    ImgCoords p1, p2;
    filterMatchesAndExtractPoints(kp1, kp2, matches, .4*img1.rows(), p1, p2);
    
    H = cv::findHomography(p1, p2,
                           cv::RANSAC, /*RANSACreprojThresh:*/5.0
                           /*mask:cv::noArray()*/
                           /*maxIters:2000*/ /*confidence:0.995*/);
}

void Stitcher::stitch(Mats &images, cv::Mat &pano) {
    images[0].copyTo(pano);
    int i = 0;
    for(auto img : images) {
        if (++i == 1) continue;
        cv::Mat H, W;
        cv::Size S;
        cv::Point MIN;
        findHomographyMatrix(pano, img, H);
        if (H.empty()) continue;    // Failed to find homography; omit the image.
        findWarpSizeAndMin(img, pano, H, W, S, MIN);
        mergeImageIntoPano(img, pano, W, S, MIN, pano);
    }
}

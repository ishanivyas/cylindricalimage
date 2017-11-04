#include "Stitcher.hpp"
#include <vector>

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

void Stitcher::warpTwoImages(cv::InputArray img1, cv::InputArray img2, cv::Mat &H, cv::OutputArray out) {
    float h1 = img1.rows(); float w1 = img1.cols();
    float h2 = img2.rows(); float w2 = img2.cols();

    // Warp the extrema of img2 to find out where its points would be in
    // a merged image (in img1's coordinates).
    cv::Mat pts2_transformed;
    const int dims[] = {4,1,2};
    float pts1d[] = {0,0,0,h1,w1,h1,w1,0},
          pts2d[] = {0,0,0,h2,w2,h2,w2,0};
    cv::Mat pts1(3, dims, CV_32F, pts1d),
            pts2(3, dims, CV_32F, pts2d);
    cv::perspectiveTransform(pts2, pts2_transformed, H);
    
    // Find the extrema of img1 and and the transformed-extrema of img2.
    float max_x = fmax(0, w1), max_y = fmax(0, h1),
          min_x = fmin(0, w1), min_y = fmin(0, h1);
    for(int i = 0; i < 4; i++) {
        float px = pts2_transformed.at<float>(i,0,0);
        float py = pts2_transformed.at<float>(i,0,1);
        if(px < min_x) min_x = px;  if(py < min_y) min_y = py;
        if(px > max_x) max_x = px;  if(py > max_y) max_y = py;
    }
    // WARNING: may have to round min/max away from 0!  The python code
    // appears to have approximated this by subtracting .5 from min_* and
    // adding it to max_*:
    min_y -= .5; min_x -= .5;
    max_y += .5; max_x += .5;

    // Build a translation matrix in homogenous coordinates.
    const int Tdims[] = {3,3};
    float Tdata[] =  {1, 0, -min_x, 0, 1, -min_y, 0, 0, 1};
    cv::Mat T(2, Tdims, CV_32F, Tdata);

    // Translate and warp img2 so that its pixels align with img1.
    cv::Size s(int(max_x - min_x), int(max_y - min_y));
    cv::Mat warped;
    cv::warpPerspective(img2, warped, T.mul(H), s);
    
    // Copy the pixels of img1 over warped-img2
    img1.copyTo(warped(cv::Rect(cv::Point(min_x, min_y), cv::Size(w1, h1))));
}

void Stitcher::findHomographyMatrix(cv::InputArray img1, cv::InputArray img2, cv::Mat &H) {
    // Find keypoints and their descriptors for each image using ORB.
    cv::Ptr<cv::ORB> detector = cv::ORB::create();
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
    filterMatchesAndExtractPoints(kp1, kp2, matches, .1*img1.rows(), p1, p2);
    H = cv::findHomography(p1, p2, cv::RANSAC, 5.0);
}

void Stitcher::stitch(Mats &images, cv::Mat &pano) {
    images[0].copyTo(pano);
    for(auto img : images) {
        cv::Mat H;
        findHomographyMatrix(pano, img, H);
        warpTwoImages(pano, img, H, pano);
    }
}

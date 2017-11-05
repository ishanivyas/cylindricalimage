#include <iostream>
#include "Stitcher.hpp"

void testStitch() {
    cv::Mat I1 = cv::imread("data/img01.jpg"),
            I2 = cv::imread("data/img02.jpg"),
            I3 = cv::imread("data/img03.jpg"),
            I4 = cv::imread("data/img04.jpg"),
            I5 = cv::imread("data/img05.jpg")
    ;
    if (I1.empty()
        || I2.empty()
        || I3.empty()
        || I4.empty()
        || I5.empty()) {
        std::cout << "Could not read one of the 5 source images.\n";
        return;
    }

    Stitcher::Mats images =
        std::vector<cv::Mat>{I1, I2, I3, I4, I5};

    cv::Mat pano;
    Stitcher::stitch(images, pano);
    
    cv::imwrite("data/pano.jpg", pano);
}

int main(int argc, const char * argv[]) {
    std::cout << "Testing Stitcher::stitch...\n";
    testStitch();
    return 0;
}

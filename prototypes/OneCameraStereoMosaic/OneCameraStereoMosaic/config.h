#ifndef config_h
#define config_h

#define SIMPLE_STITCHER                    1
#define PER_STRIP_HOMOGRAPHY_STITCHER      2
#define FULL_HOMOGRAPHY_APPLIED_TO_STRIPS  3
#define OPENCV_STITCHER                    4
#define STITCHER                           FULL_HOMOGRAPHY_APPLIED_TO_STRIPS

#define BRUTE_FORCE_MATCHER                 1
#define FLANN_MATCHER                       2
#define MATCHER                             BRUTE_FORCE_MATCHER

#define DRAW_MATCHES                        1

#define SKIP_FALSE_MOTION                   1
//#define USE_LOG_OF_CHANGED_PIXELS_FOR_MOTION_DETECTION    1

#endif /* config_h */

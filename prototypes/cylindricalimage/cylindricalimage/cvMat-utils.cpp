static const char *type2depth(cv::Mat m) {
    auto type = m.type();
    uchar depth = type & CV_MAT_DEPTH_MASK;
    switch ( depth ) {
        case CV_8U:  return "CV_8U";
        case CV_8S:  return "CV_8S";
        case CV_16U: return "CV_16U";
        case CV_16S: return "CV_16S";
        case CV_32S: return "CV_32S";
        case CV_32F: return "CV_32F";
        case CV_64F: return "CV_64F";
        default:     return "User";
    }
}

static char type2chans(cv::Mat m) {
    return '0' + 1 + (m.type() >> CV_CN_SHIFT);
}

#define desc(m) do{std::cout << #m " is " << type2depth(m) << "C" << type2chans(m) << " of size " << m.size() << std::endl; }while(0)

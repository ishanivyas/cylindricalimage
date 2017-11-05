#!/bin/bash

# Install Homebrew because we need CMake to build OpenCV
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
brew install cmake

# Go to project directory, checkout code for OpenCV (and its optional features), and build it.
export PROJECT_DIR=$HOME/Documents/GitHub/cylindricalimage/prototypes/cylindricalimage/cylindricalimage
mkdir $PROJECT_DIR/ios	;# make a director for holding the iOS build of OpenCV
cd $PROJECT_DIR
git clone https://github.com/opencv/opencv.git	;# get OpenCV source code
cd opencv/
git clone https://github.com/opencv/opencv_contrib.git contrib	;# Get OpenCV contrib (SIFT, etc...)
cd platforms/ios/
python build_framework.py $PROJECT_DIR/ios --contrib=$PROJECT_DIR/opencv/contrib	;# Build it all

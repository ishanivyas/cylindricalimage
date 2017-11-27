#import <XCTest/XCTest.h>
#import <UIKit/UIKit.h>
#import "UIImage+utils.h"

@interface UIImage_utilsTest : XCTestCase {
    pixel *pixels;
    int W, H, S;
}
@end

@implementation UIImage_utilsTest

- (void)setUp {
    [super setUp];

    pixels = new pixel[6];
    pixels[0] = 1;
    pixels[1] = 63;
    pixels[2] = 127;
    pixels[3] = 255;
    pixels[4] = 255;
    pixels[5] = 255;
    W = 3;
    H = 2;
    S = 32;
}

- (void)tearDown {
    [super tearDown];
    delete[] pixels;
}

/* Untested:
 - (CGRect)rect;
 
 - (pixel*)pixels4Of:(CGRect)r;
 
 - (pixel*)pixels4Scaled:(CGFloat)s;
 - (pixel*)pixels4Rotated90:(int)n;
 - (pixel*)pixels4Scaled:(CGFloat)s rotated90:(int)n;
 - (pixel*)pixels4Scaled:(CGFloat)s rotated90:(int)n translated:(CGVector)t;
 
 - (pixel*)pixels4Of:(CGRect)r scaled:(CGFloat)s;
 - (pixel*)pixels4Of:(CGRect)r rotated90:(int)n;
 - (pixel*)pixels4Of:(CGRect)r scaled:(CGFloat)s rotated90:(int)n;
 - (pixel*)pixels4Of:(CGRect)r scaled:(CGFloat)s rotated90:(int)n translated:(CGVector)t;
 
 - (UIImage *)rotatedBy90:(int)n;
*/

- (void)testImageCreatedFromRawIsNotNil {
    XCTAssertNotNil([UIImage imageFrom:pixels ofWidth:W height:H]);
}

- (void)testImageCreatedFromRawHasSize {
    UIImage *i = [UIImage imageFrom:pixels ofWidth:W height:H];
    XCTAssertEqual(H, i.size.height);
    XCTAssertEqual(W, i.size.width);
    XCTAssertEqual(H, i.height);
    XCTAssertEqual(W, i.width);
}

- (void)testScaledImageCreatedFromRawIsNotNil {
    UIImage *scaled = [[UIImage imageFrom:pixels ofWidth:W height:H] scaledBy:S];
    XCTAssertNotNil(scaled);
    XCTAssertEqual(S*W, scaled.width);
    XCTAssertEqual(S*H, scaled.height);
}

- (void)testClippedImageCreatedFromRawIsNotNil {
    UIImage *clipped = [[UIImage imageFrom:pixels ofWidth:W height:H]
                        clippedBy:CGRectMake(0, 0, W-1, H)];
    XCTAssertNotNil(clipped);
    XCTAssertEqual(W-1, clipped.width);
    XCTAssertEqual(H, clipped.height);
}

- (void)testZeroRotatedImageCreatedFromRaw {
    UIImage *unrotated = [[UIImage imageFrom:pixels ofWidth:W height:H]
                        rotatedBy90:0];
    XCTAssertNotNil(unrotated);
    XCTAssertEqual(W, unrotated.width);
    XCTAssertEqual(H, unrotated.height);
}

- (void)test360RotatedImageCreatedFromRaw {
    UIImage *unrotated = [[UIImage imageFrom:pixels ofWidth:W height:H]
                          rotatedBy90:4];
    XCTAssertNotNil(unrotated);
    XCTAssertEqual(W, unrotated.width);
    XCTAssertEqual(H, unrotated.height);
}

- (void)test90RotatedImageCreatedFromRaw {
    UIImage *rotated = [[UIImage imageFrom:pixels ofWidth:W height:H]
                        rotatedBy90:1];
    XCTAssertNotNil(rotated);
    XCTAssertEqual(H, rotated.width);
    XCTAssertEqual(W, rotated.height);
    UIImage *scaled = [rotated scaledBy:S];
    XCTFail("This test looks like its passing but it is not.  Use quick-look on the results to see why.");
}

- (void)testCompositeExtractPixels {
    UIImage *img = [UIImage imageFrom:pixels ofWidth:W height:H];
    pixel *also_pixels = [img pixels4Scaled:S rotated90:1 translated:CGVectorMake(0,0)];
    UIImage *result = [UIImage imageFrom:also_pixels ofWidth:S*H height:S*W];
    XCTAssertNotNil(result);
    XCTAssertEqual(S*W, result.height);
    XCTAssertEqual(S*H, result.width);
    XCTFail("This test looks like its passing but it is not.  Use quick-look on the results to see why.");
}

- (void)testRoundtrip {
    UIImage *constructed = [UIImage imageFrom:pixels ofWidth:W height:H];
    pixel *also_pixels = [constructed pixels4];
    XCTAssertEqual(also_pixels[0], 1);
    XCTAssertEqual(also_pixels[1], 63);
    XCTAssertEqual(also_pixels[2], 127);
    XCTAssertEqual(also_pixels[3], 255);
    XCTAssertEqual(also_pixels[4], 255);
    XCTAssertEqual(also_pixels[5], 255);
}

@end

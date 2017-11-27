#import <XCTest/XCTest.h>
#include "dtw.h"

@interface DTWTest : XCTestCase @end

@implementation DTWTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testSelfIsZero {
    unsigned seq_a[] = {1, 2, 3, 4, 5, 6, 7, 8, 9};
    int n = sizeof(seq_a) / sizeof(seq_a[0]);
    XCTAssertEqual(   dtw_distance(n, seq_a, seq_a), 0);
}

- (void)testConstantOffsetIsNxK {
    unsigned seq_a[] = {1, 2, 3, 4, 5, 6, 7, 8, 9};
    unsigned seq_b[] = {0, 1, 2, 3, 4, 5, 6, 7, 8};
    int n = sizeof(seq_a) / sizeof(seq_a[0]);
    XCTAssertNotEqual(dtw_distance(n, seq_a, seq_b), 0);
    XCTAssertEqual(   dtw_distance(n, seq_a, seq_b), 1);
}

- (void)testV {
    unsigned seq_a[] = {11, 10, 7, 6, 5, 6, 7, 8, 9};
    unsigned seq_b[] = { 9,  8, 7, 6, 5, 6, 8, 9, 9};
    int n = sizeof(seq_a) / sizeof(seq_a[0]);
    XCTAssertNotEqual(dtw_distance(n, seq_a, seq_b), 0);
    XCTAssertEqual(   dtw_distance(n, seq_a, seq_b), 5);
}

@end

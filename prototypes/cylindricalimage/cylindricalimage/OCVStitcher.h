#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@interface OCVStitcher : NSObject
+ (UIImage *)stitch:(NSArray*)images;
@end
NS_ASSUME_NONNULL_END

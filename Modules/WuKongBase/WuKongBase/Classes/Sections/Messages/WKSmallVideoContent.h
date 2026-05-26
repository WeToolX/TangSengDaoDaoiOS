//
//  WKSmallVideoContent.h
//  WuKongBase
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <WuKongIMSDK/WuKongIMSDK.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKSmallVideoContent : WKMediaMessageContent

@property(nonatomic,assign) CGFloat width;
@property(nonatomic,assign) CGFloat height;
@property(nonatomic,assign) NSInteger duration;
@property(nonatomic,assign) long long size;

+ (instancetype)videoContentWithVideoPath:(NSString *)videoPath coverPath:(nullable NSString *)coverPath;
+ (instancetype)videoContentWithVideoPath:(NSString *)videoPath;

- (nullable UIImage *)coverImage;
- (NSString *)coverURL;
- (NSString *)durationText;

@end

NS_ASSUME_NONNULL_END

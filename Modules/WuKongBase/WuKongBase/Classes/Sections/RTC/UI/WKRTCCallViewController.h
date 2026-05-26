//
//  WKRTCCallViewController.h
//  WuKongBase
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class WKRTCSessionManager;

@interface WKRTCCallViewController : UIViewController

- (instancetype)initWithSession:(WKRTCSessionManager *)session;

@end

NS_ASSUME_NONNULL_END

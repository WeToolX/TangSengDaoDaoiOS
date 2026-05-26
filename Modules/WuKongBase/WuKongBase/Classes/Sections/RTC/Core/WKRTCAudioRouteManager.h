//
//  WKRTCAudioRouteManager.h
//  WuKongBase
//

#import <Foundation/Foundation.h>
#import "WKRTCModels.h"

NS_ASSUME_NONNULL_BEGIN

/// 音频路由变化通知。
FOUNDATION_EXPORT NSString * const WKRTCAudioRouteDidChangeNotification;

/// 通话音频路由管理，负责扬声器、听筒和蓝牙路由的本地切换。
@interface WKRTCAudioRouteManager : NSObject

+ (instancetype)shared;

@property(nonatomic,assign,readonly) BOOL speakerEnabled;
@property(nonatomic,copy,readonly) NSString *currentRouteName;

- (void)prepareAudioSessionForCallType:(WKRTCCallType)callType;
- (void)setSpeakerEnabled:(BOOL)enabled callType:(WKRTCCallType)callType;
- (void)deactivateAudioSession;

@end

NS_ASSUME_NONNULL_END

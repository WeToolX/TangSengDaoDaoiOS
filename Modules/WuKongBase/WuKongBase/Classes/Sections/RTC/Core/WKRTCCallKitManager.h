//
//  WKRTCCallKitManager.h
//  WuKongBase
//

#import <Foundation/Foundation.h>
#import "WKRTCModels.h"

NS_ASSUME_NONNULL_BEGIN

/// CallKit 管理器，负责系统来电、接听和拒接动作。
@interface WKRTCCallKitManager : NSObject

+ (instancetype)shared;

/// 上报系统来电，VoIP push 到达后必须尽快调用。
- (void)reportIncomingCall:(WKRTCCallPayload *)payload completion:(void(^_Nullable)(NSError *_Nullable error))completion;

/// 当前通话结束时关闭系统来电 UI。
- (void)endCallIfNeeded:(NSString *)callId reason:(NSString *_Nullable)reason;

@end

NS_ASSUME_NONNULL_END

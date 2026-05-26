//
//  WKRTCAPI.h
//  WuKongBase
//

#import <Foundation/Foundation.h>
#import <PromiseKit/PromiseKit.h>
#import "WKRTCModels.h"

NS_ASSUME_NONNULL_BEGIN

/// RTC HTTP 接口封装，只实现服务端文档中存在的接口。
@interface WKRTCAPI : NSObject

+ (instancetype)shared;

/// 当前安装实例的稳定设备 ID。
- (NSString *)deviceId;

/// 发起私聊或群聊通话。
- (AnyPromise *)startCallWithChannelId:(NSString *)channelId
                           channelType:(WKChannelType)channelType
                              callType:(WKRTCCallType)callType
                            inviteUids:(NSArray<NSString *> *_Nullable)inviteUids
                             requestId:(NSString *)requestId;

/// 接听或加入通话。
- (AnyPromise *)joinCall:(NSString *)callId joinCode:(NSString *_Nullable)joinCode;

/// 拒绝通话或强邀请。
- (AnyPromise *)rejectCall:(NSString *)callId;

/// 发起方取消未接通的通话。
- (AnyPromise *)cancelCall:(NSString *)callId;

/// 关闭整个房间。
- (AnyPromise *)closeCall:(NSString *)callId reason:(NSString *)reason;

/// 当前用户离开房间，不一定关闭整个房间。
- (AnyPromise *)leaveCall:(NSString *)callId;

/// 邀请成员加入通话。
- (AnyPromise *)inviteCall:(NSString *)callId uids:(NSArray<NSString *> *)uids;

/// 创建一次性加入码。
- (AnyPromise *)createJoinCodeForCall:(NSString *)callId;

/// 查询频道当前通话状态。
- (AnyPromise *)channelStateWithChannelId:(NSString *)channelId channelType:(WKChannelType)channelType;

/// 上传普通 APNs 或 PushKit VoIP token。
- (AnyPromise *)uploadDeviceToken:(NSString *)deviceToken deviceType:(NSString *)deviceType bundleId:(NSString *)bundleId;

@end

NS_ASSUME_NONNULL_END

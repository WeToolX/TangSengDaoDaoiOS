//
//  WKRTCModels.h
//  WuKongBase
//

#import <Foundation/Foundation.h>
#import <WuKongIMSDK/WuKongIMSDK.h>

NS_ASSUME_NONNULL_BEGIN

@class WKRTCChannelStateResp;

/// RTC 会话变化通知，通话页通过该通知刷新 UI。
FOUNDATION_EXPORT NSString * const WKRTCSessionDidChangeNotification;

/// LiveKit 参与者变化通知，通话页通过该通知刷新远端画面。
FOUNDATION_EXPORT NSString * const WKRTCMediaParticipantsDidChangeNotification;

/// RTC 群聊普通通知，业务侧可按需在会话顶部展示“正在通话”入口。
FOUNDATION_EXPORT NSString * const WKRTCNoticeDidReceiveNotification;

/// RTC 频道通话状态变化通知，会话页据此刷新顶部入口。
FOUNDATION_EXPORT NSString * const WKRTCChannelCallDidChangeNotification;

/// RTC 媒体成员加入或离开通知，通话页和会话管理器用它处理群聊提示和私聊挂断。
FOUNDATION_EXPORT NSString * const WKRTCMediaParticipantPresenceDidChangeNotification;

/// 媒体成员加入事件。
FOUNDATION_EXPORT NSString * const WKRTCMediaParticipantPresenceActionJoined;

/// 媒体成员离开事件。
FOUNDATION_EXPORT NSString * const WKRTCMediaParticipantPresenceActionLeft;

/// 本地通话状态。
typedef NS_ENUM(NSInteger, WKRTCCallState) {
    WKRTCCallStateIdle = 0,             // 当前没有通话。
    WKRTCCallStateOutgoingRinging,      // 已发起通话，等待对方接听。
    WKRTCCallStateIncomingRinging,      // 收到来电或强邀请，等待本机处理。
    WKRTCCallStateJoining,              // 正在调用 join 接口。
    WKRTCCallStateConnecting,           // 已拿到 token，正在连接 LiveKit。
    WKRTCCallStateActive,               // LiveKit 已连接，通话进行中。
    WKRTCCallStateReconnecting,         // LiveKit 正在重连。
    WKRTCCallStateEnding,               // 正在调用结束类接口。
    WKRTCCallStateEnded,                // 通话已结束。
    WKRTCCallStateFailed                // 通话失败。
};

/// RTC 通话类型。
typedef NS_ENUM(NSInteger, WKRTCCallType) {
    WKRTCCallTypeAudio = 0,             // 语音通话。
    WKRTCCallTypeVideo                  // 视频通话。
};

/// LiveKit 连接信息，只允许来自后端 HTTP 响应。
@interface WKRTCLiveKitInfo : NSObject

@property(nonatomic,copy) NSString *url;
@property(nonatomic,copy) NSString *token;

+ (instancetype)modelWithDictionary:(NSDictionary *)dictionary;

@end

/// 发起、加入接口返回的通话对象。
@interface WKRTCCallResp : NSObject

@property(nonatomic,copy) NSString *callId;
@property(nonatomic,assign) BOOL existing;
@property(nonatomic,copy) NSString *roomName;
@property(nonatomic,assign) NSTimeInterval expireAt;
@property(nonatomic,copy) NSString *status;
@property(nonatomic,strong) NSArray<NSString *> *permissions;
@property(nonatomic,strong) WKRTCLiveKitInfo *livekit;

+ (instancetype)modelWithDictionary:(NSDictionary *)dictionary;
- (BOOL)hasPermission:(NSString *)permission;

@end

/// IM CMD、离线推送里的 rtc_call payload。
@interface WKRTCCallPayload : NSObject

@property(nonatomic,copy) NSString *callId;
@property(nonatomic,copy) NSString *roomName;
@property(nonatomic,copy) NSString *channelId;
@property(nonatomic,assign) WKChannelType channelType;
@property(nonatomic,assign) WKRTCCallType callType;
@property(nonatomic,copy) NSString *fromUid;
@property(nonatomic,copy) NSString *fromName;
@property(nonatomic,strong) NSArray<NSString *> *inviteUids;
@property(nonatomic,assign) NSTimeInterval expireAt;
@property(nonatomic,copy) NSString *answerUid;
@property(nonatomic,copy) NSString *answerDeviceId;
@property(nonatomic,copy) NSString *reason;

+ (instancetype)modelWithDictionary:(NSDictionary *)dictionary;
+ (instancetype)payloadWithChannel:(WKChannel *)channel callType:(WKRTCCallType)callType;
+ (instancetype)payloadWithChannelState:(WKRTCChannelStateResp *)state channel:(WKChannel *)channel;
- (NSString *)callTypeString;
- (NSDictionary *)toDictionary;

@end

/// 频道当前通话状态查询结果。
@interface WKRTCChannelStateResp : NSObject

@property(nonatomic,assign) BOOL existing;
@property(nonatomic,copy) NSString *callId;
@property(nonatomic,copy) NSString *roomName;
@property(nonatomic,copy) NSString *status;
@property(nonatomic,assign) WKRTCCallType callType;
@property(nonatomic,copy) NSString *fromUid;
@property(nonatomic,strong) NSArray<NSString *> *inviteUids;
@property(nonatomic,assign) NSTimeInterval expireAt;

+ (instancetype)modelWithDictionary:(NSDictionary *)dictionary;

@end

/// 一次性加入码创建结果。
@interface WKRTCJoinCodeResp : NSObject

@property(nonatomic,copy) NSString *callId;
@property(nonatomic,copy) NSString *joinCode;
@property(nonatomic,assign) NSTimeInterval expireAt;

+ (instancetype)modelWithDictionary:(NSDictionary *)dictionary;

@end

/// 媒体参与者状态，来自 LiveKit 本地回调，不依赖服务端扩展字段。
@interface WKRTCMediaParticipantState : NSObject

@property(nonatomic,copy) NSString *participantId;       // 参与者身份，通常是用户 UID。
@property(nonatomic,copy) NSString *networkQuality;      // 网络质量：unknown/lost/poor/good/excellent。
@property(nonatomic,assign) float audioLevel;            // 音量等级，取值由 LiveKit 返回。
@property(nonatomic,assign) BOOL speaking;               // 是否正在说话。
@property(nonatomic,assign) BOOL videoEnabled;           // 摄像头是否开启。

@end

/// RTC 错误构造，确保提示文案能直接用于 UI。
FOUNDATION_EXPORT NSError *WKRTCError(NSInteger code, NSString *message);

/// 将后端错误或系统错误转换成可展示的中文错误。
FOUNDATION_EXPORT NSError *WKRTCNormalizeError(NSError *error, NSString *fallbackMessage);

/// 将 LiveKit identity 转换为业务 UID；LiveKit identity 可能是 uid:device_id。
FOUNDATION_EXPORT NSString *WKRTCUIDFromParticipantID(NSString *_Nullable participantId);

/// 将用户 UID 转换为当前本地已知的展示昵称，取不到时返回 UID。
FOUNDATION_EXPORT NSString *WKRTCDisplayNameForUID(NSString *_Nullable uid);

/// 当前本地已知的用户头像 URL，取不到显式头像时回退到默认头像接口。
FOUNDATION_EXPORT NSString *WKRTCAvatarURLForUID(NSString *_Nullable uid);

/// 通话类型字符串转本地枚举。
FOUNDATION_EXPORT WKRTCCallType WKRTCCallTypeFromString(NSString *_Nullable callType);

NS_ASSUME_NONNULL_END

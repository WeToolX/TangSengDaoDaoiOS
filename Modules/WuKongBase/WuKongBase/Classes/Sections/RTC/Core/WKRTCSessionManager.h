//
//  WKRTCSessionManager.h
//  WuKongBase
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <WuKongIMSDK/WuKongIMSDK.h>
#import "WKRTCModels.h"
#import "WKRTCMediaAdapter.h"

NS_ASSUME_NONNULL_BEGIN

/// RTC 会话管理器，统一处理发起、接听、挂断、IM CMD 和 VoIP push。
@interface WKRTCSessionManager : NSObject

+ (instancetype)shared;

@property(nonatomic,strong,nullable,readonly) WKRTCCallPayload *currentPayload;
@property(nonatomic,strong,readonly) WKRTCMediaAdapter *mediaAdapter;
@property(nonatomic,assign,readonly) WKRTCCallState state;
@property(nonatomic,assign) BOOL audioEnabled;
@property(nonatomic,assign) BOOL videoEnabled;
@property(nonatomic,assign) BOOL speakerEnabled;

/// 发起语音或视频通话。
- (void)startCallWithChannel:(WKChannel *)channel callType:(WKRTCCallType)callType inviteUids:(NSArray<NSString *> *_Nullable)inviteUids;

/// 处理在线 IM CMD。
- (void)handleRTCCommand:(NSString *)cmd param:(NSDictionary *)param;

/// 处理 PushKit / APNs 中的 RTC payload。
- (void)handleRemotePayload:(NSDictionary *)payload reportCallKit:(BOOL)reportCallKit completion:(void(^_Nullable)(void))completion;

/// 接听当前来电。
- (void)acceptIncomingCallWithCompletion:(void(^_Nullable)(NSError *_Nullable error))completion;

/// 加入指定通话，用于群聊顶部入口、持久通知入口和加入码入口。
- (void)joinCallWithPayload:(WKRTCCallPayload *)payload joinCode:(NSString *_Nullable)joinCode completion:(void(^_Nullable)(NSError *_Nullable error))completion;

/// 拒绝当前来电。
- (void)rejectIncomingCall;

/// 挂断、取消或离开当前通话，具体接口按当前状态和权限选择。
- (void)hangup;

/// 当前通话时长，单位秒。
- (NSInteger)currentCallDuration;

/// 指定通话是否已经在本端收到结束类命令，用于群通话通知消息隐藏加入入口。
- (BOOL)isCallEnded:(NSString *)callId;

/// 收起通话页后展示悬浮通话入口。私聊视频使用系统画中画，语音和群通话使用悬浮按钮。
- (void)showFloatingCall;

/// 收起视频通话页后启动 iOS 原生画中画。
- (void)showPictureInPictureFromSourceView:(UIView *)sourceView completion:(void(^_Nullable)(NSError *_Nullable error))completion;

/// 视频通话页展示后提前准备 iOS 原生画中画控制器。
- (void)preparePictureInPictureFromSourceView:(UIView *)sourceView;

@end

NS_ASSUME_NONNULL_END

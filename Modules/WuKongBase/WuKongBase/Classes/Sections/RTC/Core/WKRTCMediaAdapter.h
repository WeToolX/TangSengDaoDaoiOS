//
//  WKRTCMediaAdapter.h
//  WuKongBase
//

#import <UIKit/UIKit.h>
#import "WKRTCModels.h"

NS_ASSUME_NONNULL_BEGIN

/// 媒体引擎连接状态，避免 ObjC 侧直接依赖 LiveKit 类型。
typedef NSString * WKRTCMediaEngineState NS_TYPED_EXTENSIBLE_ENUM;
FOUNDATION_EXPORT WKRTCMediaEngineState const WKRTCMediaEngineStateConnected;
FOUNDATION_EXPORT WKRTCMediaEngineState const WKRTCMediaEngineStateReconnecting;
FOUNDATION_EXPORT WKRTCMediaEngineState const WKRTCMediaEngineStateDisconnected;
FOUNDATION_EXPORT WKRTCMediaEngineState const WKRTCMediaEngineStateFailed;

/// App Target 内的 Swift LiveKit 桥接类实现该协议，Pod 内代码只依赖协议。
@protocol WKRTCMediaEngine <NSObject>

- (void)connectWithURL:(NSString *)url
                 token:(NSString *)token
          audioEnabled:(BOOL)audioEnabled
          videoEnabled:(BOOL)videoEnabled
            completion:(void(^)(NSError *_Nullable error))completion;

- (void)disconnectWithCompletion:(void(^_Nullable)(void))completion;
- (void)setAudioEnabled:(BOOL)enabled completion:(void(^_Nullable)(NSError *_Nullable error))completion;
- (void)setVideoEnabled:(BOOL)enabled completion:(void(^_Nullable)(NSError *_Nullable error))completion;
- (void)switchCameraWithCompletion:(void(^_Nullable)(NSError *_Nullable error))completion;
- (void)preparePictureInPictureWithSourceView:(UIView *)sourceView;
- (void)startPictureInPictureWithSourceView:(UIView *)sourceView completion:(void(^_Nullable)(NSError *_Nullable error))completion;
- (void)stopPictureInPictureWithCompletion:(void(^_Nullable)(void))completion;
- (UIView *)localVideoView;
- (UIView *)remoteVideoView;
- (NSArray<NSString *> *)currentParticipants;
- (NSDictionary<NSString *, WKRTCMediaParticipantState *> *)participantStates;
- (void)setRemoteParticipant:(NSString *)participantId videoView:(UIView *)videoView;
- (void)setVisibleRemoteParticipants:(NSArray<NSString *> *)participantIds;
- (void)setStateChangedHandler:(void(^_Nullable)(WKRTCMediaEngineState state, NSError *_Nullable error))handler;

@end

/// 媒体适配器负责把业务会话和真实 LiveKit 引擎隔离开。
@interface WKRTCMediaAdapter : NSObject

/// App 启动时必须注册，用于创建真实 LiveKit 引擎。
@property(class,nonatomic,copy,nullable) id<WKRTCMediaEngine> (^engineFactory)(void);

@property(nonatomic,copy,nullable) void(^stateChanged)(WKRTCMediaEngineState state, NSError *_Nullable error);

- (void)connectWithURL:(NSString *)url
                 token:(NSString *)token
          audioEnabled:(BOOL)audioEnabled
          videoEnabled:(BOOL)videoEnabled
            completion:(void(^)(NSError *_Nullable error))completion;

- (void)disconnectWithCompletion:(void(^_Nullable)(void))completion;
- (void)setAudioEnabled:(BOOL)enabled completion:(void(^_Nullable)(NSError *_Nullable error))completion;
- (void)setVideoEnabled:(BOOL)enabled completion:(void(^_Nullable)(NSError *_Nullable error))completion;
- (void)switchCameraWithCompletion:(void(^_Nullable)(NSError *_Nullable error))completion;
- (void)preparePictureInPictureWithSourceView:(UIView *)sourceView;
- (void)startPictureInPictureWithSourceView:(UIView *)sourceView completion:(void(^_Nullable)(NSError *_Nullable error))completion;
- (void)stopPictureInPictureWithCompletion:(void(^_Nullable)(void))completion;
- (UIView *)localVideoView;
- (UIView *)remoteVideoView;
- (NSArray<NSString *> *)currentParticipants;
- (NSDictionary<NSString *, WKRTCMediaParticipantState *> *)participantStates;
- (void)setRemoteParticipant:(NSString *)participantId videoView:(UIView *)videoView;
- (void)setVisibleRemoteParticipants:(NSArray<NSString *> *)participantIds;

@end

NS_ASSUME_NONNULL_END

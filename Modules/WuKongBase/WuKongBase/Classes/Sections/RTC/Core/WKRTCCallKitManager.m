//
//  WKRTCCallKitManager.m
//  WuKongBase
//

#import "WKRTCCallKitManager.h"
#import <CallKit/CallKit.h>
#import <AVFoundation/AVFoundation.h>
#import "WKRTCSessionManager.h"
#import "WKRTCAudioRouteManager.h"
#import "WKLogs.h"

@interface WKRTCCallKitManager ()<CXProviderDelegate>

@property(nonatomic,strong) CXProvider *provider;
@property(nonatomic,strong) CXCallController *callController;
@property(nonatomic,strong) NSMutableDictionary<NSString *, NSUUID *> *callIdToUUID;
@property(nonatomic,strong) NSMutableDictionary<NSUUID *, NSString *> *uuidToCallId;

@end

@implementation WKRTCCallKitManager

+ (instancetype)shared {
    static WKRTCCallKitManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [WKRTCCallKitManager new];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if(!self) return nil;
    _callController = [CXCallController new];
    _callIdToUUID = [NSMutableDictionary dictionary];
    _uuidToCallId = [NSMutableDictionary dictionary];
    [self setupProvider];
    return self;
}

- (void)setupProvider {
    CXProviderConfiguration *config = [[CXProviderConfiguration alloc] initWithLocalizedName:@"唐僧叨叨"];
    config.supportsVideo = YES;
    config.maximumCallsPerCallGroup = 1;
    config.maximumCallGroups = 1;
    config.supportedHandleTypes = [NSSet setWithObject:@(CXHandleTypeGeneric)];
    self.provider = [[CXProvider alloc] initWithConfiguration:config];
    [self.provider setDelegate:self queue:dispatch_get_main_queue()];
}

- (void)reportIncomingCall:(WKRTCCallPayload *)payload completion:(void (^)(NSError * _Nullable))completion {
    if(payload.callId.length == 0) {
        if(completion) completion(WKRTCError(-1, @"通话 ID 不能为空"));
        return;
    }
    NSUUID *uuid = self.callIdToUUID[payload.callId] ?: [NSUUID UUID];
    self.callIdToUUID[payload.callId] = uuid;
    self.uuidToCallId[uuid] = payload.callId;
    
    CXCallUpdate *update = [CXCallUpdate new];
    NSString *displayName = payload.fromName.length > 0 ? payload.fromName : (payload.fromUid.length > 0 ? payload.fromUid : @"音视频通话");
    update.remoteHandle = [[CXHandle alloc] initWithType:CXHandleTypeGeneric value:displayName];
    update.localizedCallerName = displayName;
    update.hasVideo = payload.callType == WKRTCCallTypeVideo;
    update.supportsHolding = NO;
    update.supportsGrouping = NO;
    update.supportsUngrouping = NO;
    update.supportsDTMF = NO;
    
    WKLogDebug(@"音视频向系统通话上报来电，通话编号：%@", payload.callId);
    [self.provider reportNewIncomingCallWithUUID:uuid update:update completion:^(NSError * _Nullable error) {
        if(error) {
            WKLogError(@"音视频系统通话上报来电失败：%@", error);
        }
        if(completion) completion(error);
    }];
}

- (void)endCallIfNeeded:(NSString *)callId reason:(NSString *)reason {
    if(callId.length == 0) {
        return;
    }
    NSUUID *uuid = self.callIdToUUID[callId];
    if(!uuid) {
        return;
    }
    WKLogDebug(@"音视频结束系统通话，通话编号：%@，原因：%@", callId, reason ?: @"");
    CXEndCallAction *action = [[CXEndCallAction alloc] initWithCallUUID:uuid];
    CXTransaction *transaction = [[CXTransaction alloc] initWithAction:action];
    [self.callController requestTransaction:transaction completion:^(NSError * _Nullable error) {
        if(error) {
            WKLogError(@"音视频请求系统通话结束失败：%@", error);
        }
    }];
    [self removeCallMapping:uuid];
}

- (void)removeCallMapping:(NSUUID *)uuid {
    NSString *callId = self.uuidToCallId[uuid];
    if(callId.length > 0) {
        [self.callIdToUUID removeObjectForKey:callId];
    }
    [self.uuidToCallId removeObjectForKey:uuid];
}

#pragma mark - CXProviderDelegate

- (void)providerDidReset:(CXProvider *)provider {
    WKLogDebug(@"音视频系统通话服务已重置");
    [self.callIdToUUID removeAllObjects];
    [self.uuidToCallId removeAllObjects];
}

- (void)provider:(CXProvider *)provider performAnswerCallAction:(CXAnswerCallAction *)action {
    NSString *callId = self.uuidToCallId[action.callUUID];
    if(callId.length == 0) {
        [action fail];
        return;
    }
    WKLogDebug(@"音视频系统通话接听动作，通话编号：%@", callId);
    [[WKRTCSessionManager shared] acceptIncomingCallWithCompletion:^(NSError * _Nullable error) {
        if(error) {
            [action fail];
        }else {
            [action fulfill];
        }
    }];
}

- (void)provider:(CXProvider *)provider performEndCallAction:(CXEndCallAction *)action {
    NSString *callId = self.uuidToCallId[action.callUUID];
    WKLogDebug(@"音视频系统通话结束动作，通话编号：%@", callId ?: @"");
    if(callId.length > 0) {
        WKRTCSessionManager *session = [WKRTCSessionManager shared];
        if([session.currentPayload.callId isEqualToString:callId]) {
            if(session.state == WKRTCCallStateIncomingRinging) {
                [session rejectIncomingCall];
            }else {
                [session hangup];
            }
        }
    }
    [self removeCallMapping:action.callUUID];
    [action fulfill];
}

- (void)provider:(CXProvider *)provider didActivateAudioSession:(AVAudioSession *)audioSession {
    WKLogDebug(@"音视频系统通话已激活音频会话");
    [[WKRTCAudioRouteManager shared] prepareAudioSessionForCallType:[WKRTCSessionManager shared].currentPayload.callType];
}

- (void)provider:(CXProvider *)provider didDeactivateAudioSession:(AVAudioSession *)audioSession {
    WKLogDebug(@"音视频系统通话已停用音频会话");
}

@end

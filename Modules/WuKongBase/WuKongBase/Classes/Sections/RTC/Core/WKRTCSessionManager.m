//
//  WKRTCSessionManager.m
//  WuKongBase
//

#import "WKRTCSessionManager.h"
#import <AVFoundation/AVFoundation.h>
#import "WKRTCAPI.h"
#import "WKRTCAudioRouteManager.h"
#import "WKRTCCallKitManager.h"
#import "WKRTCCallViewController.h"
#import "WKNavigationManager.h"
#import "WKApp.h"
#import "WKLogs.h"
#import <Toast/UIView+Toast.h>

static NSString * const WKRTCCMDInvite = @"rtc.invite";
static NSString * const WKRTCCMDNotice = @"rtc.notice";
static NSString * const WKRTCCMDJoined = @"rtc.joined";
static NSString * const WKRTCCMDRejected = @"rtc.rejected";
static NSString * const WKRTCCMDCancelled = @"rtc.cancelled";
static NSString * const WKRTCCMDClosed = @"rtc.closed";
static NSString * const WKRTCCMDTimeout = @"rtc.timeout";
static NSString * const WKRTCPictureInPictureRestoreRequestedNotification = @"WKRTCPictureInPictureRestoreRequested";

@interface WKRTCFloatingCallView : UIControl

@property(nonatomic,strong) UIView *videoHost;
@property(nonatomic,strong) UILabel *titleLabel;
@property(nonatomic,strong) UILabel *subtitleLabel;
@property(nonatomic,strong) UILabel *iconLabel;
@property(nonatomic,assign) BOOL videoMode;
@property(nonatomic,assign) CGPoint panStartCenter;

- (void)configureWithPayload:(WKRTCCallPayload *)payload duration:(NSInteger)duration;

@end

@implementation WKRTCFloatingCallView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(!self) return nil;
    self.backgroundColor = [UIColor colorWithWhite:0.04f alpha:0.92f];
    self.layer.cornerRadius = 12.0f;
    self.layer.masksToBounds = YES;
    self.layer.borderWidth = 1.0f;
    self.layer.borderColor = [UIColor colorWithWhite:1.0f alpha:0.16f].CGColor;
    
    _videoHost = [[UIView alloc] init];
    _videoHost.backgroundColor = UIColor.blackColor;
    _videoHost.clipsToBounds = YES;
    _videoHost.userInteractionEnabled = NO;
    [self addSubview:_videoHost];
    
    _iconLabel = [[UILabel alloc] init];
    _iconLabel.backgroundColor = [UIColor colorWithRed:0.02f green:0.76f blue:0.38f alpha:1.0f];
    _iconLabel.textColor = UIColor.whiteColor;
    _iconLabel.textAlignment = NSTextAlignmentCenter;
    _iconLabel.font = [UIFont systemFontOfSize:18.0f weight:UIFontWeightSemibold];
    _iconLabel.layer.masksToBounds = YES;
    _iconLabel.userInteractionEnabled = NO;
    [self addSubview:_iconLabel];
    
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.textColor = UIColor.whiteColor;
    _titleLabel.font = [UIFont systemFontOfSize:13.0f weight:UIFontWeightSemibold];
    _titleLabel.userInteractionEnabled = NO;
    [self addSubview:_titleLabel];
    
    _subtitleLabel = [[UILabel alloc] init];
    _subtitleLabel.textColor = [UIColor colorWithWhite:1.0f alpha:0.76f];
    _subtitleLabel.font = [UIFont systemFontOfSize:11.0f weight:UIFontWeightRegular];
    _subtitleLabel.userInteractionEnabled = NO;
    [self addSubview:_subtitleLabel];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    pan.cancelsTouchesInView = YES;
    [self addGestureRecognizer:pan];
    return self;
}

- (void)configureWithPayload:(WKRTCCallPayload *)payload duration:(NSInteger)duration {
    self.videoMode = payload.callType == WKRTCCallTypeVideo && payload.channelType != WK_GROUP;
    BOOL videoCall = payload.callType == WKRTCCallTypeVideo;
    NSString *typeText = videoCall ? @"视频通话" : @"语音通话";
    self.titleLabel.text = payload.channelType == WK_GROUP ? [NSString stringWithFormat:@"群%@", typeText] : typeText;
    self.subtitleLabel.text = duration > 0 ? [NSString stringWithFormat:@"%02ld:%02ld", (long)(duration / 60), (long)(duration % 60)] : @"通话中";
    self.iconLabel.text = videoCall ? @"视" : @"语";
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if(self.videoMode) {
        self.videoHost.hidden = NO;
        self.iconLabel.hidden = YES;
        self.videoHost.frame = self.bounds;
        self.titleLabel.hidden = YES;
        self.subtitleLabel.hidden = YES;
    }else {
        self.videoHost.hidden = YES;
        self.iconLabel.hidden = NO;
        self.titleLabel.hidden = NO;
        self.subtitleLabel.hidden = NO;
        self.iconLabel.frame = CGRectMake(10.0f, 8.0f, 40.0f, 40.0f);
        self.iconLabel.layer.cornerRadius = 20.0f;
        self.titleLabel.frame = CGRectMake(60.0f, 9.0f, self.bounds.size.width - 68.0f, 20.0f);
        self.subtitleLabel.frame = CGRectMake(60.0f, 31.0f, self.bounds.size.width - 68.0f, 16.0f);
        self.titleLabel.backgroundColor = UIColor.clearColor;
        self.subtitleLabel.backgroundColor = UIColor.clearColor;
    }
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    UIView *superview = self.superview;
    if(!superview) return;
    if(gesture.state == UIGestureRecognizerStateBegan) {
        self.panStartCenter = self.center;
    }
    CGPoint translation = [gesture translationInView:superview];
    CGPoint target = CGPointMake(self.panStartCenter.x + translation.x, self.panStartCenter.y + translation.y);
    CGFloat halfW = self.bounds.size.width / 2.0f;
    CGFloat halfH = self.bounds.size.height / 2.0f;
    CGFloat top = 12.0f + superview.safeAreaInsets.top;
    CGFloat bottom = superview.bounds.size.height - 12.0f - superview.safeAreaInsets.bottom;
    target.x = MAX(halfW + 8.0f, MIN(superview.bounds.size.width - halfW - 8.0f, target.x));
    target.y = MAX(top + halfH, MIN(bottom - halfH, target.y));
    self.center = target;
}

@end

@interface WKRTCSessionManager ()

@property(nonatomic,strong,readwrite) WKRTCCallPayload *currentPayload;
@property(nonatomic,strong,readwrite) WKRTCMediaAdapter *mediaAdapter;
@property(nonatomic,assign,readwrite) WKRTCCallState state;
@property(nonatomic,strong) WKRTCCallResp *currentCallResp;
@property(nonatomic,assign) NSTimeInterval connectedAt;
@property(nonatomic,assign) BOOL ending;
@property(nonatomic,assign) NSUInteger sessionGeneration;
@property(nonatomic,strong) AVAudioPlayer *ringtonePlayer;
@property(nonatomic,strong) WKRTCFloatingCallView *floatingCallView;
@property(nonatomic,strong) NSMutableSet<NSString *> *endedCallIds;

@end

@implementation WKRTCSessionManager

+ (instancetype)shared {
    static WKRTCSessionManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [WKRTCSessionManager new];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if(!self) return nil;
    _state = WKRTCCallStateIdle;
    _audioEnabled = YES;
    _videoEnabled = YES;
    _sessionGeneration = 1;
    _endedCallIds = [NSMutableSet set];
    [self resetMediaAdapter];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaParticipantPresenceChanged:) name:WKRTCMediaParticipantPresenceDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pictureInPictureRestoreRequested:) name:WKRTCPictureInPictureRestoreRequestedNotification object:nil];
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)startCallWithChannel:(WKChannel *)channel callType:(WKRTCCallType)callType inviteUids:(NSArray<NSString *> *)inviteUids {
    if(!channel || channel.channelId.length == 0) {
        [self showToast:@"频道信息不能为空"];
        return;
    }
    if(self.state != WKRTCCallStateIdle && self.state != WKRTCCallStateEnded && self.state != WKRTCCallStateFailed) {
        [self showToast:@"当前已有通话"];
        return;
    }
    [self requestPermissionForCallType:callType completion:^(BOOL granted) {
        if(!granted) {
            [self showToast:callType == WKRTCCallTypeVideo ? @"请先开启麦克风和摄像头权限" : @"请先开启麦克风权限"];
            return;
        }
        NSString *requestId = NSUUID.UUID.UUIDString;
        WKRTCCallPayload *payload = [WKRTCCallPayload payloadWithChannel:channel callType:callType];
        payload.inviteUids = inviteUids ?: @[];
        NSUInteger generation = [self beginNewSessionGeneration];
        [self clearEndedCallId:payload.callId];
        self.currentPayload = payload;
        self.audioEnabled = YES;
        self.videoEnabled = callType == WKRTCCallTypeVideo;
        [self changeState:WKRTCCallStateConnecting];
        WKLogDebug(@"音视频发起通话，频道：%@，请求编号：%@", channel.channelId, requestId);
        [[WKRTCAPI shared] startCallWithChannelId:channel.channelId channelType:channel.channelType callType:callType inviteUids:inviteUids requestId:requestId].then(^(WKRTCCallResp *resp){
            if(![self isSessionGeneration:generation validForPayload:payload]) {
                WKLogDebug(@"音视频忽略已失效的发起通话响应：%@", resp.callId);
                return;
            }
            [self applyCallResponse:resp toPayload:payload];
            self.currentCallResp = resp;
            self.state = channel.channelType == WK_GROUP ? WKRTCCallStateActive : WKRTCCallStateOutgoingRinging;
            [self notifyChange];
            [self presentCallViewControllerIfNeeded];
            [self connectLiveKitWithResp:resp payload:payload activeAfterConnected:(channel.channelType == WK_GROUP) sessionGeneration:generation];
        }).catch(^(NSError *error){
            if(![self isSessionGeneration:generation validForPayload:payload]) {
                WKLogDebug(@"音视频忽略已失效的发起通话失败回调：%@", error.localizedDescription);
                return;
            }
            WKLogError(@"音视频发起通话失败：%@", error);
            [self finishWithState:WKRTCCallStateFailed reason:error.localizedDescription ?: @"发起通话失败" notifyCallKit:NO];
            [self showToast:error.localizedDescription ?: @"发起通话失败"];
        });
    }];
}

- (void)handleRTCCommand:(NSString *)cmd param:(NSDictionary *)param {
    if(cmd.length == 0 || ![param isKindOfClass:NSDictionary.class]) {
        return;
    }
    if(![cmd hasPrefix:@"rtc."]) {
        return;
    }
    WKRTCCallPayload *payload = [WKRTCCallPayload modelWithDictionary:param];
    WKLogDebug(@"音视频收到即时消息命令：%@，通话编号：%@", cmd, payload.callId);
    BOOL ignoredCancel = [cmd isEqualToString:WKRTCCMDCancelled] && [self shouldIgnoreCancelPayload:payload];
    if([self isEndCommand:cmd] && !ignoredCancel) {
        [self markCallEnded:payload.callId];
    }else if([cmd isEqualToString:WKRTCCMDInvite] || [cmd isEqualToString:WKRTCCMDNotice] || [cmd isEqualToString:WKRTCCMDJoined]) {
        [self clearEndedCallId:payload.callId];
    }
    [self postChannelCallChangeWithCommand:cmd payload:payload];
    if([cmd isEqualToString:WKRTCCMDInvite]) {
        [self receiveIncomingPayload:payload reportCallKit:NO];
    }else if([cmd isEqualToString:WKRTCCMDNotice]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:WKRTCNoticeDidReceiveNotification object:payload userInfo:[payload toDictionary]];
    }else if([cmd isEqualToString:WKRTCCMDJoined]) {
        if([self isCurrentCall:payload.callId]) {
            [self changeState:WKRTCCallStateActive];
        }
    }else if([cmd isEqualToString:WKRTCCMDRejected]) {
        if([self isCurrentCall:payload.callId]) {
            [self finishWithState:WKRTCCallStateEnded reason:@"对方已拒绝" notifyCallKit:YES];
        }
    }else if([cmd isEqualToString:WKRTCCMDCancelled]) {
        if(ignoredCancel) {
            WKLogDebug(@"音视频忽略本设备已接听产生的取消通知");
            return;
        }
        if([self isCurrentCall:payload.callId]) {
            NSString *reason = [payload.reason isEqualToString:@"answered_on_other_device"] ? @"已在其他设备接听" : @"通话已取消";
            [self finishWithState:WKRTCCallStateEnded reason:reason notifyCallKit:YES];
        }
    }else if([cmd isEqualToString:WKRTCCMDClosed]) {
        if([self isCurrentCall:payload.callId]) {
            [self finishWithState:WKRTCCallStateEnded reason:@"通话已结束" notifyCallKit:YES];
        }
    }else if([cmd isEqualToString:WKRTCCMDTimeout]) {
        if([self isCurrentCall:payload.callId]) {
            [self finishWithState:WKRTCCallStateEnded reason:@"通话已超时" notifyCallKit:YES];
        }
    }
}

- (void)handleRemotePayload:(NSDictionary *)payload reportCallKit:(BOOL)reportCallKit completion:(void (^)(void))completion {
    NSDictionary *rtcCall = nil;
    if([payload[@"rtc_call"] isKindOfClass:NSDictionary.class]) {
        rtcCall = payload[@"rtc_call"];
    }else if([payload[@"call_id"] isKindOfClass:NSString.class]) {
        rtcCall = payload;
    }
    if(!rtcCall) {
        WKLogDebug(@"音视频推送中没有通话字段");
        if(completion) completion();
        return;
    }
    WKRTCCallPayload *callPayload = [WKRTCCallPayload modelWithDictionary:rtcCall];
    [self receiveIncomingPayload:callPayload reportCallKit:reportCallKit];
    if(completion) completion();
}

- (void)acceptIncomingCallWithCompletion:(void (^)(NSError * _Nullable))completion {
    if(self.currentPayload.callId.length == 0) {
        if(completion) completion(WKRTCError(-1, @"通话不存在"));
        return;
    }
    WKRTCCallPayload *payload = self.currentPayload;
    [self requestPermissionForCallType:payload.callType completion:^(BOOL granted) {
        if(!granted) {
            NSError *error = WKRTCError(-1, payload.callType == WKRTCCallTypeVideo ? @"请先开启麦克风和摄像头权限" : @"请先开启麦克风权限");
            if(completion) completion(error);
            return;
        }
        [self stopRingtone];
        [self changeState:WKRTCCallStateJoining];
        NSUInteger generation = self.sessionGeneration;
        [[WKRTCAPI shared] joinCall:payload.callId joinCode:@""].then(^(WKRTCCallResp *resp){
            if(![self isSessionGeneration:generation validForPayload:payload]) {
                WKLogDebug(@"音视频忽略已失效的接听响应：%@", resp.callId);
                if(completion) completion(WKRTCError(-1, @"通话已结束"));
                return;
            }
            [self applyCallResponse:resp toPayload:payload];
            self.currentCallResp = resp;
            [self connectLiveKitWithResp:resp payload:payload activeAfterConnected:YES sessionGeneration:generation completion:completion];
        }).catch(^(NSError *error){
            if(![self isSessionGeneration:generation validForPayload:payload]) {
                WKLogDebug(@"音视频忽略已失效的接听失败回调：%@", error.localizedDescription);
                if(completion) completion(WKRTCError(-1, @"通话已结束"));
                return;
            }
            NSError *safeError = WKRTCNormalizeError(error, @"接听失败");
            WKLogError(@"音视频接听失败：%@", safeError);
            [self finishWithState:WKRTCCallStateFailed reason:safeError.localizedDescription notifyCallKit:YES];
            if(completion) completion(safeError);
        });
    }];
}

- (void)joinCallWithPayload:(WKRTCCallPayload *)payload joinCode:(NSString *)joinCode completion:(void (^)(NSError * _Nullable))completion {
    if(payload.callId.length == 0) {
        NSError *error = WKRTCError(-1, @"通话编号不能为空");
        if(completion) completion(error);
        return;
    }
    if(self.state != WKRTCCallStateIdle && self.state != WKRTCCallStateEnded && self.state != WKRTCCallStateFailed) {
        if([self isCurrentCall:payload.callId]) {
            [self presentCallViewControllerIfNeeded];
            if(completion) completion(nil);
            return;
        }
        NSError *error = WKRTCError(-1, @"当前已有通话");
        if(completion) completion(error);
        [self showToast:error.localizedDescription];
        return;
    }
    NSUInteger generation = [self beginNewSessionGeneration];
    [self clearEndedCallId:payload.callId];
    self.currentPayload = payload;
    self.currentCallResp = nil;
    self.audioEnabled = YES;
    self.videoEnabled = payload.callType == WKRTCCallTypeVideo;
    self.ending = NO;
    [self requestPermissionForCallType:payload.callType completion:^(BOOL granted) {
        if(!granted) {
            NSError *error = WKRTCError(-1, payload.callType == WKRTCCallTypeVideo ? @"请先开启麦克风和摄像头权限" : @"请先开启麦克风权限");
            if(completion) completion(error);
            [self showToast:error.localizedDescription];
            return;
        }
        [self changeState:WKRTCCallStateJoining];
        [self presentCallViewControllerIfNeeded];
        [[WKRTCAPI shared] joinCall:payload.callId joinCode:joinCode ?: @""].then(^(WKRTCCallResp *resp){
            if(![self isSessionGeneration:generation validForPayload:payload]) {
                WKLogDebug(@"音视频忽略已失效的加入通话响应：%@", resp.callId);
                if(completion) completion(WKRTCError(-1, @"通话已结束"));
                return;
            }
            [self applyCallResponse:resp toPayload:payload];
            self.currentCallResp = resp;
            [self connectLiveKitWithResp:resp payload:payload activeAfterConnected:YES sessionGeneration:generation completion:completion];
        }).catch(^(NSError *error){
            if(![self isSessionGeneration:generation validForPayload:payload]) {
                WKLogDebug(@"音视频忽略已失效的加入通话失败回调：%@", error.localizedDescription);
                if(completion) completion(WKRTCError(-1, @"通话已结束"));
                return;
            }
            NSError *safeError = WKRTCNormalizeError(error, @"加入通话失败");
            WKLogError(@"音视频加入通话失败：%@", safeError);
            [self finishWithState:WKRTCCallStateFailed reason:safeError.localizedDescription notifyCallKit:YES];
            if(completion) completion(safeError);
        });
    }];
}

- (void)rejectIncomingCall {
    if(self.currentPayload.callId.length == 0 || self.ending) {
        return;
    }
    [self stopRingtone];
    self.ending = YES;
    NSString *callId = self.currentPayload.callId;
    [self changeState:WKRTCCallStateEnding];
    [[WKRTCAPI shared] rejectCall:callId].then(^{
        [self finishWithState:WKRTCCallStateEnded reason:@"已拒绝" notifyCallKit:YES];
    }).catch(^(NSError *error){
        WKLogError(@"音视频拒绝通话失败：%@", error);
        [self finishWithState:WKRTCCallStateEnded reason:@"已拒绝" notifyCallKit:YES];
    });
}

- (void)hangup {
    if(self.currentPayload.callId.length == 0 || self.ending) {
        return;
    }
    [self stopRingtone];
    self.ending = YES;
    NSString *callId = self.currentPayload.callId;
    WKRTCCallState oldState = self.state;
    [self changeState:WKRTCCallStateEnding];
    
    AnyPromise *promise = nil;
    if(oldState == WKRTCCallStateOutgoingRinging || oldState == WKRTCCallStateConnecting) {
        promise = [[WKRTCAPI shared] cancelCall:callId];
    }else if(self.currentPayload.channelType == WK_GROUP && ![self.currentCallResp hasPermission:@"close"]) {
        promise = [[WKRTCAPI shared] leaveCall:callId];
    }else {
        promise = [[WKRTCAPI shared] closeCall:callId reason:@"hangup"];
    }
    
    promise.then(^{
        [self finishWithState:WKRTCCallStateEnded reason:@"通话已结束" notifyCallKit:YES];
    }).catch(^(NSError *error){
        WKLogError(@"音视频结束通话接口失败，本地仍断开房间：%@", error);
        [self finishWithState:WKRTCCallStateEnded reason:@"通话已结束" notifyCallKit:YES];
    });
}

- (NSInteger)currentCallDuration {
    if(self.connectedAt <= 0) {
        return 0;
    }
    return MAX(0, (NSInteger)(NSDate.date.timeIntervalSince1970 - self.connectedAt));
}

- (BOOL)isCallEnded:(NSString *)callId {
    if(callId.length == 0) {
        return NO;
    }
    @synchronized (self.endedCallIds) {
        return [self.endedCallIds containsObject:callId];
    }
}

- (void)showFloatingCall {
    dispatch_async(dispatch_get_main_queue(), ^{
        if(!self.currentPayload || self.state == WKRTCCallStateIdle || self.state == WKRTCCallStateEnded || self.state == WKRTCCallStateFailed) {
            return;
        }
        if(self.currentPayload.callType == WKRTCCallTypeVideo && self.currentPayload.channelType != WK_GROUP) {
            return;
        }
        UIWindow *window = [[WKApp shared] findWindow];
        if(!window) {
            window = UIApplication.sharedApplication.keyWindow;
        }
        if(!window) {
            return;
        }
        if(!self.floatingCallView) {
            self.floatingCallView = [[WKRTCFloatingCallView alloc] initWithFrame:CGRectZero];
            [self.floatingCallView addTarget:self action:@selector(floatingCallPressed) forControlEvents:UIControlEventTouchUpInside];
        }
        if(self.floatingCallView.superview != window) {
            [window addSubview:self.floatingCallView];
        }
        [self refreshFloatingCallView];
    });
}

- (void)showPictureInPictureFromSourceView:(UIView *)sourceView completion:(void (^)(NSError * _Nullable))completion {
    void (^startBlock)(void) = ^{
        if(!self.currentPayload || self.currentPayload.callType != WKRTCCallTypeVideo) {
            NSError *error = WKRTCError(-1, @"当前不是视频通话");
            if(completion) completion(error);
            return;
        }
        if(self.state == WKRTCCallStateIdle || self.state == WKRTCCallStateEnded || self.state == WKRTCCallStateFailed) {
            NSError *error = WKRTCError(-1, @"通话已结束");
            if(completion) completion(error);
            return;
        }
        [self hideFloatingCall];
        [self.mediaAdapter startPictureInPictureWithSourceView:sourceView completion:completion];
    };
    if(NSThread.isMainThread) {
        startBlock();
    }else {
        dispatch_async(dispatch_get_main_queue(), startBlock);
    }
}

- (void)preparePictureInPictureFromSourceView:(UIView *)sourceView {
    if(!sourceView || !self.currentPayload || self.currentPayload.callType != WKRTCCallTypeVideo) {
        return;
    }
    if(self.state == WKRTCCallStateIdle || self.state == WKRTCCallStateEnded || self.state == WKRTCCallStateFailed) {
        return;
    }
    [self.mediaAdapter preparePictureInPictureWithSourceView:sourceView];
}

#pragma mark - 内部状态

- (void)receiveIncomingPayload:(WKRTCCallPayload *)payload reportCallKit:(BOOL)reportCallKit {
    if(payload.callId.length == 0) {
        WKLogError(@"音视频来电数据缺少通话编号");
        return;
    }
    if(self.state != WKRTCCallStateIdle && self.state != WKRTCCallStateEnded && self.state != WKRTCCallStateFailed && ![self isCurrentCall:payload.callId]) {
        WKLogWarn(@"音视频当前已有通话，忽略新的来电：%@", payload.callId);
        return;
    }
    [self beginNewSessionGeneration];
    self.currentPayload = payload;
    self.currentCallResp = nil;
    self.audioEnabled = YES;
    self.videoEnabled = payload.callType == WKRTCCallTypeVideo;
    self.ending = NO;
    [self changeState:WKRTCCallStateIncomingRinging];
    [self presentCallViewControllerIfNeeded];
    if(reportCallKit) {
        [[WKRTCCallKitManager shared] reportIncomingCall:payload completion:nil];
    }
}

- (void)connectLiveKitWithResp:(WKRTCCallResp *)resp payload:(WKRTCCallPayload *)payload activeAfterConnected:(BOOL)activeAfterConnected {
    [self connectLiveKitWithResp:resp payload:payload activeAfterConnected:activeAfterConnected sessionGeneration:self.sessionGeneration completion:nil];
}

- (void)connectLiveKitWithResp:(WKRTCCallResp *)resp
                       payload:(WKRTCCallPayload *)payload
          activeAfterConnected:(BOOL)activeAfterConnected
             sessionGeneration:(NSUInteger)sessionGeneration {
    [self connectLiveKitWithResp:resp payload:payload activeAfterConnected:activeAfterConnected sessionGeneration:sessionGeneration completion:nil];
}

- (void)connectLiveKitWithResp:(WKRTCCallResp *)resp
                       payload:(WKRTCCallPayload *)payload
          activeAfterConnected:(BOOL)activeAfterConnected
             sessionGeneration:(NSUInteger)sessionGeneration
                    completion:(void(^_Nullable)(NSError *_Nullable error))completion {
    if(![self isSessionGeneration:sessionGeneration validForPayload:payload]) {
        NSError *error = WKRTCError(-1, @"通话已结束");
        WKLogDebug(@"音视频忽略已失效的媒体连接请求：%@", payload.callId);
        if(completion) completion(error);
        return;
    }
    if(resp.livekit.url.length == 0 || resp.livekit.token.length == 0) {
        NSError *error = WKRTCError(-1, @"媒体连接信息为空");
        [self finishWithState:WKRTCCallStateFailed reason:error.localizedDescription notifyCallKit:YES];
        if(completion) completion(error);
        return;
    }
    if(activeAfterConnected) {
        [self stopRingtone];
    }
    [self changeState:WKRTCCallStateConnecting];
    [[WKRTCAudioRouteManager shared] prepareAudioSessionForCallType:payload.callType];
    __weak typeof(self) weakSelf = self;
    self.mediaAdapter.stateChanged = ^(WKRTCMediaEngineState  _Nonnull state, NSError * _Nullable error) {
        [weakSelf handleMediaState:state error:error];
    };
    [self.mediaAdapter connectWithURL:resp.livekit.url token:resp.livekit.token audioEnabled:YES videoEnabled:(payload.callType == WKRTCCallTypeVideo) completion:^(NSError * _Nullable error) {
        if(![self isSessionGeneration:sessionGeneration validForPayload:payload]) {
            WKLogDebug(@"音视频忽略已失效的媒体连接回调：%@", payload.callId);
            if(completion) completion(WKRTCError(-1, @"通话已结束"));
            return;
        }
        if(error) {
            NSError *safeError = WKRTCNormalizeError(error, @"连接媒体房间失败");
            [self finishWithState:WKRTCCallStateFailed reason:safeError.localizedDescription notifyCallKit:YES];
            if(completion) completion(safeError);
            return;
        }
        self.audioEnabled = YES;
        self.videoEnabled = payload.callType == WKRTCCallTypeVideo;
        if(activeAfterConnected || self.state == WKRTCCallStateActive || [self mediaRoomHasPrivatePeer]) {
            [self changeState:WKRTCCallStateActive];
        }else {
            [self changeState:WKRTCCallStateOutgoingRinging];
        }
        if(completion) completion(nil);
    }];
}

- (void)handleMediaState:(WKRTCMediaEngineState)state error:(NSError *)error {
    if([state isEqualToString:WKRTCMediaEngineStateConnected]) {
        if(self.state == WKRTCCallStateReconnecting) {
            [self changeState:WKRTCCallStateActive];
        }
    }else if([state isEqualToString:WKRTCMediaEngineStateReconnecting]) {
        [self changeState:WKRTCCallStateReconnecting];
    }else if([state isEqualToString:WKRTCMediaEngineStateDisconnected]) {
        WKLogDebug(@"音视频媒体房间已断开");
    }else if([state isEqualToString:WKRTCMediaEngineStateFailed]) {
        [self finishWithState:WKRTCCallStateFailed reason:error.localizedDescription ?: @"媒体连接失败" notifyCallKit:YES];
    }
}

// 私聊中对方离开 LiveKit 房间时按挂断处理；群聊只做成员列表刷新和页面提示。
- (void)mediaParticipantPresenceChanged:(NSNotification *)notification {
    if(!self.currentPayload || self.state == WKRTCCallStateEnded || self.state == WKRTCCallStateIdle) {
        return;
    }
    NSString *participantId = notification.userInfo[@"participant_id"];
    NSString *action = notification.userInfo[@"action"];
    if(participantId.length == 0 || action.length == 0) {
        return;
    }
    if(self.currentPayload.channelType == WK_PERSON && [action isEqualToString:WKRTCMediaParticipantPresenceActionJoined]) {
        NSString *localUid = [WKSDK shared].options.connectInfo.uid ?: @"";
        NSString *peerUid = [self privatePeerUIDForPayload:self.currentPayload];
        NSString *participantUID = WKRTCUIDFromParticipantID(participantId);
        if(participantUID.length > 0 && ![participantUID isEqualToString:localUid] && [participantUID isEqualToString:peerUid]) {
            WKLogDebug(@"音视频私聊对方已进入媒体房间，切换为通话中：%@", participantId);
            [self changeState:WKRTCCallStateActive];
        }
        return;
    }
    if(self.currentPayload.channelType == WK_PERSON && [action isEqualToString:WKRTCMediaParticipantPresenceActionLeft]) {
        // 只有已进入通话后的远端离开才按挂断处理；连接过程中的离开事件可能是旧设备或重连抖动。
        if(self.state != WKRTCCallStateActive && self.state != WKRTCCallStateReconnecting) {
            WKLogDebug(@"音视频忽略连接阶段的私聊成员离开事件：%@", participantId);
            return;
        }
        NSString *localUid = [WKSDK shared].options.connectInfo.uid ?: @"";
        NSString *peerUid = [self privatePeerUIDForPayload:self.currentPayload];
        NSString *participantUID = WKRTCUIDFromParticipantID(participantId);
        if(participantUID.length > 0 && ![participantUID isEqualToString:localUid] && [participantUID isEqualToString:peerUid]) {
            WKLogDebug(@"音视频私聊对方已离开，按挂断处理：%@", participantId);
            [self finishWithState:WKRTCCallStateEnded reason:@"对方已离开，通话已结束" notifyCallKit:YES];
        }
    }
}

- (void)applyCallResponse:(WKRTCCallResp *)resp toPayload:(WKRTCCallPayload *)payload {
    payload.callId = resp.callId ?: payload.callId;
    payload.roomName = resp.roomName ?: payload.roomName;
    payload.expireAt = resp.expireAt > 0 ? resp.expireAt : payload.expireAt;
}

- (BOOL)isCurrentCall:(NSString *)callId {
    return callId.length > 0 && [self.currentPayload.callId isEqualToString:callId];
}

- (NSUInteger)beginNewSessionGeneration {
    self.sessionGeneration += 1;
    return self.sessionGeneration;
}

- (BOOL)isSessionGeneration:(NSUInteger)generation validForPayload:(WKRTCCallPayload *)payload {
    if(generation == 0 || generation != self.sessionGeneration || self.ending) {
        return NO;
    }
    if(!self.currentPayload || self.state == WKRTCCallStateIdle || self.state == WKRTCCallStateEnded || self.state == WKRTCCallStateFailed) {
        return NO;
    }
    if(payload.callId.length > 0 && self.currentPayload.callId.length > 0 && ![payload.callId isEqualToString:self.currentPayload.callId]) {
        return NO;
    }
    if(payload.channelId.length > 0 && self.currentPayload.channelId.length > 0 && ![payload.channelId isEqualToString:self.currentPayload.channelId]) {
        return NO;
    }
    return YES;
}

- (BOOL)shouldIgnoreCancelPayload:(WKRTCCallPayload *)payload {
    if(![self isCurrentCall:payload.callId]) {
        return NO;
    }
    NSString *deviceId = [[WKRTCAPI shared] deviceId];
    return payload.answerDeviceId.length > 0 && [payload.answerDeviceId isEqualToString:deviceId];
}

- (BOOL)mediaRoomHasPrivatePeer {
    NSString *peerUid = [self privatePeerUIDForPayload:self.currentPayload];
    if(self.currentPayload.channelType != WK_PERSON || peerUid.length == 0) {
        return NO;
    }
    NSString *localUid = [WKSDK shared].options.connectInfo.uid ?: @"";
    for (NSString *participantId in [self.mediaAdapter currentParticipants]) {
        NSString *participantUID = WKRTCUIDFromParticipantID(participantId);
        if(participantUID.length > 0 && ![participantUID isEqualToString:localUid] && [participantUID isEqualToString:peerUid]) {
            return YES;
        }
    }
    return NO;
}

- (NSString *)privatePeerUIDForPayload:(WKRTCCallPayload *)payload {
    if(payload.channelType != WK_PERSON) {
        return payload.channelId ?: @"";
    }
    NSString *localUid = [WKSDK shared].options.connectInfo.uid ?: @"";
    if(payload.channelId.length > 0 && ![payload.channelId isEqualToString:localUid]) {
        return payload.channelId;
    }
    if(payload.fromUid.length > 0 && ![payload.fromUid isEqualToString:localUid]) {
        return payload.fromUid;
    }
    return payload.channelId ?: @"";
}

- (void)changeState:(WKRTCCallState)state {
    self.state = state;
    if(state == WKRTCCallStateActive && self.connectedAt <= 0) {
        self.connectedAt = NSDate.date.timeIntervalSince1970;
    }
    if(state == WKRTCCallStateIncomingRinging) {
        [self playRingtoneWithReason:@"来电"];
    }else if(state == WKRTCCallStateOutgoingRinging) {
        [self playRingtoneWithReason:@"去电"];
    }else if(state == WKRTCCallStateJoining || state == WKRTCCallStateActive || state == WKRTCCallStateEnding || state == WKRTCCallStateEnded || state == WKRTCCallStateFailed) {
        [self stopRingtone];
    }
    [self refreshFloatingCallIfNeeded];
    [self notifyChange];
}

- (void)finishWithState:(WKRTCCallState)state reason:(NSString *)reason notifyCallKit:(BOOL)notifyCallKit {
    [self beginNewSessionGeneration];
    NSString *callId = self.currentPayload.callId ?: @"";
    WKLogDebug(@"音视频结束本地通话，通话编号：%@，原因：%@", callId, reason ?: @"");
    [self markCallEnded:callId];
    [self stopRingtone];
    [self hideFloatingCall];
    [self.mediaAdapter stopPictureInPictureWithCompletion:nil];
    [self.mediaAdapter disconnectWithCompletion:nil];
    [[WKRTCAudioRouteManager shared] deactivateAudioSession];
    if(notifyCallKit && callId.length > 0) {
        [[WKRTCCallKitManager shared] endCallIfNeeded:callId reason:reason];
    }
    self.ending = NO;
    self.connectedAt = 0;
    self.currentCallResp = nil;
    [self changeState:state];
    self.currentPayload = nil;
    [self resetMediaAdapter];
    [self notifyChange];
}

- (void)resetMediaAdapter {
    _mediaAdapter = [WKRTCMediaAdapter new];
}

- (void)notifyChange {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:WKRTCSessionDidChangeNotification object:self];
    });
}

- (void)presentCallViewControllerIfNeeded {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *top = [WKNavigationManager shared].topViewController;
        if([top isKindOfClass:WKRTCCallViewController.class]) {
            if(!top.isBeingDismissed && top.view.window) {
                [self hideFloatingCall];
            }
            return;
        }
        WKRTCCallViewController *vc = [[WKRTCCallViewController alloc] initWithSession:self];
        [top presentViewController:vc animated:YES completion:^{
            [self hideFloatingCall];
        }];
    });
}

- (void)floatingCallPressed {
    [self presentCallViewControllerIfNeeded];
}

- (void)pictureInPictureRestoreRequested:(NSNotification *)notification {
    [self presentCallViewControllerIfNeeded];
}

- (void)refreshFloatingCallIfNeeded {
    if(!self.floatingCallView.superview) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self refreshFloatingCallView];
    });
}

- (void)refreshFloatingCallView {
    WKRTCCallPayload *payload = self.currentPayload;
    if(!payload || self.state == WKRTCCallStateIdle || self.state == WKRTCCallStateEnded || self.state == WKRTCCallStateFailed) {
        [self hideFloatingCall];
        return;
    }
    BOOL privateVideo = payload.callType == WKRTCCallTypeVideo && payload.channelType != WK_GROUP;
    CGSize size = privateVideo ? CGSizeMake(112.0f, 158.0f) : CGSizeMake(168.0f, 56.0f);
    UIView *superview = self.floatingCallView.superview;
    if(CGRectIsEmpty(self.floatingCallView.frame) || fabs(self.floatingCallView.bounds.size.width - size.width) > 0.5f) {
        CGFloat x = MAX(12.0f, superview.bounds.size.width - size.width - 16.0f);
        CGFloat y = superview.safeAreaInsets.top + 88.0f;
        self.floatingCallView.frame = CGRectMake(x, y, size.width, size.height);
    }else {
        CGRect frame = self.floatingCallView.frame;
        frame.size = size;
        self.floatingCallView.frame = frame;
    }
    [self.floatingCallView configureWithPayload:payload duration:[self currentCallDuration]];
    [self attachFloatingVideoIfNeeded];
    [superview bringSubviewToFront:self.floatingCallView];
}

- (void)attachFloatingVideoIfNeeded {
    if(self.currentPayload.callType != WKRTCCallTypeVideo || self.currentPayload.channelType == WK_GROUP) {
        [self.floatingCallView.videoHost.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        return;
    }
    NSArray<NSString *> *participants = [self.mediaAdapter currentParticipants];
    UIView *videoView = participants.count > 0 ? [self.mediaAdapter remoteVideoView] : [self.mediaAdapter localVideoView];
    if(videoView.superview != self.floatingCallView.videoHost) {
        [self.floatingCallView.videoHost.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        videoView.userInteractionEnabled = NO;
        videoView.frame = self.floatingCallView.videoHost.bounds;
        videoView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.floatingCallView.videoHost insertSubview:videoView atIndex:0];
    }
}

- (void)hideFloatingCall {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.floatingCallView removeFromSuperview];
    });
}

- (void)playRingtoneWithReason:(NSString *)reason {
    dispatch_async(dispatch_get_main_queue(), ^{
        if(self.ringtonePlayer.isPlaying) {
            return;
        }
        NSString *path = [self ringtonePath];
        if(path.length == 0) {
            WKLogWarn(@"音视频%@铃声资源不存在", reason ?: @"通话");
            return;
        }
        NSError *error = nil;
        self.ringtonePlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path] error:&error];
        if(error || !self.ringtonePlayer) {
            WKLogWarn(@"音视频%@铃声初始化失败：%@", reason ?: @"通话", error.localizedDescription);
            return;
        }
        self.ringtonePlayer.numberOfLoops = -1;
        self.ringtonePlayer.volume = 1.0f;
        [self.ringtonePlayer prepareToPlay];
        [self.ringtonePlayer play];
        WKLogDebug(@"音视频开始播放%@铃声：%@", reason ?: @"通话", path.lastPathComponent);
    });
}

- (void)stopRingtone {
    dispatch_async(dispatch_get_main_queue(), ^{
        if(!self.ringtonePlayer) {
            return;
        }
        [self.ringtonePlayer stop];
        self.ringtonePlayer = nil;
        WKLogDebug(@"音视频停止播放铃声");
    });
}

- (NSString *)ringtonePath {
    NSBundle *bundle = [[WKApp shared] resourceBundle:@"WuKongBase"];
    NSString *path = [bundle pathForResource:@"rtc_ring" ofType:@"mp3" inDirectory:@"Other"];
    if(path.length == 0) {
        path = [bundle pathForResource:@"message" ofType:@"caf" inDirectory:@"Other"];
    }
    if(path.length == 0) {
        path = [bundle pathForResource:@"newmsg" ofType:@"wav" inDirectory:@"Other"];
    }
    if(path.length == 0) {
        path = [NSBundle.mainBundle pathForResource:@"rtc_ring" ofType:@"mp3" inDirectory:@"Other"];
    }
    if(path.length == 0) {
        path = [NSBundle.mainBundle pathForResource:@"message" ofType:@"caf" inDirectory:@"Other"];
    }
    if(path.length == 0) {
        path = [NSBundle.mainBundle pathForResource:@"newmsg" ofType:@"wav" inDirectory:@"Other"];
    }
    return path ?: @"";
}

- (void)requestPermissionForCallType:(WKRTCCallType)callType completion:(void(^)(BOOL granted))completion {
    [self requestMediaType:AVMediaTypeAudio completion:^(BOOL audioGranted) {
        if(!audioGranted || callType == WKRTCCallTypeAudio) {
            completion(audioGranted);
            return;
        }
        [self requestMediaType:AVMediaTypeVideo completion:completion];
    }];
}

- (void)requestMediaType:(AVMediaType)mediaType completion:(void(^)(BOOL granted))completion {
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    if(status == AVAuthorizationStatusAuthorized) {
        completion(YES);
    }else if(status == AVAuthorizationStatusNotDetermined) {
        [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(granted);
            });
        }];
    }else {
        completion(NO);
    }
}

- (void)postChannelCallChangeWithCommand:(NSString *)cmd payload:(WKRTCCallPayload *)payload {
    if(payload.channelId.length == 0 || payload.channelType == 0) {
        return;
    }
    NSDictionary *userInfo = @{
        @"cmd": cmd ?: @"",
        @"payload": payload
    };
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:WKRTCChannelCallDidChangeNotification object:payload userInfo:userInfo];
    });
}

- (BOOL)isEndCommand:(NSString *)cmd {
    return [cmd isEqualToString:WKRTCCMDRejected] ||
           [cmd isEqualToString:WKRTCCMDCancelled] ||
           [cmd isEqualToString:WKRTCCMDClosed] ||
           [cmd isEqualToString:WKRTCCMDTimeout];
}

- (void)markCallEnded:(NSString *)callId {
    if(callId.length == 0) {
        return;
    }
    @synchronized (self.endedCallIds) {
        [self.endedCallIds addObject:callId];
        if(self.endedCallIds.count > 200) {
            [self.endedCallIds removeObject:self.endedCallIds.anyObject];
        }
    }
}

- (void)clearEndedCallId:(NSString *)callId {
    if(callId.length == 0) {
        return;
    }
    @synchronized (self.endedCallIds) {
        [self.endedCallIds removeObject:callId];
    }
}

- (void)showToast:(NSString *)text {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[WKNavigationManager shared].topViewController.view makeToast:text];
    });
}

@end

//
//  WKRTCMediaAdapter.m
//  WuKongBase
//

#import "WKRTCMediaAdapter.h"
#import "WKRTCModels.h"
#import "WKLogs.h"

WKRTCMediaEngineState const WKRTCMediaEngineStateConnected = @"connected";
WKRTCMediaEngineState const WKRTCMediaEngineStateReconnecting = @"reconnecting";
WKRTCMediaEngineState const WKRTCMediaEngineStateDisconnected = @"disconnected";
WKRTCMediaEngineState const WKRTCMediaEngineStateFailed = @"failed";

static id<WKRTCMediaEngine> (^WKRTCGlobalEngineFactory)(void);

@interface WKRTCMediaAdapter ()

@property(nonatomic,strong,nullable) id<WKRTCMediaEngine> engine;
@property(nonatomic,strong) UIView *emptyLocalView;
@property(nonatomic,strong) UIView *emptyRemoteView;

@end

@implementation WKRTCMediaAdapter

+ (id<WKRTCMediaEngine>  _Nullable (^)(void))engineFactory {
    return WKRTCGlobalEngineFactory;
}

+ (void)setEngineFactory:(id<WKRTCMediaEngine>  _Nullable (^)(void))engineFactory {
    WKRTCGlobalEngineFactory = [engineFactory copy];
}

- (void)connectWithURL:(NSString *)url
                 token:(NSString *)token
          audioEnabled:(BOOL)audioEnabled
          videoEnabled:(BOOL)videoEnabled
            completion:(void (^)(NSError * _Nullable))completion {
    if(url.length == 0 || token.length == 0) {
        if(completion) {
            completion(WKRTCError(-1, @"媒体连接信息不能为空"));
        }
        return;
    }
    id<WKRTCMediaEngine> engine = [self prepareEngine];
    if(!engine) {
        if(completion) {
            completion(WKRTCError(-1, @"媒体引擎未注册"));
        }
        return;
    }
    WKLogDebug(@"音视频开始连接媒体房间");
    [engine connectWithURL:url token:token audioEnabled:audioEnabled videoEnabled:videoEnabled completion:completion];
}

- (void)disconnectWithCompletion:(void (^)(void))completion {
    if(!self.engine) {
        if(completion) completion();
        return;
    }
    WKLogDebug(@"音视频断开媒体房间");
    [self.engine disconnectWithCompletion:completion];
}

- (void)setAudioEnabled:(BOOL)enabled completion:(void (^)(NSError * _Nullable))completion {
    if(!self.engine) {
        if(completion) completion(WKRTCError(-1, @"媒体引擎未连接"));
        return;
    }
    WKLogDebug(@"音视频设置麦克风：%@", enabled ? @"开启" : @"关闭");
    [self.engine setAudioEnabled:enabled completion:completion];
}

- (void)setVideoEnabled:(BOOL)enabled completion:(void (^)(NSError * _Nullable))completion {
    if(!self.engine) {
        if(completion) completion(WKRTCError(-1, @"媒体引擎未连接"));
        return;
    }
    WKLogDebug(@"音视频设置摄像头：%@", enabled ? @"开启" : @"关闭");
    [self.engine setVideoEnabled:enabled completion:completion];
}

- (void)switchCameraWithCompletion:(void (^)(NSError * _Nullable))completion {
    if(!self.engine) {
        if(completion) completion(WKRTCError(-1, @"媒体引擎未连接"));
        return;
    }
    WKLogDebug(@"音视频切换前后摄像头");
    [self.engine switchCameraWithCompletion:completion];
}

- (void)preparePictureInPictureWithSourceView:(UIView *)sourceView {
    if(!self.engine || !sourceView) {
        return;
    }
    [self.engine preparePictureInPictureWithSourceView:sourceView];
}

- (void)startPictureInPictureWithSourceView:(UIView *)sourceView completion:(void (^)(NSError * _Nullable))completion {
    if(!self.engine) {
        if(completion) completion(WKRTCError(-1, @"媒体引擎未连接"));
        return;
    }
    if(!sourceView) {
        if(completion) completion(WKRTCError(-1, @"画中画来源视图为空"));
        return;
    }
    WKLogDebug(@"音视频启动系统画中画");
    [self.engine startPictureInPictureWithSourceView:sourceView completion:completion];
}

- (void)stopPictureInPictureWithCompletion:(void (^)(void))completion {
    if(!self.engine) {
        if(completion) completion();
        return;
    }
    WKLogDebug(@"音视频停止系统画中画");
    [self.engine stopPictureInPictureWithCompletion:completion];
}

- (UIView *)localVideoView {
    return self.engine ? [self.engine localVideoView] : self.emptyLocalView;
}

- (UIView *)remoteVideoView {
    return self.engine ? [self.engine remoteVideoView] : self.emptyRemoteView;
}

- (NSArray<NSString *> *)currentParticipants {
    return self.engine ? [self.engine currentParticipants] : @[];
}

- (NSDictionary<NSString *,WKRTCMediaParticipantState *> *)participantStates {
    return self.engine ? [self.engine participantStates] : @{};
}

- (void)setRemoteParticipant:(NSString *)participantId videoView:(UIView *)videoView {
    if(participantId.length == 0 || !videoView || !self.engine) {
        return;
    }
    [self.engine setRemoteParticipant:participantId videoView:videoView];
}

- (void)setVisibleRemoteParticipants:(NSArray<NSString *> *)participantIds {
    if(!self.engine) {
        return;
    }
    [self.engine setVisibleRemoteParticipants:participantIds ?: @[]];
}

- (id<WKRTCMediaEngine>)prepareEngine {
    if(self.engine) {
        return self.engine;
    }
    if(!WKRTCGlobalEngineFactory) {
        WKLogError(@"音视频媒体引擎未注册，请在应用启动时注册媒体引擎工厂");
        return nil;
    }
    self.engine = WKRTCGlobalEngineFactory();
    __weak typeof(self) weakSelf = self;
    [self.engine setStateChangedHandler:^(WKRTCMediaEngineState  _Nonnull state, NSError * _Nullable error) {
        if(weakSelf.stateChanged) {
            weakSelf.stateChanged(state, error);
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:WKRTCMediaParticipantsDidChangeNotification object:weakSelf];
    }];
    return self.engine;
}

- (UIView *)emptyLocalView {
    if(!_emptyLocalView) {
        _emptyLocalView = [self emptyVideoViewWithText:@"等待本地视频"];
    }
    return _emptyLocalView;
}

- (UIView *)emptyRemoteView {
    if(!_emptyRemoteView) {
        _emptyRemoteView = [self emptyVideoViewWithText:@"等待对方视频"];
    }
    return _emptyRemoteView;
}

- (UIView *)emptyVideoViewWithText:(NSString *)text {
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = UIColor.blackColor;
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.textColor = [UIColor colorWithWhite:1.0f alpha:0.72f];
    label.font = [UIFont systemFontOfSize:13.0f];
    label.textAlignment = NSTextAlignmentCenter;
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    label.frame = view.bounds;
    [view addSubview:label];
    return view;
}

@end

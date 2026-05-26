//
//  WKRTCAudioRouteManager.m
//  WuKongBase
//

#import "WKRTCAudioRouteManager.h"
#import <AVFoundation/AVFoundation.h>
#import "WKLogs.h"

NSString * const WKRTCAudioRouteDidChangeNotification = @"WKRTCAudioRouteDidChangeNotification";

@interface WKRTCAudioRouteManager ()

@property(nonatomic,assign,readwrite) BOOL speakerEnabled;

@end

@implementation WKRTCAudioRouteManager

+ (instancetype)shared {
    static WKRTCAudioRouteManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [WKRTCAudioRouteManager new];
        [[NSNotificationCenter defaultCenter] addObserver:manager selector:@selector(routeChanged:) name:AVAudioSessionRouteChangeNotification object:nil];
    });
    return manager;
}

- (void)prepareAudioSessionForCallType:(WKRTCCallType)callType {
    AVAudioSession *session = AVAudioSession.sharedInstance;
    NSError *error = nil;
    AVAudioSessionMode mode = callType == WKRTCCallTypeVideo ? AVAudioSessionModeVideoChat : AVAudioSessionModeVoiceChat;
    AVAudioSessionCategoryOptions options = AVAudioSessionCategoryOptionAllowBluetooth | AVAudioSessionCategoryOptionAllowBluetoothA2DP;
    if(callType == WKRTCCallTypeVideo || self.speakerEnabled) {
        options |= AVAudioSessionCategoryOptionDefaultToSpeaker;
    }
    [session setCategory:AVAudioSessionCategoryPlayAndRecord mode:mode options:options error:&error];
    if(error) {
        WKLogError(@"音视频配置音频会话失败：%@", error);
        return;
    }
    [session setActive:YES error:&error];
    if(error) {
        WKLogError(@"音视频激活音频会话失败：%@", error);
    }
}

- (void)setSpeakerEnabled:(BOOL)enabled callType:(WKRTCCallType)callType {
    self.speakerEnabled = enabled;
    [self prepareAudioSessionForCallType:callType];
    NSError *error = nil;
    [AVAudioSession.sharedInstance overrideOutputAudioPort:enabled ? AVAudioSessionPortOverrideSpeaker : AVAudioSessionPortOverrideNone error:&error];
    if(error) {
        WKLogError(@"音视频切换音频输出失败：%@", error);
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:WKRTCAudioRouteDidChangeNotification object:self];
}

- (void)deactivateAudioSession {
    NSError *error = nil;
    [AVAudioSession.sharedInstance overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];
    [AVAudioSession.sharedInstance setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
    if(error) {
        WKLogError(@"音视频关闭音频会话失败：%@", error);
    }
    self.speakerEnabled = NO;
}

- (NSString *)currentRouteName {
    AVAudioSessionRouteDescription *route = AVAudioSession.sharedInstance.currentRoute;
    for (AVAudioSessionPortDescription *output in route.outputs) {
        NSString *port = output.portType;
        if([port isEqualToString:AVAudioSessionPortBluetoothA2DP] ||
           [port isEqualToString:AVAudioSessionPortBluetoothHFP] ||
           [port isEqualToString:AVAudioSessionPortBluetoothLE]) {
            return @"bluetooth";
        }
        if([port isEqualToString:AVAudioSessionPortBuiltInSpeaker]) {
            return @"speaker";
        }
    }
    return @"receiver";
}

- (void)routeChanged:(NSNotification *)notification {
    WKLogDebug(@"音视频音频路由发生变化：%@", self.currentRouteName);
    [[NSNotificationCenter defaultCenter] postNotificationName:WKRTCAudioRouteDidChangeNotification object:self];
}

@end

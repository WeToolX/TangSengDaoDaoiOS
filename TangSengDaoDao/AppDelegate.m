//
//  AppDelegate.m
//  TangSengDaoDao
//
//  Created by tt on 2019/11/30.
//  Copyright © 2019 xinbida. All rights reserved.
//

#import "AppDelegate.h"
#import <WuKongBase/WuKongBase.h>
#import "WKMainTabController.h"
@import WuKongContacts;
#import <WuKongBase/WKSyncService.h>
#import "WKMeVC.h"

#import "SELUpdateAlert.h"
#import <PushKit/PushKit.h>
#import <UserNotifications/UserNotifications.h>
#import <WuKongBase/WKRTCAPI.h>
#import <WuKongBase/WKRTCSessionManager.h>
#import <WuKongBase/WKRTCMediaAdapter.h>
#import "TangSengDaoDao-Swift.h"


#if DEBUG
#define SERVER_IP @"api.qinghangim.com" // xxx.xxx.xx.xx:8090
#define HTTPS_ON true // https开关
#else
#define SERVER_IP @"api.qinghangim.com"
#define HTTPS_ON true
#endif


#define BASE_URL [NSString stringWithFormat:@"%@://%@/v1/",HTTPS_ON?@"https":@"http",SERVER_IP]
#define WEB_URL [NSString stringWithFormat:@"%@://%@/web/",HTTPS_ON?@"https":@"http",SERVER_IP]
// api基地址
#define API_BASE_URL  BASE_URL
// 文件基地址
#define FILE_BASE_URL BASE_URL
// 文件预览地址
#define FILE_BROWSE_URL BASE_URL
// 图片预览地址
#define IMAGE_BROWSE_URL BASE_URL

// 举报地址
#define REPORT_URL  [NSString stringWithFormat:@"%@://%@/web/report.html",HTTPS_ON?@"https":@"http",SERVER_IP]


static NSString * const WKRTCIncomingLocalNotificationPrefix = @"rtc_incoming_";
static NSString * const WKRTCPendingIncomingPayloadKey = @"WKRTCPendingIncomingPayloadKey";
static NSString * const WKRTCIncomingNotificationSoundName = @"rtc_ring.mp3";




@interface AppDelegate ()<UITabBarControllerDelegate, PKPushRegistryDelegate, UNUserNotificationCenterDelegate>

@property(nonatomic,strong) WKConversationListVC *conversationList;
//@property(nonatomic,strong)  WKContactsVC *contactVC;
@property(nonatomic,strong) WKMeVC *meVC;
@property(nonatomic,strong) PKPushRegistry *voipRegistry;


@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor grayColor];
    [self.window makeKeyAndVisible];

    // 加载登录信息
    [[WKApp shared].loginInfo load];

    // app配置
    WKAppConfig *config = [WKAppConfig new];
    config.apiBaseUrl = API_BASE_URL; // api地址
    config.fileBaseUrl = FILE_BASE_URL; // 文件上传地址
    config.fileBrowseUrl = FILE_BROWSE_URL; // 文件预览地址
    config.imageBrowseUrl = IMAGE_BROWSE_URL; // 图片预览地址
    config.reportUrl = [NSString stringWithFormat:@"%@report/html",API_BASE_URL]; //举报地址
    config.privacyAgreementUrl = [NSString stringWithFormat:@"%@privacy_policy.html",WEB_URL]; //隐私协议
    config.userAgreementUrl = [NSString stringWithFormat:@"%@user_agreement.html",WEB_URL]; //用户协议
    [WKApp shared].config = config;
    
    // 注册 LiveKit SPM 媒体引擎工厂，Pods 内 RTC 业务层通过协议调用。
    [WKRTCLiveKitMediaEngine configureForAppAudioSession];
    WKRTCMediaAdapter.engineFactory = ^id<WKRTCMediaEngine> _Nonnull{
        return [WKRTCLiveKitMediaEngine new];
    };
    
    // app首页设置
    [WKApp shared].getHomeViewController = ^UIViewController * _Nonnull{
        WKMainTabController *homeViewController =  [WKMainTabController new];
        return homeViewController;
    };
   

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleRTCBackgroundInvite:) name:@"WKRTCSessionDidReceiveBackgroundInviteNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleRTCSessionDidFinish:) name:@"WKRTCSessionDidFinishNotification" object:nil];
    if (@available(iOS 10.0, *)) {
        [UNUserNotificationCenter currentNotificationCenter].delegate = self;
    }
    [self prepareRTCIncomingNotificationSound];
    // app初始化
    [[WKApp shared] appInit];
    [self registerVoIPPush];
    
    if (@available(iOS 13.0, *)) {
        if([WKApp shared].config.style == WKSystemStyleDark) {
            self.window.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
        }else{
            self.window.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
        }
    }
   
    return YES;
}

- (void)handleRTCBackgroundInvite:(NSNotification *)notification {
    NSDictionary *payload = notification.userInfo;
    if(![payload isKindOfClass:NSDictionary.class]) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if(![[WKRTCLiveCommunicationKitBridge shared] isSupported]) {
            WKLogWarn(@"当前系统不支持 LiveCommunicationKit，后台在线来电改用本地通知提醒");
            [self showRTCIncomingLocalNotification:payload];
            return;
        }
        [[WKRTCLiveCommunicationKitBridge shared] reportIncomingPushPayload:payload completion:^(BOOL handled) {
            if(!handled) {
                WKLogWarn(@"LiveCommunicationKit 上报后台在线来电失败");
            }
        }];
    });
}

- (void)handleRTCSessionDidFinish:(NSNotification *)notification {
    NSString *callId = notification.userInfo[@"call_id"];
    if(![callId isKindOfClass:NSString.class] || callId.length == 0) {
        return;
    }
    [self clearPendingRTCInviteWithCallId:callId];
    [self removeRTCIncomingLocalNotificationWithCallId:callId];
}

- (void)showRTCIncomingLocalNotification:(NSDictionary *)payload {
    NSDictionary *rtcCall = [payload[@"rtc_call"] isKindOfClass:NSDictionary.class] ? payload[@"rtc_call"] : payload;
    if(![rtcCall isKindOfClass:NSDictionary.class]) {
        return;
    }
    NSString *callId = [rtcCall[@"call_id"] isKindOfClass:NSString.class] ? rtcCall[@"call_id"] : @"";
    if(callId.length == 0) {
        return;
    }
    NSString *callType = [rtcCall[@"call_type"] isKindOfClass:NSString.class] ? rtcCall[@"call_type"] : @"audio";
    NSString *fromName = [rtcCall[@"from_name"] isKindOfClass:NSString.class] ? rtcCall[@"from_name"] : @"";
    if(fromName.length == 0) {
        fromName = @"卿航IM";
    }
    NSString *body = [callType isEqualToString:@"video"] ? @"邀请你进行视频通话" : @"邀请你进行语音通话";
    NSString *identifier = [self rtcIncomingLocalNotificationIdentifier:callId];
    [self savePendingRTCInvitePayload:@{@"rtc_call": rtcCall}];
    if (@available(iOS 10.0, *)) {
        UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
        content.title = fromName;
        content.body = body;
        content.sound = [self rtcIncomingUNNotificationSound];
        content.userInfo = @{@"rtc_call": rtcCall};
        UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier content:content trigger:nil];
        [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
            if(error) {
                WKLogError(@"音视频本地来电通知失败！-> %@", error);
            }else {
                WKLogDebug(@"音视频本地来电通知已提交，通话编号：%@", callId);
            }
        }];
    } else {
        UILocalNotification *localNotification = [[UILocalNotification alloc] init];
        localNotification.alertTitle = fromName;
        localNotification.alertBody = body;
        localNotification.soundName = [self rtcIncomingNotificationSoundName] ?: UILocalNotificationDefaultSoundName;
        localNotification.userInfo = @{@"call_id": callId};
        [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
    }
}

- (void)removeRTCIncomingLocalNotificationWithCallId:(NSString *)callId {
    NSString *identifier = [self rtcIncomingLocalNotificationIdentifier:callId];
    if (@available(iOS 10.0, *)) {
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        [center removePendingNotificationRequestsWithIdentifiers:@[identifier]];
        [center removeDeliveredNotificationsWithIdentifiers:@[identifier]];
    }else {
        NSArray<UILocalNotification *> *notifications = [UIApplication sharedApplication].scheduledLocalNotifications;
        for (UILocalNotification *notification in notifications) {
            if([notification.userInfo[@"call_id"] isEqualToString:callId]) {
                [[UIApplication sharedApplication] cancelLocalNotification:notification];
            }
        }
    }
}

- (NSString *)rtcIncomingLocalNotificationIdentifier:(NSString *)callId {
    return [WKRTCIncomingLocalNotificationPrefix stringByAppendingString:callId ?: @""];
}

- (UNNotificationSound *)rtcIncomingUNNotificationSound API_AVAILABLE(ios(10.0)) {
    NSString *soundName = [self rtcIncomingNotificationSoundName];
    if(soundName.length > 0) {
        return [UNNotificationSound soundNamed:soundName];
    }
    return [UNNotificationSound defaultSound];
}

- (NSString *)rtcIncomingNotificationSoundName {
    return [self prepareRTCIncomingNotificationSound] ? WKRTCIncomingNotificationSoundName : nil;
}

- (BOOL)prepareRTCIncomingNotificationSound {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *libraryURL = [[fileManager URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] firstObject];
    if(!libraryURL) {
        return NO;
    }
    NSURL *soundsURL = [libraryURL URLByAppendingPathComponent:@"Sounds" isDirectory:YES];
    NSURL *targetURL = [soundsURL URLByAppendingPathComponent:WKRTCIncomingNotificationSoundName];
    if([fileManager fileExistsAtPath:targetURL.path]) {
        return YES;
    }
    NSError *directoryError = nil;
    if(![fileManager createDirectoryAtURL:soundsURL withIntermediateDirectories:YES attributes:nil error:&directoryError]) {
        WKLogWarn(@"音视频通知铃声目录创建失败：%@", directoryError);
        return NO;
    }
    NSBundle *baseBundle = [NSBundle bundleForClass:WKRTCSessionManager.class];
    NSBundle *resourceBundle = [NSBundle bundleWithPath:[baseBundle pathForResource:@"WuKongBase_resources" ofType:@"bundle"]];
    NSString *sourcePath = [resourceBundle pathForResource:@"rtc_ring" ofType:@"mp3" inDirectory:@"Other"];
    if(sourcePath.length == 0) {
        sourcePath = [[NSBundle mainBundle] pathForResource:@"rtc_ring" ofType:@"mp3"];
    }
    if(sourcePath.length == 0) {
        return NO;
    }
    NSError *copyError = nil;
    if(![fileManager copyItemAtURL:[NSURL fileURLWithPath:sourcePath] toURL:targetURL error:&copyError]) {
        WKLogWarn(@"音视频通知铃声准备失败：%@", copyError);
        return NO;
    }
    return YES;
}

- (void)openRTCInviteFromNotificationUserInfo:(NSDictionary *)userInfo completion:(void (^)(void))completion {
    if([userInfo[@"rtc_call"] isKindOfClass:NSDictionary.class] || [userInfo[@"call_id"] isKindOfClass:NSString.class]) {
        WKLogDebug(@"音视频点击来电通知，准备打开接听页");
        NSDictionary *rtcCall = [userInfo[@"rtc_call"] isKindOfClass:NSDictionary.class] ? userInfo[@"rtc_call"] : userInfo;
        [self clearPendingRTCInviteWithCallId:[rtcCall[@"call_id"] isKindOfClass:NSString.class] ? rtcCall[@"call_id"] : @""];
        [[WKRTCSessionManager shared] handleRemotePayload:userInfo completion:completion];
        return;
    }
    if(completion) completion();
}

- (void)openPendingRTCInviteIfNeeded {
    NSDictionary *payload = [[NSUserDefaults standardUserDefaults] objectForKey:WKRTCPendingIncomingPayloadKey];
    NSDictionary *rtcCall = [payload[@"rtc_call"] isKindOfClass:NSDictionary.class] ? payload[@"rtc_call"] : nil;
    if(!rtcCall) {
        return;
    }
    NSTimeInterval expireAt = [rtcCall[@"expire_at"] doubleValue];
    if(expireAt > 0 && expireAt <= NSDate.date.timeIntervalSince1970) {
        [self clearPendingRTCInviteWithCallId:[rtcCall[@"call_id"] isKindOfClass:NSString.class] ? rtcCall[@"call_id"] : @""];
        return;
    }
    WKLogDebug(@"音视频手动打开 App，准备打开待接听页");
    [self openRTCInviteFromNotificationUserInfo:payload completion:nil];
}

- (void)savePendingRTCInvitePayload:(NSDictionary *)payload {
    [[NSUserDefaults standardUserDefaults] setObject:payload forKey:WKRTCPendingIncomingPayloadKey];
}

- (void)clearPendingRTCInviteWithCallId:(NSString *)callId {
    NSDictionary *payload = [[NSUserDefaults standardUserDefaults] objectForKey:WKRTCPendingIncomingPayloadKey];
    NSDictionary *rtcCall = [payload[@"rtc_call"] isKindOfClass:NSDictionary.class] ? payload[@"rtc_call"] : nil;
    NSString *pendingCallId = [rtcCall[@"call_id"] isKindOfClass:NSString.class] ? rtcCall[@"call_id"] : @"";
    if(callId.length == 0 || [pendingCallId isEqualToString:callId]) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:WKRTCPendingIncomingPayloadKey];
    }
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    [self openRTCInviteFromNotificationUserInfo:notification.userInfo completion:nil];
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
didReceiveNotificationResponse:(UNNotificationResponse *)response
         withCompletionHandler:(void (^)(void))completionHandler API_AVAILABLE(ios(10.0)) {
    [self openRTCInviteFromNotificationUserInfo:response.notification.request.content.userInfo completion:completionHandler];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [self openPendingRTCInviteIfNeeded];
}

-(void) applicationWillEnterForeground:(UIApplication *)application {
    NSInteger lastCheckUpdateTime = [[NSUserDefaults standardUserDefaults] integerForKey:@"lastCheckUpdateTime"];
    if(lastCheckUpdateTime == 0) {
        [self checkAppVersionOrUpdate];
    }else if ([[NSDate date] timeIntervalSince1970] - lastCheckUpdateTime > 60.0f * 30.0f){
        [self checkAppVersionOrUpdate];
    }
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    NSLog(@"内存警告");
}

-(void) checkAppVersionOrUpdate {
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *appVersion = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    [[WKAPIClient sharedClient] GET:[NSString stringWithFormat:@"common/appversion/iOS/%@",appVersion] parameters:nil].then(^(NSDictionary *resultDict){
        [[NSUserDefaults standardUserDefaults] setInteger:[[NSDate date] timeIntervalSince1970] forKey:@"lastCheckUpdateTime"];
        NSString *version = resultDict[@"app_version"];
        if(!version||[version isEqualToString:@""]) {
            [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"lastAlertUpdateTime"];
            return;
        }
        
        if([self versionStrToInt:version]>[self versionStrToInt:appVersion]) {
            NSString  *updateDesc = resultDict[@"update_desc"];
            BOOL isForce = resultDict[@"is_force"]?[resultDict[@"is_force"] boolValue]:false;
            NSString *downloadURL = resultDict[@"download_url"];
            
            [SELUpdateAlert showUpdateAlertWithVersion:resultDict[@"app_version"] Description:updateDesc downloadURL:downloadURL forceUpdate:isForce];
        }
      
    });
}

-(NSInteger) versionStrToInt:(NSString*)versionStr {
    return [[versionStr stringByReplacingOccurrencesOfString:@"." withString:@""] integerValue];;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    if (!deviceToken || ![deviceToken isKindOfClass:[NSData class]] || deviceToken.length==0) {
        return;
    }
    NSString *(^getDeviceToken)(void) = ^() {
            if (@available(iOS 13.0, *)) {
                const unsigned char *dataBuffer = (const unsigned char *)deviceToken.bytes;
                NSMutableString *myToken  = [NSMutableString stringWithCapacity:(deviceToken.length * 2)];
                for (int i = 0; i < deviceToken.length; i++) {
                    [myToken appendFormat:@"%02x", dataBuffer[i]];
                }
                return (NSString *)[myToken copy];
            } else {
                NSCharacterSet *characterSet = [NSCharacterSet characterSetWithCharactersInString:@"<>"];
                NSString *myToken = [[deviceToken description] stringByTrimmingCharactersInSet:characterSet];
                return [myToken stringByReplacingOccurrencesOfString:@" " withString:@""];
            }
        };
    NSString *myToken = getDeviceToken();
    WKLogDebug(@"收到普通远程推送令牌，准备上传");
    [WKApp shared].loginInfo.deviceToken = myToken;
    [[WKApp shared].loginInfo save];
   NSString *bundleID = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
    [[WKRTCAPI shared] uploadDeviceToken:myToken deviceType:@"IOS" bundleId:bundleID].catch(^(NSError *error){
        WKLogError(@"上传普通远程推送令牌失败！-> %@",error);
    });
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    WKLogDebug(@"收到普通远程通知");
    [[WKRTCSessionManager shared] handleRemotePayload:userInfo completion:nil];
    [WKApp.shared application:application didReceiveRemoteNotification:userInfo fetchCompletionHandler:completionHandler];
}


- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    WKLogError(@"注册远程通知失败->%@",error);
}

#pragma mark - PushKit

// 注册 PushKit，RTC 离线来电通过 LiveCommunicationKit 上报系统通话界面。
- (void)registerVoIPPush {
    if (@available(iOS 17.4, *)) {
    }else {
        WKLogWarn(@"当前系统不支持 LiveCommunicationKit，跳过 VoIP push 注册");
        return;
    }
    self.voipRegistry = [[PKPushRegistry alloc] initWithQueue:dispatch_get_main_queue()];
    self.voipRegistry.delegate = self;
    self.voipRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
}

- (void)pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials:(PKPushCredentials *)pushCredentials forType:(PKPushType)type {
    if(![type isEqualToString:PKPushTypeVoIP]) {
        return;
    }
    if(![[WKRTCLiveCommunicationKitBridge shared] isSupported]) {
        WKLogWarn(@"当前系统不支持 LiveCommunicationKit，忽略 VoIP token");
        return;
    }
    NSData *tokenData = pushCredentials.token;
    if(tokenData.length == 0) {
        return;
    }
    NSMutableString *token = [NSMutableString stringWithCapacity:tokenData.length * 2];
    const unsigned char *bytes = tokenData.bytes;
    for (NSUInteger i = 0; i < tokenData.length; i++) {
        [token appendFormat:@"%02x", bytes[i]];
    }
    NSString *bundleID = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"] ?: @"";
    NSString *voipBundleID = [bundleID stringByAppendingString:@".voip"];
    WKLogDebug(@"收到网络电话推送令牌，准备上传");
    [[WKRTCAPI shared] uploadDeviceToken:token deviceType:@"IOS" bundleId:voipBundleID].catch(^(NSError *error){
        WKLogError(@"上传网络电话推送令牌失败！-> %@",error);
    });
}

- (void)pushRegistry:(PKPushRegistry *)registry didInvalidatePushTokenForType:(PKPushType)type {
    if([type isEqualToString:PKPushTypeVoIP]) {
        WKLogDebug(@"网络电话推送令牌已失效");
    }
}

- (void)pushRegistry:(PKPushRegistry *)registry
didReceiveIncomingPushWithPayload:(PKPushPayload *)payload
             forType:(PKPushType)type
withCompletionHandler:(void (^)(void))completion {
    if(![type isEqualToString:PKPushTypeVoIP]) {
        if(completion) completion();
        return;
    }
    WKLogDebug(@"收到网络电话来电推送");
    if(![[WKRTCLiveCommunicationKitBridge shared] isSupported]) {
        WKLogWarn(@"当前系统不支持 LiveCommunicationKit，VoIP push 交由普通 APNs 降级链路处理");
        if(completion) completion();
        return;
    }
    [[WKRTCLiveCommunicationKitBridge shared] reportIncomingPushPayload:payload.dictionaryPayload completion:^(BOOL handled) {
        if(!handled) {
            WKLogWarn(@"LiveCommunicationKit 上报来电失败");
        }
        if(completion) completion();
    }];
}
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    
    return [[WKApp shared] appOpenURL:url options:options];
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler {
    
    return [[WKApp shared] appContinueUserActivity:userActivity restorationHandler:restorationHandler];
}

@end

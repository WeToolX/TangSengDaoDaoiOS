//
//  WKConversationVC.m
//  WuKongBase
//
//  Created by tt on 2022/5/18.
//

#import "WKConversationVC.h"
#import "WKMessageListView.h"
#import "WuKongBase.h"
#import "WKMessageListDataProviderImp.h"
#import "WKConversationChannelHeader.h"
#import "WKConversationListVM.h"
#import "WKConversationView.h"
#import "NSString+WK.h"
#import "WKConversationView+Robot.h"
#import "WKMessageListView+Position.h"
#import <WuKongBase/WuKongBase-Swift.h>
#import "Svg.h"
#import "WKThemeUtil.h"
#import "WKRTCSessionManager.h"
#import "WKRTCAPI.h"
#import "WKConversationPasswordVM.h"
#import "WKConversationPasswordVC.h"
#import "WKPwdKeyboardInputView.h"
@interface WKConversationVC ()<WKChannelManagerDelegate>

@property(nonatomic,strong) WKConversationView *conversationView;

@property(nonatomic,strong) WKConversationChannelHeader *channelHeader;

@property(nonatomic,strong) UIButton *cancelMutipleBtn; // 取消多选的按钮

@property(nonatomic,strong) WKChannelInfo *channelInfo;

@property(nonatomic,assign) BOOL firstLoad; // 是否第一次加载

@property(nonatomic,strong) UIImageView *backgroundView;

@property(nonatomic,strong) UIView *injectedTopPanel;
@property(nonatomic,strong) UIControl *rtcTopPanel;
@property(nonatomic,strong) UILabel *rtcTopTitleLabel;
@property(nonatomic,strong) UILabel *rtcTopSubtitleLabel;
@property(nonatomic,strong) WKRTCCallPayload *currentRTCTopPayload;
@property(nonatomic,assign) BOOL rtcStateRequesting;
@property(nonatomic,assign) BOOL chatPasswordVerified;
@property(nonatomic,assign) BOOL chatPasswordPrompting;

@end

@implementation WKConversationVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.firstLoad = true;
    [self.view addSubview:self.backgroundView];
    
    [self addDelegates];
    
    [self setupChatBackground];
   
    [self.navigationBar addSubview:self.channelHeader];
    [self.view addSubview:self.conversationView];
    [self.view bringSubviewToFront:self.navigationBar]; // 将导航栏放到最顶层
    
    __weak typeof(self) weakSelf = self;
    
    self.conversationView.channel = self.channel;
    self.conversationView.locationAtOrderSeq = self.locationAtOrderSeq;
    self.conversationView.conversationVM.onMemberUpdate = ^{
        [weakSelf refreshTitle];
        [weakSelf.conversationView setGroupForbiddenIfNeed];
        [weakSelf.conversationView syncRobot:[weakSelf getMemberRobotIDs]];
        WKChannelMember *memberOfMe = weakSelf.conversationView.conversationVM.memberOfMe;
        if(memberOfMe) {
            [weakSelf refreshRTCCallButtons];
        }
        
    };
    [self.conversationView viewDidLoad];
     
   
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        if(!weakSelf) {
            return;
        }
        [weakSelf requestLoadChannelInfoIfNeed];
        [weakSelf markFlameMessages];
    });
    
    
    // 获取注入的顶部面板
   UIView *topPanel = [WKApp.shared invoke:WKPOINT_CONVERSATION_TOP_PANEL param:@{@"channel":self.channel,@"context":self.conversationView.conversationContext}];
    self.injectedTopPanel = topPanel;
    self.conversationView.topView.hidden = YES;
    self.conversationView.topView.lim_top = -self.conversationView.topView.lim_height;
    if(topPanel) {
        self.conversationView.topView.lim_height = topPanel.lim_height;
        [self.conversationView.topView addSubview:topPanel];
    }
    [self updateInjectedTopPanel];
}


-(void) addDelegates {
    [[WKSDK shared].channelManager addDelegate:self]; // 频道数据监听
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateChatBackground) name:WKNOTIFY_CHATBACKGROUND_CHANGE object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rtcChannelCallDidChange:) name:WKRTCChannelCallDidChangeNotification object:nil];
}
-(void) removeDelegates {
    [[WKSDK shared].channelManager removeDelegate:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:WKNOTIFY_CHATBACKGROUND_CHANGE object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:WKRTCChannelCallDidChangeNotification object:nil];
}


// 标记阅后即焚的消息（如果超时则删除）
-(void) markFlameMessages {
    NSArray<WKMessage*> *messages = [WKFlameManager.shared getMessagesOfNeedFlame];
    if(messages && messages.count>0) {
        NSMutableArray<WKMessageModel*> *messageModels = [NSMutableArray array];
        for (WKMessage *message in messages) {
            [messageModels addObject:[[WKMessageModel alloc] initWithMessage:message]];
        }
        [WKMessageManager.shared deleteMessages:messageModels];
    }
}

// 获取机器人成员
-(NSArray<NSString*>*) getMemberRobotIDs {
    NSMutableArray *robots = [NSMutableArray array];
    for (WKChannelMember *channelMember in self.conversationView.conversationVM.members) {
        if(channelMember.robot) {
            [robots addObject:channelMember.memberUid];
        }
    }
    return robots;
}

-(void) requestLoadChannelInfoIfNeed{
    BOOL needFetch = false;
    self.channelInfo = [[WKChannelManager shared] getChannelInfo:self.channel];
    self.conversationView.conversationVM.channelInfo = self.channelInfo;
    if(self.channelInfo) {
        if(self.conversationView.conversationVM.groupType == WKGroupTypeSuper) {
            needFetch = true; // 超级群每次都获取channelInfo
        }
        __weak typeof(self) weakSelf  = self;
        lim_dispatch_main_async_safe(^{
            [weakSelf channelInfoLoadFinished];
        })
    }else {
        needFetch = true;
    }
    
    if(needFetch) {
        [[WKChannelManager shared] fetchChannelInfo:self.channel];
    }
}

- (void)dealloc {
    NSLog(@"会话页面释放");
    [self removeDelegates];
    [self markFlameMessages];
}

-(void) channelInfoLoadFinished {
    [self refreshTitle];
    if(![self verifyChatPasswordIfNeeded]) {
        return;
    }
    [self.conversationView setGroupForbiddenIfNeed];
    if(self.channel.channelType == WK_PERSON && self.channelInfo.robot) {
        [self.conversationView syncRobot:@[self.channel.channelId]];
    }
    
    if(self.firstLoad) {
        self.firstLoad = false;
        WKGroupType groupType =  self.conversationView.conversationVM.groupType;
        if(groupType == WKGroupTypeCommon) { // 普通群
            [self commonGroupInit];
        }else if(groupType == WKGroupTypeSuper) { // 超级群
            [self superGroupInit];
        }
    }
    
    
}

-(BOOL)verifyChatPasswordIfNeeded {
    if(!self.channelInfo) {
        return YES;
    }
    BOOL chatPwdOn = [self.channelInfo settingForKey:WKChannelExtraKeyChatPwd defaultValue:false];
    if(!chatPwdOn) {
        self.chatPasswordVerified = YES;
        self.conversationView.hidden = NO;
        return YES;
    }
    if(self.chatPasswordVerified || [[[WKApp shared].loginInfo.extra objectForKey:[self chatPwdVerifiedKey]] boolValue]) {
        self.chatPasswordVerified = YES;
        self.conversationView.hidden = NO;
        return YES;
    }
    self.conversationView.hidden = YES;
    if(self.chatPasswordPrompting) {
        return NO;
    }
    NSString *chatPwd = [WKApp shared].loginInfo.extra[@"chat_pwd"];
    if(chatPwd.length == 0) {
        [self showChatPasswordSetupAlert];
        return NO;
    }
    [self showChatPasswordVerifyInput:chatPwd];
    return NO;
}

-(void)showChatPasswordSetupAlert {
    self.chatPasswordPrompting = YES;
    __weak typeof(self) weakSelf = self;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LLang(@"聊天密码") message:LLang(@"请先设置6位数字聊天密码") preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:LLang(@"取消") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        weakSelf.chatPasswordPrompting = NO;
        [[WKNavigationManager shared] popViewControllerAnimated:YES];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:LLang(@"去设置") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        WKConversationPasswordVC *vc = [WKConversationPasswordVC new];
        vc.onFinish = ^{
            weakSelf.chatPasswordPrompting = NO;
            [weakSelf markChatPasswordVerified];
            [weakSelf channelInfoLoadFinished];
        };
        [[WKNavigationManager shared] pushViewController:vc animated:YES];
    }]];
    [[WKNavigationManager shared].topViewController presentViewController:alertController animated:YES completion:nil];
}

-(void)showChatPasswordVerifyInput:(NSString*)chatPwd {
    self.chatPasswordPrompting = YES;
    __weak typeof(self) weakSelf = self;
    __block NSInteger errorCount = [self getChatPwdErrorCount:self.channel];
    WKPwdKeyboardInputView *vw = [WKPwdKeyboardInputView new];
    vw.remark = LLang(@"聊天密码");
    [vw setFinishBlock:^(NSString * _Nonnull pwd) {
        if([[WKConversationPasswordVM digestPwd:pwd] isEqualToString:chatPwd]) {
            weakSelf.chatPasswordPrompting = NO;
            [weakSelf setChatPwdErrorCount:0 channel:weakSelf.channel];
            [weakSelf markChatPasswordVerified];
            [weakSelf channelInfoLoadFinished];
        }else {
            errorCount++;
            [weakSelf setChatPwdErrorCount:errorCount channel:weakSelf.channel];
            if(errorCount >= 3) {
                [WKAlertUtil alert:LLang(@"连续错误次数太多，已删除该聊天记录！") title:LLang(@"错误密码")];
                [[WKMessageManager shared] clearMessages:weakSelf.channel];
                [weakSelf setChatPwdErrorCount:0 channel:weakSelf.channel];
            }else {
                [WKAlertUtil alert:[NSString stringWithFormat:LLang(@"还连续%ld次输入错误，将会清空该聊天记录！\n如果您忘记聊天密码，您可以重置聊天密码"),3 - (long)errorCount] title:LLang(@"错误密码")];
            }
        }
    }];
    [vw setCancelBlock:^{
        weakSelf.chatPasswordPrompting = NO;
        [[WKNavigationManager shared] popViewControllerAnimated:YES];
    }];
    [vw setOtherButtonClickBlock:^(UIButton *btn) {
        weakSelf.chatPasswordPrompting = NO;
        WKConversationPasswordVC *vc = [WKConversationPasswordVC new];
        [[WKNavigationManager shared] pushViewController:vc animated:YES];
    }];
    [vw show];
}

-(void)markChatPasswordVerified {
    self.chatPasswordVerified = YES;
    self.conversationView.hidden = NO;
    [WKApp shared].loginInfo.extra[[self chatPwdVerifiedKey]] = @(YES);
}

-(void)setChatPwdErrorCount:(NSInteger)count channel:(WKChannel*)channel {
    [[NSUserDefaults standardUserDefaults] setInteger:count forKey:[self chatPwdErrorKey:channel]];
}

-(NSInteger)getChatPwdErrorCount:(WKChannel*)channel {
    return [[NSUserDefaults standardUserDefaults] integerForKey:[self chatPwdErrorKey:channel]];
}

-(NSString*)chatPwdErrorKey:(WKChannel*)channel {
    return [NSString stringWithFormat:@"chatpwderror_%@_%@_%hhu",[WKApp shared].loginInfo.uid,channel.channelId,channel.channelType];
}

-(NSString*)chatPwdVerifiedKey {
    return [NSString stringWithFormat:@"chatpwdverified_%@_%@_%hhu",[WKApp shared].loginInfo.uid,self.channel.channelId,self.channel.channelType];
}
// 超级群初始化
-(void) superGroupInit {
    [self refreshTitle];
}

// 普通群初始化
-(void) commonGroupInit {
    [self.conversationView.conversationVM requestMembers];
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.conversationView viewWillDisappear:animated];
   
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.conversationView viewWillAppear];
    [self updateInjectedTopPanel];
    [self queryRTCChannelStateIfNeed];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.conversationView viewDidDisappear];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.conversationView viewDidAppear];
}
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    [self.conversationView layoutSubviews];
    [self.conversationView.messageListView viewDidLayoutSubviewsOfPosition];
}

- (WKConversationView *)conversationView {
    if(!_conversationView) {
        CGFloat offset = self.navigationBar.lim_bottom;
        _conversationView = [[WKConversationView alloc] initWithFrame:CGRectMake(0.0f, offset, self.view.lim_width, self.view.lim_height - offset) channel:self.channel];
        __weak typeof(self) weakSelf = self;
        _conversationView.onMultiple = ^(BOOL on) {
            // 显示或隐藏 取消按钮
            weakSelf.navigationBar.showBackButton = !on;
            if(on) {
                [weakSelf.navigationBar addSubview:weakSelf.cancelMutipleBtn];
            }else{
                [weakSelf.cancelMutipleBtn removeFromSuperview];
            }
        };
    }
    return _conversationView;
}
-(void) refreshTitle {
    if(self.channelInfo) {
        
        self.channelHeader.channelInfo = self.channelInfo;
        self.channelHeader.memberCount = self.conversationView.conversationVM.memberCount;
        
        
        [self.channelHeader layoutSubviews];
        
        NSString *channelName = self.channelInfo.displayName;
        NSString *showChannelName = [channelName limitedStringForMaxBytesLength:20];
        if(showChannelName.length <channelName.length) {
            showChannelName = [NSString stringWithFormat:@"%@...",showChannelName];
        }
        [self.conversationView.input.textView internalTextView].placeholder=[NSString stringWithFormat:LLang(@"发送给 %@"),showChannelName];
       
    }
}

- (UIImageView *)backgroundView {
    if(!_backgroundView) {
        _backgroundView = [[UIImageView alloc] initWithFrame:self.view.bounds];
        _backgroundView.clipsToBounds = YES;
        _backgroundView.contentMode = UIViewContentModeScaleAspectFill;
    }
    return _backgroundView;
}

- (void)viewConfigChange:(WKViewConfigChangeType)type {
    [super viewConfigChange:type];
    if(type == WKViewConfigChangeTypeStyle) {
        [self setupChatBackground];
    }
}

-(void) setChatBackgroud:(UIImage*)img {
//    self.view.layer.contents = (id)img.CGImage;
    self.backgroundView.image = img;
}

-(BOOL) hasSetChatBackgroud {
    if(self.view.layer.contents) {
        return true;
    }
    return false;
}

-(void) setupChatBackground {
    if([self hasSetChatBackgroud]) {
        return;
    }
    [self updateChatBackground];
   
}

-(void) updateChatBackground {
    BOOL existChannelBg = [WKThemeUtil existChatBackground:self.channel];
    if(existChannelBg) {
       NSData *channelBgData = [WKThemeUtil getChatBackground:self.channel style:WKApp.shared.config.style];
        if(channelBgData) {
            [self setChatBackgroud:[UIImage imageWithData:channelBgData]];
            return;
        }
    }
    
    BOOL existDefaultBg = [WKThemeUtil existDefaultbackground];
    if(existDefaultBg) {
        NSData *defaultBgData = [WKThemeUtil getDefaultBackground:WKApp.shared.config.style];
         if(defaultBgData) {
             [self setChatBackgroud:[UIImage imageWithData:defaultBgData]];
             return;
         }
    }
    
    [self setChatBackgroud:[self imageName:@"Conversation/Index/ChatBg"]];
}

- (WKConversationChannelHeader *)channelHeader {
    if(!_channelHeader) {
        CGFloat leftSpace = 50.0f;
        CGFloat rightSpace = 10.0f;
        CGFloat statusBottom = [UIApplication sharedApplication].statusBarFrame.origin.y + [UIApplication sharedApplication].statusBarFrame.size.height;
       
        _channelHeader = [[WKConversationChannelHeader alloc] initWithFrame:CGRectMake(leftSpace, statusBottom, self.view.lim_width - leftSpace - rightSpace, self.navigationBar.lim_height - (statusBottom))];
        __weak typeof(self) weakSelf = self;
        [_channelHeader setOnInfo:^{
            [[WKApp shared] invoke:WKPOINT_CONVERSATION_SETTING param:@{@"channel":weakSelf.channel,@"context":weakSelf.conversationView.conversationContext}];
        }];
        
        [self refreshRTCCallButtons];
        
        [_channelHeader setOnVoiceCall:^{
            [weakSelf startRTCCall:WKRTCCallTypeAudio];
        }];
        
        [_channelHeader setOnVideoCall:^{
            [weakSelf startRTCCall:WKRTCCallTypeVideo];
        }];
//        [_channelHeader setBackgroundColor:[UIColor redColor]];
    }
    return _channelHeader;
}

-(void) showVideoCall:(BOOL) show {
    if(!show) {
        _channelHeader.voiceCallBtn.hidden = YES;
        _channelHeader.videoCallBtn.hidden = YES;
    }else {
        _channelHeader.voiceCallBtn.hidden = NO;
        _channelHeader.videoCallBtn.hidden = NO;
    }
    [_channelHeader layoutSubviews];
}

// 根据当前会话类型刷新 RTC 入口，私聊和群聊都支持语音/视频。
-(void) refreshRTCCallButtons {
    BOOL support = self.channel && (self.channel.channelType == WK_PERSON || self.channel.channelType == WK_GROUP);
    if(self.channel.channelType == WK_PERSON) {
        if([self.channel.channelId isEqualToString:[WKApp shared].config.systemUID] ||
           [self.channel.channelId isEqualToString:[WKApp shared].config.fileHelperUID]) {
            support = NO;
        }
    }
    [self showVideoCall:support];
}

// 从会话页发起 RTC 通话，所有鉴权和媒体权限检查由会话管理器继续处理。
-(void) startRTCCall:(WKRTCCallType)callType {
    if(self.channel.channelType == WK_GROUP) {
        [self showRTCGroupInviteOptionsForCallType:callType];
        return;
    }
    [[WKRTCSessionManager shared] startCallWithChannel:self.channel callType:callType inviteUids:nil];
}

// 群聊发起通话时允许选择强邀请成员；不选择则按普通群通话发起。
-(void) showRTCGroupInviteOptionsForCallType:(WKRTCCallType)callType {
    NSString *title = callType == WKRTCCallTypeVideo ? LLang(@"发起群视频通话") : LLang(@"发起群语音通话");
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:LLang(@"可选择需要强提醒的群成员") preferredStyle:UIAlertControllerStyleActionSheet];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:LLang(@"直接发起") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[WKRTCSessionManager shared] startCallWithChannel:weakSelf.channel callType:callType inviteUids:nil];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:LLang(@"选择成员并发起") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf showRTCGroupInviteSelectorForCallType:callType];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:LLang(@"取消") style:UIAlertActionStyleCancel handler:nil]];
    if(alert.popoverPresentationController) {
        alert.popoverPresentationController.sourceView = callType == WKRTCCallTypeVideo ? self.channelHeader.videoCallBtn : self.channelHeader.voiceCallBtn;
        alert.popoverPresentationController.sourceRect = alert.popoverPresentationController.sourceView.bounds;
    }
    [[WKNavigationManager shared].topViewController presentViewController:alert animated:YES completion:nil];
}

// 成员选择器只使用当前 SDK 已同步的群成员；服务端仍会最终校验邀请权限。
-(void) showRTCGroupInviteSelectorForCallType:(WKRTCCallType)callType {
    NSArray<WKContactsSelect *> *members = [self rtcInviteContactsForCurrentGroup];
    if(members.count == 0) {
        [[WKNavigationManager shared].topViewController.view showMsg:LLang(@"群成员数据为空，请稍后重试")];
        return;
    }
    WKContactsSelectVC *vc = [WKContactsSelectVC new];
    vc.showBack = YES;
    vc.mode = WKContactsModeMulti;
    vc.title = LLang(@"选择邀请成员");
    vc.data = members;
    NSString *uid = [WKSDK shared].options.connectInfo.uid;
    vc.hiddenUsers = uid.length > 0 ? @[uid] : @[];
    __weak typeof(self) weakSelf = self;
    vc.onFinishedSelect = ^(NSArray<NSString *> *uids) {
        if(uids.count == 0) {
            [[WKNavigationManager shared].topViewController.view showMsg:LLang(@"请选择成员")];
            return;
        }
        UIViewController *selectorVC = weakSelf.presentedViewController;
        void (^startBlock)(void) = ^{
            [[WKRTCSessionManager shared] startCallWithChannel:weakSelf.channel callType:callType inviteUids:uids];
        };
        if(selectorVC) {
            [selectorVC dismissViewControllerAnimated:YES completion:startBlock];
        }else {
            startBlock();
        }
    };
    [[WKNavigationManager shared].topViewController presentViewController:vc animated:YES completion:nil];
}

-(NSArray<WKContactsSelect *> *)rtcInviteContactsForCurrentGroup {
    if(self.channel.channelType != WK_GROUP || self.channel.channelId.length == 0) {
        return @[];
    }
    WKChannel *channel = [[WKChannel alloc] initWith:self.channel.channelId channelType:self.channel.channelType];
    NSArray<WKChannelMember *> *members = [[WKSDK shared].channelManager getMembersWithChannel:channel];
    NSMutableArray<WKContactsSelect *> *items = [NSMutableArray array];
    for (WKChannelMember *member in members) {
        if(member.memberUid.length == 0) {
            continue;
        }
        [items addObject:[WKModelConvert toContactsSelect:member]];
    }
    return items.copy;
}

-(void) showTopView:(BOOL)show {
    [self.conversationView showTopView:show animated:YES];
}

-(void) updateInjectedTopPanel {
    [self.conversationView.topView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    CGFloat topHeight = 0.0f;
    if([self shouldShowRTCTopPanelForPayload:self.currentRTCTopPayload]) {
        [self configureRTCTopPanelWithPayload:self.currentRTCTopPayload];
        self.rtcTopPanel.frame = CGRectMake(0.0f, topHeight, self.conversationView.topView.lim_width, 54.0f);
        [self layoutRTCTopPanel];
        [self.conversationView.topView addSubview:self.rtcTopPanel];
        topHeight += self.rtcTopPanel.lim_height;
    }
    if(self.injectedTopPanel) {
        self.injectedTopPanel.lim_top = topHeight;
        [self.conversationView.topView addSubview:self.injectedTopPanel];
        topHeight += self.injectedTopPanel.lim_height;
    }
    if(topHeight > 0.0f) {
        self.conversationView.topView.lim_height = topHeight;
        [self.conversationView showTopView:YES animated:YES];
    }else {
        [self.conversationView showTopView:NO animated:YES];
    }
}

#pragma mark - RTC 顶部通话入口

// 只在群语音会话展示普通正在通话入口，私聊与群视频仍走通话页。
-(void) queryRTCChannelStateIfNeed {
    if(self.channel.channelType != WK_GROUP || self.channel.channelId.length == 0 || self.rtcStateRequesting) {
        return;
    }
    self.rtcStateRequesting = YES;
    __weak typeof(self) weakSelf = self;
    [[WKRTCAPI shared] channelStateWithChannelId:self.channel.channelId channelType:self.channel.channelType].then(^(WKRTCChannelStateResp *resp){
        weakSelf.rtcStateRequesting = NO;
        if(resp.existing && resp.callId.length > 0 && resp.callType == WKRTCCallTypeAudio) {
            WKRTCCallPayload *payload = [WKRTCCallPayload payloadWithChannelState:resp channel:weakSelf.channel];
            [weakSelf showRTCTopPayload:payload];
        }else {
            [weakSelf hideRTCTopPayloadIfCallId:nil];
        }
    }).catch(^(NSError *error){
        weakSelf.rtcStateRequesting = NO;
        WKLogDebug(@"音视频查询群聊通话状态失败：%@", error);
    });
}

// 处理服务端在线通话通知，当前会话匹配时刷新顶部入口。
-(void) rtcChannelCallDidChange:(NSNotification*)notification {
    WKRTCCallPayload *payload = notification.userInfo[@"payload"];
    NSString *cmd = notification.userInfo[@"cmd"];
    if(![payload isKindOfClass:WKRTCCallPayload.class] || ![self isCurrentChannelRTCPayload:payload]) {
        return;
    }
    if([cmd isEqualToString:@"rtc.closed"] ||
       [cmd isEqualToString:@"rtc.cancelled"] ||
       [cmd isEqualToString:@"rtc.timeout"]) {
        [self hideRTCTopPayloadIfCallId:payload.callId];
        return;
    }
    if([cmd isEqualToString:@"rtc.notice"] || [cmd isEqualToString:@"rtc.invite"] || [cmd isEqualToString:@"rtc.joined"]) {
        if([self shouldShowRTCTopPanelForPayload:payload]) {
            [self showRTCTopPayload:payload];
        }else {
            [self hideRTCTopPayloadIfCallId:payload.callId];
        }
    }
}

-(BOOL) isCurrentChannelRTCPayload:(WKRTCCallPayload*)payload {
    return payload.channelType == self.channel.channelType && [payload.channelId isEqualToString:self.channel.channelId];
}

-(BOOL) shouldShowRTCTopPanelForPayload:(WKRTCCallPayload*)payload {
    return payload.callId.length > 0 && payload.channelType == WK_GROUP && payload.callType == WKRTCCallTypeAudio;
}

-(void) showRTCTopPayload:(WKRTCCallPayload*)payload {
    if(![self shouldShowRTCTopPanelForPayload:payload]) {
        return;
    }
    self.currentRTCTopPayload = payload;
    [self updateInjectedTopPanel];
}

-(void) hideRTCTopPayloadIfCallId:(NSString*)callId {
    if(callId.length > 0 && self.currentRTCTopPayload.callId.length > 0 && ![self.currentRTCTopPayload.callId isEqualToString:callId]) {
        return;
    }
    self.currentRTCTopPayload = nil;
    [self updateInjectedTopPanel];
}

-(void) configureRTCTopPanelWithPayload:(WKRTCCallPayload*)payload {
    self.rtcTopTitleLabel.text = LLang(@"正在通话，点击加入");
    NSString *fromName = payload.fromName.length > 0 ? payload.fromName : payload.fromUid;
    NSString *callType = payload.callType == WKRTCCallTypeVideo ? LLang(@"群视频通话") : LLang(@"群语音通话");
    if(fromName.length > 0) {
        self.rtcTopSubtitleLabel.text = [NSString stringWithFormat:@"%@%@%@", fromName, LLang(@"发起 · "), callType];
    }else {
        self.rtcTopSubtitleLabel.text = callType;
    }
    [self.rtcTopPanel setNeedsLayout];
}

-(void) layoutRTCTopPanel {
    CGFloat width = self.rtcTopPanel.lim_width > 0.0f ? self.rtcTopPanel.lim_width : WKScreenWidth;
    UIView *dotView = [self.rtcTopPanel viewWithTag:1001];
    UILabel *arrowLabel = (UILabel*)[self.rtcTopPanel viewWithTag:1002];
    dotView.frame = CGRectMake(14.0f, 22.0f, 10.0f, 10.0f);
    arrowLabel.frame = CGRectMake(width - 32.0f, 0.0f, 18.0f, 54.0f);
    self.rtcTopTitleLabel.frame = CGRectMake(36.0f, 8.0f, width - 78.0f, 21.0f);
    self.rtcTopSubtitleLabel.frame = CGRectMake(36.0f, 30.0f, width - 78.0f, 17.0f);
}

-(void) rtcTopPanelPressed {
    WKRTCCallPayload *payload = self.currentRTCTopPayload;
    if(payload.callId.length == 0) {
        [self queryRTCChannelStateIfNeed];
        return;
    }
    [[WKNavigationManager shared].topViewController.view showHUD:LLang(@"正在加入")];
    __weak typeof(self) weakSelf = self;
    [[WKRTCSessionManager shared] joinCallWithPayload:payload joinCode:@"" completion:^(NSError * _Nullable error) {
        [[WKNavigationManager shared].topViewController.view hideHud];
        if(error) {
            if(error.code == 40006) {
                [weakSelf showRTCJoinCodePromptForPayload:payload message:error.localizedDescription ?: LLang(@"请输入加入码后重试")];
            }else {
                [[WKNavigationManager shared].topViewController.view showMsg:error.localizedDescription ?: LLang(@"加入通话失败")];
            }
            [weakSelf queryRTCChannelStateIfNeed];
        }
    }];
}

// 服务端要求加入码时，基于当前已知通话编号继续输入加入码，不自行推断其他通话信息。
-(void) showRTCJoinCodePromptForPayload:(WKRTCCallPayload*)payload message:(NSString*)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:LLang(@"输入加入码") message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = LLang(@"通话编号");
        textField.text = payload.callId ?: @"";
        textField.enabled = payload.callId.length == 0;
    }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = LLang(@"加入码");
        textField.keyboardType = UIKeyboardTypeNumberPad;
    }];
    [alert addAction:[UIAlertAction actionWithTitle:LLang(@"取消") style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:LLang(@"加入") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *callId = alert.textFields.firstObject.text ?: @"";
        NSString *joinCode = alert.textFields.lastObject.text ?: @"";
        if(callId.length == 0 || joinCode.length == 0) {
            [[WKNavigationManager shared].topViewController.view showMsg:LLang(@"通话编号和加入码不能为空")];
            return;
        }
        WKRTCCallPayload *joinPayload = [WKRTCCallPayload new];
        joinPayload.callId = callId;
        joinPayload.roomName = payload.roomName ?: @"";
        joinPayload.channelId = payload.channelId ?: weakSelf.channel.channelId;
        joinPayload.channelType = payload.channelType ?: weakSelf.channel.channelType;
        joinPayload.callType = payload.callType;
        [[WKNavigationManager shared].topViewController.view showHUD:LLang(@"正在加入")];
        [[WKRTCSessionManager shared] joinCallWithPayload:joinPayload joinCode:joinCode completion:^(NSError * _Nullable error) {
            [[WKNavigationManager shared].topViewController.view hideHud];
            if(error) {
                [[WKNavigationManager shared].topViewController.view showMsg:error.localizedDescription ?: LLang(@"加入通话失败")];
            }
        }];
    }]];
    [[WKNavigationManager shared].topViewController presentViewController:alert animated:YES completion:nil];
}

- (UIControl *)rtcTopPanel {
    if(!_rtcTopPanel) {
        _rtcTopPanel = [[UIControl alloc] initWithFrame:CGRectMake(0.0f, 0.0f, WKScreenWidth, 54.0f)];
        _rtcTopPanel.backgroundColor = [WKApp.shared.config.themeColor colorWithAlphaComponent:0.92f];
        [_rtcTopPanel addTarget:self action:@selector(rtcTopPanelPressed) forControlEvents:UIControlEventTouchUpInside];
        
        UIView *dotView = [[UIView alloc] initWithFrame:CGRectMake(14.0f, 20.0f, 10.0f, 10.0f)];
        dotView.backgroundColor = UIColor.whiteColor;
        dotView.layer.cornerRadius = 5.0f;
        dotView.layer.masksToBounds = YES;
        dotView.tag = 1001;
        [_rtcTopPanel addSubview:dotView];
        
        [_rtcTopPanel addSubview:self.rtcTopTitleLabel];
        [_rtcTopPanel addSubview:self.rtcTopSubtitleLabel];
        
        UILabel *arrowLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        arrowLabel.text = @">";
        arrowLabel.textColor = UIColor.whiteColor;
        arrowLabel.font = [UIFont systemFontOfSize:18.0f weight:UIFontWeightSemibold];
        arrowLabel.textAlignment = NSTextAlignmentRight;
        arrowLabel.tag = 1002;
        [_rtcTopPanel addSubview:arrowLabel];
    }
    return _rtcTopPanel;
}

- (UILabel *)rtcTopTitleLabel {
    if(!_rtcTopTitleLabel) {
        _rtcTopTitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _rtcTopTitleLabel.textColor = UIColor.whiteColor;
        _rtcTopTitleLabel.font = [WKApp.shared.config appFontOfSizeSemibold:15.0f];
    }
    return _rtcTopTitleLabel;
}

- (UILabel *)rtcTopSubtitleLabel {
    if(!_rtcTopSubtitleLabel) {
        _rtcTopSubtitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _rtcTopSubtitleLabel.textColor = [UIColor colorWithWhite:1.0f alpha:0.82f];
        _rtcTopSubtitleLabel.font = [WKApp.shared.config appFontOfSize:12.0f];
        _rtcTopSubtitleLabel.adjustsFontSizeToFitWidth = YES;
        _rtcTopSubtitleLabel.minimumScaleFactor = 0.75f;
    }
    return _rtcTopSubtitleLabel;
}


- (UIButton *)cancelMutipleBtn {
    if(!_cancelMutipleBtn) {
        CGFloat statusHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
        _cancelMutipleBtn = [[UIButton alloc] initWithFrame:CGRectMake(10.0f, statusHeight, 0.0f, 0.0f)];
        [_cancelMutipleBtn setTitle:LLang(@"取消") forState:UIControlStateNormal];
        [_cancelMutipleBtn.titleLabel setFont:[[WKApp shared].config appFontOfSize:16.0f]];
        [_cancelMutipleBtn setTitleColor:[WKApp shared].config.defaultTextColor forState:UIControlStateNormal];
        [_cancelMutipleBtn sizeToFit];
        [_cancelMutipleBtn addTarget:self action:@selector(cancelMultiplePressed) forControlEvents:UIControlEventTouchUpInside];
        _cancelMutipleBtn.lim_top = (self.navigationBar.lim_height - statusHeight)/2.0f - _cancelMutipleBtn.lim_height/2.0f + statusHeight;
    }
    return _cancelMutipleBtn;
}

-(void) cancelMultiplePressed {
    [self.conversationView setMultipleOn:NO selectedMessage:nil];
}

-(UIImage*) imageName:(NSString*)name {
    return [WKApp.shared loadImage:name moduleID:@"WuKongBase"];
//    return [[WKResource shared] resourceForImage:name podName:@"WuKongBase_images"];
}

#pragma mark - WKChannelManagerDelegate
// 频道信息更新
-(void) channelInfoUpdate:(WKChannelInfo*)channelInfo oldChannelInfo:(WKChannelInfo * _Nullable)oldChannelInfo {
    if([self.channel isEqual:channelInfo.channel]) { // 更新的当前会话的信息
        self.channelInfo = channelInfo;
        self.conversationView.conversationVM.channelInfo = self.channelInfo;
        [self channelInfoLoadFinished];
        if(oldChannelInfo.flame!=channelInfo.flame) {
            [(id<WKConversationContext>)self.conversationView.conversationContext refreshInputView];
        }
    }
   
}
@end

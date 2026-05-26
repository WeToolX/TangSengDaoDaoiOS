//
//  WKRTCMessageCell.m
//  WuKongBase
//

#import "WKRTCMessageCell.h"
#import "WKRTCMessageContent.h"
#import "WKRTCSessionManager.h"
#import <Toast/UIView+Toast.h>

@interface WKRTCMessageCell ()

@property(nonatomic,strong) UIView *cardView;
@property(nonatomic,strong) UIImageView *iconImageView;
@property(nonatomic,strong) UILabel *titleLabel;
@property(nonatomic,strong) UILabel *subtitleLabel;
@property(nonatomic,strong) UILabel *actionLabel;

@end

@implementation WKRTCMessageCell

+ (CGSize)contentSizeForMessage:(WKMessageModel *)model {
    WKRTCMessageContent *content = (WKRTCMessageContent *)model.content;
    if(![content isKindOfClass:WKRTCMessageContent.class] || [content isNotice]) {
        return CGSizeMake(260.0f, 88.0f);
    }
    NSString *text = [content recordTextForCurrentUid:[WKApp shared].loginInfo.uid];
    UIFont *font = [[WKApp shared].config appFontOfSize:15.0f];
    CGSize textSize = [text boundingRectWithSize:CGSizeMake(180.0f, 22.0f)
                                         options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                      attributes:@{NSFontAttributeName:font}
                                         context:nil].size;
    CGSize trailingSize = [WKTrailingView size:model];
    CGFloat titleWidth = ceil(textSize.width) + 12.0f + 18.0f + 6.0f + 12.0f;
    CGFloat timeWidth = trailingSize.width + 15.0f + 10.0f;
    CGFloat width = MAX(titleWidth, timeWidth);
    return CGSizeMake(MAX(104.0f, MIN(250.0f, width)), 52.0f);
}

- (void)initUI {
    [super initUI];
    self.messageContentView.layer.masksToBounds = YES;
    self.messageContentView.layer.cornerRadius = 8.0f;
    
    self.cardView = [[UIView alloc] init];
    self.cardView.userInteractionEnabled = NO;
    [self.messageContentView addSubview:self.cardView];
    
    self.iconImageView = [[UIImageView alloc] init];
    self.iconImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.iconImageView.tintColor = WKApp.shared.config.messageRecvTextColor;
    [self.cardView addSubview:self.iconImageView];
    
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = [WKApp.shared.config appFontOfSize:15.0f];
    self.titleLabel.textColor = WKApp.shared.config.messageRecvTextColor;
    [self.cardView addSubview:self.titleLabel];
    
    self.subtitleLabel = [[UILabel alloc] init];
    self.subtitleLabel.font = [WKApp.shared.config appFontOfSize:12.0f];
    self.subtitleLabel.textColor = WKApp.shared.config.tipColor;
    self.subtitleLabel.numberOfLines = 2;
    [self.cardView addSubview:self.subtitleLabel];
    
    self.actionLabel = [[UILabel alloc] init];
    self.actionLabel.textAlignment = NSTextAlignmentRight;
    self.actionLabel.font = [WKApp.shared.config appFontOfSizeMedium:13.0f];
    self.actionLabel.textColor = WKApp.shared.config.themeColor;
    [self.cardView addSubview:self.actionLabel];
    
    [self.messageContentView bringSubviewToFront:self.trailingView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rtcChannelCallDidChange:) name:WKRTCChannelCallDidChangeNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:WKRTCChannelCallDidChangeNotification object:nil];
}

- (void)refresh:(WKMessageModel *)model {
    [super refresh:model];
    WKRTCMessageContent *content = (WKRTCMessageContent *)model.content;
    BOOL notice = [content isNotice];
    
    self.messageContentView.backgroundColor = model.isSend ? WKApp.shared.config.themeColor : WKApp.shared.config.cellBackgroundColor;
    self.messageContentView.layer.cornerRadius = notice ? 8.0f : 4.0f;
    self.iconImageView.image = [self iconForCallType:content.callType];
    UIColor *contentColor = model.isSend ? WKApp.shared.config.messageSendTextColor : WKApp.shared.config.messageRecvTextColor;
    self.iconImageView.tintColor = notice ? UIColor.whiteColor : contentColor;
    BOOL endedNotice = notice && [[WKRTCSessionManager shared] isCallEnded:content.callId];
    self.titleLabel.text = notice ? (endedNotice ? LLang(@"群通话已结束") : LLang(@"群通话进行中")) : [content recordTextForCurrentUid:[WKApp shared].loginInfo.uid];
    self.titleLabel.textColor = notice ? WKApp.shared.config.messageRecvTextColor : contentColor;
    if(notice) {
        NSString *callType = content.callType == WKRTCCallTypeVideo ? LLang(@"视频通话") : LLang(@"语音通话");
        NSString *fromName = WKRTCDisplayNameForUID(content.fromUid);
        self.iconImageView.backgroundColor = endedNotice ? WKApp.shared.config.tipColor : WKApp.shared.config.themeColor;
        self.iconImageView.layer.cornerRadius = 22.0f;
        self.iconImageView.layer.masksToBounds = YES;
        self.subtitleLabel.text = fromName.length > 0 ? [NSString stringWithFormat:@"%@%@%@", fromName, LLang(@"发起 · "), callType] : callType;
        self.actionLabel.text = endedNotice ? @"" : LLang(@"加入");
    }else {
        self.iconImageView.backgroundColor = UIColor.clearColor;
        self.iconImageView.layer.cornerRadius = 0.0f;
        self.iconImageView.layer.masksToBounds = NO;
        self.subtitleLabel.text = @"";
        self.actionLabel.text = @"";
    }
    self.subtitleLabel.hidden = !notice;
    self.actionLabel.hidden = !notice || endedNotice;
    self.trailingView.hidden = NO;
    [self.messageContentView bringSubviewToFront:self.trailingView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.cardView.frame = self.messageContentView.bounds;
    WKRTCMessageContent *content = (WKRTCMessageContent *)self.messageModel.content;
    if([content isNotice]) {
        self.iconImageView.frame = CGRectMake(12.0f, 18.0f, 44.0f, 44.0f);
        CGFloat actionAreaWidth = self.actionLabel.hidden ? 12.0f : 58.0f;
        self.actionLabel.frame = CGRectMake(self.cardView.lim_width - actionAreaWidth, 0.0f, MAX(0.0f, actionAreaWidth - 12.0f), self.cardView.lim_height);
        CGFloat textLeft = self.iconImageView.lim_right + 10.0f;
        CGFloat textRight = self.cardView.lim_width - actionAreaWidth - 12.0f;
        self.titleLabel.frame = CGRectMake(textLeft, 16.0f, textRight - textLeft, 22.0f);
        self.subtitleLabel.frame = CGRectMake(textLeft, self.titleLabel.lim_bottom + 4.0f, textRight - textLeft, 34.0f);
        return;
    }
    
    CGFloat iconSize = 18.0f;
    CGFloat contentRowHeight = 32.0f;
    CGFloat iconTop = (contentRowHeight - iconSize)/2.0f;
    if(self.messageModel.isSend) {
        self.iconImageView.frame = CGRectMake(self.cardView.lim_width - 12.0f - iconSize, iconTop, iconSize, iconSize);
        self.titleLabel.frame = CGRectMake(12.0f, 0.0f, self.iconImageView.lim_left - 18.0f, contentRowHeight);
        self.titleLabel.textAlignment = NSTextAlignmentRight;
    }else {
        self.iconImageView.frame = CGRectMake(12.0f, iconTop, iconSize, iconSize);
        self.titleLabel.frame = CGRectMake(self.iconImageView.lim_right + 6.0f, 0.0f, self.cardView.lim_width - self.iconImageView.lim_right - 18.0f, contentRowHeight);
        self.titleLabel.textAlignment = NSTextAlignmentLeft;
    }
}

- (BOOL)respondContentSingleTap {
    return YES;
}

- (void)onTap {
    [super onTap];
    WKRTCMessageContent *content = (WKRTCMessageContent *)self.messageModel.content;
    if(![content isNotice]) {
        WKChannel *channel = self.messageModel.channel;
        if(!channel || channel.channelId.length == 0) {
            channel = [WKChannel channelID:content.channelId channelType:content.channelType];
        }
        [[WKRTCSessionManager shared] startCallWithChannel:channel callType:content.callType inviteUids:nil];
        return;
    }
    WKRTCCallPayload *payload = [content toCallPayloadWithMessageChannel:self.messageModel.channel];
    if(payload.callId.length == 0) {
        [[WKNavigationManager shared].topViewController.view makeToast:LLang(@"通话编号为空")];
        return;
    }
    if([[WKRTCSessionManager shared] isCallEnded:payload.callId]) {
        [[WKNavigationManager shared].topViewController.view makeToast:LLang(@"通话已结束")];
        return;
    }
    [[WKRTCSessionManager shared] joinCallWithPayload:payload joinCode:@"" completion:^(NSError * _Nullable error) {
        if(error) {
            [[WKNavigationManager shared].topViewController.view makeToast:error.localizedDescription ?: LLang(@"加入通话失败")];
        }
    }];
}

- (void)rtcChannelCallDidChange:(NSNotification *)notification {
    WKRTCMessageContent *content = (WKRTCMessageContent *)self.messageModel.content;
    WKRTCCallPayload *payload = notification.userInfo[@"payload"];
    NSString *cmd = notification.userInfo[@"cmd"];
    if(![content isKindOfClass:WKRTCMessageContent.class] ||
       ![payload isKindOfClass:WKRTCCallPayload.class] ||
       ![content isNotice] ||
       content.callId.length == 0 ||
       ![content.callId isEqualToString:payload.callId]) {
        return;
    }
    if([cmd isEqualToString:@"rtc.closed"] ||
       [cmd isEqualToString:@"rtc.cancelled"] ||
       [cmd isEqualToString:@"rtc.timeout"] ||
       [cmd isEqualToString:@"rtc.rejected"]) {
        [self refresh:self.messageModel];
        [self setNeedsLayout];
    }
}

+ (BOOL)hiddenBubble {
    return YES;
}

- (UIImage *)iconForCallType:(WKRTCCallType)callType {
    NSString *symbolName = callType == WKRTCCallTypeVideo ? @"video" : @"phone";
    UIImage *image = [UIImage systemImageNamed:symbolName];
    return [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

@end

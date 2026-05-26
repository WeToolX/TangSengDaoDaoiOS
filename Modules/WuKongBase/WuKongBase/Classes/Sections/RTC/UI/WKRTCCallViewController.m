//
//  WKRTCCallViewController.m
//  WuKongBase
//

#import "WKRTCCallViewController.h"
#import "WKRTCSessionManager.h"
#import "WKRTCMediaAdapter.h"
#import "WKRTCAudioRouteManager.h"
#import "WKRTCAPI.h"
#import "WKModelConvert.h"
#import "WuKongBase.h"
#import "Svg.h"

static const CGFloat WKRTCDesignWidth = 390.0f;
static const CGFloat WKRTCDesignHeight = 884.0f;

static UIColor *WKRTCColor(CGFloat r, CGFloat g, CGFloat b, CGFloat a) {
    return [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:a];
}

static NSString *WKRTCSafeName(NSString *name) {
    return name.length > 0 ? name : @"成员";
}

@interface WKRTCIconButton : UIControl

@property(nonatomic,strong) UIView *circleView;
@property(nonatomic,strong) UIImageView *iconView;
@property(nonatomic,strong) UILabel *textLabel;
@property(nonatomic,copy) NSString *iconName;
@property(nonatomic,assign) CGSize iconSize;
@property(nonatomic,assign) CGFloat circleSize;

- (instancetype)initWithTitle:(NSString *)title iconName:(NSString *)iconName circleSize:(CGFloat)circleSize iconSize:(CGSize)iconSize circleColor:(UIColor *)circleColor;
- (void)setCircleColor:(UIColor *)color;
- (void)setIconName:(NSString *)iconName iconSize:(CGSize)iconSize;

@end

@implementation WKRTCIconButton

- (instancetype)initWithTitle:(NSString *)title iconName:(NSString *)iconName circleSize:(CGFloat)circleSize iconSize:(CGSize)iconSize circleColor:(UIColor *)circleColor {
    self = [super initWithFrame:CGRectZero];
    if(!self) return nil;
    self.circleSize = circleSize;
    self.iconSize = iconSize;
    self.iconName = iconName;
    
    _circleView = [[UIView alloc] init];
    _circleView.userInteractionEnabled = NO;
    _circleView.backgroundColor = circleColor;
    _circleView.layer.cornerRadius = circleSize/2.0f;
    _circleView.layer.masksToBounds = YES;
    _circleView.layer.borderWidth = 1.0f;
    _circleView.layer.borderColor = [UIColor colorWithWhite:1.0f alpha:0.10f].CGColor;
    [self addSubview:_circleView];
    
    _iconView = [[UIImageView alloc] init];
    _iconView.contentMode = UIViewContentModeScaleAspectFit;
    _iconView.image = [self.class svgImageNamed:iconName size:iconSize color:UIColor.whiteColor];
    [_circleView addSubview:_iconView];
    
    _textLabel = [[UILabel alloc] init];
    _textLabel.text = title;
    _textLabel.textAlignment = NSTextAlignmentCenter;
    _textLabel.textColor = WKRTCColor(187.0f, 203.0f, 186.0f, 1.0f);
    _textLabel.font = [UIFont systemFontOfSize:12.0f weight:UIFontWeightMedium];
    [self addSubview:_textLabel];
    return self;
}

- (void)setCircleColor:(UIColor *)color {
    self.circleView.backgroundColor = color;
}

- (void)setIconName:(NSString *)iconName iconSize:(CGSize)iconSize {
    if(iconName.length == 0) return;
    self.iconName = iconName;
    self.iconSize = iconSize;
    self.iconView.image = [self.class svgImageNamed:iconName size:iconSize color:UIColor.whiteColor];
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.circleView.frame = CGRectMake((self.bounds.size.width - self.circleSize)/2.0f, 0.0f, self.circleSize, self.circleSize);
    self.circleView.layer.cornerRadius = self.circleSize/2.0f;
    self.iconView.bounds = CGRectMake(0.0f, 0.0f, self.iconSize.width, self.iconSize.height);
    self.iconView.center = CGPointMake(self.circleSize/2.0f, self.circleSize/2.0f);
    self.textLabel.frame = CGRectMake(0.0f, self.circleSize + 8.0f, self.bounds.size.width, 20.0f);
}

+ (UIImage *)svgImageNamed:(NSString *)name size:(CGSize)size color:(UIColor *)color {
    NSString *path = [self svgPathNamed:name];
    NSData *data = path.length > 0 ? [NSData dataWithContentsOfFile:path] : nil;
    if(data.length == 0) {
        return nil;
    }
    return drawSvgImage(data, size, UIColor.clearColor, color);
}

+ (NSString *)svgPathNamed:(NSString *)name {
    NSArray<NSBundle *> *bundles = @[
        NSBundle.mainBundle,
        [NSBundle bundleForClass:self]
    ];
    for (NSBundle *bundle in bundles) {
        NSString *path = [bundle pathForResource:name ofType:@"svg" inDirectory:@"RTCIcons"];
        if(path.length == 0) path = [bundle pathForResource:name ofType:@"svg" inDirectory:@"Other/RTCIcons"];
        if(path.length > 0) return path;
        NSString *resourceBundlePath = [bundle pathForResource:@"WuKongBase_resources" ofType:@"bundle"];
        NSBundle *resourceBundle = resourceBundlePath.length > 0 ? [NSBundle bundleWithPath:resourceBundlePath] : nil;
        path = [resourceBundle pathForResource:name ofType:@"svg" inDirectory:@"RTCIcons"];
        if(path.length == 0) path = [resourceBundle pathForResource:name ofType:@"svg" inDirectory:@"Other/RTCIcons"];
        if(path.length > 0) return path;
    }
    return nil;
}

@end

@interface WKRTCGroupHeaderView : UIView

@property(nonatomic,strong) NSArray<UILabel *> *avatarLabels;
@property(nonatomic,strong) UILabel *extraLabel;
@property(nonatomic,strong) UILabel *titleLabel;
@property(nonatomic,strong) UILabel *subtitleLabel;

- (void)configureWithTitle:(NSString *)title subtitle:(NSString *)subtitle participants:(NSArray<NSString *> *)participants participantStates:(NSDictionary<NSString *, WKRTCMediaParticipantState *> *)participantStates;

@end

@implementation WKRTCGroupHeaderView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(!self) return nil;
    NSMutableArray *avatars = [NSMutableArray array];
    NSArray *colors = @[WKRTCColor(55,111,203,1), WKRTCColor(39,166,143,1), WKRTCColor(242,152,43,1)];
    for (NSInteger i = 0; i < 3; i++) {
        UILabel *label = [[UILabel alloc] init];
        label.backgroundColor = colors[i];
        label.textColor = UIColor.whiteColor;
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:22.0f weight:UIFontWeightSemibold];
        label.layer.masksToBounds = YES;
        [self addSubview:label];
        [avatars addObject:label];
    }
    _avatarLabels = avatars;
    
    _extraLabel = [[UILabel alloc] init];
    _extraLabel.backgroundColor = WKRTCColor(43,48,68,1);
    _extraLabel.textColor = UIColor.whiteColor;
    _extraLabel.textAlignment = NSTextAlignmentCenter;
    _extraLabel.font = [UIFont systemFontOfSize:20.0f weight:UIFontWeightMedium];
    _extraLabel.layer.masksToBounds = YES;
    [self addSubview:_extraLabel];
    
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.textColor = UIColor.whiteColor;
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    _titleLabel.font = [UIFont systemFontOfSize:28.0f weight:UIFontWeightSemibold];
    [self addSubview:_titleLabel];
    
    _subtitleLabel = [[UILabel alloc] init];
    _subtitleLabel.textColor = WKRTCColor(237,237,242,1);
    _subtitleLabel.textAlignment = NSTextAlignmentCenter;
    _subtitleLabel.font = [UIFont systemFontOfSize:18.0f weight:UIFontWeightRegular];
    _subtitleLabel.adjustsFontSizeToFitWidth = YES;
    _subtitleLabel.minimumScaleFactor = 0.75f;
    [self addSubview:_subtitleLabel];
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat avatarSize = 76.0f;
    NSArray *xs = @[@24.0f, @82.0f, @140.0f];
    for (NSInteger i = 0; i < self.avatarLabels.count; i++) {
        UILabel *label = self.avatarLabels[i];
        label.frame = CGRectMake([xs[i] floatValue], 0.0f, avatarSize, avatarSize);
        label.layer.cornerRadius = avatarSize/2.0f;
    }
    self.extraLabel.frame = CGRectMake(170.0f, 48.0f, 44.0f, 44.0f);
    self.extraLabel.layer.cornerRadius = 22.0f;
    self.titleLabel.frame = CGRectMake(0.0f, 108.0f, self.bounds.size.width, 37.0f);
    self.subtitleLabel.frame = CGRectMake(0.0f, 156.0f, self.bounds.size.width, 24.0f);
}

- (void)configureWithTitle:(NSString *)title subtitle:(NSString *)subtitle participants:(NSArray<NSString *> *)participants participantStates:(NSDictionary<NSString *, WKRTCMediaParticipantState *> *)participantStates {
    for (NSInteger i = 0; i < self.avatarLabels.count; i++) {
        NSString *participantId = i < participants.count ? participants[i] : @"";
        NSString *name = participantId.length > 0 ? WKRTCDisplayNameForUID(participantId) : @"";
        self.avatarLabels[i].hidden = participantId.length == 0;
        self.avatarLabels[i].text = name.length > 0 ? [name substringToIndex:1] : @"";
        WKRTCMediaParticipantState *state = participantStates[participantId];
        CGFloat level = state ? MAX(0.0f, MIN(1.0f, state.audioLevel)) : 0.0f;
        BOOL speaking = state.speaking || level > 0.08f;
        self.avatarLabels[i].layer.borderWidth = speaking ? (2.0f + level * 2.0f) : 0.0f;
        self.avatarLabels[i].layer.borderColor = speaking ? WKRTCColor(69, 225, 124, 0.96f).CGColor : UIColor.clearColor.CGColor;
    }
    NSInteger extra = MAX(0, (NSInteger)participants.count - 3);
    self.extraLabel.hidden = extra <= 0;
    self.extraLabel.text = extra > 0 ? [NSString stringWithFormat:@"+%ld",(long)extra] : @"";
    self.titleLabel.text = title.length > 0 ? title : LLang(@"群通话");
    self.subtitleLabel.text = subtitle;
}

@end

@interface WKRTCVideoAvatarPlaceholderView : UIView

@property(nonatomic,strong) UIImageView *avatarImageView;
@property(nonatomic,strong) UILabel *initialLabel;

- (void)configureWithUID:(NSString *)uid name:(NSString *)name;

@end

@implementation WKRTCVideoAvatarPlaceholderView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(!self) return nil;
    self.backgroundColor = UIColor.blackColor;
    self.userInteractionEnabled = NO;
    
    _avatarImageView = [[UIImageView alloc] init];
    _avatarImageView.backgroundColor = WKRTCColor(44, 50, 58, 1.0f);
    _avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    _avatarImageView.clipsToBounds = YES;
    [self addSubview:_avatarImageView];
    
    _initialLabel = [[UILabel alloc] init];
    _initialLabel.textColor = UIColor.whiteColor;
    _initialLabel.textAlignment = NSTextAlignmentCenter;
    _initialLabel.font = [UIFont systemFontOfSize:28.0f weight:UIFontWeightSemibold];
    [_avatarImageView addSubview:_initialLabel];
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat size = MIN(self.bounds.size.width, self.bounds.size.height) * 0.34f;
    size = MAX(44.0f, MIN(96.0f, size));
    self.avatarImageView.frame = CGRectMake((self.bounds.size.width - size) / 2.0f, (self.bounds.size.height - size) / 2.0f, size, size);
    self.avatarImageView.layer.cornerRadius = size / 2.0f;
    self.initialLabel.frame = self.avatarImageView.bounds;
    self.initialLabel.font = [UIFont systemFontOfSize:MAX(18.0f, size * 0.38f) weight:UIFontWeightSemibold];
}

- (void)configureWithUID:(NSString *)uid name:(NSString *)name {
    NSString *displayName = name.length > 0 ? name : WKRTCDisplayNameForUID(uid);
    self.initialLabel.text = displayName.length > 0 ? [displayName substringToIndex:1] : @"?";
    NSString *avatarURL = WKRTCAvatarURLForUID(uid);
    if(avatarURL.length > 0) {
        [self.avatarImageView lim_setImageWithURL:[NSURL URLWithString:avatarURL]];
        self.initialLabel.hidden = YES;
    }else {
        self.avatarImageView.image = nil;
        self.initialLabel.hidden = NO;
    }
}

@end

@interface WKRTCVideoTileView : UIView

@property(nonatomic,strong) UIView *videoHost;
@property(nonatomic,strong) WKRTCVideoAvatarPlaceholderView *placeholderView;
@property(nonatomic,strong) UILabel *hintLabel;
@property(nonatomic,strong) UILabel *nameLabel;
@property(nonatomic,strong) UIView *namePill;
@property(nonatomic,strong) UIView *statusPill;
@property(nonatomic,strong) UILabel *statusLabel;
@property(nonatomic,strong) NSArray<UIView *> *volumeBars;

- (void)configureWithName:(NSString *)name hint:(NSString *)hint backgroundColor:(UIColor *)backgroundColor participantState:(WKRTCMediaParticipantState *)participantState;
- (void)setPlaceholderHidden:(BOOL)hidden uid:(NSString *)uid name:(NSString *)name;

@end

@implementation WKRTCVideoTileView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(!self) return nil;
    self.clipsToBounds = YES;
    self.layer.cornerRadius = 18.0f;

    _videoHost = [[UIView alloc] init];
    _videoHost.clipsToBounds = YES;
    [self addSubview:_videoHost];
    
    _placeholderView = [[WKRTCVideoAvatarPlaceholderView alloc] init];
    _placeholderView.hidden = YES;
    [self addSubview:_placeholderView];
    
    _hintLabel = [[UILabel alloc] init];
    _hintLabel.textColor = UIColor.whiteColor;
    _hintLabel.font = [UIFont systemFontOfSize:12.0f];
    [self addSubview:_hintLabel];
    
    _namePill = [[UIView alloc] init];
    _namePill.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.28f];
    _namePill.layer.cornerRadius = 14.0f;
    [self addSubview:_namePill];
    
    _nameLabel = [[UILabel alloc] init];
    _nameLabel.textColor = UIColor.whiteColor;
    _nameLabel.font = [UIFont systemFontOfSize:14.0f weight:UIFontWeightSemibold];
    [_namePill addSubview:_nameLabel];
    
    _statusPill = [[UIView alloc] init];
    _statusPill.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.30f];
    _statusPill.layer.cornerRadius = 13.0f;
    [self addSubview:_statusPill];
    
    _statusLabel = [[UILabel alloc] init];
    _statusLabel.textColor = UIColor.whiteColor;
    _statusLabel.font = [UIFont systemFontOfSize:11.0f weight:UIFontWeightMedium];
    [_statusPill addSubview:_statusLabel];
    
    NSMutableArray *bars = [NSMutableArray array];
    for (NSInteger i = 0; i < 3; i++) {
        UIView *bar = [[UIView alloc] init];
        bar.backgroundColor = WKRTCColor(69, 225, 124, 1.0f);
        bar.layer.cornerRadius = 1.5f;
        [_statusPill addSubview:bar];
        [bars addObject:bar];
    }
    _volumeBars = bars.copy;
    return self;
}

- (void)configureWithName:(NSString *)name hint:(NSString *)hint backgroundColor:(UIColor *)backgroundColor participantState:(WKRTCMediaParticipantState *)participantState {
    self.backgroundColor = backgroundColor;
    self.nameLabel.text = WKRTCSafeName(name);
    self.hintLabel.text = hint;
    [self configureParticipantState:participantState];
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.videoHost.frame = self.bounds;
    [self sendSubviewToBack:self.videoHost];
    self.placeholderView.frame = self.bounds;
    self.hintLabel.frame = CGRectMake(12.0f, self.bounds.size.height - 46.0f, self.bounds.size.width - 24.0f, 16.0f);
    self.namePill.frame = CGRectMake(12.0f, self.bounds.size.height - 32.0f, 90.0f, 28.0f);
    self.nameLabel.frame = CGRectMake(12.0f, 0.0f, 70.0f, 28.0f);
    CGFloat statusWidth = MIN(116.0f, MAX(78.0f, self.bounds.size.width - 24.0f));
    self.statusPill.frame = CGRectMake(self.bounds.size.width - statusWidth - 12.0f, 10.0f, statusWidth, 26.0f);
    self.statusLabel.frame = CGRectMake(28.0f, 0.0f, statusWidth - 36.0f, 26.0f);
    for (NSInteger i = 0; i < self.volumeBars.count; i++) {
        UIView *bar = self.volumeBars[i];
        CGFloat barHeight = [self barHeightAtIndex:i];
        bar.frame = CGRectMake(10.0f + i * 5.0f, 13.0f - barHeight/2.0f, 3.0f, barHeight);
    }
}

// 根据 LiveKit 本地状态展示成员网络质量和音量，不依赖服务端扩展字段。
- (void)configureParticipantState:(WKRTCMediaParticipantState *)state {
    CGFloat level = state ? MAX(0.0f, MIN(1.0f, state.audioLevel)) : 0.0f;
    BOOL speaking = state.speaking || level > 0.08f;
    self.layer.borderWidth = speaking ? (2.0f + level * 2.0f) : 0.0f;
    self.layer.borderColor = speaking ? WKRTCColor(69, 225, 124, 0.96f).CGColor : UIColor.clearColor.CGColor;
    self.statusPill.hidden = state == nil;
    self.statusLabel.text = speaking ? LLang(@"正在说话") : [self networkQualityText:state.networkQuality];
    for (NSInteger i = 0; i < self.volumeBars.count; i++) {
        UIView *bar = self.volumeBars[i];
        CGFloat threshold = (CGFloat)(i + 1) / (CGFloat)self.volumeBars.count;
        bar.alpha = speaking || level >= threshold ? 1.0f : 0.35f;
    }
}

- (void)setPlaceholderHidden:(BOOL)hidden uid:(NSString *)uid name:(NSString *)name {
    self.placeholderView.hidden = hidden;
    if(!hidden) {
        [self.placeholderView configureWithUID:uid name:name];
        [self bringSubviewToFront:self.placeholderView];
        [self bringSubviewToFront:self.hintLabel];
        [self bringSubviewToFront:self.namePill];
        [self bringSubviewToFront:self.statusPill];
    }
}

- (CGFloat)barHeightAtIndex:(NSInteger)index {
    NSArray<NSNumber *> *heights = @[@8.0f, @13.0f, @18.0f];
    return [heights[index] floatValue];
}

- (NSString *)networkQualityText:(NSString *)quality {
    if([quality isEqualToString:@"excellent"]) return LLang(@"网络极佳");
    if([quality isEqualToString:@"good"]) return LLang(@"网络良好");
    if([quality isEqualToString:@"poor"]) return LLang(@"网络较差");
    if([quality isEqualToString:@"lost"]) return LLang(@"网络断开");
    return LLang(@"网络未知");
}

@end

@interface WKRTCParticipantChipView : UIControl

@property(nonatomic,copy) NSString *participantId;
@property(nonatomic,strong) UIImageView *avatarImageView;
@property(nonatomic,strong) UILabel *initialLabel;
@property(nonatomic,strong) UILabel *nameLabel;

- (void)configureWithParticipantId:(NSString *)participantId;

@end

@implementation WKRTCParticipantChipView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(!self) return nil;
    self.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.08f];
    self.layer.cornerRadius = 10.0f;
    self.layer.masksToBounds = YES;
    
    _avatarImageView = [[UIImageView alloc] init];
    _avatarImageView.backgroundColor = WKRTCColor(44, 50, 58, 1.0f);
    _avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    _avatarImageView.clipsToBounds = YES;
    [self addSubview:_avatarImageView];
    
    _initialLabel = [[UILabel alloc] init];
    _initialLabel.textAlignment = NSTextAlignmentCenter;
    _initialLabel.textColor = UIColor.whiteColor;
    _initialLabel.font = [UIFont systemFontOfSize:17.0f weight:UIFontWeightSemibold];
    [_avatarImageView addSubview:_initialLabel];
    
    _nameLabel = [[UILabel alloc] init];
    _nameLabel.textAlignment = NSTextAlignmentCenter;
    _nameLabel.textColor = UIColor.whiteColor;
    _nameLabel.font = [UIFont systemFontOfSize:12.0f weight:UIFontWeightMedium];
    _nameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    [self addSubview:_nameLabel];
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat avatarSize = 46.0f;
    self.avatarImageView.frame = CGRectMake((self.bounds.size.width - avatarSize)/2.0f, 8.0f, avatarSize, avatarSize);
    self.avatarImageView.layer.cornerRadius = avatarSize/2.0f;
    self.initialLabel.frame = self.avatarImageView.bounds;
    self.nameLabel.frame = CGRectMake(6.0f, CGRectGetMaxY(self.avatarImageView.frame) + 6.0f, self.bounds.size.width - 12.0f, 18.0f);
}

- (void)configureWithParticipantId:(NSString *)participantId {
    self.participantId = participantId ?: @"";
    NSString *uid = WKRTCUIDFromParticipantID(participantId);
    NSString *name = WKRTCDisplayNameForUID(uid);
    self.nameLabel.text = WKRTCSafeName(name);
    self.initialLabel.text = name.length > 0 ? [name substringToIndex:1] : @"?";
    NSString *avatarURL = WKRTCAvatarURLForUID(uid);
    if(avatarURL.length > 0) {
        [self.avatarImageView lim_setImageWithURL:[NSURL URLWithString:avatarURL]];
        self.initialLabel.hidden = YES;
    }else {
        self.avatarImageView.image = nil;
        self.initialLabel.hidden = NO;
    }
}

@end

@interface WKRTCCallViewController ()

@property(nonatomic,strong) WKRTCSessionManager *session;
@property(nonatomic,strong) UIView *backgroundView;
@property(nonatomic,strong) UIView *ambientView;
@property(nonatomic,strong) UIView *singleVideoContainer;
@property(nonatomic,strong) UIView *smallVideoContainer;
@property(nonatomic,strong) UILabel *smallVideoLabel;
@property(nonatomic,strong) WKRTCVideoAvatarPlaceholderView *mainVideoPlaceholder;
@property(nonatomic,strong) WKRTCVideoAvatarPlaceholderView *smallVideoPlaceholder;
@property(nonatomic,strong) UIView *avatarContainer;
@property(nonatomic,strong) UIImageView *avatarImageView;
@property(nonatomic,strong) UILabel *avatarInitialLabel;
@property(nonatomic,strong) UIView *ring1;
@property(nonatomic,strong) UIView *ring2;
@property(nonatomic,strong) UILabel *nameLabel;
@property(nonatomic,strong) UILabel *statusLabel;
@property(nonatomic,strong) WKRTCGroupHeaderView *groupHeaderView;
@property(nonatomic,strong) UIView *groupVideoGridView;
@property(nonatomic,strong) UILabel *groupVideoTitleLabel;
@property(nonatomic,strong) UIScrollView *groupVideoParticipantScrollView;
@property(nonatomic,strong) UIView *controlsArea;
@property(nonatomic,strong) WKRTCIconButton *speakerButton;
@property(nonatomic,strong) WKRTCIconButton *muteButton;
@property(nonatomic,strong) WKRTCIconButton *videoButton;
@property(nonatomic,strong) WKRTCIconButton *flipCameraButton;
@property(nonatomic,strong) WKRTCIconButton *keypadButton;
@property(nonatomic,strong) WKRTCIconButton *messageButton;
@property(nonatomic,strong) WKRTCIconButton *membersButton;
@property(nonatomic,strong) WKRTCIconButton *rejectButton;
@property(nonatomic,strong) WKRTCIconButton *acceptButton;
@property(nonatomic,strong) WKRTCIconButton *hangupButton;
@property(nonatomic,strong) UIButton *minimizeButton;
@property(nonatomic,strong) UIButton *inviteButton;
@property(nonatomic,strong) UIView *minimizeTransitionView;
@property(nonatomic,strong) NSTimer *timer;
@property(nonatomic,assign) NSTimeInterval activeAt;
@property(nonatomic,assign) BOOL didAttachRemoteVideo;
@property(nonatomic,assign) BOOL didAttachLocalVideo;
@property(nonatomic,assign) BOOL showingRemoteVideo;
@property(nonatomic,assign) BOOL userSwappedVideo;
@property(nonatomic,assign) BOOL lastMainVideoWasRemote;
@property(nonatomic,assign) BOOL accepting;
@property(nonatomic,assign) CGPoint smallVideoPanStartCenter;
@property(nonatomic,assign) BOOL smallVideoManuallyPositioned;
@property(nonatomic,strong) NSArray<NSString *> *groupVisibleParticipantIds;
@property(nonatomic,copy) NSString *groupVisibleCallId;

@end

@implementation WKRTCCallViewController

- (instancetype)initWithSession:(WKRTCSessionManager *)session {
    self = [super initWithNibName:nil bundle:nil];
    if(!self) return nil;
    self.session = session;
    self.modalPresentationStyle = UIModalPresentationFullScreen;
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionChanged) name:WKRTCSessionDidChangeNotification object:self.session];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionChanged) name:WKRTCMediaParticipantsDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(participantPresenceChanged:) name:WKRTCMediaParticipantPresenceDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionChanged) name:WKRTCAudioRouteDidChangeNotification object:nil];
    [self refresh];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.timer invalidate];
}

- (void)setupUI {
    self.view.backgroundColor = WKRTCColor(18, 20, 20, 1.0f);
    
    self.backgroundView = [[UIView alloc] init];
    self.backgroundView.backgroundColor = WKRTCColor(18, 20, 20, 1.0f);
    [self.view addSubview:self.backgroundView];
    
    self.ambientView = [[UIView alloc] init];
    self.ambientView.backgroundColor = WKRTCColor(69, 225, 124, 0.10f);
    self.ambientView.layer.cornerRadius = 240.0f;
    [self.backgroundView addSubview:self.ambientView];
    
    self.singleVideoContainer = [[UIView alloc] init];
    self.singleVideoContainer.backgroundColor = UIColor.blackColor;
    self.singleVideoContainer.clipsToBounds = YES;
    [self.view addSubview:self.singleVideoContainer];
    self.mainVideoPlaceholder = [[WKRTCVideoAvatarPlaceholderView alloc] init];
    self.mainVideoPlaceholder.hidden = YES;
    [self.singleVideoContainer addSubview:self.mainVideoPlaceholder];

    self.smallVideoContainer = [[UIView alloc] init];
    self.smallVideoContainer.backgroundColor = WKRTCColor(20, 24, 24, 1.0f);
    self.smallVideoContainer.clipsToBounds = YES;
    self.smallVideoContainer.layer.cornerRadius = 8.0f;
    self.smallVideoContainer.layer.borderWidth = 1.0f;
    self.smallVideoContainer.layer.borderColor = [UIColor colorWithWhite:1.0f alpha:0.18f].CGColor;
    self.smallVideoContainer.hidden = YES;
    [self.view addSubview:self.smallVideoContainer];
    self.smallVideoPlaceholder = [[WKRTCVideoAvatarPlaceholderView alloc] init];
    self.smallVideoPlaceholder.hidden = YES;
    [self.smallVideoContainer addSubview:self.smallVideoPlaceholder];
    UITapGestureRecognizer *swapTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(swapVideoPressed)];
    UIPanGestureRecognizer *smallVideoPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleSmallVideoPan:)];
    // 拖动小窗时不能同时触发点击切换，否则会误把拖动当成大小窗切换。
    [swapTap requireGestureRecognizerToFail:smallVideoPan];
    [self.smallVideoContainer addGestureRecognizer:swapTap];
    [self.smallVideoContainer addGestureRecognizer:smallVideoPan];

    self.smallVideoLabel = [[UILabel alloc] init];
    self.smallVideoLabel.textColor = UIColor.whiteColor;
    self.smallVideoLabel.font = [UIFont systemFontOfSize:12.0f weight:UIFontWeightMedium];
    self.smallVideoLabel.textAlignment = NSTextAlignmentCenter;
    self.smallVideoLabel.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.28f];
    self.smallVideoLabel.hidden = YES;
    [self.smallVideoContainer addSubview:self.smallVideoLabel];
    
    self.groupVideoGridView = [[UIView alloc] init];
    self.groupVideoGridView.hidden = YES;
    [self.view addSubview:self.groupVideoGridView];
    
    self.groupVideoTitleLabel = [[UILabel alloc] init];
    self.groupVideoTitleLabel.textColor = UIColor.whiteColor;
    self.groupVideoTitleLabel.font = [UIFont systemFontOfSize:16.0f weight:UIFontWeightSemibold];
    self.groupVideoTitleLabel.hidden = YES;
    [self.view addSubview:self.groupVideoTitleLabel];
    
    self.groupVideoParticipantScrollView = [[UIScrollView alloc] init];
    self.groupVideoParticipantScrollView.hidden = YES;
    self.groupVideoParticipantScrollView.showsHorizontalScrollIndicator = NO;
    self.groupVideoParticipantScrollView.alwaysBounceHorizontal = YES;
    self.groupVideoParticipantScrollView.contentInset = UIEdgeInsetsMake(0.0f, 16.0f, 0.0f, 16.0f);
    [self.view addSubview:self.groupVideoParticipantScrollView];
    
    self.avatarContainer = [[UIView alloc] init];
    [self.view addSubview:self.avatarContainer];
    
    self.ring2 = [[UIView alloc] init];
    self.ring2.layer.borderWidth = 1.0f;
    self.ring2.layer.borderColor = WKRTCColor(69, 225, 124, 0.10f).CGColor;
    [self.avatarContainer addSubview:self.ring2];
    
    self.ring1 = [[UIView alloc] init];
    self.ring1.layer.borderWidth = 2.0f;
    self.ring1.layer.borderColor = WKRTCColor(69, 225, 124, 0.22f).CGColor;
    [self.avatarContainer addSubview:self.ring1];
    
    self.avatarImageView = [[UIImageView alloc] init];
    self.avatarImageView.backgroundColor = WKRTCColor(34, 42, 44, 1.0f);
    self.avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarImageView.clipsToBounds = YES;
    self.avatarImageView.layer.borderWidth = 2.0f;
    self.avatarImageView.layer.borderColor = WKRTCColor(69, 225, 124, 0.5f).CGColor;
    [self.avatarContainer addSubview:self.avatarImageView];
    
    self.avatarInitialLabel = [[UILabel alloc] init];
    self.avatarInitialLabel.textColor = UIColor.whiteColor;
    self.avatarInitialLabel.textAlignment = NSTextAlignmentCenter;
    self.avatarInitialLabel.font = [UIFont systemFontOfSize:42.0f weight:UIFontWeightSemibold];
    [self.avatarImageView addSubview:self.avatarInitialLabel];
    
    self.nameLabel = [[UILabel alloc] init];
    self.nameLabel.textColor = WKRTCColor(227, 226, 226, 1.0f);
    self.nameLabel.textAlignment = NSTextAlignmentCenter;
    self.nameLabel.font = [UIFont systemFontOfSize:34.0f weight:UIFontWeightMedium];
    [self.view addSubview:self.nameLabel];
    
    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.textColor = WKRTCColor(187, 203, 186, 1.0f);
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.font = [UIFont systemFontOfSize:14.0f weight:UIFontWeightMedium];
    self.statusLabel.adjustsFontSizeToFitWidth = YES;
    self.statusLabel.minimumScaleFactor = 0.75f;
    [self.view addSubview:self.statusLabel];
    
    self.groupHeaderView = [[WKRTCGroupHeaderView alloc] init];
    self.groupHeaderView.hidden = YES;
    [self.view addSubview:self.groupHeaderView];
    
    self.controlsArea = [[UIView alloc] init];
    [self.view addSubview:self.controlsArea];
    
    UIColor *glass = [UIColor colorWithWhite:1.0f alpha:0.08f];
    UIColor *incomingGlass = [UIColor colorWithWhite:0.10f alpha:0.82f];
    self.muteButton = [[WKRTCIconButton alloc] initWithTitle:LLang(@"静音") iconName:@"rtc_mute" circleSize:56.0f iconSize:CGSizeMake(20.0f, 21.0f) circleColor:glass];
    self.speakerButton = [[WKRTCIconButton alloc] initWithTitle:LLang(@"扬声器") iconName:@"rtc_speaker" circleSize:56.0f iconSize:CGSizeMake(18.0f, 18.0f) circleColor:glass];
    self.videoButton = [[WKRTCIconButton alloc] initWithTitle:LLang(@"视频") iconName:@"rtc_video" circleSize:56.0f iconSize:CGSizeMake(20.0f, 16.0f) circleColor:glass];
    self.flipCameraButton = [[WKRTCIconButton alloc] initWithTitle:LLang(@"翻转") iconName:@"rtc_video" circleSize:56.0f iconSize:CGSizeMake(20.0f, 16.0f) circleColor:glass];
    self.keypadButton = [[WKRTCIconButton alloc] initWithTitle:LLang(@"拨号盘") iconName:@"rtc_keypad" circleSize:56.0f iconSize:CGSizeMake(16.0f, 22.0f) circleColor:glass];
    self.messageButton = [[WKRTCIconButton alloc] initWithTitle:LLang(@"消息") iconName:@"rtc_message" circleSize:56.0f iconSize:CGSizeMake(20.0f, 20.0f) circleColor:incomingGlass];
    self.membersButton = [[WKRTCIconButton alloc] initWithTitle:LLang(@"成员") iconName:@"rtc_members" circleSize:56.0f iconSize:CGSizeMake(20.0f, 18.0f) circleColor:glass];
    self.rejectButton = [[WKRTCIconButton alloc] initWithTitle:LLang(@"拒接") iconName:@"rtc_hangup" circleSize:80.0f iconSize:CGSizeMake(30.0f, 12.0f) circleColor:WKRTCColor(255,77,79,1)];
    self.acceptButton = [[WKRTCIconButton alloc] initWithTitle:LLang(@"接听") iconName:@"rtc_accept" circleSize:80.0f iconSize:CGSizeMake(24.0f, 24.0f) circleColor:WKRTCColor(7,193,96,1)];
    self.hangupButton = [[WKRTCIconButton alloc] initWithTitle:LLang(@"结束通话") iconName:@"rtc_hangup" circleSize:80.0f iconSize:CGSizeMake(30.0f, 12.0f) circleColor:WKRTCColor(169,1,27,1)];
    
    for (UIControl *button in @[self.muteButton,self.speakerButton,self.videoButton,self.flipCameraButton,self.keypadButton,self.messageButton,self.membersButton,self.rejectButton,self.acceptButton,self.hangupButton]) {
        [self.controlsArea addSubview:button];
    }

    self.minimizeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.minimizeButton.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.36f];
    self.minimizeButton.tintColor = UIColor.whiteColor;
    self.minimizeButton.layer.cornerRadius = 18.0f;
    self.minimizeButton.layer.masksToBounds = YES;
    UIImage *minimizeImage = [UIImage systemImageNamed:@"arrow.down.right.and.arrow.up.left"];
    if(minimizeImage) {
        [self.minimizeButton setImage:minimizeImage forState:UIControlStateNormal];
    }else {
        [self.minimizeButton setTitle:LLang(@"缩小") forState:UIControlStateNormal];
        self.minimizeButton.titleLabel.font = [UIFont systemFontOfSize:12.0f weight:UIFontWeightSemibold];
    }
    [self.minimizeButton addTarget:self action:@selector(minimizePressed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.minimizeButton];

    self.inviteButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.inviteButton.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.36f];
    self.inviteButton.tintColor = UIColor.whiteColor;
    self.inviteButton.layer.cornerRadius = 18.0f;
    self.inviteButton.layer.masksToBounds = YES;
    self.inviteButton.hidden = YES;
    self.inviteButton.accessibilityLabel = LLang(@"邀请成员");
    UIImage *inviteImage = [UIImage systemImageNamed:@"plus"];
    if(inviteImage) {
        [self.inviteButton setImage:inviteImage forState:UIControlStateNormal];
    }else {
        [self.inviteButton setTitle:@"+" forState:UIControlStateNormal];
        self.inviteButton.titleLabel.font = [UIFont systemFontOfSize:24.0f weight:UIFontWeightMedium];
    }
    [self.inviteButton addTarget:self action:@selector(inviteMembersPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.inviteButton];

    self.minimizeTransitionView = [[UIView alloc] init];
    self.minimizeTransitionView.backgroundColor = UIColor.blackColor;
    self.minimizeTransitionView.alpha = 0.0f;
    self.minimizeTransitionView.hidden = YES;
    self.minimizeTransitionView.userInteractionEnabled = YES;
    [self.view addSubview:self.minimizeTransitionView];
    
    [self.muteButton addTarget:self action:@selector(mutePressed) forControlEvents:UIControlEventTouchUpInside];
    [self.speakerButton addTarget:self action:@selector(speakerPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.videoButton addTarget:self action:@selector(videoPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.flipCameraButton addTarget:self action:@selector(flipCameraPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.keypadButton addTarget:self action:@selector(keypadPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.messageButton addTarget:self action:@selector(messagePressed) forControlEvents:UIControlEventTouchUpInside];
    [self.membersButton addTarget:self action:@selector(membersPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.rejectButton addTarget:self action:@selector(rejectPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.acceptButton addTarget:self action:@selector(acceptPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.hangupButton addTarget:self action:@selector(hangupPressed) forControlEvents:UIControlEventTouchUpInside];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self layoutForCurrentState];
}

- (CGFloat)sx {
    return self.view.bounds.size.width / WKRTCDesignWidth;
}

- (CGFloat)sy {
    return self.view.bounds.size.height / WKRTCDesignHeight;
}

- (CGFloat)ss {
    return MIN([self sx], [self sy]);
}

- (CGRect)r:(CGFloat)x y:(CGFloat)y w:(CGFloat)w h:(CGFloat)h {
    return CGRectMake(x * [self sx], y * [self sy], w * [self sx], h * [self sy]);
}

- (void)layoutForCurrentState {
    WKRTCCallPayload *payload = self.session.currentPayload;
    if(!payload) {
        return;
    }
    BOOL group = payload.channelType == WK_GROUP;
    BOOL video = payload.callType == WKRTCCallTypeVideo;
    BOOL incoming = self.session.state == WKRTCCallStateIncomingRinging;
    BOOL active = [self isActiveLikeState:self.session.state];
    
    self.backgroundView.frame = self.view.bounds;
    self.ambientView.frame = [self r:-39 y:661 w:468 h:354];
    self.ambientView.layer.cornerRadius = self.ambientView.bounds.size.height/2.0f;
    self.singleVideoContainer.frame = self.view.bounds;
    self.mainVideoPlaceholder.frame = self.singleVideoContainer.bounds;
    CGRect defaultSmallVideoFrame = [self r:250 y:62 w:116 h:164];
    if(!self.smallVideoManuallyPositioned || CGRectIsEmpty(self.smallVideoContainer.frame)) {
        self.smallVideoContainer.frame = defaultSmallVideoFrame;
    }else {
        CGRect frame = self.smallVideoContainer.frame;
        frame.size = defaultSmallVideoFrame.size;
        self.smallVideoContainer.frame = [self clampedSmallVideoFrame:frame];
    }
    self.smallVideoLabel.frame = CGRectMake(0.0f, self.smallVideoContainer.bounds.size.height - 28.0f, self.smallVideoContainer.bounds.size.width, 28.0f);
    self.smallVideoPlaceholder.frame = self.smallVideoContainer.bounds;
    self.controlsArea.frame = self.view.bounds;
    self.minimizeButton.frame = CGRectMake(16.0f, self.view.safeAreaInsets.top + 12.0f, 36.0f, 36.0f);
    self.inviteButton.frame = CGRectMake(self.view.bounds.size.width - 52.0f, self.view.safeAreaInsets.top + 12.0f, 36.0f, 36.0f);
    self.minimizeTransitionView.frame = self.view.bounds;
    
    [self layoutAvatarBlockAtY:group ? 96.0f : 96.0f];
    self.nameLabel.frame = [self r:20 y:248 w:350 h:42];
    self.statusLabel.frame = [self r:20 y:292 w:350 h:24];
    
    if(group && video && active) {
        [self layoutGroupVideoActive];
    }else if(group) {
        CGFloat headerY = (video && !incoming) ? 128.0f : 176.0f;
        if(incoming && video) headerY = 96.0f;
        self.groupHeaderView.frame = [self r:75 y:headerY w:240 h:224];
    }
    
    if(incoming) {
        if(group && video) {
            [self layoutGroupVideoIncomingButtons];
        }else {
            [self layoutIncomingButtons];
        }
    }else if(active) {
        if(group && video) {
            [self layoutGroupVideoActiveButtons];
        }else if(group) {
            [self layoutGroupAudioActiveButtons];
        }else {
            [self layoutSingleActiveButtonsVideo:video];
        }
    }else {
        [self layoutOutgoingButtonsVideo:video group:group];
    }
    [self.view bringSubviewToFront:self.controlsArea];
    [self.view bringSubviewToFront:self.groupVideoParticipantScrollView];
    [self.view bringSubviewToFront:self.smallVideoContainer];
    [self.view bringSubviewToFront:self.minimizeButton];
    [self.view bringSubviewToFront:self.inviteButton];
    if(!self.minimizeTransitionView.hidden) {
        [self.view bringSubviewToFront:self.minimizeTransitionView];
    }
}

- (void)layoutAvatarBlockAtY:(CGFloat)y {
    CGRect avatarFrame = [self r:131 y:y w:128 h:128];
    self.avatarContainer.frame = CGRectInset(avatarFrame, -32.0f * [self ss], -32.0f * [self ss]);
    CGFloat inset = 32.0f * [self ss];
    CGFloat avatarSize = 128.0f * [self ss];
    CGRect avatarBoundsFrame = CGRectMake(inset, inset, avatarSize, avatarSize);
    self.avatarImageView.frame = avatarBoundsFrame;
    self.avatarImageView.layer.cornerRadius = avatarSize/2.0f;
    self.avatarInitialLabel.frame = self.avatarImageView.bounds;
    self.ring1.frame = CGRectInset(avatarBoundsFrame, -16.0f * [self ss], -16.0f * [self ss]);
    self.ring2.frame = CGRectInset(avatarBoundsFrame, -32.0f * [self ss], -32.0f * [self ss]);
    self.ring1.layer.cornerRadius = self.ring1.bounds.size.width/2.0f;
    self.ring2.layer.cornerRadius = self.ring2.bounds.size.width/2.0f;
}

- (void)layoutUtilityButtons:(NSArray<WKRTCIconButton *> *)buttons y:(CGFloat)y buttonSize:(CGFloat)buttonSize itemWidth:(CGFloat)itemWidth startX:(CGFloat)startX gap:(CGFloat)gap {
    for (NSInteger i = 0; i < buttons.count; i++) {
        WKRTCIconButton *button = buttons[i];
        button.circleSize = buttonSize * [self ss];
        button.frame = [self r:startX + (itemWidth + gap) * i y:y w:itemWidth h:88];
    }
}

- (void)layoutIncomingButtons {
    NSArray *buttons = self.session.currentPayload.callType == WKRTCCallTypeVideo ? @[self.speakerButton,self.videoButton,self.messageButton] : @[self.speakerButton,self.messageButton];
    CGFloat itemWidth = buttons.count == 2 ? 90.67f : 90.67f;
    CGFloat gap = buttons.count == 2 ? 56.0f : 24.0f;
    CGFloat startX = buttons.count == 2 ? 80.0f : 35.0f;
    [self layoutUtilityButtons:buttons y:580 buttonSize:56 itemWidth:itemWidth startX:startX gap:gap];
    self.rejectButton.circleSize = 80.0f * [self ss];
    self.acceptButton.circleSize = 80.0f * [self ss];
    self.rejectButton.frame = [self r:67.5 y:736 w:80 h:116];
    self.acceptButton.frame = [self r:242.5 y:736 w:80 h:116];
}

- (void)layoutGroupVideoIncomingButtons {
    self.rejectButton.circleSize = 72.0f * [self ss];
    self.messageButton.circleSize = 48.0f * [self ss];
    self.acceptButton.circleSize = 72.0f * [self ss];
    self.rejectButton.frame = [self r:20 y:736 w:72 h:100];
    self.messageButton.frame = [self r:170 y:748 w:50 h:88];
    self.acceptButton.frame = [self r:298 y:736 w:72 h:100];
}

- (void)layoutOutgoingButtonsVideo:(BOOL)video group:(BOOL)group {
    NSArray *buttons = video ? @[self.muteButton,self.speakerButton,self.videoButton] : @[self.muteButton,self.speakerButton,self.messageButton];
    if(group && video) {
        buttons = @[self.muteButton,self.speakerButton,self.videoButton];
    }
    [self layoutUtilityButtons:buttons y:580 buttonSize:56 itemWidth:74 yStartWorkaround:0];
    self.hangupButton.circleSize = 80.0f * [self ss];
    self.hangupButton.frame = [self r:155 y:696 w:80 h:100];
}

- (void)layoutUtilityButtons:(NSArray<WKRTCIconButton *> *)buttons y:(CGFloat)y buttonSize:(CGFloat)buttonSize itemWidth:(CGFloat)itemWidth yStartWorkaround:(CGFloat)unused {
    CGFloat totalWidth = 0.0f;
    CGFloat gap = buttons.count == 4 ? 24.0f : 51.0f;
    for (NSInteger i = 0; i < buttons.count; i++) totalWidth += itemWidth;
    totalWidth += gap * MAX(0, (NSInteger)buttons.count - 1);
    CGFloat startX = (WKRTCDesignWidth - totalWidth)/2.0f;
    [self layoutUtilityButtons:buttons y:y buttonSize:buttonSize itemWidth:itemWidth startX:startX gap:gap];
}

- (void)layoutSingleActiveButtonsVideo:(BOOL)video {
    NSArray *buttons = video ? @[self.muteButton,self.speakerButton,self.flipCameraButton,self.videoButton] : @[self.muteButton,self.speakerButton,self.messageButton];
    [self layoutUtilityButtons:buttons y:580 buttonSize:56 itemWidth:74 yStartWorkaround:0];
    self.hangupButton.circleSize = 80.0f * [self ss];
    self.hangupButton.frame = [self r:155 y:736 w:80 h:108];
}

- (void)layoutGroupAudioActiveButtons {
    [self layoutUtilityButtons:@[self.muteButton,self.speakerButton] y:573 buttonSize:64 itemWidth:74 yStartWorkaround:0];
    self.hangupButton.circleSize = 64.0f * [self ss];
    self.hangupButton.frame = [self r:163 y:736 w:64 h:84];
}

- (void)layoutGroupVideoActiveButtons {
    [self layoutUtilityButtons:@[self.muteButton,self.speakerButton,self.flipCameraButton,self.videoButton] y:620 buttonSize:56 itemWidth:69.5f yStartWorkaround:0];
    self.hangupButton.circleSize = 80.0f * [self ss];
    self.hangupButton.frame = [self r:155 y:776 w:80 h:108];
}

- (void)layoutGroupVideoActive {
    self.groupVideoGridView.frame = [self r:0 y:0 w:390 h:390];
    self.groupVideoTitleLabel.frame = [self r:16 y:402 w:358 h:24];
    self.groupVideoParticipantScrollView.frame = [self r:0 y:432 w:390 h:104];
    [self layoutGroupVideoTiles];
}

- (void)layoutGroupVideoTiles {
    NSArray<NSString *> *allParticipants = [self participantNames];
    NSArray<NSString *> *visibleParticipants = [self currentGroupVisibleParticipants];
    NSDictionary<NSString *, WKRTCMediaParticipantState *> *participantStates = [self participantStates];
    NSArray *colors = @[WKRTCColor(35,42,59,1), WKRTCColor(56,73,67,1), WKRTCColor(209,135,56,1), WKRTCColor(163,82,194,1)];
    while (self.groupVideoGridView.subviews.count < 4) {
        [self.groupVideoGridView addSubview:[[WKRTCVideoTileView alloc] init]];
    }
    for (NSInteger i = 0; i < self.groupVideoGridView.subviews.count; i++) {
        WKRTCVideoTileView *tile = (WKRTCVideoTileView *)self.groupVideoGridView.subviews[i];
        if(i >= visibleParticipants.count) {
            tile.hidden = YES;
            [tile.videoHost.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
            continue;
        }
        tile.hidden = NO;
        tile.frame = [self groupVideoTileFrameAtIndex:i count:visibleParticipants.count];
        NSString *participantId = visibleParticipants[i];
        [tile.videoHost.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        if([self isLocalParticipantId:participantId]) {
            UIView *localVideoView = [[self.session mediaAdapter] localVideoView];
            if(localVideoView.superview != tile.videoHost) {
                [self attachVideoView:localVideoView toContainer:tile.videoHost];
            }
        }else{
            [[self.session mediaAdapter] setRemoteParticipant:participantId videoView:tile.videoHost];
        }
        NSString *name = [self displayNameForParticipantId:participantId];
        NSString *hint = nil;
        if([self isLocalParticipantId:participantId]) {
            hint = self.session.videoEnabled ? LLang(@"视频已开启") : LLang(@"未开启摄像头");
        }else{
            WKRTCMediaParticipantState *remoteState = participantStates[participantId];
            hint = remoteState && !remoteState.videoEnabled ? LLang(@"未开启摄像头") : LLang(@"视频已开启");
        }
        [tile configureWithName:name hint:hint backgroundColor:colors[i] participantState:participantStates[participantId]];
        BOOL videoEnabled = [self isLocalParticipantId:participantId] ? self.session.videoEnabled : [self videoEnabledForParticipantId:participantId states:participantStates];
        [tile setPlaceholderHidden:videoEnabled uid:[self avatarUIDForParticipantId:participantId] name:name];
    }
    NSArray<NSString *> *visibleRemoteParticipants = [self remoteParticipantsFromParticipants:visibleParticipants];
    [[self.session mediaAdapter] setVisibleRemoteParticipants:visibleRemoteParticipants];
    [self layoutGroupVideoParticipantStripWithAllParticipants:allParticipants visibleParticipants:visibleParticipants];
}

- (CGRect)groupVideoTileFrameAtIndex:(NSInteger)index count:(NSInteger)count {
    if(count <= 1) {
        return [self r:0 y:0 w:390 h:390];
    }
    if(count == 2) {
        return [self r:index == 0 ? 0 : 195 y:0 w:195 h:390];
    }
    CGFloat x = (index % 2) * 195.0f;
    CGFloat y = (index / 2) * 195.0f;
    return [self r:x y:y w:195 h:195];
}

- (NSArray<NSString *> *)currentGroupVisibleParticipants {
    NSArray<NSString *> *allParticipants = [self participantNames];
    NSString *callId = self.session.currentPayload.callId ?: @"";
    if(![self.groupVisibleCallId isEqualToString:callId]) {
        self.groupVisibleCallId = callId;
        self.groupVisibleParticipantIds = @[];
    }
    NSMutableArray<NSString *> *visible = [NSMutableArray array];
    for (NSString *participantId in self.groupVisibleParticipantIds) {
        if([self participantArray:allParticipants containsParticipantId:participantId] && ![self participantArray:visible containsParticipantId:participantId]) {
            [visible addObject:participantId];
        }
    }
    NSInteger targetCount = MIN(4, (NSInteger)allParticipants.count);
    for (NSString *participantId in allParticipants) {
        if(visible.count >= targetCount) {
            break;
        }
        if(![self participantArray:visible containsParticipantId:participantId]) {
            [visible addObject:participantId];
        }
    }
    while (visible.count > 4) {
        [visible removeLastObject];
    }
    self.groupVisibleParticipantIds = visible.copy;
    return self.groupVisibleParticipantIds;
}

- (void)layoutGroupVideoParticipantStripWithAllParticipants:(NSArray<NSString *> *)allParticipants visibleParticipants:(NSArray<NSString *> *)visibleParticipants {
    [self.groupVideoParticipantScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    NSMutableArray<NSString *> *hiddenParticipants = [NSMutableArray array];
    for (NSString *participantId in allParticipants) {
        if(![self participantArray:visibleParticipants containsParticipantId:participantId]) {
            [hiddenParticipants addObject:participantId];
        }
    }
    self.groupVideoParticipantScrollView.hidden = hiddenParticipants.count == 0;
    if(hiddenParticipants.count == 0) {
        self.groupVideoParticipantScrollView.contentSize = CGSizeZero;
        return;
    }
    CGFloat chipWidth = 72.0f * [self ss];
    CGFloat chipHeight = 86.0f * [self ss];
    CGFloat gap = 10.0f * [self ss];
    CGFloat x = 0.0f;
    for (NSString *participantId in hiddenParticipants) {
        WKRTCParticipantChipView *chip = [[WKRTCParticipantChipView alloc] initWithFrame:CGRectMake(x, 8.0f * [self ss], chipWidth, chipHeight)];
        [chip configureWithParticipantId:participantId];
        [chip addTarget:self action:@selector(groupParticipantChipPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self.groupVideoParticipantScrollView addSubview:chip];
        x += chipWidth + gap;
    }
    self.groupVideoParticipantScrollView.contentSize = CGSizeMake(MAX(x - gap, 0.0f), self.groupVideoParticipantScrollView.bounds.size.height);
}

- (void)groupParticipantChipPressed:(WKRTCParticipantChipView *)chip {
    NSString *replacementId = chip.participantId;
    if(replacementId.length == 0) {
        return;
    }
    NSArray<NSString *> *visibleParticipants = [self currentGroupVisibleParticipants];
    if(visibleParticipants.count == 0) {
        return;
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:LLang(@"替换视频") message:LLang(@"选择要替换的视频窗口") preferredStyle:UIAlertControllerStyleActionSheet];
    __weak typeof(self) weakSelf = self;
    for (NSString *visibleId in visibleParticipants) {
        NSString *title = [NSString stringWithFormat:@"%@ %@", LLang(@"替换"), [self displayNameForParticipantId:visibleId]];
        [alert addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [weakSelf replaceVisibleParticipant:visibleId withParticipant:replacementId];
        }]];
    }
    [alert addAction:[UIAlertAction actionWithTitle:LLang(@"取消") style:UIAlertActionStyleCancel handler:nil]];
    if(alert.popoverPresentationController) {
        alert.popoverPresentationController.sourceView = chip;
        alert.popoverPresentationController.sourceRect = chip.bounds;
    }
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)replaceVisibleParticipant:(NSString *)oldParticipantId withParticipant:(NSString *)newParticipantId {
    if(oldParticipantId.length == 0 || newParticipantId.length == 0) {
        return;
    }
    NSMutableArray<NSString *> *visible = [[self currentGroupVisibleParticipants] mutableCopy];
    NSUInteger oldIndex = [visible indexOfObject:oldParticipantId];
    if(oldIndex == NSNotFound || [visible containsObject:newParticipantId]) {
        return;
    }
    visible[oldIndex] = newParticipantId;
    self.groupVisibleParticipantIds = visible.copy;
    [self layoutGroupVideoTiles];
}

- (BOOL)participantArray:(NSArray<NSString *> *)participants containsParticipantId:(NSString *)participantId {
    for (NSString *item in participants) {
        if([item isEqualToString:participantId]) {
            return YES;
        }
    }
    return NO;
}

- (NSArray<NSString *> *)remoteParticipantsFromParticipants:(NSArray<NSString *> *)participants {
    NSMutableArray<NSString *> *items = [NSMutableArray array];
    for (NSString *participantId in participants) {
        if(![self isLocalParticipantId:participantId]) {
            [items addObject:participantId];
        }
    }
    return items.copy;
}

- (BOOL)isLocalParticipantId:(NSString *)participantId {
    NSString *localId = [self localParticipantId];
    NSString *participantUID = WKRTCUIDFromParticipantID(participantId);
    NSString *localUID = WKRTCUIDFromParticipantID(localId);
    return localId.length > 0 && ([participantId isEqualToString:localId] || [participantUID isEqualToString:localUID]);
}

- (NSString *)avatarUIDForParticipantId:(NSString *)participantId {
    NSString *uid = WKRTCUIDFromParticipantID(participantId);
    return uid.length > 0 ? uid : participantId;
}

- (NSString *)displayNameForParticipantId:(NSString *)participantId {
    NSString *uid = [self avatarUIDForParticipantId:participantId];
    NSString *name = WKRTCDisplayNameForUID(uid);
    return WKRTCSafeName(name);
}

- (BOOL)videoEnabledForParticipantId:(NSString *)participantId states:(NSDictionary<NSString *, WKRTCMediaParticipantState *> *)states {
    WKRTCMediaParticipantState *state = states[participantId];
    if(!state) {
        return YES;
    }
    return state.videoEnabled;
}

- (void)sessionChanged {
    [self refresh];
}

- (void)participantPresenceChanged:(NSNotification *)notification {
    WKRTCCallPayload *payload = self.session.currentPayload;
    if(payload.channelType != WK_GROUP || ![self isActiveLikeState:self.session.state]) {
        return;
    }
    NSString *participantId = notification.userInfo[@"participant_id"];
    NSString *action = notification.userInfo[@"action"];
    if(participantId.length == 0 || action.length == 0) {
        return;
    }
    NSString *name = WKRTCDisplayNameForUID(participantId);
    NSString *message = [action isEqualToString:WKRTCMediaParticipantPresenceActionJoined] ? [NSString stringWithFormat:@"%@%@", name, LLang(@"已加入通话")] : [NSString stringWithFormat:@"%@%@", name, LLang(@"已离开通话")];
    [self.view makeToast:message];
}

- (void)refresh {
    WKRTCCallPayload *payload = self.session.currentPayload;
    if(!payload) {
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    BOOL group = payload.channelType == WK_GROUP;
    BOOL video = payload.callType == WKRTCCallTypeVideo;
    BOOL incoming = self.session.state == WKRTCCallStateIncomingRinging;
    BOOL active = [self isActiveLikeState:self.session.state];
    
    self.nameLabel.text = [self displayNameForPayload:payload];
    self.avatarInitialLabel.text = self.nameLabel.text.length > 0 ? [self.nameLabel.text substringToIndex:1] : @"?";
    [self refreshMainAvatarWithPayload:payload];
    
    self.singleVideoContainer.hidden = !(video && !group);
    self.smallVideoContainer.hidden = !(video && !group && active && !incoming);
    self.avatarContainer.hidden = group || (video && !incoming);
    self.nameLabel.hidden = group || (video && !incoming);
    self.statusLabel.hidden = group || (video && !incoming);
    self.groupHeaderView.hidden = !group || (video && active);
    self.groupVideoGridView.hidden = !(group && video && active);
    self.groupVideoTitleLabel.hidden = !(group && video && active);
    self.groupVideoParticipantScrollView.hidden = !(group && video && active);
    self.minimizeButton.hidden = incoming;
    
    if(video && !group) {
        [self attachSingleVideoIfNeededActive:active incoming:incoming];
        if(!incoming && active && self.singleVideoContainer.window && !CGRectIsEmpty(self.singleVideoContainer.bounds)) {
            [self.session preparePictureInPictureFromSourceView:self.singleVideoContainer];
        }
    }
    
    if(group) {
        NSString *title = [self displayNameForPayload:payload];
        NSString *subtitle = [self groupSubtitleIncoming:incoming active:active video:video];
        [self.groupHeaderView configureWithTitle:title subtitle:subtitle participants:[self participantNames] participantStates:[self participantStates]];
    }
    
    if(group && video && active) {
        self.groupVideoTitleLabel.text = [NSString stringWithFormat:@"%@ · %ld%@", [self displayNameForPayload:payload], (long)[self participantNames].count, LLang(@"人通话")];
        [self layoutGroupVideoTiles];
    }
    
    if(self.session.state == WKRTCCallStateActive) {
        if(self.activeAt <= 0.0f) {
            self.activeAt = NSDate.date.timeIntervalSince1970 - [self.session currentCallDuration];
            self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(updateDuration) userInfo:nil repeats:YES];
        }
        [self updateDuration];
    }else{
        [self.timer invalidate];
        self.timer = nil;
        if(self.session.state != WKRTCCallStateReconnecting) {
            self.activeAt = 0.0f;
        }
        self.statusLabel.text = [self statusTextForState:self.session.state video:video];
    }
    [self refreshWeakNetworkHintIfNeeded];
    self.acceptButton.enabled = !self.accepting;
    self.acceptButton.alpha = self.accepting ? 0.5f : 1.0f;
    self.muteButton.textLabel.text = self.session.audioEnabled ? LLang(@"静音") : LLang(@"取消静音");
    [self.muteButton setIconName:self.session.audioEnabled ? @"rtc_mic" : @"rtc_mute" iconSize:CGSizeMake(20.0f, 21.0f)];
    self.videoButton.textLabel.text = self.session.videoEnabled ? LLang(@"关闭视频") : LLang(@"开启视频");
    [self.videoButton setIconName:self.session.videoEnabled ? @"rtc_video" : @"rtc_video_off" iconSize:CGSizeMake(22.0f, 18.0f)];
    WKRTCAudioRouteManager *routeManager = [WKRTCAudioRouteManager shared];
    NSString *route = routeManager.currentRouteName;
    if([route isEqualToString:@"bluetooth"]) {
        self.speakerButton.textLabel.text = LLang(@"蓝牙");
        [self.speakerButton setIconName:@"rtc_speaker" iconSize:CGSizeMake(20.0f, 20.0f)];
    }else if(self.session.speakerEnabled || routeManager.speakerEnabled) {
        self.speakerButton.textLabel.text = LLang(@"扬声器");
        [self.speakerButton setIconName:@"rtc_speaker" iconSize:CGSizeMake(20.0f, 20.0f)];
    }else{
        self.speakerButton.textLabel.text = LLang(@"听筒");
        [self.speakerButton setIconName:@"rtc_receiver" iconSize:CGSizeMake(20.0f, 20.0f)];
    }
    
    [self updateButtonVisibilityIncoming:incoming active:active video:video group:group];
    [self.view bringSubviewToFront:self.smallVideoContainer];
    [self.view bringSubviewToFront:self.minimizeButton];
    if(!self.minimizeTransitionView.hidden) {
        [self.view bringSubviewToFront:self.minimizeTransitionView];
    }
    [self.view setNeedsLayout];
}

- (void)attachSingleVideoIfNeededActive:(BOOL)active incoming:(BOOL)incoming {
    if(active && !incoming && !self.userSwappedVideo) {
        self.showingRemoteVideo = YES;
    }
    BOOL showSmallVideo = active && !incoming;
    UIView *mainView = nil;
    UIView *smallView = nil;
    if(showSmallVideo) {
        mainView = self.showingRemoteVideo ? [[self.session mediaAdapter] remoteVideoView] : [[self.session mediaAdapter] localVideoView];
        smallView = self.showingRemoteVideo ? [[self.session mediaAdapter] localVideoView] : [[self.session mediaAdapter] remoteVideoView];
        self.smallVideoLabel.text = @"";
        self.smallVideoLabel.hidden = YES;
    }else{
        mainView = [[self.session mediaAdapter] localVideoView];
        self.userSwappedVideo = NO;
        self.showingRemoteVideo = NO;
    }
    BOOL shouldRelayoutVideoViews = mainView.superview != self.singleVideoContainer || self.lastMainVideoWasRemote != self.showingRemoteVideo;
    if(shouldRelayoutVideoViews) {
        [self attachVideoView:mainView toContainer:self.singleVideoContainer];
    }
    [self refreshPlaceholder:self.mainVideoPlaceholder hidden:[self videoEnabledForRemote:self.showingRemoteVideo] uid:[self uidForRemote:self.showingRemoteVideo] name:[self nameForRemote:self.showingRemoteVideo]];
    if(showSmallVideo) {
        if(shouldRelayoutVideoViews || smallView.superview != self.smallVideoContainer) {
            [self attachVideoView:smallView toContainer:self.smallVideoContainer];
        }
        BOOL smallRemote = !self.showingRemoteVideo;
        [self refreshPlaceholder:self.smallVideoPlaceholder hidden:[self videoEnabledForRemote:smallRemote] uid:[self uidForRemote:smallRemote] name:[self nameForRemote:smallRemote]];
        [self.smallVideoContainer bringSubviewToFront:self.smallVideoPlaceholder];
        [self.smallVideoContainer bringSubviewToFront:self.smallVideoLabel];
    }else{
        for (UIView *view in self.smallVideoContainer.subviews.copy) {
            if(view != self.smallVideoLabel && view != self.smallVideoPlaceholder) {
                [view removeFromSuperview];
            }
        }
        self.smallVideoPlaceholder.hidden = YES;
        if(self.smallVideoLabel.superview != self.smallVideoContainer) {
            [self.smallVideoContainer addSubview:self.smallVideoLabel];
        }
    }
    [self.singleVideoContainer bringSubviewToFront:self.mainVideoPlaceholder];
    self.lastMainVideoWasRemote = self.showingRemoteVideo;
}

- (void)attachVideoView:(UIView *)videoView toContainer:(UIView *)container {
    for (UIView *view in container.subviews.copy) {
        if(view != self.smallVideoLabel && view != self.mainVideoPlaceholder && view != self.smallVideoPlaceholder) {
            [view removeFromSuperview];
        }
    }
    // LiveKit 的 VideoView 可能会接管触摸；小窗切换统一由容器手势处理。
    videoView.userInteractionEnabled = NO;
    videoView.frame = container.bounds;
    videoView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [container insertSubview:videoView atIndex:0];
    if(container == self.singleVideoContainer && self.mainVideoPlaceholder.superview != self.singleVideoContainer) {
        [self.singleVideoContainer addSubview:self.mainVideoPlaceholder];
    }
    if(container == self.smallVideoContainer && self.smallVideoPlaceholder.superview != self.smallVideoContainer) {
        [self.smallVideoContainer addSubview:self.smallVideoPlaceholder];
    }
    if(container == self.smallVideoContainer && self.smallVideoLabel.superview != self.smallVideoContainer) {
        [self.smallVideoContainer addSubview:self.smallVideoLabel];
    }
}

- (void)refreshPlaceholder:(WKRTCVideoAvatarPlaceholderView *)placeholder hidden:(BOOL)hidden uid:(NSString *)uid name:(NSString *)name {
    placeholder.hidden = hidden;
    if(!hidden) {
        [placeholder configureWithUID:uid name:name];
    }
}

- (BOOL)videoEnabledForRemote:(BOOL)remote {
    if(!remote) {
        return self.session.videoEnabled;
    }
    WKRTCMediaParticipantState *state = [self stateForUID:[self privatePeerUIDForPayload:self.session.currentPayload]];
    return state ? state.videoEnabled : YES;
}

- (NSString *)uidForRemote:(BOOL)remote {
    if(remote) {
        return [self privatePeerUIDForPayload:self.session.currentPayload];
    }
    return [self localParticipantId];
}

- (NSString *)nameForRemote:(BOOL)remote {
    if(remote) {
        return [self displayNameForPayload:self.session.currentPayload];
    }
    return LLang(@"自己");
}

- (WKRTCMediaParticipantState *)stateForUID:(NSString *)uid {
    if(uid.length == 0) {
        return nil;
    }
    NSDictionary<NSString *, WKRTCMediaParticipantState *> *states = [self participantStates];
    WKRTCMediaParticipantState *directState = states[uid];
    if(directState) {
        return directState;
    }
    for (WKRTCMediaParticipantState *state in states.allValues) {
        NSString *participantUID = WKRTCUIDFromParticipantID(state.participantId);
        if([participantUID isEqualToString:uid]) {
            return state;
        }
    }
    return nil;
}

- (void)swapVideoPressed {
    if(self.session.currentPayload.callType != WKRTCCallTypeVideo || ![self isActiveLikeState:self.session.state]) {
        return;
    }
    self.userSwappedVideo = YES;
    self.showingRemoteVideo = !self.showingRemoteVideo;
    [self refresh];
}

- (void)handleSmallVideoPan:(UIPanGestureRecognizer *)gesture {
    if(self.smallVideoContainer.hidden) {
        return;
    }
    if(gesture.state == UIGestureRecognizerStateBegan) {
        self.smallVideoPanStartCenter = self.smallVideoContainer.center;
        self.smallVideoManuallyPositioned = YES;
    }
    CGPoint translation = [gesture translationInView:self.view];
    CGPoint center = CGPointMake(self.smallVideoPanStartCenter.x + translation.x, self.smallVideoPanStartCenter.y + translation.y);
    CGRect frame = self.smallVideoContainer.frame;
    frame.origin = CGPointMake(center.x - frame.size.width / 2.0f, center.y - frame.size.height / 2.0f);
    self.smallVideoContainer.frame = [self clampedSmallVideoFrame:frame];
    self.smallVideoLabel.frame = CGRectMake(0.0f, self.smallVideoContainer.bounds.size.height - 28.0f, self.smallVideoContainer.bounds.size.width, 28.0f);
    self.smallVideoPlaceholder.frame = self.smallVideoContainer.bounds;
}

- (CGRect)clampedSmallVideoFrame:(CGRect)frame {
    CGFloat margin = 12.0f;
    UIEdgeInsets safeArea = self.view.safeAreaInsets;
    CGFloat minX = margin;
    CGFloat maxX = self.view.bounds.size.width - frame.size.width - margin;
    CGFloat minY = safeArea.top + margin;
    CGFloat maxY = self.view.bounds.size.height - safeArea.bottom - frame.size.height - margin;
    frame.origin.x = MAX(minX, MIN(maxX, frame.origin.x));
    frame.origin.y = MAX(minY, MIN(maxY, frame.origin.y));
    return frame;
}

- (void)updateButtonVisibilityIncoming:(BOOL)incoming active:(BOOL)active video:(BOOL)video group:(BOOL)group {
    for (UIView *view in self.controlsArea.subviews) {
        view.hidden = YES;
    }
    self.inviteButton.hidden = YES;
    if(incoming) {
        self.rejectButton.hidden = NO;
        self.acceptButton.hidden = NO;
        if(group && video) {
            self.messageButton.hidden = NO;
            self.messageButton.textLabel.text = LLang(@"回复消息");
        }else{
            self.speakerButton.hidden = NO;
            self.videoButton.hidden = !video;
            self.messageButton.hidden = NO;
            self.messageButton.textLabel.text = LLang(@"消息");
        }
        return;
    }
    self.hangupButton.hidden = NO;
    if(active) {
        self.muteButton.hidden = NO;
        self.speakerButton.hidden = NO;
        if(group && video) {
            self.videoButton.hidden = NO;
            self.flipCameraButton.hidden = !self.session.videoEnabled;
        }else if(group) {
        }else{
            self.videoButton.hidden = !video;
            self.messageButton.hidden = video;
            self.flipCameraButton.hidden = !video || !self.session.videoEnabled;
            self.videoButton.textLabel.text = LLang(@"关闭视频");
            self.messageButton.textLabel.text = LLang(@"消息");
        }
        self.inviteButton.hidden = NO;
    }else{
        self.muteButton.hidden = NO;
        self.speakerButton.hidden = NO;
        if(video) {
            self.videoButton.hidden = NO;
            self.videoButton.textLabel.text = LLang(@"关闭视频");
        }else{
            self.messageButton.hidden = NO;
            self.messageButton.textLabel.text = LLang(@"消息");
        }
        self.inviteButton.hidden = !group;
    }
}

- (NSString *)groupSubtitleIncoming:(BOOL)incoming active:(BOOL)active video:(BOOL)video {
    if(incoming) {
        NSString *name = self.session.currentPayload.fromName.length > 0 ? self.session.currentPayload.fromName : self.session.currentPayload.fromUid;
        if(name.length > 0) {
            return [NSString stringWithFormat:@"%@%@", name, video ? LLang(@"邀请你加入群视频") : LLang(@"邀请你加入群语音")];
        }
        return video ? LLang(@"邀请你加入群视频") : LLang(@"邀请你加入群语音");
    }
    if(active) {
        NSInteger count = MAX(1, [self participantNames].count);
        return [NSString stringWithFormat:@"%@ · %ld %@", [self durationText], (long)count, LLang(@"人在线")];
    }
    return video ? LLang(@"正在邀请成员加入视频通话...") : LLang(@"正在邀请成员加入语音通话...");
}

- (void)updateDuration {
    if(self.session.currentPayload.channelType == WK_GROUP) {
        NSString *subtitle = [self groupSubtitleIncoming:NO active:YES video:self.session.currentPayload.callType == WKRTCCallTypeVideo];
        [self.groupHeaderView configureWithTitle:[self displayNameForPayload:self.session.currentPayload] subtitle:subtitle participants:[self participantNames] participantStates:[self participantStates]];
    }else{
        self.statusLabel.text = [self durationText];
    }
}

- (NSString *)durationText {
    NSInteger seconds = [self.session currentCallDuration];
    return [NSString stringWithFormat:@"%02ld:%02ld", (long)(seconds/60), (long)(seconds%60)];
}

- (NSArray<NSString *> *)participantNames {
    NSMutableArray *names = [NSMutableArray array];
    NSString *uid = [self localParticipantId];
    if(uid.length > 0) {
        [names addObject:uid];
    }
    NSArray<NSString *> *remoteParticipants = [[self.session mediaAdapter] currentParticipants];
    [names addObjectsFromArray:remoteParticipants];
    return names;
}

- (NSString *)localParticipantId {
    return [WKSDK shared].options.connectInfo.uid ?: @"";
}

- (NSDictionary<NSString *, WKRTCMediaParticipantState *> *)participantStates {
    NSDictionary *states = [[self.session mediaAdapter] participantStates];
    return [states isKindOfClass:NSDictionary.class] ? states : @{};
}

- (NSString *)networkQualityTextForState:(WKRTCMediaParticipantState *)state {
    if([state.networkQuality isEqualToString:@"excellent"]) return LLang(@"网络极佳");
    if([state.networkQuality isEqualToString:@"good"]) return LLang(@"网络良好");
    if([state.networkQuality isEqualToString:@"poor"]) return LLang(@"网络较差");
    if([state.networkQuality isEqualToString:@"lost"]) return LLang(@"网络断开");
    return LLang(@"网络未知");
}

- (NSString *)participantLineForId:(NSString *)participantId state:(WKRTCMediaParticipantState *)state {
    NSString *displayName = participantId.length > 0 ? WKRTCDisplayNameForUID(participantId) : LLang(@"成员");
    NSString *localUid = [self localParticipantId];
    if(localUid.length > 0 && [participantId isEqualToString:localUid]) {
        displayName = [NSString stringWithFormat:@"%@（%@）", displayName, LLang(@"我")];
    }
    NSString *speaking = state.speaking || state.audioLevel > 0.08f ? LLang(@"正在说话") : LLang(@"未说话");
    NSString *quality = [self networkQualityTextForState:state];
    return [NSString stringWithFormat:@"%@ · %@ · %@", displayName, speaking, quality];
}

- (NSString *)participantStatusMessage {
    NSArray<NSString *> *names = [self participantNames];
    if(names.count == 0) {
        return LLang(@"暂无成员");
    }
    NSDictionary<NSString *, WKRTCMediaParticipantState *> *states = [self participantStates];
    NSMutableArray<NSString *> *lines = [NSMutableArray array];
    for (NSString *participantId in names) {
        [lines addObject:[self participantLineForId:participantId state:states[participantId]]];
    }
    return [lines componentsJoinedByString:@"\n"];
}

- (NSString *)displayNameForPayload:(WKRTCCallPayload *)payload {
    NSString *channelId = payload.channelType == WK_PERSON ? [self privatePeerUIDForPayload:payload] : payload.channelId;
    WKChannel *channel = [[WKChannel alloc] initWith:channelId channelType:payload.channelType];
    WKChannelInfo *info = [[WKSDK shared].channelManager getChannelInfo:channel];
    if(info.displayName.length > 0) {
        return info.displayName;
    }
    if(payload.fromName.length > 0 && self.session.state == WKRTCCallStateIncomingRinging) {
        return payload.fromName;
    }
    return payload.channelType == WK_GROUP ? (payload.channelId ?: LLang(@"群通话")) : (channelId ?: LLang(@"音视频通话"));
}

- (void)refreshMainAvatarWithPayload:(WKRTCCallPayload *)payload {
    if(payload.channelType != WK_PERSON) {
        self.avatarImageView.image = nil;
        return;
    }
    NSString *avatarURL = WKRTCAvatarURLForUID([self privatePeerUIDForPayload:payload]);
    if(avatarURL.length > 0) {
        // 优先显示本地已知头像，失败时保留首字母占位。
        [self.avatarImageView lim_setImageWithURL:[NSURL URLWithString:avatarURL]];
        self.avatarInitialLabel.hidden = YES;
    }else {
        self.avatarInitialLabel.hidden = NO;
    }
}

- (void)refreshWeakNetworkHintIfNeeded {
    if(![self isActiveLikeState:self.session.state]) {
        return;
    }
    NSDictionary<NSString *, WKRTCMediaParticipantState *> *states = [self participantStates];
    BOOL hasWeakNetwork = NO;
    for (WKRTCMediaParticipantState *state in states.allValues) {
        if([state.networkQuality isEqualToString:@"poor"] || [state.networkQuality isEqualToString:@"lost"]) {
            hasWeakNetwork = YES;
            break;
        }
    }
    if(hasWeakNetwork) {
        NSString *text = self.session.state == WKRTCCallStateReconnecting ? LLang(@"网络不稳定，正在重连...") : LLang(@"网络不稳定，已降低视频订阅");
        if(self.session.currentPayload.channelType == WK_GROUP) {
            self.groupVideoTitleLabel.text = text;
        }else {
            self.statusLabel.text = text;
        }
    }
}

- (BOOL)isActiveLikeState:(WKRTCCallState)state {
    return state == WKRTCCallStateActive || state == WKRTCCallStateReconnecting;
}

- (NSString *)statusTextForState:(WKRTCCallState)state video:(BOOL)video {
    switch (state) {
        case WKRTCCallStateOutgoingRinging:
            return video ? LLang(@"正在等待对方接受邀请...") : LLang(@"正在呼叫...");
        case WKRTCCallStateIncomingRinging:
            return video ? LLang(@"邀请你视频通话...") : LLang(@"邀请你语音通话...");
        case WKRTCCallStateJoining:
            return LLang(@"正在接听...");
        case WKRTCCallStateConnecting:
            return LLang(@"正在连接...");
        case WKRTCCallStateReconnecting:
            return LLang(@"正在重连...");
        case WKRTCCallStateEnding:
            return LLang(@"正在结束...");
        case WKRTCCallStateEnded:
            return LLang(@"已结束");
        case WKRTCCallStateFailed:
            return LLang(@"通话失败");
        case WKRTCCallStateIdle:
        case WKRTCCallStateActive:
            return @"";
    }
}

- (void)speakerPressed {
    BOOL enabled = !self.session.speakerEnabled;
    self.session.speakerEnabled = enabled;
    self.speakerButton.textLabel.text = enabled ? LLang(@"扬声器") : LLang(@"听筒");
    [self.speakerButton setIconName:enabled ? @"rtc_speaker" : @"rtc_receiver" iconSize:CGSizeMake(20.0f, 20.0f)];
    [[WKRTCAudioRouteManager shared] setSpeakerEnabled:enabled callType:self.session.currentPayload.callType];
    [self refresh];
}

- (void)mutePressed {
    BOOL target = !self.session.audioEnabled;
    BOOL previous = self.session.audioEnabled;
    NSString *callId = self.session.currentPayload.callId ?: @"";
    if(callId.length == 0) {
        [[WKNavigationManager shared].topViewController.view makeToast:LLang(@"通话不存在")];
        return;
    }
    self.muteButton.enabled = NO;
    [[self.session mediaAdapter] setAudioEnabled:target completion:^(NSError * _Nullable error) {
        if(![self.session.currentPayload.callId isEqualToString:callId]) {
            return;
        }
        if(!error) {
            self.muteButton.enabled = YES;
            self.session.audioEnabled = target;
            [self refresh];
        }else {
            [[self.session mediaAdapter] setAudioEnabled:previous completion:nil];
            self.session.audioEnabled = previous;
            self.muteButton.enabled = YES;
            [[WKNavigationManager shared].topViewController.view makeToast:error.localizedDescription ?: LLang(@"设置麦克风失败")];
            [self refresh];
        }
    }];
}

- (void)videoPressed {
    BOOL target = !self.session.videoEnabled;
    BOOL previous = self.session.videoEnabled;
    NSString *callId = self.session.currentPayload.callId ?: @"";
    if(callId.length == 0) {
        [[WKNavigationManager shared].topViewController.view makeToast:LLang(@"通话不存在")];
        return;
    }
    self.videoButton.enabled = NO;
    [[self.session mediaAdapter] setVideoEnabled:target completion:^(NSError * _Nullable error) {
        if(![self.session.currentPayload.callId isEqualToString:callId]) {
            return;
        }
        if(!error) {
            self.videoButton.enabled = YES;
            self.session.videoEnabled = target;
            [self refresh];
        }else {
            [[self.session mediaAdapter] setVideoEnabled:previous completion:nil];
            self.session.videoEnabled = previous;
            self.videoButton.enabled = YES;
            [[WKNavigationManager shared].topViewController.view makeToast:error.localizedDescription ?: LLang(@"设置摄像头失败")];
            [self refresh];
        }
    }];
}

- (void)flipCameraPressed {
    NSString *callId = self.session.currentPayload.callId ?: @"";
    if(callId.length == 0) {
        [[WKNavigationManager shared].topViewController.view makeToast:LLang(@"通话不存在")];
        return;
    }
    if(!self.session.videoEnabled) {
        [[WKNavigationManager shared].topViewController.view makeToast:LLang(@"请先开启摄像头")];
        return;
    }
    self.flipCameraButton.enabled = NO;
    [[self.session mediaAdapter] switchCameraWithCompletion:^(NSError * _Nullable error) {
        if(![self.session.currentPayload.callId isEqualToString:callId]) {
            return;
        }
        self.flipCameraButton.enabled = YES;
        if(error) {
            [[WKNavigationManager shared].topViewController.view makeToast:error.localizedDescription ?: LLang(@"切换摄像头失败")];
        }else {
            [[WKNavigationManager shared].topViewController.view makeToast:LLang(@"已切换摄像头")];
        }
    }];
}

- (void)keypadPressed {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:LLang(@"拨号盘") message:LLang(@"当前通话暂不支持发送按键音") preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:LLang(@"知道了") style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)messagePressed {
    BOOL incoming = self.session.state == WKRTCCallStateIncomingRinging;
    if(incoming) {
        [self.session rejectIncomingCall];
    }else if([self isActiveLikeState:self.session.state] || self.session.state == WKRTCCallStateConnecting || self.session.state == WKRTCCallStateOutgoingRinging) {
        [self.session showFloatingCall];
    }
    [self openCurrentConversation];
}

- (void)beginMinimizeTransition {
    self.minimizeTransitionView.hidden = NO;
    self.minimizeTransitionView.frame = self.view.bounds;
    self.minimizeTransitionView.alpha = 0.0f;
    [self.view bringSubviewToFront:self.minimizeTransitionView];
    self.minimizeButton.enabled = NO;
    [UIView animateWithDuration:0.08f delay:0.0f options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseOut animations:^{
        self.minimizeTransitionView.alpha = 1.0f;
    } completion:nil];
}

- (void)cancelMinimizeTransition {
    self.minimizeButton.enabled = YES;
    [UIView animateWithDuration:0.12f delay:0.0f options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseOut animations:^{
        self.minimizeTransitionView.alpha = 0.0f;
    } completion:^(BOOL finished) {
        if(finished) {
            self.minimizeTransitionView.hidden = YES;
        }
    }];
}

- (void)minimizePressed {
    if(self.session.state == WKRTCCallStateIncomingRinging) {
        return;
    }
    BOOL privateVideo = self.session.currentPayload.callType == WKRTCCallTypeVideo && self.session.currentPayload.channelType != WK_GROUP;
    if(privateVideo) {
        [self beginMinimizeTransition];
        [self.session showPictureInPictureFromSourceView:self.singleVideoContainer completion:^(NSError * _Nullable error) {
            if(error) {
                [self cancelMinimizeTransition];
                [[WKNavigationManager shared].topViewController.view makeToast:error.localizedDescription ?: LLang(@"启动画中画失败")];
                return;
            }
            [self dismissViewControllerAnimated:NO completion:nil];
        }];
    }else {
        [self.session showFloatingCall];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)membersPressed {
    NSString *message = [self participantStatusMessage];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:LLang(@"通话成员") message:message preferredStyle:UIAlertControllerStyleActionSheet];
    [alert addAction:[UIAlertAction actionWithTitle:LLang(@"邀请成员") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self inviteMembersPressed];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:LLang(@"分享加入码") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self shareJoinCodePressed];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:LLang(@"知道了") style:UIAlertActionStyleCancel handler:nil]];
    if(alert.popoverPresentationController) {
        alert.popoverPresentationController.sourceView = self.membersButton;
        alert.popoverPresentationController.sourceRect = self.membersButton.bounds;
    }
    [self presentViewController:alert animated:YES completion:nil];
}

// 通过现有联系人选择器选择要强邀请的成员，服务端最终校验邀请权限。
- (void)inviteMembersPressed {
    WKRTCCallPayload *payload = self.session.currentPayload;
    if(payload.callId.length == 0) {
        [self.view makeToast:LLang(@"通话不存在")];
        return;
    }
    WKContactsSelectVC *vc = [WKContactsSelectVC new];
    vc.showBack = YES;
    vc.mode = WKContactsModeMulti;
    vc.title = LLang(@"邀请成员");
    NSArray<NSString *> *hiddenUsers = [self hiddenInviteUsers];
    vc.hiddenUsers = hiddenUsers;
    vc.data = [self filteredInviteContactsData:[self inviteContactsDataForPayload:payload] hiddenUsers:hiddenUsers];
    if(payload.channelType == WK_GROUP && vc.data.count == 0) {
        [self.view makeToast:LLang(@"没有可邀请的成员")];
        return;
    }
    __weak typeof(self) weakSelf = self;
    vc.onFinishedSelect = ^(NSArray<NSString *> *uids) {
        NSArray<NSString *> *validUids = [weakSelf filteredInviteUids:uids];
        if(validUids.count == 0) {
            NSString *message = uids.count > 0 ? LLang(@"所选成员正在通话中或不可邀请") : LLang(@"请选择成员");
            [weakSelf.view makeToast:message];
            return;
        }
        // 只关闭成员选择器，保留当前通话页继续展示媒体状态。
        UIViewController *selectorVC = weakSelf.presentedViewController;
        void (^inviteBlock)(void) = ^{
            [weakSelf.view showHUD:LLang(@"正在邀请")];
            [[WKRTCAPI shared] inviteCall:payload.callId uids:validUids].then(^{
                [weakSelf.view hideHud];
                [weakSelf appendInviteUids:validUids toPayload:payload];
                [weakSelf.view makeToast:LLang(@"已发送邀请")];
            }).catch(^(NSError *error){
                [weakSelf.view hideHud];
                [weakSelf.view makeToast:error.localizedDescription ?: LLang(@"邀请成员失败")];
            });
        };
        if(selectorVC) {
            [selectorVC dismissViewControllerAnimated:YES completion:inviteBlock];
        }else {
            inviteBlock();
        }
    };
    [self presentViewController:vc animated:YES completion:nil];
}

// 创建一次性加入码并展示分享入口，分享内容只包含服务端返回的通话编号和加入码。
- (void)shareJoinCodePressed {
    WKRTCCallPayload *payload = self.session.currentPayload;
    if(payload.callId.length == 0) {
        [self.view makeToast:LLang(@"通话不存在")];
        return;
    }
    [self.view showHUD:LLang(@"正在创建加入码")];
    __weak typeof(self) weakSelf = self;
    [[WKRTCAPI shared] createJoinCodeForCall:payload.callId].then(^(WKRTCJoinCodeResp *resp){
        [weakSelf.view hideHud];
        if(resp.callId.length == 0 || resp.joinCode.length == 0) {
            [weakSelf.view makeToast:LLang(@"加入码返回为空")];
            return;
        }
        NSString *callType = payload.callType == WKRTCCallTypeVideo ? LLang(@"视频通话") : LLang(@"语音通话");
        NSString *text = [NSString stringWithFormat:@"%@：%@\n%@：%@\n%@：%@\n%@", LLang(@"通话编号"), resp.callId, LLang(@"加入码"), resp.joinCode, LLang(@"通话类型"), callType, LLang(@"加入码 5 分钟内有效且只能使用一次")];
        [weakSelf presentJoinCodeShareText:text];
    }).catch(^(NSError *error){
        [weakSelf.view hideHud];
        [weakSelf.view makeToast:error.localizedDescription ?: LLang(@"创建加入码失败")];
    });
}

- (void)presentJoinCodeShareText:(NSString *)text {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:LLang(@"加入码") message:text preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:LLang(@"复制") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UIPasteboard.generalPasteboard.string = text;
        [self.view makeToast:LLang(@"加入码已复制")];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:LLang(@"分享") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UIActivityViewController *activity = [[UIActivityViewController alloc] initWithActivityItems:@[text] applicationActivities:nil];
        if(activity.popoverPresentationController) {
            UIView *sourceView = self.inviteButton.hidden ? self.membersButton : self.inviteButton;
            activity.popoverPresentationController.sourceView = sourceView;
            activity.popoverPresentationController.sourceRect = sourceView.bounds;
        }
        [self presentViewController:activity animated:YES completion:nil];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:LLang(@"关闭") style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (NSArray<WKContactsSelect *> *)inviteContactsDataForPayload:(WKRTCCallPayload *)payload {
    if(payload.channelType != WK_GROUP) {
        NSArray *data = [[WKApp shared] invoke:WKPOINT_CONTACTS_SELECT_DATA param:nil];
        return [data isKindOfClass:NSArray.class] ? data : @[];
    }
    WKChannel *channel = [[WKChannel alloc] initWith:payload.channelId channelType:payload.channelType];
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

- (NSArray<WKContactsSelect *> *)filteredInviteContactsData:(NSArray<WKContactsSelect *> *)data hiddenUsers:(NSArray<NSString *> *)hiddenUsers {
    NSSet<NSString *> *hiddenSet = [NSSet setWithArray:hiddenUsers ?: @[]];
    NSMutableArray<WKContactsSelect *> *items = [NSMutableArray array];
    for (WKContactsSelect *contact in data) {
        NSString *uid = contact.uid ?: @"";
        if(uid.length == 0 || [hiddenSet containsObject:uid] || [hiddenSet containsObject:WKRTCUIDFromParticipantID(uid)]) {
            continue;
        }
        [items addObject:contact];
    }
    return items.copy;
}

- (NSArray<NSString *> *)hiddenInviteUsers {
    NSMutableSet<NSString *> *users = [NSMutableSet set];
    [self addSystemInviteHiddenUsers:users];
    NSString *uid = [WKSDK shared].options.connectInfo.uid;
    [self addInviteHiddenUser:uid toSet:users];
    
    WKRTCCallPayload *payload = self.session.currentPayload;
    [self addInviteHiddenUser:payload.fromUid toSet:users];
    [self addInviteHiddenUser:payload.answerUid toSet:users];
    if(payload.channelType == WK_PERSON) {
        [self addInviteHiddenUser:payload.channelId toSet:users];
    }
    for (NSString *inviteUid in payload.inviteUids) {
        [self addInviteHiddenUser:inviteUid toSet:users];
    }
    for (NSString *participantId in [[self.session mediaAdapter] currentParticipants]) {
        [self addInviteHiddenUser:participantId toSet:users];
        [self addInviteHiddenUser:WKRTCUIDFromParticipantID(participantId) toSet:users];
    }
    return users.allObjects;
}

- (NSArray<NSString *> *)filteredInviteUids:(NSArray<NSString *> *)uids {
    NSSet<NSString *> *hiddenUsers = [NSSet setWithArray:[self hiddenInviteUsers]];
    NSMutableArray<NSString *> *validUids = [NSMutableArray array];
    for (NSString *uid in uids) {
        if(uid.length == 0 || [hiddenUsers containsObject:uid] || [hiddenUsers containsObject:WKRTCUIDFromParticipantID(uid)]) {
            continue;
        }
        [validUids addObject:uid];
    }
    return validUids.copy;
}

- (void)appendInviteUids:(NSArray<NSString *> *)uids toPayload:(WKRTCCallPayload *)payload {
    NSMutableOrderedSet<NSString *> *items = [NSMutableOrderedSet orderedSetWithArray:payload.inviteUids ?: @[]];
    for (NSString *uid in uids) {
        if(uid.length > 0) {
            [items addObject:uid];
        }
    }
    payload.inviteUids = items.array;
}

- (void)addSystemInviteHiddenUsers:(NSMutableSet<NSString *> *)users {
    [self addInviteHiddenUser:WKApp.shared.config.systemUID toSet:users];
    [self addInviteHiddenUser:WKApp.shared.config.fileHelperUID toSet:users];
    [self addInviteHiddenUser:@"10000" toSet:users];
    [self addInviteHiddenUser:@"20000" toSet:users];
    [self addInviteHiddenUser:@"u_10000" toSet:users];
    [self addInviteHiddenUser:@"u_20000" toSet:users];
    [self addInviteHiddenUser:@"fileHelper" toSet:users];
}

- (void)addInviteHiddenUser:(NSString *)uid toSet:(NSMutableSet<NSString *> *)users {
    if(uid.length == 0) {
        return;
    }
    [users addObject:uid];
    NSString *safeUID = WKRTCUIDFromParticipantID(uid);
    if(safeUID.length > 0) {
        [users addObject:safeUID];
    }
    if([safeUID hasPrefix:@"u_"] && safeUID.length > 2) {
        [users addObject:[safeUID substringFromIndex:2]];
    }else if(safeUID.length > 0) {
        [users addObject:[NSString stringWithFormat:@"u_%@", safeUID]];
    }
}

- (void)openCurrentConversation {
    WKRTCCallPayload *payload = self.session.currentPayload;
    NSString *channelId = payload.channelType == WK_PERSON ? [self privatePeerUIDForPayload:payload] : payload.channelId;
    if(channelId.length == 0) {
        return;
    }
    WKChannel *channel = [[WKChannel alloc] initWith:channelId channelType:payload.channelType];
    [self dismissViewControllerAnimated:YES completion:^{
        [[WKApp shared] pushConversation:channel];
    }];
}

- (NSString *)privatePeerUIDForPayload:(WKRTCCallPayload *)payload {
    if(payload.channelType != WK_PERSON) {
        return payload.channelId ?: @"";
    }
    NSString *localUid = [self localParticipantId];
    if(payload.channelId.length > 0 && ![payload.channelId isEqualToString:localUid]) {
        return payload.channelId;
    }
    if(payload.fromUid.length > 0 && ![payload.fromUid isEqualToString:localUid]) {
        return payload.fromUid;
    }
    return payload.channelId ?: @"";
}

- (void)rejectPressed {
    [self.session rejectIncomingCall];
}

- (void)acceptPressed {
    if(self.accepting) {
        return;
    }
    self.accepting = YES;
    self.acceptButton.enabled = NO;
    self.acceptButton.alpha = 0.5f;
    [self.session acceptIncomingCallWithCompletion:^(NSError * _Nullable error) {
        self.accepting = NO;
        self.acceptButton.enabled = YES;
        self.acceptButton.alpha = 1.0f;
        if(error) {
            [[WKNavigationManager shared].topViewController.view makeToast:error.localizedDescription ?: LLang(@"接听失败")];
        }
        [self refresh];
    }];
}

- (void)hangupPressed {
    [self.session hangup];
}

@end

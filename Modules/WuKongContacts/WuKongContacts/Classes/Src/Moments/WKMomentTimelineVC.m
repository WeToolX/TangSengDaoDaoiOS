//
//  WKMomentTimelineVC.m
//  WuKongContacts
//

#import "WKMomentTimelineVC.h"
#import "WKMomentVM.h"
#import "WKMomentComposeVC.h"
#import "WKMomentNoticeVC.h"
#import "WKMomentNoticeManager.h"
#import <WuKongBase/WKPhotoBrowser.h>
#import <WuKongBase/WKMediaPickerController.h>
#import <WuKongBase/WKVideoRecordUtil.h>
#import "UIView+WK.h"
#import "UIView+WKCommon.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

static CGFloat const WKMomentLeft = 12.0f;
static CGFloat const WKMomentAvatarSize = 44.0f;

static UIColor *WKMomentBlueColor(void) {
    return [UIColor colorWithRed:91.0f/255.0f green:111.0f/255.0f blue:152.0f/255.0f alpha:1.0f];
}

static UIColor *WKMomentPanelColor(void) {
    return [UIColor colorWithRed:246.0f/255.0f green:246.0f/255.0f blue:246.0f/255.0f alpha:1.0f];
}

static UIImage *fallbackMomentIcon(NSString *name) {
    NSString *lowerName = name.lowercaseString ?: @"";
    NSString *symbolName = [lowerName containsString:@"comment"] ? @"text.bubble" : ([lowerName containsString:@"like"] ? @"heart.fill" : nil);
    if(symbolName.length > 0) {
        UIImage *image = [UIImage systemImageNamed:symbolName];
        if(image) {
            return [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        }
    }
    return nil;
}

static BOOL WKMomentMediaIsVideo(WKMomentMedia *media) {
    NSString *type = media.mediaType.lowercaseString ?: @"";
    return [type containsString:@"video"] || media.duration > 0 || media.coverURL.length > 0;
}

static UIImage *WKMomentImageNamed(NSString *name) {
    UIImage *image = [WKApp.shared loadImage:name moduleID:@"WuKongContacts"];
    if(image) {
        return image;
    }
    NSString *lastName = name.lastPathComponent;
    if(lastName.length > 0 && ![lastName isEqualToString:name]) {
        image = [WKApp.shared loadImage:lastName moduleID:@"WuKongContacts"];
        if(image) {
            return image;
        }
    }
    return fallbackMomentIcon(name);
}

@interface WKMomentActionMenu : UIControl
@property(nonatomic,strong) UIView *box;
@property(nonatomic,strong) UIButton *likeBtn;
@property(nonatomic,strong) UIButton *commentBtn;
@property(nonatomic,copy) void(^onLike)(void);
@property(nonatomic,copy) void(^onComment)(void);
-(void)showFromRect:(CGRect)rect liked:(BOOL)liked inView:(UIView*)view;
-(UIImage*)momentImage:(NSString*)name;
@end

@implementation WKMomentActionMenu

-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        self.backgroundColor = UIColor.clearColor;
        [self addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.box];
    }
    return self;
}

-(UIView *)box {
    if(!_box) {
        _box = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 212.0f, 46.0f)];
        _box.backgroundColor = [UIColor colorWithRed:45.0f/255.0f green:45.0f/255.0f blue:45.0f/255.0f alpha:1.0f];
        _box.layer.cornerRadius = 4.0f;
        [_box addSubview:self.likeBtn];
        [_box addSubview:self.commentBtn];
        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(106.0f, 10.0f, 0.5f, 26.0f)];
        line.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.15f];
        [_box addSubview:line];
    }
    return _box;
}

-(UIButton *)likeBtn {
    if(!_likeBtn) {
        _likeBtn = [[UIButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 106.0f, 46.0f)];
        _likeBtn.titleLabel.font = [WKApp.shared.config appFontOfSize:16.0f];
        [_likeBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        _likeBtn.tintColor = UIColor.whiteColor;
        [_likeBtn addTarget:self action:@selector(likePressed) forControlEvents:UIControlEventTouchUpInside];
    }
    return _likeBtn;
}

-(UIButton *)commentBtn {
    if(!_commentBtn) {
        _commentBtn = [[UIButton alloc] initWithFrame:CGRectMake(106.0f, 0.0f, 106.0f, 46.0f)];
        _commentBtn.titleLabel.font = [WKApp.shared.config appFontOfSize:16.0f];
        [_commentBtn setTitle:LLang(@"评论") forState:UIControlStateNormal];
        [_commentBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        _commentBtn.tintColor = UIColor.whiteColor;
        [_commentBtn setImage:[self momentImage:@"Moments/Timeline/Comment"] forState:UIControlStateNormal];
        _commentBtn.imageEdgeInsets = UIEdgeInsetsMake(0.0f, -6.0f, 0.0f, 0.0f);
        [_commentBtn addTarget:self action:@selector(commentPressed) forControlEvents:UIControlEventTouchUpInside];
    }
    return _commentBtn;
}

-(void)showFromRect:(CGRect)rect liked:(BOOL)liked inView:(UIView*)view {
    self.frame = view.bounds;
    [view addSubview:self];
    [self.likeBtn setTitle:(liked ? LLang(@"取消") : LLang(@"点赞")) forState:UIControlStateNormal];
    [self.likeBtn setImage:[self momentImage:(liked ? @"Moments/Timeline/LikeMenuActive" : @"Moments/Timeline/LikeOutline")] forState:UIControlStateNormal];
    self.likeBtn.imageEdgeInsets = UIEdgeInsetsMake(0.0f, -6.0f, 0.0f, 0.0f);
    CGFloat x = MAX(12.0f, MIN(rect.origin.x - 212.0f + 4.0f, view.lim_width - 224.0f));
    CGFloat y = CGRectGetMidY(rect) - 23.0f;
    self.box.frame = CGRectMake(x, y, 212.0f, 46.0f);
    self.box.alpha = 0.0f;
    self.box.transform = CGAffineTransformMakeScale(0.86f, 0.86f);
    [UIView animateWithDuration:0.18f animations:^{
        self.box.alpha = 1.0f;
        self.box.transform = CGAffineTransformIdentity;
    }];
}

-(void)likePressed {
    if(self.onLike) self.onLike();
    [self dismiss];
}

-(void)commentPressed {
    if(self.onComment) self.onComment();
    [self dismiss];
}

-(void)dismiss {
    [self removeFromSuperview];
}

-(UIImage*)momentImage:(NSString*)name {
    return WKMomentImageNamed(name);
}

@end

@interface WKMomentPublishSheet : UIControl
@property(nonatomic,strong) UIView *sheet;
@property(nonatomic,copy) void(^onCamera)(void);
@property(nonatomic,copy) void(^onAlbum)(void);
-(void)showInView:(UIView*)view;
-(UIImage*)momentImage:(NSString*)name;
@end

@implementation WKMomentPublishSheet

-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        self.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.0f];
        [self addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.sheet];
    }
    return self;
}

-(UIView *)sheet {
    if(!_sheet) {
        CGFloat bottom = UIApplication.sharedApplication.keyWindow.safeAreaInsets.bottom;
        _sheet = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, WKScreenWidth, 112.0f + bottom)];
        _sheet.backgroundColor = UIColor.whiteColor;
        [_sheet addSubview:[self rowWithTop:0.0f icon:@"Moments/Timeline/Camera" title:LLang(@"拍照/图片或视频") action:@selector(cameraPressed)]];
        [_sheet addSubview:[self rowWithTop:56.0f icon:@"Moments/Timeline/Album" title:LLang(@"从相册中获取") action:@selector(albumPressed)]];
    }
    return _sheet;
}

-(UIView*)rowWithTop:(CGFloat)top icon:(NSString*)icon title:(NSString*)title action:(SEL)action {
    UIControl *row = [[UIControl alloc] initWithFrame:CGRectMake(0.0f, top, WKScreenWidth, 56.0f)];
    [row addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(24.0f, 16.0f, 24.0f, 24.0f)];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.image = [self momentImage:icon];
    [row addSubview:imageView];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(64.0f, 0.0f, WKScreenWidth - 88.0f, 56.0f)];
    label.text = title;
    label.textColor = WKApp.shared.config.defaultTextColor;
    label.font = [WKApp.shared.config appFontOfSize:17.0f];
    [row addSubview:label];
    return row;
}

-(void)showInView:(UIView*)view {
    self.frame = view.bounds;
    [view addSubview:self];
    self.sheet.lim_top = view.lim_height;
    [UIView animateWithDuration:0.22f animations:^{
        self.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.28f];
        self.sheet.lim_top = view.lim_height - self.sheet.lim_height;
    }];
}

-(void)cameraPressed {
    if(self.onCamera) self.onCamera();
    [self dismiss];
}

-(void)albumPressed {
    if(self.onAlbum) self.onAlbum();
    [self dismiss];
}

-(void)dismiss {
    [UIView animateWithDuration:0.18f animations:^{
        self.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.0f];
        self.sheet.lim_top = self.lim_height;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

-(UIImage*)momentImage:(NSString*)name {
    return WKMomentImageNamed(name);
}

@end

@interface WKMomentTimelineHeader : UIView
@property(nonatomic,strong) UIImageView *coverView;
@property(nonatomic,strong) WKUserAvatar *avatarView;
@property(nonatomic,strong) UILabel *nameLbl;
@property(nonatomic,strong) UIControl *noticeBubble;
@property(nonatomic,strong) WKUserAvatar *noticeAvatarView;
@property(nonatomic,strong) UILabel *noticeBubbleLbl;
@property(nonatomic,copy) void(^onCoverTap)(void);
@property(nonatomic,copy) void(^onNoticeTap)(void);
-(void)refreshWithUID:(NSString*)uid name:(NSString*)name cover:(NSString*)cover;
-(void)refreshNoticeCount:(NSInteger)count;
@end

@implementation WKMomentTimelineHeader

-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        self.backgroundColor = WKApp.shared.config.cellBackgroundColor;
        [self addSubview:self.coverView];
        [self addSubview:self.avatarView];
        [self addSubview:self.nameLbl];
        [self addSubview:self.noticeBubble];
    }
    return self;
}

-(UIImageView *)coverView {
    if(!_coverView) {
        _coverView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, WKScreenWidth, 250.0f)];
        _coverView.contentMode = UIViewContentModeScaleAspectFill;
        _coverView.clipsToBounds = YES;
        _coverView.backgroundColor = [UIColor colorWithRed:190.0f/255.0f green:205.0f/255.0f blue:220.0f/255.0f alpha:1.0f];
        _coverView.userInteractionEnabled = YES;
        [_coverView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(coverTap)]];
    }
    return _coverView;
}

-(WKUserAvatar *)avatarView {
    if(!_avatarView) {
        _avatarView = [[WKUserAvatar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 72.0f, 72.0f)];
        _avatarView.layer.borderWidth = 0.0f;
    }
    return _avatarView;
}

-(UILabel *)nameLbl {
    if(!_nameLbl) {
        _nameLbl = [UILabel new];
        _nameLbl.textColor = UIColor.whiteColor;
        _nameLbl.font = [WKApp.shared.config appFontOfSizeMedium:18.0f];
        _nameLbl.textAlignment = NSTextAlignmentRight;
    }
    return _nameLbl;
}

-(UIControl *)noticeBubble {
    if(!_noticeBubble) {
        _noticeBubble = [[UIControl alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 112.0f, 30.0f)];
        _noticeBubble.backgroundColor = [UIColor colorWithWhite:0.18f alpha:0.84f];
        _noticeBubble.layer.cornerRadius = 4.0f;
        _noticeBubble.clipsToBounds = YES;
        [_noticeBubble addTarget:self action:@selector(noticeTap) forControlEvents:UIControlEventTouchUpInside];
        [_noticeBubble addSubview:self.noticeAvatarView];
        [_noticeBubble addSubview:self.noticeBubbleLbl];
        _noticeBubble.hidden = YES;
    }
    return _noticeBubble;
}

-(WKUserAvatar *)noticeAvatarView {
    if(!_noticeAvatarView) {
        _noticeAvatarView = [[WKUserAvatar alloc] initWithFrame:CGRectMake(8.0f, 5.0f, 20.0f, 20.0f)];
        _noticeAvatarView.url = [WKAvatarUtil getAvatar:WKApp.shared.loginInfo.uid];
    }
    return _noticeAvatarView;
}

-(UILabel *)noticeBubbleLbl {
    if(!_noticeBubbleLbl) {
        _noticeBubbleLbl = [[UILabel alloc] initWithFrame:CGRectMake(34.0f, 0.0f, 72.0f, 30.0f)];
        _noticeBubbleLbl.textColor = UIColor.whiteColor;
        _noticeBubbleLbl.font = [WKApp.shared.config appFontOfSize:12.0f];
    }
    return _noticeBubbleLbl;
}

-(void)layoutSubviews {
    [super layoutSubviews];
    self.coverView.frame = CGRectMake(0.0f, 0.0f, self.lim_width, 250.0f);
    self.avatarView.lim_left = self.lim_width - 88.0f;
    self.avatarView.lim_top = self.coverView.lim_bottom - 36.0f;
    self.nameLbl.lim_left = 16.0f;
    self.nameLbl.lim_top = self.avatarView.lim_top + 14.0f;
    self.nameLbl.lim_width = self.avatarView.lim_left - 28.0f;
    self.nameLbl.lim_height = 24.0f;
    self.noticeBubble.lim_left = (self.lim_width - self.noticeBubble.lim_width)/2.0f;
    self.noticeBubble.lim_top = self.coverView.lim_bottom + 8.0f;
}

-(void)refreshWithUID:(NSString*)uid name:(NSString*)name cover:(NSString*)cover {
    self.nameLbl.text = name.length > 0 ? name : uid;
    self.avatarView.url = [WKAvatarUtil getAvatar:uid];
    if(cover.length > 0) {
        [self.coverView lim_setImageWithURL:[WKApp.shared getFileFullUrl:cover]];
    }else {
        self.coverView.image = nil;
    }
}

-(void)coverTap {
    if(self.onCoverTap) {
        self.onCoverTap();
    }
}

-(void)noticeTap {
    if(self.onNoticeTap) {
        self.onNoticeTap();
    }
}

-(void)refreshNoticeCount:(NSInteger)count {
    self.noticeBubble.hidden = count <= 0;
    self.noticeBubbleLbl.text = [NSString stringWithFormat:@"%ld%@",(long)count,LLang(@"条新消息")];
}

@end

@interface WKMomentPostCell : UITableViewCell
@property(nonatomic,strong) WKUserAvatar *avatarView;
@property(nonatomic,strong) UILabel *nameLbl;
@property(nonatomic,strong) UILabel *textLbl;
@property(nonatomic,strong) UIView *mediaBox;
@property(nonatomic,strong) UILabel *timeLbl;
@property(nonatomic,strong) UIButton *actionBtn;
@property(nonatomic,strong) UIView *interactionBox;
@property(nonatomic,strong) UILabel *likesLbl;
@property(nonatomic,strong) UILabel *commentsLbl;
@property(nonatomic,strong) UIImageView *likeIconView;
@property(nonatomic,strong) UIImageView *commentIconView;
@property(nonatomic,strong) UIView *separatorLine;
@property(nonatomic,strong) WKMomentPost *post;
@property(nonatomic,copy) void(^onAction)(WKMomentPost *post, CGRect rect);
@property(nonatomic,copy) void(^onMediaTap)(WKMomentMedia *media, UIImageView *imageView);
-(void)refresh:(WKMomentPost*)post;
+(CGFloat)heightForPost:(WKMomentPost*)post;
@end

@implementation WKMomentPostCell

+(NSString*)cellId {
    return @"WKMomentPostCell";
}

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if(self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = WKApp.shared.config.cellBackgroundColor;
        [self.contentView addSubview:self.avatarView];
        [self.contentView addSubview:self.nameLbl];
        [self.contentView addSubview:self.textLbl];
        [self.contentView addSubview:self.mediaBox];
        [self.contentView addSubview:self.timeLbl];
        [self.contentView addSubview:self.actionBtn];
        [self.contentView addSubview:self.interactionBox];
        [self.interactionBox addSubview:self.likeIconView];
        [self.interactionBox addSubview:self.commentIconView];
        [self.interactionBox addSubview:self.likesLbl];
        [self.interactionBox addSubview:self.commentsLbl];
        [self.contentView addSubview:self.separatorLine];
    }
    return self;
}

-(WKUserAvatar *)avatarView {
    if(!_avatarView) {
        _avatarView = [[WKUserAvatar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, WKMomentAvatarSize, WKMomentAvatarSize)];
    }
    return _avatarView;
}

-(UILabel *)nameLbl {
    if(!_nameLbl) {
        _nameLbl = [UILabel new];
        _nameLbl.textColor = [UIColor colorWithRed:71.0f/255.0f green:88.0f/255.0f blue:135.0f/255.0f alpha:1.0f];
        _nameLbl.font = [WKApp.shared.config appFontOfSizeMedium:16.0f];
    }
    return _nameLbl;
}

-(UILabel *)textLbl {
    if(!_textLbl) {
        _textLbl = [UILabel new];
        _textLbl.textColor = WKApp.shared.config.defaultTextColor;
        _textLbl.font = [WKApp.shared.config appFontOfSize:16.0f];
        _textLbl.numberOfLines = 0;
    }
    return _textLbl;
}

-(UIView *)mediaBox {
    if(!_mediaBox) {
        _mediaBox = [UIView new];
    }
    return _mediaBox;
}

-(UILabel *)timeLbl {
    if(!_timeLbl) {
        _timeLbl = [UILabel new];
        _timeLbl.textColor = WKApp.shared.config.tipColor;
        _timeLbl.font = [WKApp.shared.config appFontOfSize:12.0f];
    }
    return _timeLbl;
}

-(UIButton *)actionBtn {
    if(!_actionBtn) {
        _actionBtn = [[UIButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 34.0f, 24.0f)];
        [_actionBtn setTitle:@"•••" forState:UIControlStateNormal];
        [_actionBtn setTitleColor:WKMomentBlueColor() forState:UIControlStateNormal];
        _actionBtn.titleLabel.font = [WKApp.shared.config appFontOfSizeMedium:15.0f];
        _actionBtn.backgroundColor = [UIColor colorWithRed:247.0f/255.0f green:248.0f/255.0f blue:252.0f/255.0f alpha:1.0f];
        _actionBtn.layer.cornerRadius = 4.0f;
        [_actionBtn addTarget:self action:@selector(actionPressed) forControlEvents:UIControlEventTouchUpInside];
    }
    return _actionBtn;
}

-(UIView *)interactionBox {
    if(!_interactionBox) {
        _interactionBox = [UIView new];
        _interactionBox.backgroundColor = WKMomentPanelColor();
        _interactionBox.layer.cornerRadius = 6.0f;
        _interactionBox.clipsToBounds = YES;
    }
    return _interactionBox;
}

-(UIImageView *)likeIconView {
    if(!_likeIconView) {
        _likeIconView = [[UIImageView alloc] initWithFrame:CGRectMake(8.0f, 8.0f, 16.0f, 16.0f)];
        _likeIconView.contentMode = UIViewContentModeScaleAspectFit;
        _likeIconView.tintColor = WKMomentBlueColor();
        _likeIconView.image = [self momentImage:@"Moments/Timeline/LikeActive"];
    }
    return _likeIconView;
}

-(UIImageView *)commentIconView {
    if(!_commentIconView) {
        _commentIconView = [[UIImageView alloc] initWithFrame:CGRectMake(8.0f, 8.0f, 16.0f, 16.0f)];
        _commentIconView.contentMode = UIViewContentModeScaleAspectFit;
        _commentIconView.tintColor = WKMomentBlueColor();
        _commentIconView.image = [self momentImage:@"Moments/Timeline/Comment"];
    }
    return _commentIconView;
}

-(UILabel *)likesLbl {
    if(!_likesLbl) {
        _likesLbl = [UILabel new];
        _likesLbl.textColor = WKMomentBlueColor();
        _likesLbl.font = [WKApp.shared.config appFontOfSize:14.0f];
        _likesLbl.numberOfLines = 0;
    }
    return _likesLbl;
}

-(UILabel *)commentsLbl {
    if(!_commentsLbl) {
        _commentsLbl = [UILabel new];
        _commentsLbl.textColor = WKApp.shared.config.defaultTextColor;
        _commentsLbl.font = [WKApp.shared.config appFontOfSize:14.0f];
        _commentsLbl.numberOfLines = 0;
    }
    return _commentsLbl;
}

-(UIView *)separatorLine {
    if(!_separatorLine) {
        _separatorLine = [UIView new];
        _separatorLine.backgroundColor = [UIColor colorWithRed:238.0f/255.0f green:238.0f/255.0f blue:238.0f/255.0f alpha:1.0f];
    }
    return _separatorLine;
}

-(void)refresh:(WKMomentPost *)post {
    self.post = post;
    self.avatarView.url = post.user.avatar.length > 0 ? [WKAvatarUtil getFullAvatarWIthPath:post.user.avatar] : [WKAvatarUtil getAvatar:post.user.uid];
    self.nameLbl.text = post.user.name.length > 0 ? post.user.name : post.user.uid;
    self.textLbl.text = post.text;
    self.timeLbl.text = [self showTime:post.createdAt];
    self.likesLbl.text = [self likesText:post.likes];
    self.commentsLbl.text = [self commentsText:post.comments];
    [self reloadMedia];
    [self setNeedsLayout];
}

-(NSString*)likesText:(NSArray<WKMomentActor*>*)likes {
    if(likes.count == 0) {
        return @"";
    }
    NSMutableArray *names = [NSMutableArray array];
    for(WKMomentActor *actor in likes) {
        [names addObject:actor.name.length > 0 ? actor.name : actor.uid];
    }
    return [names componentsJoinedByString:@"，"];
}

-(NSString*)commentsText:(NSArray<WKMomentComment*>*)comments {
    if(comments.count == 0) {
        return @"";
    }
    NSMutableArray *lines = [NSMutableArray array];
    for(WKMomentComment *comment in comments) {
        NSString *name = comment.user.name.length > 0 ? comment.user.name : comment.user.uid;
        if(comment.replyName.length > 0) {
            [lines addObject:[NSString stringWithFormat:@"%@ %@ %@：%@",name,LLang(@"回复"),comment.replyName,comment.content ?: @""]];
        }else {
            [lines addObject:[NSString stringWithFormat:@"%@：%@",name,comment.content ?: @""]];
        }
    }
    return [lines componentsJoinedByString:@"\n"];
}

-(NSString*)showTime:(NSString*)time {
    if(time.length == 0) {
        return @"";
    }
    NSDate *date = [self dateFromString:time];
    if(!date) {
        return time.length > 16 ? [time substringToIndex:16] : time;
    }
    NSTimeInterval delta = MAX(0.0f, -date.timeIntervalSinceNow);
    if(delta < 60.0f) {
        return [NSString stringWithFormat:@"%ld%@",MAX(1L,(long)delta),LLang(@"秒前")];
    }
    if(delta < 3600.0f) {
        return [NSString stringWithFormat:@"%ld%@",(long)(delta / 60.0f),LLang(@"分钟前")];
    }
    if(delta < 86400.0f) {
        return [NSString stringWithFormat:@"%ld%@",(long)(delta / 3600.0f),LLang(@"小时前")];
    }
    if(delta < 2592000.0f) {
        return [NSString stringWithFormat:@"%ld%@",(long)(delta / 86400.0f),LLang(@"天前")];
    }
    if(delta < 31536000.0f) {
        return [NSString stringWithFormat:@"%ld%@",(long)(delta / 2592000.0f),LLang(@"月前")];
    }
    return [NSString stringWithFormat:@"%ld%@",(long)(delta / 31536000.0f),LLang(@"年前")];
}

-(NSDate*)dateFromString:(NSString*)time {
    static NSArray<NSString*> *formats;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formats = @[@"yyyy-MM-dd HH:mm:ss",@"yyyy-MM-dd'T'HH:mm:ss.SSSZ",@"yyyy-MM-dd'T'HH:mm:ssZ",@"yyyy-MM-dd HH:mm",@"yyyy-MM-dd"];
    });
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    for(NSString *format in formats) {
        formatter.dateFormat = format;
        NSDate *date = [formatter dateFromString:time];
        if(date) return date;
    }
    return nil;
}

-(void)reloadMedia {
    for(UIView *view in self.mediaBox.subviews) {
        [view removeFromSuperview];
    }
    CGFloat itemW = 82.0f;
    NSInteger index = 0;
    for(WKMomentMedia *media in self.post.medias) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake((index % 3) * (itemW + 5.0f), (index / 3) * (itemW + 5.0f), itemW, itemW)];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        imageView.userInteractionEnabled = YES;
        imageView.tag = index;
        [imageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(mediaTap:)]];
        BOOL video = WKMomentMediaIsVideo(media);
        NSString *url = video && media.coverURL.length > 0 ? media.coverURL : media.mediaURL;
        [imageView lim_setImageWithURL:[WKApp.shared getFileFullUrl:url]];
        [self.mediaBox addSubview:imageView];
        if(video) {
            UIView *shade = [[UIView alloc] initWithFrame:imageView.bounds];
            shade.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.18f];
            shade.userInteractionEnabled = NO;
            [imageView addSubview:shade];
            UILabel *play = [[UILabel alloc] initWithFrame:imageView.bounds];
            play.text = @"▶";
            play.textColor = UIColor.whiteColor;
            play.textAlignment = NSTextAlignmentCenter;
            play.font = [WKApp.shared.config appFontOfSize:28.0f];
            play.userInteractionEnabled = NO;
            [imageView addSubview:play];
        }
        index++;
    }
}

-(void)mediaTap:(UITapGestureRecognizer*)tap {
    NSInteger index = tap.view.tag;
    if(index < 0 || index >= self.post.medias.count) {
        return;
    }
    if(self.onMediaTap) {
        self.onMediaTap(self.post.medias[index], (UIImageView*)tap.view);
    }
}

-(void)layoutSubviews {
    [super layoutSubviews];
    CGFloat contentLeft = WKMomentLeft + WKMomentAvatarSize + 10.0f;
    CGFloat contentWidth = self.contentView.lim_width - contentLeft - 12.0f;
    self.avatarView.lim_left = WKMomentLeft;
    self.avatarView.lim_top = 14.0f;
    self.nameLbl.frame = CGRectMake(contentLeft, 14.0f, contentWidth, 22.0f);
    CGSize textSize = [self.textLbl sizeThatFits:CGSizeMake(contentWidth, CGFLOAT_MAX)];
    self.textLbl.frame = CGRectMake(contentLeft, self.nameLbl.lim_bottom + 6.0f, contentWidth, textSize.height);
    CGFloat top = self.textLbl.text.length > 0 ? self.textLbl.lim_bottom + 8.0f : self.nameLbl.lim_bottom + 6.0f;
    CGFloat mediaHeight = [WKMomentPostCell mediaHeight:self.post];
    self.mediaBox.frame = CGRectMake(contentLeft, top, contentWidth, mediaHeight);
    top = mediaHeight > 0 ? self.mediaBox.lim_bottom + 8.0f : top;
    self.timeLbl.frame = CGRectMake(contentLeft, top, contentWidth - 42.0f, 20.0f);
    self.actionBtn.lim_left = self.contentView.lim_width - 54.0f;
    self.actionBtn.lim_top = self.timeLbl.lim_top - 2.0f;
    top = self.timeLbl.lim_bottom + 6.0f;
    CGSize likeSize = [self.likesLbl sizeThatFits:CGSizeMake(contentWidth, CGFLOAT_MAX)];
    CGFloat likeHeight = self.likesLbl.text.length > 0 ? MAX(22.0f, ceil(likeSize.height) + 12.0f) : 0.0f;
    CGSize commentSize = [self.commentsLbl sizeThatFits:CGSizeMake(contentWidth, CGFLOAT_MAX)];
    CGFloat commentHeight = self.commentsLbl.text.length > 0 ? ceil(commentSize.height) + 12.0f : 0.0f;
    CGFloat boxHeight = likeHeight + commentHeight;
    self.interactionBox.hidden = boxHeight <= 0.0f;
    self.interactionBox.frame = CGRectMake(contentLeft, top, contentWidth, boxHeight);
    self.likeIconView.hidden = likeHeight <= 0.0f;
    self.likeIconView.frame = CGRectMake(8.0f, 8.0f, 16.0f, 16.0f);
    self.commentIconView.hidden = commentHeight <= 0.0f;
    self.commentIconView.frame = CGRectMake(8.0f, likeHeight + 8.0f, 16.0f, 16.0f);
    self.likesLbl.frame = CGRectMake(30.0f, 6.0f, contentWidth - 38.0f, MAX(0.0f, likeHeight - 8.0f));
    self.commentsLbl.frame = CGRectMake(30.0f, likeHeight + 6.0f, contentWidth - 38.0f, MAX(0.0f, commentHeight - 8.0f));
    self.separatorLine.frame = CGRectMake(contentLeft, self.contentView.lim_height - 0.5f, contentWidth, 0.5f);
}

-(void)actionPressed {
    if(self.onAction) {
        self.onAction(self.post, [self.actionBtn convertRect:self.actionBtn.bounds toView:nil]);
    }
}

+(CGFloat)mediaHeight:(WKMomentPost*)post {
    if(post.medias.count == 0) {
        return 0.0f;
    }
    NSInteger rows = (post.medias.count + 2) / 3;
    return rows * 82.0f + MAX(0, rows - 1) * 5.0f;
}

+(CGFloat)heightForPost:(WKMomentPost *)post {
    CGFloat contentWidth = WKScreenWidth - (WKMomentLeft + WKMomentAvatarSize + 10.0f) - 12.0f;
    CGFloat height = 14.0f + 22.0f + 6.0f;
    if(post.text.length > 0) {
        CGRect textRect = [post.text boundingRectWithSize:CGSizeMake(contentWidth, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[WKApp.shared.config appFontOfSize:16.0f]} context:nil];
        height += ceil(textRect.size.height) + 8.0f;
    }
    height += [self mediaHeight:post] + (post.medias.count > 0 ? 8.0f : 0.0f);
    height += 20.0f + 6.0f;
    NSString *likes = [[WKMomentPostCell new] likesText:post.likes];
    if(likes.length > 0) {
        CGRect rect = [likes boundingRectWithSize:CGSizeMake(contentWidth - 38.0f, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[WKApp.shared.config appFontOfSize:14.0f]} context:nil];
        height += MAX(22.0f, ceil(rect.size.height) + 12.0f);
    }
    NSString *comments = [[WKMomentPostCell new] commentsText:post.comments];
    if(comments.length > 0) {
        CGRect rect = [comments boundingRectWithSize:CGSizeMake(contentWidth - 38.0f, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[WKApp.shared.config appFontOfSize:14.0f]} context:nil];
        height += ceil(rect.size.height) + 12.0f;
    }
    return MAX(82.0f, height + 12.0f);
}

-(UIImage*)momentImage:(NSString*)name {
    return WKMomentImageNamed(name);
}

@end

@interface WKMomentTimelineVC ()<UITableViewDataSource,UITableViewDelegate>
@property(nonatomic,strong) UITableView *tableView;
@property(nonatomic,strong) UIButton *composeBtn;
@property(nonatomic,strong) UIButton *noticeBtn;
@property(nonatomic,strong) WKMomentTimelineHeader *headerView;
@property(nonatomic,strong) WKMomentActionMenu *actionMenu;
@property(nonatomic,strong) WKMomentPublishSheet *publishSheet;
@property(nonatomic,strong) WKMediaFetcher *mediaFetcher;
@property(nonatomic,strong) WKMomentVM *vm;
@property(nonatomic,strong) NSMutableArray<WKMomentPost*> *posts;
@property(nonatomic,copy) NSString *uid;
@property(nonatomic,assign) NSInteger pageIndex;
@property(nonatomic,assign) BOOL loading;
@property(nonatomic,assign) BOOL hasMore;
@property(nonatomic,copy) NSString *cover;
@end

@implementation WKMomentTimelineVC

-(instancetype)init {
    return [self initWithUID:nil];
}

-(instancetype)initWithUID:(NSString *)uid {
    self = [super init];
    if(self) {
        _uid = uid;
        _vm = [WKMomentVM new];
        _posts = [NSMutableArray array];
        _pageIndex = 1;
        _hasMore = YES;
    }
    return self;
}

-(void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.tableView];
    if([self isMine]) {
        [self.navigationBar setRightView:self.composeBtn];
        [self.navigationBar addSubview:self.noticeBtn];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(momentNoticeUpdate) name:WK_NOTIFY_MOMENT_NOTICE_UPDATE object:nil];
        [[WKMomentNoticeManager shared] sync];
    }
    [self requestProfile];
    [self refresh];
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:WK_NOTIFY_MOMENT_NOTICE_UPDATE object:nil];
}

-(NSString *)langTitle {
    return LLang(@"朋友圈");
}

-(BOOL)isMine {
    return self.uid.length == 0 || [self.uid isEqualToString:WKApp.shared.loginInfo.uid];
}

-(NSString*)targetUID {
    return self.uid.length > 0 ? self.uid : WKApp.shared.loginInfo.uid;
}

-(NSString*)targetName {
    if([self isMine]) {
        NSString *name = WKApp.shared.loginInfo.extra[@"name"];
        return name.length > 0 ? name : WKApp.shared.loginInfo.uid;
    }
    return self.targetUID;
}

-(UITableView *)tableView {
    if(!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:[self visibleRect] style:UITableViewStylePlain];
        _tableView.backgroundColor = WKApp.shared.config.cellBackgroundColor;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.tableHeaderView = self.headerView;
        _tableView.tableFooterView = [UIView new];
        [_tableView registerClass:WKMomentPostCell.class forCellReuseIdentifier:[WKMomentPostCell cellId]];
        if(@available(iOS 10.0, *)) {
            _tableView.refreshControl = [[UIRefreshControl alloc] init];
            [_tableView.refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
        }
    }
    return _tableView;
}

-(WKMomentTimelineHeader *)headerView {
    if(!_headerView) {
        _headerView = [[WKMomentTimelineHeader alloc] initWithFrame:CGRectMake(0.0f, 0.0f, WKScreenWidth, 302.0f)];
        __weak typeof(self) weakSelf = self;
        _headerView.onCoverTap = ^{
            [weakSelf changeCover];
        };
        _headerView.onNoticeTap = ^{
            [weakSelf noticePressed];
        };
    }
    return _headerView;
}

-(UIButton *)composeBtn {
    if(!_composeBtn) {
        _composeBtn = [[UIButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 34.0f, 34.0f)];
        [_composeBtn setImage:[self momentImage:@"Moments/Timeline/Compose"] forState:UIControlStateNormal];
        [_composeBtn addTarget:self action:@selector(composePressed) forControlEvents:UIControlEventTouchUpInside];
        [_composeBtn addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(composeLongPressed:)]];
    }
    return _composeBtn;
}

-(UIButton *)noticeBtn {
    if(!_noticeBtn) {
        _noticeBtn = [[UIButton alloc] init];
        _noticeBtn.titleLabel.font = [WKApp.shared.config appFontOfSize:15.0f];
        [_noticeBtn setTitleColor:WKApp.shared.config.navBarButtonColor forState:UIControlStateNormal];
        [_noticeBtn addTarget:self action:@selector(noticePressed) forControlEvents:UIControlEventTouchUpInside];
        [self momentNoticeUpdate];
    }
    return _noticeBtn;
}

-(void)momentNoticeUpdate {
    NSInteger count = [WKMomentNoticeManager shared].unreadCount;
    NSString *title = count > 0 ? [NSString stringWithFormat:@"%@(%ld)",LLang(@"消息"),(long)count] : LLang(@"消息");
    [self.noticeBtn setTitle:title forState:UIControlStateNormal];
    [self.noticeBtn sizeToFit];
    self.noticeBtn.lim_left = self.navigationBar.backButton.lim_right + 4.0f;
    self.noticeBtn.lim_top = self.navigationBar.backButton.lim_top;
    self.noticeBtn.lim_height = self.navigationBar.backButton.lim_height;
    [self.headerView refreshNoticeCount:count];
}

-(void)requestProfile {
    __weak typeof(self) weakSelf = self;
    [self.vm profile:self.targetUID].then(^(WKMomentProfile *profile) {
        weakSelf.cover = profile.cover;
        [weakSelf.headerView refreshWithUID:weakSelf.targetUID name:weakSelf.targetName cover:weakSelf.cover];
    }).catch(^(NSError *error) {
        [weakSelf.headerView refreshWithUID:weakSelf.targetUID name:weakSelf.targetName cover:nil];
    });
}

-(void)refresh {
    self.pageIndex = 1;
    self.hasMore = YES;
    [self requestList:YES];
}

-(void)requestList:(BOOL)reset {
    if(self.loading) {
        return;
    }
    self.loading = YES;
    AnyPromise *promise = [self isMine] ? [self.vm timelineWithPageIndex:self.pageIndex pageSize:20] : [self.vm userTimeline:self.targetUID pageIndex:self.pageIndex pageSize:20];
    __weak typeof(self) weakSelf = self;
    promise.then(^(NSArray<WKMomentPost*> *items) {
        weakSelf.loading = NO;
        if(@available(iOS 10.0, *)) {
            [weakSelf.tableView.refreshControl endRefreshing];
        }
        if(reset) {
            [weakSelf.posts removeAllObjects];
        }
        [weakSelf.posts addObjectsFromArray:items ?: @[]];
        weakSelf.hasMore = items.count >= 20;
        weakSelf.pageIndex += 1;
        [weakSelf.tableView reloadData];
    }).catch(^(NSError *error) {
        weakSelf.loading = NO;
        if(@available(iOS 10.0, *)) {
            [weakSelf.tableView.refreshControl endRefreshing];
        }
        [weakSelf.view showHUDWithHide:error.domain];
    });
}

-(void)composePressed {
    __weak typeof(self) weakSelf = self;
    self.publishSheet.onCamera = ^{
        [weakSelf openCameraForMoment];
    };
    self.publishSheet.onAlbum = ^{
        [weakSelf openAlbumForMoment];
    };
    [self.publishSheet showInView:self.view];
}

-(void)composeLongPressed:(UILongPressGestureRecognizer*)gesture {
    if(gesture.state == UIGestureRecognizerStateBegan) {
        [self pushComposeTextOnly:YES images:nil video:nil cover:nil];
    }
}

-(void)pushComposeTextOnly:(BOOL)textOnly images:(NSArray<NSData*>*)images video:(NSString*)videoPath cover:(UIImage*)cover {
    WKMomentComposeVC *vc = [WKMomentComposeVC new];
    vc.textOnly = textOnly;
    if(images.count > 0) {
        [vc setInitialImageDatas:images];
    }
    if(videoPath.length > 0) {
        [vc setInitialVideoPath:videoPath cover:cover];
    }
    __weak typeof(self) weakSelf = self;
    vc.onPublished = ^{
        [weakSelf refresh];
    };
    [[WKNavigationManager shared] pushViewController:vc animated:YES];
}

-(void)openCameraForMoment {
    __weak typeof(self) weakSelf = self;
    [WKVideoRecordUtil videoRecord:^(NSString *coverPath, NSString *videoPath) {
        UIImage *cover = coverPath.length > 0 ? [UIImage imageWithContentsOfFile:coverPath] : nil;
        [weakSelf pushComposeTextOnly:NO images:nil video:videoPath cover:cover];
    } imgCallback:^(UIImage *img) {
        NSData *data = UIImageJPEGRepresentation(img, 0.85f);
        [weakSelf pushComposeTextOnly:NO images:data ? @[data] : @[] video:nil cover:nil];
    }];
}

-(void)openAlbumForMoment {
    self.mediaFetcher = [WKMediaFetcher new];
    self.mediaFetcher.limit = 9;
    self.mediaFetcher.allowTakePicture = NO;
    self.mediaFetcher.mediaTypes = @[(NSString*)kUTTypeImage,(NSString*)kUTTypeMovie];
    __block NSMutableArray<NSData*> *imageDatas = [NSMutableArray array];
    __weak typeof(self) weakSelf = self;
    [self.mediaFetcher fetchPhotoFromLibrary:^(UIImage *img, NSString *path, bool isSelectOriginalPhoto, PHAssetMediaType type, NSInteger left) {
        if(type == PHAssetMediaTypeVideo) {
            [weakSelf videoFirstFrameAsync:path completion:^(UIImage *cover) {
                [weakSelf pushComposeTextOnly:NO images:nil video:path cover:cover];
                weakSelf.mediaFetcher = nil;
            }];
            return;
        }
        NSData *data = nil;
        if(img) {
            data = UIImageJPEGRepresentation(img, 0.85f);
        }else if(path.length > 0) {
            data = [NSData dataWithContentsOfFile:path];
        }
        if(data && imageDatas.count < 9) {
            [imageDatas addObject:data];
        }
        if(left <= 0) {
            [weakSelf pushComposeTextOnly:NO images:imageDatas video:nil cover:nil];
            weakSelf.mediaFetcher = nil;
        }
    } cancel:^{
        weakSelf.mediaFetcher = nil;
    }];
}

-(UIImage*)videoFirstFrame:(NSString*)path {
    if([path hasPrefix:@"file://"]) {
        path = [NSURL URLWithString:path].path ?: path;
    }
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:path] options:nil];
    AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    generator.appliesPreferredTrackTransform = YES;
    CGImageRef imageRef = [generator copyCGImageAtTime:CMTimeMake(0, 1) actualTime:nil error:nil];
    UIImage *image = imageRef ? [UIImage imageWithCGImage:imageRef] : nil;
    if(imageRef) CGImageRelease(imageRef);
    return image;
}

-(void)videoFirstFrameAsync:(NSString*)path completion:(void(^)(UIImage *cover))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *cover = path.length > 0 ? [self videoFirstFrame:path] : nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            if(completion) completion(cover);
        });
    });
}

-(WKMomentPublishSheet *)publishSheet {
    if(!_publishSheet) {
        _publishSheet = [WKMomentPublishSheet new];
    }
    return _publishSheet;
}

-(WKMomentActionMenu *)actionMenu {
    if(!_actionMenu) {
        _actionMenu = [WKMomentActionMenu new];
    }
    return _actionMenu;
}

-(void)noticePressed {
    [[WKNavigationManager shared] pushViewController:[WKMomentNoticeVC new] animated:YES];
}

-(void)changeCover {
    if(![self isMine]) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    [[WKPhotoBrowser shared] showPhotoLibraryWithSender:self selectCompressImageBlock:^(NSArray<NSData *> * _Nonnull images, NSArray<PHAsset *> * _Nonnull assets, BOOL isOriginal) {
        NSData *data = images.firstObject;
        if(!data) {
            return;
        }
        [weakSelf.view showHUD];
        [weakSelf.vm uploadImageData:data type:@"momentcover" completion:^(NSString * _Nullable path, NSError * _Nullable error) {
            if(error || path.length == 0) {
                [weakSelf.view hideHud];
                [weakSelf.view showHUDWithHide:error.domain ?: LLang(@"封面上传失败")];
                return;
            }
            [weakSelf.vm setCover:path].then(^{
                [weakSelf.view hideHud];
                weakSelf.cover = path;
                [weakSelf.headerView refreshWithUID:weakSelf.targetUID name:weakSelf.targetName cover:path];
            }).catch(^(NSError *error) {
                [weakSelf.view hideHud];
                [weakSelf.view showHUDWithHide:error.domain];
            });
        }];
    } maxSelectCount:1 allowSelectVideo:NO];
}

-(void)showActions:(WKMomentPost*)post rect:(CGRect)rect {
    __weak typeof(self) weakSelf = self;
    self.actionMenu.onLike = ^{
        [weakSelf toggleLike:post];
    };
    self.actionMenu.onComment = ^{
        [weakSelf inputComment:post reply:nil];
    };
    CGRect viewRect = [self.view convertRect:rect fromView:nil];
    [self.actionMenu showFromRect:viewRect liked:post.likedByMe inView:self.view];
}

-(void)toggleLike:(WKMomentPost*)post {
    [self.vm toggleLike:post.postId].then(^(NSDictionary *result) {
        post.likedByMe = [result[@"liked"] integerValue] == 1;
        [self refresh];
    }).catch(^(NSError *error) {
        [self.view showHUDWithHide:error.domain];
    });
}

-(void)inputComment:(WKMomentPost*)post reply:(WKMomentComment*)reply {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:LLang(@"评论") message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = LLang(@"请输入评论");
    }];
    [alert addAction:[UIAlertAction actionWithTitle:LLang(@"取消") style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:LLang(@"发送") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *content = [alert.textFields.firstObject.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        if(content.length == 0) {
            return;
        }
        [self.vm addComment:post.postId content:content replyCommentId:reply.commentId].then(^{
            [self refresh];
        }).catch(^(NSError *error) {
            [self.view showHUDWithHide:error.domain];
        });
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

-(void)deletePost:(WKMomentPost*)post {
    [self.vm deletePost:post.postId].then(^{
        [self.posts removeObject:post];
        [self.tableView reloadData];
    }).catch(^(NSError *error) {
        [self.view showHUDWithHide:error.domain];
    });
}

#pragma mark - UITableView

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.posts.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WKMomentPostCell *cell = [tableView dequeueReusableCellWithIdentifier:[WKMomentPostCell cellId] forIndexPath:indexPath];
    WKMomentPost *post = self.posts[indexPath.row];
    [cell refresh:post];
    __weak typeof(self) weakSelf = self;
    cell.onAction = ^(WKMomentPost *post, CGRect rect) {
        [weakSelf showActions:post rect:rect];
    };
    cell.onMediaTap = ^(WKMomentMedia *media, UIImageView *imageView) {
        [weakSelf openMedia:media fromView:imageView];
    };
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [WKMomentPostCell heightForPost:self.posts[indexPath.row]];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
}

-(void)openMedia:(WKMomentMedia*)media fromView:(UIImageView*)imageView {
    if(!WKMomentMediaIsVideo(media)) {
        return;
    }
    NSURL *url = [WKApp.shared getFileFullUrl:media.mediaURL];
    if(!url) {
        return;
    }
    AVPlayerViewController *vc = [AVPlayerViewController new];
    vc.player = [AVPlayer playerWithURL:url];
    [self presentViewController:vc animated:YES completion:^{
        [vc.player play];
    }];
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if(!self.hasMore || self.loading || self.posts.count == 0) {
        return;
    }
    CGFloat offset = scrollView.contentOffset.y + scrollView.lim_height - scrollView.contentSize.height;
    if(offset > 80.0f) {
        [self requestList:NO];
    }
}

-(UIImage*)momentImage:(NSString*)name {
    return WKMomentImageNamed(name);
}

@end

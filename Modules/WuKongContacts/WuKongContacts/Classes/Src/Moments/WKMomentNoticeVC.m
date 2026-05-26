//
//  WKMomentNoticeVC.m
//  WuKongContacts
//

#import "WKMomentNoticeVC.h"
#import "WKMomentVM.h"
#import "WKMomentNoticeManager.h"
#import "UIView+WK.h"
#import "UIView+WKCommon.h"

@interface WKMomentNoticeCell : UITableViewCell
@property(nonatomic,strong) WKUserAvatar *avatarView;
@property(nonatomic,strong) UILabel *nameLbl;
@property(nonatomic,strong) UILabel *actionLbl;
@property(nonatomic,strong) UILabel *contentLbl;
@property(nonatomic,strong) UILabel *timeLbl;
@property(nonatomic,strong) UILabel *previewLbl;
@property(nonatomic,strong) UIImageView *previewImgView;
@property(nonatomic,strong) UIView *lineView;
-(void)refresh:(WKMomentNotice*)notice;
@end

@implementation WKMomentNoticeCell
+(NSString*)cellId { return @"WKMomentNoticeCell"; }
-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if(self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = WKApp.shared.config.cellBackgroundColor;
        [self.contentView addSubview:self.avatarView];
        [self.contentView addSubview:self.nameLbl];
        [self.contentView addSubview:self.actionLbl];
        [self.contentView addSubview:self.contentLbl];
        [self.contentView addSubview:self.timeLbl];
        [self.contentView addSubview:self.previewLbl];
        [self.contentView addSubview:self.previewImgView];
        [self.contentView addSubview:self.lineView];
    }
    return self;
}
-(WKUserAvatar*)avatarView {
    if(!_avatarView) _avatarView = [[WKUserAvatar alloc] initWithFrame:CGRectMake(8.0f, 14.0f, 34.0f, 34.0f)];
    return _avatarView;
}
-(UILabel*)nameLbl {
    if(!_nameLbl) {
        _nameLbl = [UILabel new];
        _nameLbl.font = [WKApp.shared.config appFontOfSizeMedium:14.0f];
        _nameLbl.textColor = [UIColor colorWithRed:91.0f/255.0f green:111.0f/255.0f blue:152.0f/255.0f alpha:1.0f];
    }
    return _nameLbl;
}
-(UILabel*)actionLbl {
    if(!_actionLbl) {
        _actionLbl = [UILabel new];
        _actionLbl.font = [WKApp.shared.config appFontOfSize:14.0f];
        _actionLbl.textColor = WKApp.shared.config.defaultTextColor;
    }
    return _actionLbl;
}
-(UILabel*)contentLbl {
    if(!_contentLbl) {
        _contentLbl = [UILabel new];
        _contentLbl.font = [WKApp.shared.config appFontOfSize:13.0f];
        _contentLbl.textColor = WKApp.shared.config.defaultTextColor;
        _contentLbl.numberOfLines = 1;
    }
    return _contentLbl;
}
-(UILabel*)timeLbl {
    if(!_timeLbl) {
        _timeLbl = [UILabel new];
        _timeLbl.font = [WKApp.shared.config appFontOfSize:12.0f];
        _timeLbl.textColor = WKApp.shared.config.tipColor;
    }
    return _timeLbl;
}
-(UILabel*)previewLbl {
    if(!_previewLbl) {
        _previewLbl = [UILabel new];
        _previewLbl.backgroundColor = [UIColor colorWithRed:247.0f/255.0f green:247.0f/255.0f blue:247.0f/255.0f alpha:1.0f];
        _previewLbl.textColor = WKApp.shared.config.tipColor;
        _previewLbl.font = [WKApp.shared.config appFontOfSize:12.0f];
        _previewLbl.textAlignment = NSTextAlignmentCenter;
        _previewLbl.numberOfLines = 2;
    }
    return _previewLbl;
}
-(UIImageView*)previewImgView {
    if(!_previewImgView) {
        _previewImgView = [UIImageView new];
        _previewImgView.backgroundColor = [UIColor colorWithRed:247.0f/255.0f green:247.0f/255.0f blue:247.0f/255.0f alpha:1.0f];
        _previewImgView.contentMode = UIViewContentModeScaleAspectFill;
        _previewImgView.clipsToBounds = YES;
    }
    return _previewImgView;
}
-(UIView*)lineView {
    if(!_lineView) {
        _lineView = [UIView new];
        _lineView.backgroundColor = [UIColor colorWithRed:245.0f/255.0f green:245.0f/255.0f blue:245.0f/255.0f alpha:1.0f];
    }
    return _lineView;
}
-(void)refresh:(WKMomentNotice *)notice {
    NSString *name = notice.fromUser.name.length > 0 ? notice.fromUser.name : notice.fromUser.uid;
    NSString *action = LLang(@"提醒了你");
    if([notice.noticeType containsString:@"like"]) action = LLang(@"来看看");
    if([notice.noticeType containsString:@"comment"]) action = LLang(@"评论了你");
    if([notice.noticeType containsString:@"reply"]) action = LLang(@"提到了你");
    self.nameLbl.text = name ?: @"";
    self.actionLbl.text = action;
    self.contentLbl.text = notice.content.length > 0 ? notice.content : @"";
    self.contentLbl.hidden = self.contentLbl.text.length == 0;
    self.timeLbl.text = [self showTime:notice.createdAt];
    self.avatarView.url = notice.fromUser.avatar.length > 0 ? [WKAvatarUtil getFullAvatarWIthPath:notice.fromUser.avatar] : [WKAvatarUtil getAvatar:notice.fromUser.uid];
    self.previewLbl.hidden = notice.postCover.length > 0;
    self.previewImgView.hidden = notice.postCover.length == 0;
    self.previewLbl.text = notice.postText.length > 0 ? notice.postText : (notice.postId.length > 0 ? LLang(@"动态") : @"");
    if(notice.postCover.length > 0) {
        [self.previewImgView lim_setImageWithURL:[WKApp.shared getFileFullUrl:notice.postCover]];
    }else {
        self.previewImgView.image = nil;
    }
}
-(void)layoutSubviews {
    [super layoutSubviews];
    self.avatarView.lim_left = 8.0f;
    self.avatarView.lim_top = 14.0f;
    CGFloat previewW = 58.0f;
    self.previewLbl.frame = CGRectMake(self.contentView.lim_width - previewW - 24.0f, 12.0f, previewW, 58.0f);
    self.previewImgView.frame = self.previewLbl.frame;
    CGFloat left = self.avatarView.lim_right + 8.0f;
    CGFloat width = self.previewLbl.lim_left - left - 12.0f;
    self.nameLbl.frame = CGRectMake(left, 10.0f, width, 18.0f);
    self.actionLbl.frame = CGRectMake(left, self.nameLbl.lim_bottom + 1.0f, width, 18.0f);
    CGFloat timeTop = self.actionLbl.lim_bottom + 1.0f;
    if(!self.contentLbl.hidden) {
        self.contentLbl.frame = CGRectMake(left, self.actionLbl.lim_bottom + 1.0f, width, 18.0f);
        timeTop = self.contentLbl.lim_bottom + 1.0f;
    }
    self.timeLbl.frame = CGRectMake(left, timeTop, width, 16.0f);
    self.lineView.frame = CGRectMake(left, self.contentView.lim_height - 0.5f, self.contentView.lim_width - left - 16.0f, 0.5f);
}

-(NSString*)showTime:(NSString*)time {
    if(time.length == 0) {
        return @"";
    }
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    for(NSString *format in @[@"yyyy-MM-dd HH:mm:ss",@"yyyy-MM-dd'T'HH:mm:ss.SSSZ",@"yyyy-MM-dd'T'HH:mm:ssZ"]) {
        formatter.dateFormat = format;
        NSDate *date = [formatter dateFromString:time];
        if(date) {
            NSTimeInterval delta = MAX(0.0f, -date.timeIntervalSinceNow);
            if(delta < 60.0f) return LLang(@"刚刚");
            if(delta < 3600.0f) return [NSString stringWithFormat:@"%ld%@",(long)(delta/60.0f),LLang(@"分钟前")];
            if(delta < 86400.0f) return [NSString stringWithFormat:@"%ld%@",(long)(delta/3600.0f),LLang(@"小时前")];
            if(delta < 2592000.0f) return [NSString stringWithFormat:@"%ld%@",(long)(delta/86400.0f),LLang(@"天前")];
            if(delta < 31536000.0f) return [NSString stringWithFormat:@"%ld%@",(long)(delta/2592000.0f),LLang(@"月前")];
            return [NSString stringWithFormat:@"%ld%@",(long)(delta/31536000.0f),LLang(@"年前")];
        }
    }
    return time.length > 16 ? [time substringToIndex:16] : time;
}
@end

@interface WKMomentNoticeVC ()<UITableViewDataSource,UITableViewDelegate>
@property(nonatomic,strong) UITableView *tableView;
@property(nonatomic,strong) WKMomentVM *vm;
@property(nonatomic,strong) NSMutableArray<WKMomentNotice*> *notices;
@end

@implementation WKMomentNoticeVC
-(instancetype)init {
    self = [super init];
    if(self) {
        _vm = [WKMomentVM new];
        _notices = [NSMutableArray array];
    }
    return self;
}
-(void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.tableView];
    [self requestData];
}
-(NSString*)langTitle { return LLang(@"消息"); }
-(UITableView*)tableView {
    if(!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:[self visibleRect] style:UITableViewStylePlain];
        _tableView.backgroundColor = WKApp.shared.config.backgroundColor;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.tableFooterView = [UIView new];
        [_tableView registerClass:WKMomentNoticeCell.class forCellReuseIdentifier:[WKMomentNoticeCell cellId]];
    }
    return _tableView;
}
-(void)requestData {
    [self.view showHUD];
    [self.vm syncNoticesWithVersion:0 limit:100].then(^(NSArray<WKMomentNotice*> *items) {
        [self.view hideHud];
        [self.notices removeAllObjects];
        [self.notices addObjectsFromArray:items ?: @[]];
        [self.tableView reloadData];
        [[WKMomentNoticeManager shared] markAllRead];
    }).catch(^(NSError *error) {
        [self.view hideHud];
        [self.view showHUDWithHide:error.domain];
    });
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return self.notices.count; }
-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WKMomentNoticeCell *cell = [tableView dequeueReusableCellWithIdentifier:[WKMomentNoticeCell cellId] forIndexPath:indexPath];
    [cell refresh:self.notices[indexPath.row]];
    return cell;
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath { return 82.0f; }
@end

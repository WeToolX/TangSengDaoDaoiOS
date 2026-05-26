//
//  WKFileMessageCell.m
//  WuKongBase
//

#import "WKFileMessageCell.h"
#import "WKFileContent.h"
#import "WKFileDetailVC.h"
#import "WuKongBase.h"

@interface WKFileMessageCell ()
@property(nonatomic,strong) UILabel *nameLabel;
@property(nonatomic,strong) UILabel *sizeLabel;
@property(nonatomic,strong) UILabel *extLabel;
@property(nonatomic,strong) UIView *extBox;
@end

@implementation WKFileMessageCell

+ (CGSize)contentSizeForMessage:(WKMessageModel *)model {
    return CGSizeMake(250.0f, 84.0f);
}

- (void)initUI {
    [super initUI];
    self.messageContentView.layer.masksToBounds = YES;
    self.messageContentView.layer.cornerRadius = 4.0f;
    
    self.nameLabel = [[UILabel alloc] init];
    self.nameLabel.font = [[WKApp shared].config appFontOfSize:15.0f];
    self.nameLabel.numberOfLines = 2;
    [self.messageContentView addSubview:self.nameLabel];
    
    self.sizeLabel = [[UILabel alloc] init];
    self.sizeLabel.font = [[WKApp shared].config appFontOfSize:12.0f];
    [self.messageContentView addSubview:self.sizeLabel];
    
    self.extBox = [[UIView alloc] init];
    self.extBox.layer.masksToBounds = YES;
    self.extBox.layer.cornerRadius = 5.0f;
    [self.messageContentView addSubview:self.extBox];
    
    self.extLabel = [[UILabel alloc] init];
    self.extLabel.font = [UIFont boldSystemFontOfSize:13.0f];
    self.extLabel.textAlignment = NSTextAlignmentCenter;
    self.extLabel.textColor = UIColor.whiteColor;
    [self.extBox addSubview:self.extLabel];
    
    [self.messageContentView bringSubviewToFront:self.trailingView];
}

- (void)refresh:(WKMessageModel *)model {
    [super refresh:model];
    WKFileContent *content = (WKFileContent *)model.content;
    self.nameLabel.text = content.name.length > 0 ? content.name : LLang(@"未知文件");
    self.sizeLabel.text = [content displaySize];
    NSString *ext = content.ext.length > 0 ? content.ext.uppercaseString : @"FILE";
    self.extLabel.text = ext.length > 4 ? [ext substringToIndex:4] : ext;
    
    self.messageContentView.backgroundColor = [WKApp shared].config.cellBackgroundColor;
    self.nameLabel.textColor = [WKApp shared].config.messageRecvTextColor;
    self.sizeLabel.textColor = [WKApp shared].config.tipColor;
    self.extBox.backgroundColor = [WKApp shared].config.themeColor;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.extBox.lim_size = CGSizeMake(48.0f, 48.0f);
    self.extBox.lim_right = self.messageContentView.lim_width - 12.0f;
    self.extBox.lim_top = 14.0f;
    
    self.extLabel.frame = self.extBox.bounds;
    
    self.nameLabel.lim_left = 12.0f;
    self.nameLabel.lim_top = 12.0f;
    self.nameLabel.lim_width = self.extBox.lim_left - self.nameLabel.lim_left - 12.0f;
    self.nameLabel.lim_height = 40.0f;
    
    self.sizeLabel.lim_left = self.nameLabel.lim_left;
    self.sizeLabel.lim_top = self.nameLabel.lim_bottom + 6.0f;
    self.sizeLabel.lim_width = self.nameLabel.lim_width;
    self.sizeLabel.lim_height = 18.0f;
}

- (void)onTap {
    [super onTap];
    WKFileDetailVC *vc = [[WKFileDetailVC alloc] initWithMessage:self.messageModel.message];
    [[WKNavigationManager shared] pushViewController:vc animated:YES];
}

+ (BOOL)hiddenBubble {
    return YES;
}

@end

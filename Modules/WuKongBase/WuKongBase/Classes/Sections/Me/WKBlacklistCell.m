//
//  WKBlacklistCell.m
//  WuKongBase
//
//  Created by tt on 2020/6/26.
//

#import "WKBlacklistCell.h"

@implementation WKBlacklistModel

+ (WKModel *)fromMap:(NSDictionary *)dictory type:(ModelMapType)type {
    WKBlacklistModel *model = [WKBlacklistModel new];
    model.uid = dictory[@"uid"] ?: @"";
    model.name = dictory[@"name"] ?: @"";
    model.username = dictory[@"username"] ?: @"";
    if(model.name.length == 0) {
        model.name = model.username;
    }
    return model;
}

@end

@interface WKBlacklistCell ()
@property(nonatomic,strong) UILabel *nameLbl;
@property(nonatomic,strong) WKUserAvatar *avatarView;
@end

@implementation WKBlacklistCell

- (void)setupUI {
    [super setupUI];
    [self addSubview:self.avatarView];
    [self addSubview:self.nameLbl];
}

- (void)refresh:(WKBlacklistModel*)cellModel {
    [super refresh:cellModel];
    self.nameLbl.text = cellModel.name;
    [self.nameLbl sizeToFit];
    self.avatarView.uid = cellModel.uid;
    self.avatarView.url = [WKAvatarUtil getAvatar:cellModel.uid];
    
}

- (UILabel *)nameLbl {
    if(!_nameLbl) {
        _nameLbl = [[UILabel alloc] init];
    }
    return _nameLbl;
}

- (WKUserAvatar *)avatarView {
    if(!_avatarView) {
        _avatarView = [[WKUserAvatar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 48.0f, 48.0f)];
    }
    return _avatarView;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.avatarView.lim_left = 20.0f;
    self.avatarView.lim_top = self.lim_height/2.0f - self.avatarView.lim_height/2.0f;
    self.nameLbl.lim_left = self.avatarView.lim_right + 15.0f;
    self.nameLbl.lim_top = self.lim_height/2.0f - self.nameLbl.lim_height/2.0f;
}

+ (NSString *)cellId {
    return @"WKBlacklistCell";
}

@end

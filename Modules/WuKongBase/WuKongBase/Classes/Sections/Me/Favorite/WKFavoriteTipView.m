//
//  WKFavoriteTipView.m
//  WuKongBase
//

#import "WKFavoriteTipView.h"
#import "UIView+WK.h"

@interface WKFavoriteTipView ()
@property(nonatomic,copy) void(^actionBlock)(void);
@end

@implementation WKFavoriteTipView

+(void)showInView:(UIView*)view action:(void(^)(void))action {
    if(!view) {
        return;
    }
    WKFavoriteTipView *tip = [[WKFavoriteTipView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 290.0f, 36.0f)];
    tip.actionBlock = action;
    tip.backgroundColor = [UIColor colorWithWhite:0.12f alpha:0.88f];
    tip.layer.cornerRadius = 2.0f;
    tip.clipsToBounds = YES;
    tip.lim_left = (view.lim_width - tip.lim_width) / 2.0f;
    CGFloat bottom = 90.0f;
    if (@available(iOS 11.0, *)) {
        bottom += view.safeAreaInsets.bottom;
    }
    tip.lim_top = view.lim_height - bottom - tip.lim_height;
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(14.0f, 0.0f, 120.0f, tip.lim_height)];
    title.text = @"已收藏";
    title.textColor = UIColor.whiteColor;
    title.font = [UIFont systemFontOfSize:14.0f];
    [tip addSubview:title];
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(tip.lim_width - 104.0f, 0.0f, 94.0f, tip.lim_height)];
    [button setTitle:@"立即查看" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor colorWithWhite:0.85f alpha:1.0f] forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:14.0f];
    [button addTarget:tip action:@selector(actionPressed) forControlEvents:UIControlEventTouchUpInside];
    [tip addSubview:button];
    
    [view addSubview:tip];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [tip removeFromSuperview];
    });
}

-(void)actionPressed {
    [self removeFromSuperview];
    if(self.actionBlock) {
        self.actionBlock();
    }
}

@end

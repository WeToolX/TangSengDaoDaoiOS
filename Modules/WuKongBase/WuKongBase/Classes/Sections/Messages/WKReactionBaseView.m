//
//  WKReactionView.m
//  WuKongBase
//
//  Created by tt on 2021/9/13.
//

#import "WKReactionBaseView.h"
#import "WuKongBase.h"

@interface WKReactionBaseView ()

@end

@implementation WKReactionBaseView

- (void)render:(NSArray<WKReaction *> *)reactions {
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.backgroundColor = UIColor.clearColor;
    self.reactionNum = 0;
    if(reactions.count == 0) {
        self.lim_size = CGSizeZero;
        return;
    }
    UIView *tgReactionChip = [[UIView alloc] init];
    tgReactionChip.backgroundColor = [WKApp.shared.config.cellBackgroundColor colorWithAlphaComponent:0.96f];
    tgReactionChip.layer.cornerRadius = 13.0f;
    tgReactionChip.layer.borderWidth = 0.5f;
    tgReactionChip.layer.borderColor = [WKApp.shared.config.lineColor colorWithAlphaComponent:0.8f].CGColor;
    tgReactionChip.clipsToBounds = YES;
    [self addSubview:tgReactionChip];

    CGFloat left = 7.0f;
    NSInteger visibleCount = MIN(reactions.count, 3);
    for (NSInteger i = 0; i < visibleCount; i++) {
        WKReaction *reaction = reactions[i];
        UILabel *emojiLbl = [[UILabel alloc] initWithFrame:CGRectMake(left, 2.0f, 20.0f, 22.0f)];
        emojiLbl.text = reaction.emoji;
        emojiLbl.textAlignment = NSTextAlignmentCenter;
        emojiLbl.font = [UIFont systemFontOfSize:16.0f];
        [tgReactionChip addSubview:emojiLbl];
        left += 18.0f;
    }
    UILabel *countLbl = [[UILabel alloc] initWithFrame:CGRectMake(left + 2.0f, 0.0f, 20.0f, 26.0f)];
    countLbl.text = [NSString stringWithFormat:@"%ld",(long)MAX(self.reactionNum, reactions.count)];
    countLbl.textColor = WKApp.shared.config.tipColor;
    countLbl.font = [WKApp.shared.config appFontOfSize:12.0f];
    countLbl.textAlignment = NSTextAlignmentCenter;
    [tgReactionChip addSubview:countLbl];
    left += 26.0f;

    CGFloat width = MAX(42.0f, left + 4.0f);
    self.lim_size = CGSizeMake(width, 26.0f);
    tgReactionChip.frame = self.bounds;
}

- (void)setReactionNum:(NSInteger)reactionNum {
    _reactionNum = reactionNum;
    UILabel *countLbl = nil;
    UIView *tgReactionChip = self.subviews.firstObject;
    for (UIView *view in tgReactionChip.subviews) {
        if([view isKindOfClass:UILabel.class]) {
            countLbl = (UILabel*)view;
        }
    }
    if(countLbl) {
        countLbl.text = [NSString stringWithFormat:@"%ld",(long)reactionNum];
    }
}

@end

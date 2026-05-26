//
//  WKSmallVideoMessageCell.m
//  WuKongBase
//

#import "WKSmallVideoMessageCell.h"
#import "WKSmallVideoContent.h"
#import "WKLoadProgressView.h"
#import "UIImage+WK.h"
#import "WKVideoData.h"
#import <YBImageBrowser/YBImageBrowser.h>
#import <SDWebImage/SDWebImage.h>
#import <AVFoundation/AVFoundation.h>
#import <WuKongIMSDK/WKFileUtil.h>

@interface WKSmallVideoMessageCell ()
@property(nonatomic,strong) UIImageView *coverView;
@property(nonatomic,strong) UIImageView *playView;
@property(nonatomic,strong) UILabel *durationLabel;
@property(nonatomic,strong) WKLoadProgressView *progressView;
@property(nonatomic,strong) WKMessageFileUploadTask *uploadTask;
@end

@implementation WKSmallVideoMessageCell

+ (CGSize)contentSizeForMessage:(WKMessageModel *)model {
    WKSmallVideoContent *content = (WKSmallVideoContent *)model.content;
    CGSize size = CGSizeMake(content.width, content.height);
    if (size.width <= 0 || size.height <= 0) {
        size = CGSizeMake(150.0f, 200.0f);
    }
    size = [UIImage lim_sizeWithImageOriginSize:size];
    if (size.width < 120.0f) {
        CGFloat scale = 120.0f / size.width;
        size = CGSizeMake(120.0f, size.height * scale);
    }
    if (size.height < 120.0f) {
        CGFloat scale = 120.0f / size.height;
        size = CGSizeMake(size.width * scale, 120.0f);
    }
    return size;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    if (self.uploadTask) {
        [self.uploadTask removeListener:self];
        self.uploadTask = nil;
    }
    self.coverView.image = nil;
    [self.coverView sd_cancelCurrentImageLoad];
}

- (void)initUI {
    [super initUI];
    self.coverView = [[UIImageView alloc] init];
    self.coverView.contentMode = UIViewContentModeScaleAspectFill;
    self.coverView.clipsToBounds = YES;
    self.coverView.layer.cornerRadius = 5.0f;
    [self.messageContentView addSubview:self.coverView];
    
    self.playView = [[UIImageView alloc] init];
    self.playView.image = [self playIconImage];
    [self.messageContentView addSubview:self.playView];
    
    self.durationLabel = [[UILabel alloc] init];
    self.durationLabel.font = [UIFont systemFontOfSize:12.0f weight:UIFontWeightMedium];
    self.durationLabel.textColor = UIColor.whiteColor;
    self.durationLabel.textAlignment = NSTextAlignmentRight;
    self.durationLabel.shadowColor = [UIColor colorWithWhite:0.0f alpha:0.5f];
    self.durationLabel.shadowOffset = CGSizeMake(0, 1);
    [self.messageContentView addSubview:self.durationLabel];
    
    self.progressView = [[WKLoadProgressView alloc] initWithFrame:CGRectZero];
    self.progressView.maxProgress = 1.0f;
    self.progressView.backgroundColor = [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:0.7];
    self.progressView.layer.cornerRadius = 5.0f;
    self.progressView.layer.masksToBounds = YES;
    [self.messageContentView addSubview:self.progressView];
    
    [self.messageContentView bringSubviewToFront:self.trailingView];
}

- (void)refresh:(WKMessageModel *)model {
    [super refresh:model];
    WKSmallVideoContent *content = (WKSmallVideoContent *)model.content;
    UIImage *cover = [content coverImage];
    if (cover) {
        self.coverView.image = cover;
    } else if ([content coverURL].length > 0) {
        [self.coverView sd_setImageWithURL:[[WKApp shared] getImageFullUrl:[content coverURL]]];
    } else {
        self.coverView.image = nil;
        self.coverView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.18f];
    }
    self.durationLabel.text = [content durationText];
    [self updateUploadProgress];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.coverView.frame = self.messageContentView.bounds;
    self.progressView.frame = self.messageContentView.bounds;
    
    self.playView.lim_size = CGSizeMake(44.0f, 44.0f);
    self.playView.lim_centerX_parent = self.messageContentView;
    self.playView.lim_centerY_parent = self.messageContentView;
    
    self.durationLabel.lim_left = 8.0f;
    self.durationLabel.lim_width = self.messageContentView.lim_width - 16.0f;
    self.durationLabel.lim_height = 18.0f;
    self.durationLabel.lim_bottom = self.messageContentView.lim_height - 7.0f;
}

- (void)updateUploadProgress {
    __weak typeof(self) weakSelf = self;
    WKMessageFileUploadTask *task = [[WKSDK shared] getMessageFileUploadTask:self.messageModel.message];
    if (self.uploadTask && self.uploadTask != task) {
        [self.uploadTask removeListener:self];
    }
    self.uploadTask = task;
    if (task) {
        [task removeListener:self];
        [task addListener:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                if (weakSelf.uploadTask.status == WKTaskStatusProgressing) {
                    weakSelf.progressView.hidden = NO;
                    [weakSelf.progressView setProgress:weakSelf.uploadTask.progress];
                } else {
                    weakSelf.progressView.hidden = YES;
                    [weakSelf.progressView setProgress:0];
                }
            });
        } target:self];
        if (task.status == WKTaskStatusProgressing) {
            self.progressView.hidden = NO;
            [self.progressView setProgress:task.progress];
        } else {
            self.progressView.hidden = YES;
            [self.progressView setProgress:0];
        }
    } else {
        self.progressView.hidden = YES;
        [self.progressView setProgress:0];
    }
}

- (void)onTap {
    WKSmallVideoContent *content = (WKSmallVideoContent *)self.messageModel.content;
    if ([WKFileUtil fileIsExistOfPath:content.localPath]) {
        [self showVideoWithDownloadTask:nil];
        return;
    }
    WKMessageFileDownloadTask *task = [[WKSDK shared].mediaManager download:self.messageModel.message];
    [self showVideoWithDownloadTask:task];
}

- (void)showVideoWithDownloadTask:(WKMessageFileDownloadTask *)task {
    WKSmallVideoContent *content = (WKSmallVideoContent *)self.messageModel.content;
    WKVideoData *data = [WKVideoData new];
    data.thumbImage = self.coverView.image ?: [content coverImage];
    data.projectiveView = self.coverView;
    data.downloadTask = task;
    if (!task && [WKFileUtil fileIsExistOfPath:content.localPath]) {
        data.videoURL = [NSURL fileURLWithPath:content.localPath];
    }
    data.extraData = @{@"message": self.messageModel ?: [NSNull null]};
    YBImageBrowser *browser = [YBImageBrowser new];
    browser.dataSourceArray = @[data];
    browser.currentPage = 0;
    [browser showToView:[WKApp.shared findWindow]];
}

- (UIImage *)playIconImage {
    CGFloat size = 44.0f;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(size, size), NO, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [[UIColor colorWithWhite:0.0f alpha:0.38f] setFill];
    CGContextFillEllipseInRect(ctx, CGRectMake(0, 0, size, size));
    [[UIColor whiteColor] setFill];
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(18, 13)];
    [path addLineToPoint:CGPointMake(18, 31)];
    [path addLineToPoint:CGPointMake(32, 22)];
    [path closePath];
    [path fill];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (BOOL)tailWrap {
    return true;
}

+ (BOOL)hiddenBubble {
    return YES;
}

@end

//
//  WKMomentComposeVC.m
//  WuKongContacts
//

#import "WKMomentComposeVC.h"
#import "WKMomentVM.h"
#import <WuKongBase/WKPhotoBrowser.h>
#import <WuKongBase/WKMediaPickerController.h>
#import <WuKongBase/WKContactsSelectVC.h>
#import "WKContactsLabelVM.h"
#import "UIView+WK.h"
#import "UIView+WKCommon.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <MobileCoreServices/MobileCoreServices.h>

@interface WKMomentComposeVC ()
@property(nonatomic,strong) UITextView *textView;
@property(nonatomic,strong) UIButton *sendBtn;
@property(nonatomic,strong) UIButton *addPhotoBtn;
@property(nonatomic,strong) UIButton *addVideoBtn;
@property(nonatomic,strong) UIScrollView *photoScrollView;
@property(nonatomic,strong) UIView *optionBox;
@property(nonatomic,strong) UILabel *mentionValueLbl;
@property(nonatomic,strong) UILabel *visibilityValueLbl;
@property(nonatomic,strong) NSMutableArray<NSData*> *imageDatas;
@property(nonatomic,copy) NSString *videoPath;
@property(nonatomic,strong) UIImage *videoCover;
@property(nonatomic,strong) NSMutableArray<NSString*> *mentionUids;
@property(nonatomic,strong) NSMutableArray<NSNumber*> *mentionTagIds;
@property(nonatomic,copy) NSString *visibilityType;
@property(nonatomic,strong) NSMutableArray<NSString*> *visibilityUids;
@property(nonatomic,strong) NSMutableArray<NSNumber*> *visibilityTagIds;
@property(nonatomic,strong) WKMomentVM *vm;
@end

@implementation WKMomentComposeVC

-(instancetype)init {
    self = [super init];
    if(self) {
        _vm = [WKMomentVM new];
        _imageDatas = [NSMutableArray array];
        _mentionUids = [NSMutableArray array];
        _mentionTagIds = [NSMutableArray array];
        _visibilityType = @"public";
        _visibilityUids = [NSMutableArray array];
        _visibilityTagIds = [NSMutableArray array];
    }
    return self;
}

-(void)setInitialImageDatas:(NSArray<NSData*>*)imageDatas {
    [self.imageDatas removeAllObjects];
    for(NSData *data in imageDatas ?: @[]) {
        if([data isKindOfClass:NSData.class] && self.imageDatas.count < 9) {
            [self.imageDatas addObject:data];
        }
    }
    self.videoPath = nil;
    self.videoCover = nil;
    [self reloadPhotos];
}

-(void)setInitialVideoPath:(NSString*)videoPath cover:(UIImage*)cover {
    [self.imageDatas removeAllObjects];
    self.videoPath = [self normalizedVideoPath:videoPath];
    self.videoCover = cover;
    [self reloadPhotos];
    if(!self.videoCover && self.videoPath.length > 0) {
        __weak typeof(self) weakSelf = self;
        [self videoFirstFrameAsync:self.videoPath completion:^(UIImage *image) {
            if(![weakSelf.videoPath isEqualToString:[weakSelf normalizedVideoPath:videoPath]]) {
                return;
            }
            weakSelf.videoCover = image;
            [weakSelf reloadPhotos];
        }];
    }
}

-(NSString*)normalizedVideoPath:(NSString*)path {
    if(path.length == 0) {
        return @"";
    }
    if([path hasPrefix:@"file://"]) {
        return [NSURL URLWithString:path].path ?: path;
    }
    return path;
}

-(void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = WKApp.shared.config.cellBackgroundColor;
    [self.view addSubview:self.textView];
    [self.view addSubview:self.photoScrollView];
    [self.view addSubview:self.addPhotoBtn];
    [self.view addSubview:self.addVideoBtn];
    [self.view addSubview:self.optionBox];
    [self.navigationBar setRightView:self.sendBtn];
    [self reloadPhotos];
    [self reloadOptions];
}

-(NSString *)langTitle {
    return self.textOnly ? LLang(@"发表文字") : LLang(@"发布朋友圈");
}

-(UITextView *)textView {
    if(!_textView) {
        _textView = [[UITextView alloc] initWithFrame:CGRectMake(24.0f, self.visibleRect.origin.y + 22.0f, WKScreenWidth - 48.0f, self.textOnly ? 360.0f : 180.0f)];
        _textView.backgroundColor = WKApp.shared.config.cellBackgroundColor;
        _textView.textColor = WKApp.shared.config.defaultTextColor;
        _textView.font = [WKApp.shared.config appFontOfSize:18.0f];
        _textView.textContainerInset = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f);
        _textView.textContainer.lineFragmentPadding = 0.0f;
    }
    return _textView;
}

-(UIScrollView *)photoScrollView {
    if(!_photoScrollView) {
        _photoScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(24.0f, self.textView.lim_bottom + 14.0f, WKScreenWidth - 48.0f, 94.0f)];
        _photoScrollView.showsHorizontalScrollIndicator = NO;
        _photoScrollView.hidden = self.textOnly;
    }
    return _photoScrollView;
}

-(UIButton *)addPhotoBtn {
    if(!_addPhotoBtn) {
        _addPhotoBtn = [[UIButton alloc] initWithFrame:CGRectMake(24.0f, self.photoScrollView.lim_top, 88.0f, 88.0f)];
        _addPhotoBtn.backgroundColor = WKApp.shared.config.cellBackgroundColor;
        [_addPhotoBtn setTitle:@"+" forState:UIControlStateNormal];
        [_addPhotoBtn setTitleColor:WKApp.shared.config.tipColor forState:UIControlStateNormal];
        _addPhotoBtn.titleLabel.font = [WKApp.shared.config appFontOfSize:42.0f];
        _addPhotoBtn.layer.borderWidth = 0.5f;
        _addPhotoBtn.layer.borderColor = [UIColor colorWithRed:220.0f/255.0f green:220.0f/255.0f blue:220.0f/255.0f alpha:1.0f].CGColor;
        [_addPhotoBtn addTarget:self action:@selector(addPhotoPressed) forControlEvents:UIControlEventTouchUpInside];
    }
    return _addPhotoBtn;
}

-(UIButton *)addVideoBtn {
    if(!_addVideoBtn) {
        _addVideoBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.addPhotoBtn.lim_right + 10.0f, self.photoScrollView.lim_top, 88.0f, 88.0f)];
        _addVideoBtn.backgroundColor = WKApp.shared.config.cellBackgroundColor;
        [_addVideoBtn setTitle:LLang(@"视频") forState:UIControlStateNormal];
        [_addVideoBtn setTitleColor:WKApp.shared.config.tipColor forState:UIControlStateNormal];
        _addVideoBtn.titleLabel.font = [WKApp.shared.config appFontOfSize:16.0f];
        _addVideoBtn.layer.borderWidth = 0.5f;
        _addVideoBtn.layer.borderColor = [UIColor colorWithRed:220.0f/255.0f green:220.0f/255.0f blue:220.0f/255.0f alpha:1.0f].CGColor;
        [_addVideoBtn addTarget:self action:@selector(addVideoPressed) forControlEvents:UIControlEventTouchUpInside];
    }
    return _addVideoBtn;
}

-(UIView *)optionBox {
    if(!_optionBox) {
        CGFloat top = self.textOnly ? self.textView.lim_bottom + 26.0f : self.photoScrollView.lim_bottom + 16.0f;
        _optionBox = [[UIView alloc] initWithFrame:CGRectMake(0.0f, top, WKScreenWidth, 96.0f)];
        _optionBox.backgroundColor = WKApp.shared.config.cellBackgroundColor;
        [_optionBox addSubview:[self optionRowWithTop:0.0f icon:@"@" title:LLang(@"提醒谁看") valueLabel:self.mentionValueLbl action:@selector(mentionPressed)]];
        [_optionBox addSubview:[self optionRowWithTop:48.0f icon:@"●" title:LLang(@"谁可以看") valueLabel:self.visibilityValueLbl action:@selector(visibilityPressed)]];
    }
    return _optionBox;
}

-(UIView*)optionRowWithTop:(CGFloat)top icon:(NSString*)icon title:(NSString*)title valueLabel:(UILabel*)valueLabel action:(SEL)action {
    UIControl *row = [[UIControl alloc] initWithFrame:CGRectMake(0.0f, top, WKScreenWidth, 48.0f)];
    if(action) {
        [row addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    }
    UILabel *iconLbl = [[UILabel alloc] initWithFrame:CGRectMake(24.0f, 0.0f, 28.0f, 48.0f)];
    iconLbl.text = icon;
    iconLbl.font = [WKApp.shared.config appFontOfSizeMedium:22.0f];
    iconLbl.textAlignment = NSTextAlignmentCenter;
    iconLbl.textColor = [icon isEqualToString:@"@"] ? [UIColor colorWithRed:51.0f/255.0f green:132.0f/255.0f blue:234.0f/255.0f alpha:1.0f] : WKApp.shared.config.defaultTextColor;
    [row addSubview:iconLbl];
    UILabel *titleLbl = [[UILabel alloc] initWithFrame:CGRectMake(64.0f, 0.0f, 130.0f, 48.0f)];
    titleLbl.text = title;
    titleLbl.font = [WKApp.shared.config appFontOfSize:16.0f];
    titleLbl.textColor = WKApp.shared.config.defaultTextColor;
    [row addSubview:titleLbl];
    if(valueLabel) {
        valueLabel.frame = CGRectMake(145.0f, 0.0f, WKScreenWidth - 178.0f, 48.0f);
        [row addSubview:valueLabel];
    }
    UILabel *arrow = [[UILabel alloc] initWithFrame:CGRectMake(WKScreenWidth - 28.0f, 0.0f, 18.0f, 48.0f)];
    arrow.text = @">";
    arrow.textColor = WKApp.shared.config.tipColor;
    [row addSubview:arrow];
    return row;
}

-(UILabel *)mentionValueLbl {
    if(!_mentionValueLbl) {
        _mentionValueLbl = [UILabel new];
        _mentionValueLbl.textAlignment = NSTextAlignmentRight;
        _mentionValueLbl.font = [WKApp.shared.config appFontOfSize:14.0f];
        _mentionValueLbl.textColor = WKApp.shared.config.tipColor;
    }
    return _mentionValueLbl;
}

-(UILabel *)visibilityValueLbl {
    if(!_visibilityValueLbl) {
        _visibilityValueLbl = [UILabel new];
        _visibilityValueLbl.textAlignment = NSTextAlignmentRight;
        _visibilityValueLbl.font = [WKApp.shared.config appFontOfSize:14.0f];
        _visibilityValueLbl.textColor = WKApp.shared.config.tipColor;
    }
    return _visibilityValueLbl;
}

-(UIButton *)sendBtn {
    if(!_sendBtn) {
        _sendBtn = [[UIButton alloc] init];
        [_sendBtn setTitle:LLang(@"发送") forState:UIControlStateNormal];
        [_sendBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        _sendBtn.titleLabel.font = [WKApp.shared.config appFontOfSizeMedium:15.0f];
        _sendBtn.backgroundColor = [UIColor colorWithRed:250.0f/255.0f green:82.0f/255.0f blue:50.0f/255.0f alpha:1.0f];
        _sendBtn.frame = CGRectMake(0.0f, 0.0f, 82.0f, 38.0f);
        _sendBtn.layer.cornerRadius = 19.0f;
        _sendBtn.clipsToBounds = YES;
        [_sendBtn addTarget:self action:@selector(sendPressed) forControlEvents:UIControlEventTouchUpInside];
    }
    return _sendBtn;
}

-(void)addPhotoPressed {
    if(self.videoPath.length > 0) {
        [self.view showHUDWithHide:LLang(@"图片和视频不能同时发布")];
        return;
    }
    NSInteger remain = MAX(0, 9 - self.imageDatas.count);
    if(remain <= 0) {
        [self.view showHUDWithHide:LLang(@"最多选择9张图片")];
        return;
    }
    __weak typeof(self) weakSelf = self;
    [[WKPhotoBrowser shared] showPhotoLibraryWithSender:self selectCompressImageBlock:^(NSArray<NSData *> * _Nonnull images, NSArray<PHAsset *> * _Nonnull assets, BOOL isOriginal) {
        for(NSData *data in images ?: @[]) {
            if(weakSelf.imageDatas.count < 9) {
                [weakSelf.imageDatas addObject:data];
            }
        }
        [weakSelf reloadPhotos];
    } maxSelectCount:remain allowSelectVideo:NO];
}

-(void)addVideoPressed {
    if(self.imageDatas.count > 0) {
        [self.view showHUDWithHide:LLang(@"图片和视频不能同时发布")];
        return;
    }
    WKMediaFetcher *fetcher = [WKMediaFetcher new];
    fetcher.limit = 1;
    fetcher.mediaTypes = @[(NSString*)kUTTypeMovie];
    __weak typeof(self) weakSelf = self;
    [fetcher fetchPhotoFromLibrary:^(UIImage *img, NSString *path, bool isSelectOriginalPhoto, PHAssetMediaType type, NSInteger left) {
        if(type == PHAssetMediaTypeVideo && path.length > 0) {
            weakSelf.videoPath = [weakSelf normalizedVideoPath:path];
            weakSelf.videoCover = nil;
            [weakSelf reloadPhotos];
            [weakSelf videoFirstFrameAsync:path completion:^(UIImage *image) {
                if(![weakSelf.videoPath isEqualToString:[weakSelf normalizedVideoPath:path]]) {
                    return;
                }
                weakSelf.videoCover = image;
                [weakSelf reloadPhotos];
            }];
        }
    }];
}

-(void)reloadPhotos {
    for(UIView *view in self.photoScrollView.subviews) {
        [view removeFromSuperview];
    }
    CGFloat left = 0.0f;
    NSInteger index = 0;
    for(NSData *data in self.imageDatas) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(left, 0.0f, 88.0f, 88.0f)];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        imageView.image = [UIImage imageWithData:data];
        imageView.tag = index++;
        imageView.userInteractionEnabled = YES;
        [imageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(removePhotoTap:)]];
        [self.photoScrollView addSubview:imageView];
        left += 92.0f;
    }
    if(self.videoPath.length > 0) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 88.0f, 88.0f)];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        imageView.image = self.videoCover;
        imageView.userInteractionEnabled = YES;
        [imageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(previewVideo)]];
        UILabel *play = [[UILabel alloc] initWithFrame:imageView.bounds];
        play.text = @"▶";
        play.textColor = UIColor.whiteColor;
        play.textAlignment = NSTextAlignmentCenter;
        play.font = [WKApp.shared.config appFontOfSize:30.0f];
        [imageView addSubview:play];
        UIButton *deleteButton = [[UIButton alloc] initWithFrame:CGRectMake(58.0f, 4.0f, 26.0f, 26.0f)];
        deleteButton.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.55f];
        deleteButton.layer.cornerRadius = 13.0f;
        [deleteButton setTitle:@"×" forState:UIControlStateNormal];
        [deleteButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        deleteButton.titleLabel.font = [WKApp.shared.config appFontOfSizeMedium:18.0f];
        [deleteButton addTarget:self action:@selector(removeVideoPressed) forControlEvents:UIControlEventTouchUpInside];
        [imageView addSubview:deleteButton];
        [self.photoScrollView addSubview:imageView];
        left = 92.0f;
    }
    self.photoScrollView.contentSize = CGSizeMake(left, 88.0f);
    self.photoScrollView.hidden = self.textOnly;
    self.addPhotoBtn.hidden = self.textOnly || self.videoPath.length > 0 || self.imageDatas.count >= 9;
    self.addVideoBtn.hidden = self.textOnly || self.videoPath.length > 0 || self.imageDatas.count > 0;
}

-(void)removePhotoTap:(UITapGestureRecognizer*)tap {
    NSInteger index = tap.view.tag;
    if(index >= 0 && index < self.imageDatas.count) {
        [self.imageDatas removeObjectAtIndex:index];
        [self reloadPhotos];
    }
}

-(void)removeVideoPressed {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:LLang(@"删除视频") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [alert addAction:[UIAlertAction actionWithTitle:LLang(@"删除") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self removeVideo];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:LLang(@"取消") style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

-(void)removeVideo {
    self.videoPath = nil;
    self.videoCover = nil;
    [self reloadPhotos];
}

-(void)previewVideo {
    if(self.videoPath.length == 0) {
        return;
    }
    AVPlayerViewController *vc = [AVPlayerViewController new];
    vc.player = [AVPlayer playerWithURL:[NSURL fileURLWithPath:self.videoPath]];
    [self presentViewController:vc animated:YES completion:^{
        [vc.player play];
    }];
}

-(UIImage*)videoFirstFrame:(NSString*)path {
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:path] options:nil];
    AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    generator.appliesPreferredTrackTransform = YES;
    CGImageRef imageRef = [generator copyCGImageAtTime:CMTimeMake(0, 1) actualTime:nil error:nil];
    UIImage *image = imageRef ? [UIImage imageWithCGImage:imageRef] : nil;
    if(imageRef) CGImageRelease(imageRef);
    return image;
}

-(void)videoFirstFrameAsync:(NSString*)path completion:(void(^)(UIImage *image))completion {
    NSString *normalizedPath = [self normalizedVideoPath:path];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *image = normalizedPath.length > 0 ? [self videoFirstFrame:normalizedPath] : nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            if(completion) completion(image);
        });
    });
}

-(void)mentionPressed {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [sheet addAction:[UIAlertAction actionWithTitle:LLang(@"从通讯录选择") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self chooseContactsForMention:YES];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:LLang(@"从标签选择") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self chooseLabelForMention:YES];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:LLang(@"清空") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self.mentionUids removeAllObjects];
        [self.mentionTagIds removeAllObjects];
        [self reloadOptions];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:LLang(@"取消") style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:sheet animated:YES completion:nil];
}

-(void)visibilityPressed {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [sheet addAction:[UIAlertAction actionWithTitle:LLang(@"公开") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.visibilityType = @"public";
        [self.visibilityUids removeAllObjects];
        [self.visibilityTagIds removeAllObjects];
        [self reloadOptions];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:LLang(@"私有") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.visibilityType = @"private";
        [self.visibilityUids removeAllObjects];
        [self.visibilityTagIds removeAllObjects];
        [self reloadOptions];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:LLang(@"部分可见-联系人") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.visibilityType = @"partial_visible";
        [self chooseContactsForMention:NO];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:LLang(@"不给谁看-联系人") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.visibilityType = @"exclude_visible";
        [self chooseContactsForMention:NO];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:LLang(@"部分可见-标签") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.visibilityType = @"partial_visible";
        [self chooseLabelForMention:NO];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:LLang(@"不给谁看-标签") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.visibilityType = @"exclude_visible";
        [self chooseLabelForMention:NO];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:LLang(@"取消") style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:sheet animated:YES completion:nil];
}

-(void)chooseContactsForMention:(BOOL)mention {
    WKContactsSelectVC *vc = [WKContactsSelectVC new];
    vc.title = LLang(@"选择联系人");
    vc.showBack = YES;
    vc.mode = WKContactsModeMulti;
    vc.selecteds = mention ? self.mentionUids : self.visibilityUids;
    __weak typeof(self) weakSelf = self;
    vc.onFinishedSelect = ^(NSArray<NSString *> *uids) {
        if(mention) {
            [weakSelf.mentionUids removeAllObjects];
            [weakSelf.mentionUids addObjectsFromArray:uids ?: @[]];
            [weakSelf.mentionTagIds removeAllObjects];
        }else {
            [weakSelf.visibilityUids removeAllObjects];
            [weakSelf.visibilityUids addObjectsFromArray:uids ?: @[]];
            [weakSelf.visibilityTagIds removeAllObjects];
        }
        [weakSelf reloadOptions];
    };
    [[WKNavigationManager shared] pushViewController:vc animated:YES];
}

-(void)chooseLabelForMention:(BOOL)mention {
    WKContactsLabelVM *vm = [WKContactsLabelVM new];
    [vm labelsFull].then(^(NSArray<WKContactsLabel*> *labels) {
        UIAlertController *sheet = [UIAlertController alertControllerWithTitle:LLang(@"选择标签") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        for(WKContactsLabel *label in labels ?: @[]) {
            [sheet addAction:[UIAlertAction actionWithTitle:label.name style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                if(mention) {
                    [self.mentionTagIds removeAllObjects];
                    [self.mentionTagIds addObject:@(label.tagId)];
                    [self.mentionUids removeAllObjects];
                }else {
                    [self.visibilityTagIds removeAllObjects];
                    [self.visibilityTagIds addObject:@(label.tagId)];
                    [self.visibilityUids removeAllObjects];
                }
                [self reloadOptions];
            }]];
        }
        [sheet addAction:[UIAlertAction actionWithTitle:LLang(@"取消") style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:sheet animated:YES completion:nil];
    }).catch(^(NSError *error) {
        [self.view showHUDWithHide:error.domain];
    });
}

-(void)reloadOptions {
    NSInteger mentionCount = self.mentionUids.count + self.mentionTagIds.count;
    self.mentionValueLbl.text = mentionCount > 0 ? [NSString stringWithFormat:LLang(@"已选择%ld个"),(long)mentionCount] : LLang(@"未选择");
    NSString *title = LLang(@"公开");
    if([self.visibilityType isEqualToString:@"private"]) title = LLang(@"私有");
    if([self.visibilityType isEqualToString:@"partial_visible"]) title = LLang(@"部分可见");
    if([self.visibilityType isEqualToString:@"exclude_visible"]) title = LLang(@"不给谁看");
    NSInteger visibleCount = self.visibilityUids.count + self.visibilityTagIds.count;
    self.visibilityValueLbl.text = visibleCount > 0 ? [NSString stringWithFormat:@"%@ %@",title,[NSString stringWithFormat:LLang(@"已选择%ld个"),(long)visibleCount]] : title;
}

-(void)sendPressed {
    NSString *text = [self.textView.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if(text.length == 0 && self.imageDatas.count == 0 && self.videoPath.length == 0) {
        [self.view showHUDWithHide:LLang(@"请输入内容")];
        return;
    }
    self.sendBtn.enabled = NO;
    [self.view showHUD];
    [self uploadImagesAtIndex:0 paths:[NSMutableArray array] completion:^(NSArray<NSString *> *paths, NSError *error) {
        if(error) {
            self.sendBtn.enabled = YES;
            [self.view hideHud];
            [self.view showHUDWithHide:error.domain];
            return;
        }
        [self uploadVideoIfNeeded:^(WKMomentPublishMedia *video, NSError *error) {
            if(error) {
                self.sendBtn.enabled = YES;
                [self.view hideHud];
                [self.view showHUDWithHide:error.domain];
                return;
            }
            NSArray *mentionUids = self.mentionUids ? self.mentionUids : @[];
            NSArray *mentionTagIds = self.mentionTagIds ? self.mentionTagIds : @[];
            NSArray *visibilityUids = self.visibilityUids ? self.visibilityUids : @[];
            NSArray *visibilityTagIds = self.visibilityTagIds ? self.visibilityTagIds : @[];
            NSString *visibilityType = self.visibilityType ? self.visibilityType : @"public";
            NSDictionary *mention = @{@"uids":mentionUids,@"tag_ids":mentionTagIds};
            NSDictionary *visibility = @{@"type":visibilityType,@"uids":visibilityUids,@"tag_ids":visibilityTagIds};
            AnyPromise *promise = [self.vm publishText:text imagePaths:paths video:video mention:mention visibility:visibility];
            promise.then(^{
                [self.view hideHud];
                if(self.onPublished) {
                    self.onPublished();
                }
                [[WKNavigationManager shared] popViewControllerAnimated:YES];
            });
            promise.catch(^(NSError *error) {
                self.sendBtn.enabled = YES;
                [self.view hideHud];
                [self.view showHUDWithHide:error.domain];
            });
        }];
    }];
}

-(void)uploadVideoIfNeeded:(void(^)(WKMomentPublishMedia *, NSError *))completion {
    if(self.videoPath.length == 0) {
        if(completion) completion(nil,nil);
        return;
    }
    [self.vm uploadFilePath:self.videoPath type:@"moment" completion:^(NSString * _Nullable path, NSError * _Nullable error) {
        if(error || path.length == 0) {
            if(completion) completion(nil,error ?: [NSError errorWithDomain:LLang(@"视频上传失败") code:-1 userInfo:nil]);
            return;
        }
        WKMomentPublishMedia *video = [WKMomentPublishMedia new];
        video.mediaURL = path;
        NSDictionary *attrs = [NSFileManager.defaultManager attributesOfItemAtPath:self.videoPath error:nil];
        video.size = (NSInteger)attrs.fileSize;
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:self.videoPath] options:nil];
        video.duration = (NSInteger)CMTimeGetSeconds(asset.duration);
        AVAssetTrack *track = [asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
        CGSize size = CGSizeApplyAffineTransform(track.naturalSize, track.preferredTransform);
        video.width = fabs(size.width);
        video.height = fabs(size.height);
        [self uploadVideoCoverIfNeeded:video completion:completion];
    }];
}

-(void)uploadVideoCoverIfNeeded:(WKMomentPublishMedia*)video completion:(void(^)(WKMomentPublishMedia *, NSError *))completion {
    if(!self.videoCover && self.videoPath.length > 0) {
        __weak typeof(self) weakSelf = self;
        [self videoFirstFrameAsync:self.videoPath completion:^(UIImage *image) {
            weakSelf.videoCover = image;
            [weakSelf uploadVideoCoverIfNeeded:video completion:completion];
        }];
        return;
    }
    UIImage *cover = self.videoCover;
    NSData *coverData = UIImageJPEGRepresentation(cover, 0.85f);
    if(!coverData) {
        if(completion) completion(video,nil);
        return;
    }
    [self.vm uploadImageData:coverData type:@"momentcover" completion:^(NSString * _Nullable path, NSError * _Nullable error) {
        if(error || path.length == 0) {
            if(completion) completion(nil,error ?: [NSError errorWithDomain:LLang(@"视频封面上传失败") code:-1 userInfo:nil]);
            return;
        }
        video.coverURL = path;
        if(completion) completion(video,nil);
    }];
}

-(void)uploadImagesAtIndex:(NSInteger)index paths:(NSMutableArray<NSString*>*)paths completion:(void(^)(NSArray<NSString*> *paths, NSError *error))completion {
    if(index >= self.imageDatas.count) {
        if(completion) completion(paths,nil);
        return;
    }
    [self.vm uploadImageData:self.imageDatas[index] type:@"moment" completion:^(NSString * _Nullable path, NSError * _Nullable error) {
        if(error || path.length == 0) {
            if(completion) completion(paths,error ?: [NSError errorWithDomain:LLang(@"图片上传失败") code:-1 userInfo:nil]);
            return;
        }
        [paths addObject:path];
        [self uploadImagesAtIndex:index + 1 paths:paths completion:completion];
    }];
}

@end

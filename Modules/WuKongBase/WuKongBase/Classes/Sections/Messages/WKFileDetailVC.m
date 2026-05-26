//
//  WKFileDetailVC.m
//  WuKongBase
//

#import "WKFileDetailVC.h"
#import "WKFileContent.h"
#import "WuKongBase.h"
#import <QuickLook/QuickLook.h>

@interface WKFileDetailVC ()<QLPreviewControllerDataSource>
@property(nonatomic,strong) WKMessage *message;
@property(nonatomic,strong) UILabel *extLabel;
@property(nonatomic,strong) UILabel *nameLabel;
@property(nonatomic,strong) UILabel *sizeLabel;
@property(nonatomic,strong) UIButton *openButton;
@property(nonatomic,strong) UIProgressView *progressView;
@property(nonatomic,strong) NSURL *previewURL;
@end

@implementation WKFileDetailVC

- (instancetype)initWithMessage:(WKMessage *)message {
    self = [super init];
    if (self) {
        _message = message;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = LLang(@"文件");
    self.view.backgroundColor = [WKApp shared].config.backgroundColor;
    
    self.extLabel = [[UILabel alloc] initWithFrame:CGRectMake((WKScreenWidth - 72.0f) / 2.0f, 112.0f, 72.0f, 72.0f)];
    self.extLabel.layer.masksToBounds = YES;
    self.extLabel.layer.cornerRadius = 8.0f;
    self.extLabel.backgroundColor = [WKApp shared].config.themeColor;
    self.extLabel.textColor = UIColor.whiteColor;
    self.extLabel.font = [UIFont boldSystemFontOfSize:18.0f];
    self.extLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.extLabel];
    
    self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(32.0f, self.extLabel.lim_bottom + 24.0f, WKScreenWidth - 64.0f, 48.0f)];
    self.nameLabel.font = [[WKApp shared].config appFontOfSize:17.0f];
    self.nameLabel.textAlignment = NSTextAlignmentCenter;
    self.nameLabel.numberOfLines = 2;
    self.nameLabel.textColor = [WKApp shared].config.defaultTextColor;
    [self.view addSubview:self.nameLabel];
    
    self.sizeLabel = [[UILabel alloc] initWithFrame:CGRectMake(32.0f, self.nameLabel.lim_bottom + 8.0f, WKScreenWidth - 64.0f, 22.0f)];
    self.sizeLabel.font = [[WKApp shared].config appFontOfSize:13.0f];
    self.sizeLabel.textAlignment = NSTextAlignmentCenter;
    self.sizeLabel.textColor = [WKApp shared].config.tipColor;
    [self.view addSubview:self.sizeLabel];
    
    self.progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(48.0f, self.sizeLabel.lim_bottom + 30.0f, WKScreenWidth - 96.0f, 2.0f)];
    self.progressView.hidden = YES;
    [self.view addSubview:self.progressView];
    
    self.openButton = [[UIButton alloc] initWithFrame:CGRectMake(48.0f, self.sizeLabel.lim_bottom + 54.0f, WKScreenWidth - 96.0f, 44.0f)];
    self.openButton.layer.masksToBounds = YES;
    self.openButton.layer.cornerRadius = 4.0f;
    self.openButton.backgroundColor = [WKApp shared].config.themeColor;
    [self.openButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [self.openButton setTitle:LLang(@"打开") forState:UIControlStateNormal];
    [self.openButton addTarget:self action:@selector(openPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.openButton];
    
    [self refreshFileInfo];
}

- (void)refreshFileInfo {
    WKFileContent *content = (WKFileContent *)self.message.content;
    NSString *ext = content.ext.length > 0 ? content.ext.uppercaseString : @"FILE";
    self.extLabel.text = ext.length > 4 ? [ext substringToIndex:4] : ext;
    self.nameLabel.text = content.name.length > 0 ? content.name : LLang(@"未知文件");
    self.sizeLabel.text = [content displaySize];
}

- (void)openPressed {
    WKFileContent *content = (WKFileContent *)self.message.content;
    if ([[NSFileManager defaultManager] fileExistsAtPath:content.localPath]) {
        [self previewFileAtPath:content.localPath];
        return;
    }
    self.openButton.enabled = NO;
    self.progressView.hidden = NO;
    __weak typeof(self) weakSelf = self;
    [[WKSDK shared].mediaManager download:self.message callback:^(WKMediaDownloadState state, CGFloat progress, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.progressView.progress = progress;
            if (state == WKMediaDownloadStateSuccess) {
                weakSelf.openButton.enabled = YES;
                weakSelf.progressView.hidden = YES;
                [weakSelf previewFileAtPath:content.localPath];
            } else if (state == WKMediaDownloadStateFail) {
                weakSelf.openButton.enabled = YES;
                weakSelf.progressView.hidden = YES;
                [[WKNavigationManager shared].topViewController.view makeToast:error.localizedDescription ?: LLang(@"下载失败")];
            }
        });
    }];
}

- (void)previewFileAtPath:(NSString *)path {
    self.previewURL = [NSURL fileURLWithPath:path];
    QLPreviewController *previewVC = [QLPreviewController new];
    previewVC.dataSource = self;
    [self.navigationController pushViewController:previewVC animated:YES];
}

- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller {
    return self.previewURL ? 1 : 0;
}

- (id<QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index {
    return self.previewURL;
}

@end

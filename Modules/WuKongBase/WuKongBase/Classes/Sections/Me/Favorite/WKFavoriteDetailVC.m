//
//  WKFavoriteDetailVC.m
//  WuKongBase
//

#import "WKFavoriteDetailVC.h"
#import "WuKongBase.h"
#import "WKApp.h"
#import "WKConstant.h"
#import "WKImageBrowser.h"
#import "WKMessageActionManager.h"
#import "UIView+WKCommon.h"
#import "UIView+WK.h"
#import <SDWebImage/SDWebImage.h>
#import <YBImageBrowser/YBImageBrowser.h>

@interface WKFavoriteDetailVC ()
@property(nonatomic,strong) WKFavoriteItem *item;
@property(nonatomic,strong) UIScrollView *scrollView;
@property(nonatomic,strong) UILabel *textLbl;
@property(nonatomic,strong) UIImageView *imageView;
@end

@implementation WKFavoriteDetailVC

-(instancetype)initWithItem:(WKFavoriteItem *)item {
    self = [super init];
    if(self) {
        self.item = item;
    }
    return self;
}

-(NSString*)langTitle {
    return LLang(@"详情");
}

-(void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = WKApp.shared.config.backgroundColor;
    [self.view addSubview:self.scrollView];
    [self setupRightButton];
    [self renderContent];
}

-(void)setupRightButton {
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 64.0f, 32.0f)];
    [button setTitle:LLang(@"发送") forState:UIControlStateNormal];
    [button setTitleColor:WKApp.shared.config.navBarButtonColor forState:UIControlStateNormal];
    button.titleLabel.font = [WKApp.shared.config appFontOfSize:15.0f];
    [button addTarget:self action:@selector(sendPressed) forControlEvents:UIControlEventTouchUpInside];
    self.rightView = button;
}

-(void)renderContent {
    if([self.item isImage]) {
        [self.scrollView addSubview:self.imageView];
        NSURL *url = [[WKApp shared] getImageFullUrl:self.item.imageURL];
        [self.imageView sd_setImageWithURL:url];
        self.imageView.lim_top = 16.0f;
        self.imageView.lim_left = 16.0f;
        self.scrollView.contentSize = CGSizeMake(WKScreenWidth, self.imageView.lim_bottom + 30.0f);
    }else {
        [self.scrollView addSubview:self.textLbl];
        self.textLbl.text = self.item.content ?: @"";
        CGSize size = [self.textLbl sizeThatFits:CGSizeMake(WKScreenWidth - 24.0f, CGFLOAT_MAX)];
        self.textLbl.frame = CGRectMake(12.0f, 16.0f, WKScreenWidth - 24.0f, MAX(24.0f, size.height));
        self.scrollView.contentSize = CGSizeMake(WKScreenWidth, self.textLbl.lim_bottom + 30.0f);
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(textLongPressed:)];
        [self.textLbl addGestureRecognizer:longPress];
        self.textLbl.userInteractionEnabled = YES;
    }
}

-(void)textLongPressed:(UILongPressGestureRecognizer*)gesture {
    if(gesture.state != UIGestureRecognizerStateBegan) {
        return;
    }
    UIPasteboard.generalPasteboard.string = self.item.content ?: @"";
    [self.view showHUDWithHide:LLang(@"已复制")];
}

-(void)imageTapped {
    if(![self.item isImage]) {
        return;
    }
    WKImageBrowser *browser = [WKImageBrowser new];
    YBIBImageData *data = [YBIBImageData new];
    data.imageURL = [[WKApp shared] getImageFullUrl:self.item.imageURL];
    data.projectiveView = self.imageView;
    browser.dataSourceArray = @[data];
    [browser show];
}

-(void)sendPressed {
    [[WKMessageActionManager shared] sendContentToFriend:[self.item toMessageContent] complete:nil];
}

-(UIScrollView*)scrollView {
    if(!_scrollView) {
        _scrollView = [[UIScrollView alloc] initWithFrame:[self visibleRect]];
        _scrollView.alwaysBounceVertical = YES;
    }
    return _scrollView;
}

-(UILabel*)textLbl {
    if(!_textLbl) {
        _textLbl = [[UILabel alloc] init];
        _textLbl.numberOfLines = 0;
        _textLbl.font = [WKApp.shared.config appFontOfSize:16.0f];
        _textLbl.textColor = WKApp.shared.config.defaultTextColor;
    }
    return _textLbl;
}

-(UIImageView*)imageView {
    if(!_imageView) {
        _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, MIN(WKScreenWidth - 32.0f, 260.0f), MIN(WKScreenWidth - 32.0f, 260.0f))];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds = YES;
        _imageView.userInteractionEnabled = YES;
        _imageView.backgroundColor = [UIColor colorWithWhite:0.94f alpha:1.0f];
        [_imageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageTapped)]];
    }
    return _imageView;
}

@end

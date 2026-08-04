//
//  WKMeVM.m
//  WuKongBase
//
//  Created by tt on 2020/6/9.
//

#import "WKMeVM.h"
#import "WKTableSectionUtil.h"
#import "WKMeItemCell.h"
#import "WKMePushSettingVC.h"
#import "WKCommonSettingVC.h"
#import "WKMeItem.h"
#import "WuKongBase.h"
#import "UIImageView+WK.h"

@interface WKContactUsVC : WKBaseVC
@property(nonatomic,strong) UIImageView *qrCodeImageView;
@property(nonatomic,strong) UIButton *emailButton;
@end

@implementation WKContactUsVC

- (NSString *)langTitle {
    return LLang(@"联系我们");
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];

    self.qrCodeImageView = [[UIImageView alloc] init];
    self.qrCodeImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:self.qrCodeImageView];

    self.emailButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.emailButton.titleLabel.font = [UIFont systemFontOfSize:16.0f];
    [self.emailButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.emailButton addTarget:self action:@selector(copyEmail) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.emailButton];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self reloadContactInfo];
}

- (void)reloadContactInfo {
    NSString *qrCodePath = WKApp.shared.remoteConfig.contactWecomQRCode;
    NSString *email = WKApp.shared.remoteConfig.contactEmail;
    BOOL showQRCode = qrCodePath.length > 0;
    BOOL showEmail = email.length > 0;
    CGFloat width = MIN(self.view.bounds.size.width - 64.0f, 280.0f);
    CGFloat top = CGRectGetMaxY(self.navigationBar.frame) + 32.0f;

    self.qrCodeImageView.hidden = !showQRCode;
    self.qrCodeImageView.frame = CGRectMake((self.view.bounds.size.width - width) / 2.0f, top, width, width);
    if(showQRCode) {
        [self.qrCodeImageView lim_setImageWithURL:[WKApp.shared getFileFullUrl:qrCodePath]];
    }

    self.emailButton.hidden = !showEmail;
    self.emailButton.frame = CGRectMake(32.0f, top + (showQRCode ? width + 20.0f : 0.0f), self.view.bounds.size.width - 64.0f, 44.0f);
    [self.emailButton setTitle:email forState:UIControlStateNormal];
}

- (void)copyEmail {
    UIPasteboard.generalPasteboard.string = WKApp.shared.remoteConfig.contactEmail;
}

@end

@implementation WKMeVM

- (NSArray<NSDictionary *> *)tableSectionMaps {
    NSMutableArray<WKMeItem*> *itemModels = [[[WKApp shared] invokes:WKPOINT_CATEGORY_ME param:nil] mutableCopy];
    if(!itemModels || itemModels.count<=0) {
        return @[];
    }
    WKMeItem *contactItem = [WKMeItem initWithTitle:LLang(@"联系我们") icon:[self imageName:@"Me/Index/IconSetting"] onClick:^{
        [[WKNavigationManager shared] pushViewController:[WKContactUsVC new] animated:YES];
    }];
    NSUInteger commonIndex = [itemModels indexOfObjectPassingTest:^BOOL(WKMeItem * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
        return [item.title isEqualToString:LLang(@"通用")];
    }];
    [itemModels insertObject:contactItem atIndex:commonIndex == NSNotFound ? itemModels.count : commonIndex + 1];
    NSMutableArray *items = [NSMutableArray array];
    WKMeItem *preMeItem;
    for (WKMeItem *meItem in itemModels) {
       [items addObject:@{
           @"height":@(meItem.sectionHeight + (preMeItem?preMeItem.nextSectionHeight:0)),
            @"items":@[@{
                           @"class":WKMeItemModel.class,
                           @"title":meItem.title?:@"",
                           @"icon": meItem.icon,
                           @"bottomLeftSpace":@(0.0f),
                           @"showBottomLine":@(NO),
                           @"showTopLine":@(NO),
                           @"onClick":^(BOOL on){
                               if(meItem.onClick) {
                                   meItem.onClick();
                               }
                           }
                       }]
       }];
        preMeItem = meItem;
        
    }
    return items;
}

-(UIImage*) imageName:(NSString*)name {
    return [WKApp.shared loadImage:name moduleID:@"WuKongBase"];
//    return [[WKResource shared] resourceForImage:name podName:@"WuKongBase_images"];
}

@end

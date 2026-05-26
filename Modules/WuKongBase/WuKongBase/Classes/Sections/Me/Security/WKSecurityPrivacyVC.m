//
//  WKSecurityPrivacyVC.m
//  WuKongBase
//

#import "WKSecurityPrivacyVC.h"

@interface WKSecurityPrivacyVC ()<WKSecurityPrivacyVMDelegate>

@end

@implementation WKSecurityPrivacyVC

- (instancetype)init {
    self = [super init];
    if (self) {
        self.viewModel = [WKSecurityPrivacyVM new];
        self.viewModel.delegate = self;
    }
    return self;
}

- (NSString *)langTitle {
    return LLang(@"安全与隐私");
}

- (void)securityPrivacyVMNeedReload:(WKSecurityPrivacyVM *)vm {
    [self reloadData];
}

@end

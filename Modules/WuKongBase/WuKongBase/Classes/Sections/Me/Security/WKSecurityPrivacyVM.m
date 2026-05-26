//
//  WKSecurityPrivacyVM.m
//  WuKongBase
//

#import "WKSecurityPrivacyVM.h"
#import "WKConversationPasswordVC.h"
#import "WKScreenPasswordSetVC.h"
#import "WKScreenPasswordVC.h"
#import "WKScreenPasswordSettingVC.h"
#import "WKDeviceLockVC.h"
#import "WKAccountDestroyVC.h"
#import "WKBlacklistVC.h"
#import "WKMySettingManager.h"

static NSString * const WKDisableScreenshotKey = @"security.disable_screenshot";

@implementation WKSecurityPrivacyVM

- (void)requestData:(void (^)(NSError * _Nullable))complete {
    [[WKMySettingManager shared] requestSetting].then(^{
        if (complete) {
            complete(nil);
        }
    }).catch(^(NSError *error) {
        if (complete) {
            complete(error);
        }
    });
}

- (NSArray<NSDictionary *> *)tableSectionMaps {
    __weak typeof(self) weakSelf = self;
    BOOL disableScreenshot = [[NSUserDefaults standardUserDefaults] boolForKey:WKDisableScreenshotKey];
    NSString *lockScreenPwd = [WKApp shared].loginInfo.extra[@"lock_screen_pwd"];
    NSString *deviceLockDesc = [WKMySettingManager shared].deviceLock ? LLang(@"已开启") : LLang(@"已关闭");
    return @[
        @{
            @"height":@(15.0f),
            @"title":LLang(@"可以通过以下方式搜索好友"),
            @"remark":LLang(@"关闭后，其他用户将不能通过上述信息搜索好友"),
            @"items":@[
                @{
                    @"class":WKSwitchItemModel.class,
                    @"label":LLang(@"允许手机号搜索"),
                    @"on":@([WKMySettingManager shared].searchByPhone),
                    @"onSwitch":^(BOOL on) {
                        [weakSelf updateSetting:[[WKMySettingManager shared] searchByPhone:on]];
                    }
                },
                @{
                    @"class":WKSwitchItemModel.class,
                    @"label":LLang(@"允许唐僧叨叨号搜索"),
                    @"on":@([WKMySettingManager shared].searchByShort),
                    @"onSwitch":^(BOOL on) {
                        [weakSelf updateSetting:[[WKMySettingManager shared] searchByShort:on]];
                    }
                },
            ],
        },
        @{
            @"height":@(15.0f),
            @"items":@[
                @{
                    @"class":WKLabelItemModel.class,
                    @"label":LLang(@"登录密码"),
                    @"onClick":^(WKFormItemModel *model, NSIndexPath *indexPath) {
                        if([WKApp.shared hasMethod:WKPOINT_LOGIN_RESET_PASSWORD]) {
                            [WKApp.shared invoke:WKPOINT_LOGIN_RESET_PASSWORD param:nil];
                        }else {
                            [[WKNavigationManager shared].topViewController.view showHUDWithHide:LLang(@"暂未开放")];
                        }
                    }
                },
                @{
                    @"class":WKLabelItemModel.class,
                    @"label":LLang(@"聊天密码"),
                    @"onClick":^(WKFormItemModel *model, NSIndexPath *indexPath) {
                        [[WKNavigationManager shared] pushViewController:[WKConversationPasswordVC new] animated:YES];
                    }
                },
            ],
        },
        @{
            @"height":@(15.0f),
            @"title":LLang(@"屏幕保护"),
            @"remark":LLang(@"开启后，系统截屏或录屏时将显示空白内容"),
            @"items":@[
                @{
                    @"class":WKLabelItemModel.class,
                    @"label":LLang(@"锁屏密码"),
                    @"onClick":^(WKFormItemModel *model, NSIndexPath *indexPath) {
                        if(lockScreenPwd && lockScreenPwd.length > 0) {
                            WKScreenPasswordVC *vc = [WKScreenPasswordVC new];
                            vc.allowBack = true;
                            vc.onFinished = ^(NSString * _Nonnull pwd) {
                                [[WKNavigationManager shared] replacePushViewController:[WKScreenPasswordSettingVC new] animated:YES];
                            };
                            [[WKNavigationManager shared] pushViewController:vc animated:YES];
                        }else {
                            [[WKNavigationManager shared] pushViewController:[WKScreenPasswordSetVC new] animated:YES];
                        }
                    }
                },
                @{
                    @"class":WKSwitchItemModel.class,
                    @"label":LLang(@"断网屏保"),
                    @"on":@([WKMySettingManager shared].offlineProtection),
                    @"onSwitch":^(BOOL on) {
                        [weakSelf updateSetting:[[WKMySettingManager shared] offlineProtection:on]];
                    }
                },
                @{
                    @"class":WKSwitchItemModel.class,
                    @"label":LLang(@"禁止截屏"),
                    @"on":@(disableScreenshot),
                    @"onSwitch":^(BOOL on) {
                        [[NSUserDefaults standardUserDefaults] setBool:on forKey:WKDisableScreenshotKey];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                        [[WKApp shared] updateScreenshotProtection];
                    }
                },
            ],
        },
        @{
            @"height":@(15.0f),
            @"items":@[
                @{
                    @"class":WKLabelItemModel.class,
                    @"label":LLang(@"设备锁"),
                    @"value":deviceLockDesc,
                    @"onClick":^(WKFormItemModel *model, NSIndexPath *indexPath) {
                        [[WKNavigationManager shared] pushViewController:[WKDeviceLockVC new] animated:YES];
                    }
                },
            ],
        },
        @{
            @"height":@(15.0f),
            @"items":@[
                @{
                    @"class":WKLabelItemModel.class,
                    @"label":LLang(@"黑名单"),
                    @"onClick":^(WKFormItemModel *model, NSIndexPath *indexPath) {
                        [[WKNavigationManager shared] pushViewController:[WKBlacklistVC new] animated:YES];
                    }
                },
                @{
                    @"class":WKLabelItemModel.class,
                    @"label":LLang(@"注销账号"),
                    @"onClick":^(WKFormItemModel *model, NSIndexPath *indexPath) {
                        [[WKNavigationManager shared] pushViewController:[WKAccountDestroyVC new] animated:YES];
                    }
                },
            ],
        },
    ];
}

- (void)updateSetting:(AnyPromise *)promise {
    __weak typeof(self) weakSelf = self;
    promise.then(^{
        if(weakSelf.delegate) {
            [weakSelf.delegate securityPrivacyVMNeedReload:weakSelf];
        }
    }).catch(^(NSError *error) {
        [[WKNavigationManager shared].topViewController.view showHUDWithHide:error.domain];
    });
}

@end

//
//  WKDeviceLockVM.m
//  WuKongBase
//

#import "WKDeviceLockVM.h"
#import "WKMySettingManager.h"

@implementation WKSecurityDeviceModel

+ (WKModel *)fromMap:(NSDictionary *)dictory type:(ModelMapType)type {
    WKSecurityDeviceModel *model = [WKSecurityDeviceModel new];
    model.deviceId = dictory[@"device_id"] ?: @"";
    model.deviceName = dictory[@"device_name"] ?: @"";
    model.deviceModel = dictory[@"device_model"] ?: @"";
    return model;
}

@end

@interface WKDeviceLockVM ()

@property(nonatomic,strong) NSArray<WKSecurityDeviceModel *> *devices;

@end

@implementation WKDeviceLockVM

- (void)requestData:(void (^)(NSError * _Nullable))complete {
    __weak typeof(self) weakSelf = self;
    [[WKMySettingManager shared] requestSetting].then(^{
        if([WKMySettingManager shared].deviceLock) {
            return [[WKAPIClient sharedClient] GET:@"user/devices" parameters:nil model:WKSecurityDeviceModel.class];
        }
        return [AnyPromise promiseWithValue:@[]];
    }).then(^(NSArray<WKSecurityDeviceModel *> *devices) {
        weakSelf.devices = devices ?: @[];
        if(complete) {
            complete(nil);
        }
    }).catch(^(NSError *error) {
        if(complete) {
            complete(error);
        }
    });
}

- (NSArray<NSDictionary *> *)tableSectionMaps {
    __weak typeof(self) weakSelf = self;
    NSMutableArray *sections = [NSMutableArray array];
    [sections addObject:@{
        @"height":@(15.0f),
        @"title":LLang(@"开启设备锁可以保障卿航IM账号安全。在未验证的设备上进行登录操作时，需要验证手机号，即使密码泄露他人也无法登录。"),
        @"items":@[
            @{
                @"class":WKSwitchItemModel.class,
                @"label":LLang(@"设备锁"),
                @"on":@([WKMySettingManager shared].deviceLock),
                @"onSwitch":^(BOOL on) {
                    [[WKMySettingManager shared] deviceLock:on].then(^{
                        if(on) {
                            [weakSelf reloadRemoteData];
                        }else {
                            weakSelf.devices = @[];
                            [weakSelf.delegate deviceLockVMNeedReload:weakSelf];
                        }
                    }).catch(^(NSError *error) {
                        [[WKNavigationManager shared].topViewController.view showHUDWithHide:error.domain];
                    });
                }
            },
        ],
    }];
    if([WKMySettingManager shared].deviceLock && self.devices.count > 0) {
        NSMutableArray *deviceItems = [NSMutableArray array];
        for (WKSecurityDeviceModel *device in self.devices) {
            NSString *name = device.deviceName.length > 0 ? device.deviceName : device.deviceModel;
            [deviceItems addObject:@{
                @"class":WKLabelItemModel.class,
                @"label":name ?: LLang(@"未知设备"),
                @"showArrow":@(NO),
            }];
        }
        [sections addObject:@{
            @"height":@(15.0f),
            @"title":LLang(@"登录过的设备列表"),
            @"items":deviceItems,
        }];
    }
    return sections;
}

@end

//
//  WKDeviceLockVC.m
//  WuKongBase
//

#import "WKDeviceLockVC.h"

@interface WKDeviceLockVC ()<WKDeviceLockVMDelegate>

@end

@implementation WKDeviceLockVC

- (instancetype)init {
    self = [super init];
    if (self) {
        self.viewModel = [WKDeviceLockVM new];
        self.viewModel.delegate = self;
    }
    return self;
}

- (NSString *)langTitle {
    return LLang(@"设备锁");
}

- (void)deviceLockVMNeedReload:(WKDeviceLockVM *)vm {
    [self reloadData];
}

@end

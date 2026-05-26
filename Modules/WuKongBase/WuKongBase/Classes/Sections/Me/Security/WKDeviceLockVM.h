//
//  WKDeviceLockVM.h
//  WuKongBase
//

#import <WuKongBase/WuKongBase.h>

NS_ASSUME_NONNULL_BEGIN

@class WKDeviceLockVM;

@protocol WKDeviceLockVMDelegate <NSObject>

- (void)deviceLockVMNeedReload:(WKDeviceLockVM *)vm;

@end

@interface WKSecurityDeviceModel : WKModel

@property(nonatomic,copy) NSString *deviceId;
@property(nonatomic,copy) NSString *deviceName;
@property(nonatomic,copy) NSString *deviceModel;

@end

@interface WKDeviceLockVM : WKBaseTableVM

@property(nonatomic,weak) id<WKDeviceLockVMDelegate> delegate;

@end

NS_ASSUME_NONNULL_END

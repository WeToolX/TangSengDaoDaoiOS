//
//  WKSecurityPrivacyVM.h
//  WuKongBase
//

#import <WuKongBase/WuKongBase.h>

NS_ASSUME_NONNULL_BEGIN

@class WKSecurityPrivacyVM;

@protocol WKSecurityPrivacyVMDelegate <NSObject>

- (void)securityPrivacyVMNeedReload:(WKSecurityPrivacyVM *)vm;

@end

@interface WKSecurityPrivacyVM : WKBaseTableVM

@property(nonatomic,weak) id<WKSecurityPrivacyVMDelegate> delegate;

@end

NS_ASSUME_NONNULL_END

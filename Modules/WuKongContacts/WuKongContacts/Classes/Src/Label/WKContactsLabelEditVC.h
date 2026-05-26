//
//  WKContactsLabelEditVC.h
//  WuKongContacts
//

#import <WuKongBase/WuKongBase.h>
#import "WKContactsLabelModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface WKContactsLabelEditVC : WKBaseVC

@property(nonatomic,copy) void(^onSaved)(void);
@property(nonatomic,weak) UIViewController *popToViewController;

-(instancetype)initWithSelectedUIDs:(NSArray<NSString*>*)uids;
-(instancetype)initWithLabel:(WKContactsLabel*)label;

@end

NS_ASSUME_NONNULL_END

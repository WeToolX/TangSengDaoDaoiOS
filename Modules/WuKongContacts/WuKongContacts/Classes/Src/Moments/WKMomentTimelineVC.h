//
//  WKMomentTimelineVC.h
//  WuKongContacts
//

#import <WuKongBase/WuKongBase.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKMomentTimelineVC : WKBaseVC
-(instancetype)initWithUID:(nullable NSString*)uid;
-(instancetype)initWithUID:(nullable NSString*)uid name:(nullable NSString*)name avatar:(nullable NSString*)avatar;
@end

NS_ASSUME_NONNULL_END

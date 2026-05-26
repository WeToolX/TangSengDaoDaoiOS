//
//  WKStickerStoreDetailVC.h
//  WuKongBase
//

#import "WKBaseVC.h"
#import "WKStickerStoreModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface WKStickerStoreDetailVC : WKBaseVC

@property(nonatomic,copy) void(^onChanged)(void);

-(instancetype)initWithPackage:(WKStickerStorePackage*)package;

@end

NS_ASSUME_NONNULL_END

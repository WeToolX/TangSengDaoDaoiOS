//
//  WKStickerStoreModel.h
//  WuKongBase
//

#import "WKModel.h"
#import "WKStickerPackage.h"
#import "WKStickerManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface WKStickerStorePackage : WKModel

@property(nonatomic,copy) NSString *packageId;
@property(nonatomic,copy) NSString *name;
@property(nonatomic,copy) NSString *icon;
@property(nonatomic,copy) NSString *cover;
@property(nonatomic,copy) NSString *desc;
@property(nonatomic,copy) NSString *tags;
@property(nonatomic,assign) NSInteger itemCount;
@property(nonatomic,assign) NSInteger sortNum;
@property(nonatomic,assign) NSInteger status;
@property(nonatomic,assign) BOOL added;

-(WKStickerUserCategoryResp*)toUserCategory;

@end

@interface WKStickerStoreItem : WKModel

@property(nonatomic,copy) NSString *itemId;
@property(nonatomic,copy) NSString *packageId;
@property(nonatomic,copy) NSString *name;
@property(nonatomic,copy) NSString *keyword;
@property(nonatomic,assign) NSInteger sortNum;
@property(nonatomic,copy) NSString *originURL;
@property(nonatomic,copy) NSString *gifURL;
@property(nonatomic,copy) NSString *thumbURL;
@property(nonatomic,copy) NSString *originExt;
@property(nonatomic,copy) NSString *sourceMediaType;
@property(nonatomic,assign) NSInteger width;
@property(nonatomic,assign) NSInteger height;

-(WKSticker*)toSticker;
-(NSString*)displayURL;

@end

@interface WKStickerStoreListItem : WKModel

@property(nonatomic,strong) WKStickerStorePackage *package;
@property(nonatomic,assign) BOOL added;

@end

NS_ASSUME_NONNULL_END

//
//  WKStickerStoreVM.h
//  WuKongBase
//

#import "WKBaseVM.h"
#import "WKStickerStoreModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface WKStickerStoreVM : WKBaseVM<WKStickerProvider>

-(AnyPromise*)storePackages:(NSString*_Nullable)keyword pageIndex:(NSInteger)pageIndex pageSize:(NSInteger)pageSize;
-(AnyPromise*)packageDetail:(NSString*)packageId;
-(AnyPromise*)myPackages;
-(AnyPromise*)addPackage:(NSString*)packageId;
-(AnyPromise*)removePackage:(NSString*)packageId;
-(AnyPromise*)reorderMyPackages:(NSArray<NSString*>*)packageIds;

@end

NS_ASSUME_NONNULL_END

//
//  WKStickerStoreVM.m
//  WuKongBase
//

#import "WKStickerStoreVM.h"
#import "WKAPIClient.h"

@implementation WKStickerStoreVM

-(AnyPromise*)storePackages:(NSString *)keyword pageIndex:(NSInteger)pageIndex pageSize:(NSInteger)pageSize {
    NSMutableDictionary *params = [@{
        @"page_index": @(pageIndex),
        @"page_size": @(pageSize),
    } mutableCopy];
    if(keyword.length > 0) {
        params[@"keyword"] = keyword;
    }
    return [[WKAPIClient sharedClient] GET:@"sticker/store/packages" parameters:params].then(^(NSDictionary *result) {
        NSArray *list = result[@"list"] ?: @[];
        NSMutableArray *items = [NSMutableArray array];
        for (NSDictionary *dict in list) {
            [items addObject:(WKStickerStoreListItem*)[WKStickerStoreListItem fromMap:dict type:ModelMapTypeAPI]];
        }
        return items;
    });
}

-(AnyPromise*)packageDetail:(NSString *)packageId {
    return [[WKAPIClient sharedClient] GET:[NSString stringWithFormat:@"sticker/store/packages/%@",packageId ?: @""] parameters:nil].then(^(NSDictionary *result) {
        WKStickerStorePackage *package = (WKStickerStorePackage*)[WKStickerStorePackage fromMap:result[@"package"] ?: @{} type:ModelMapTypeAPI];
        NSMutableArray *items = [NSMutableArray array];
        for (NSDictionary *dict in result[@"items"] ?: @[]) {
            [items addObject:(WKStickerStoreItem*)[WKStickerStoreItem fromMap:dict type:ModelMapTypeAPI]];
        }
        return PMKManifold(package, items);
    });
}

-(AnyPromise*)myPackages {
    return [[WKAPIClient sharedClient] GET:@"sticker/my/packages" parameters:nil].then(^(NSArray *result) {
        NSMutableArray *packages = [NSMutableArray array];
        for (NSDictionary *dict in result ?: @[]) {
            WKStickerStorePackage *package = (WKStickerStorePackage*)[WKStickerStorePackage fromMap:dict[@"package"] ?: @{} type:ModelMapTypeAPI];
            package.sortNum = [dict[@"sort_num"] integerValue];
            package.added = YES;
            [packages addObject:package];
        }
        return packages;
    });
}

-(AnyPromise*)addPackage:(NSString *)packageId {
    return [[WKAPIClient sharedClient] POST:[NSString stringWithFormat:@"sticker/store/packages/%@/add",packageId ?: @""] parameters:nil];
}

-(AnyPromise*)removePackage:(NSString *)packageId {
    return [[WKAPIClient sharedClient] DELETE:[NSString stringWithFormat:@"sticker/store/packages/%@/add",packageId ?: @""] parameters:nil];
}

-(AnyPromise*)reorderMyPackages:(NSArray<NSString *> *)packageIds {
    return [[WKAPIClient sharedClient] PUT:@"sticker/my/packages/reorder" parameters:@{@"ids": packageIds ?: @[]}];
}

#pragma mark - WKStickerProvider

-(void)requestUserCategory:(void (^)(NSArray<WKStickerUserCategoryResp *> * _Nonnull, NSError * _Nullable))callback {
    [self myPackages].then(^(NSArray<WKStickerStorePackage*> *packages) {
        NSMutableArray *items = [NSMutableArray array];
        for (WKStickerStorePackage *package in packages) {
            [items addObject:[package toUserCategory]];
        }
        if(callback) {
            callback(items, nil);
        }
    }).catch(^(NSError *error) {
        if(callback) {
            callback(@[], error);
        }
    });
}

-(void)requestAddStickerCategory:(NSString *)category callback:(void (^)(NSError * _Nullable))callback {
    [self addPackage:category].then(^{
        if(callback) {
            callback(nil);
        }
    }).catch(^(NSError *error) {
        if(callback) {
            callback(error);
        }
    });
}

-(void)requestRemoveStickerCategory:(NSString *)category callback:(void (^)(NSError * _Nullable))callback {
    [self removePackage:category].then(^{
        if(callback) {
            callback(nil);
        }
    }).catch(^(NSError *error) {
        if(callback) {
            callback(error);
        }
    });
}

@end

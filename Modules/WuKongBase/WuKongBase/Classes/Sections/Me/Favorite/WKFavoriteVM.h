//
//  WKFavoriteVM.h
//  WuKongBase
//

#import <Foundation/Foundation.h>
#import <PromiseKit/PromiseKit.h>
#import "WKFavoriteItem.h"

NS_ASSUME_NONNULL_BEGIN

@class WKMessageModel;

@interface WKFavoriteVM : NSObject

-(AnyPromise*)favoritesWithPage:(NSInteger)page limit:(NSInteger)limit type:(NSString*)type;
-(AnyPromise*)toggleFavorite:(WKMessageModel*)message;
-(AnyPromise*)deleteFavorite:(WKFavoriteItem*)item;

@end

NS_ASSUME_NONNULL_END

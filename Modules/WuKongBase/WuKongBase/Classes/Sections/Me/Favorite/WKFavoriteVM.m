//
//  WKFavoriteVM.m
//  WuKongBase
//

#import "WKFavoriteVM.h"
#import "WKAPIClient.h"
#import "WKMessageModel.h"

@implementation WKFavoriteVM

-(AnyPromise*)favoritesWithPage:(NSInteger)page limit:(NSInteger)limit type:(NSString*)type {
    return [[WKAPIClient sharedClient] GET:@"message/favorite/list" parameters:@{
        @"page": @(MAX(page, 1)),
        @"limit": @(MAX(limit, 1)),
        @"type": type.length > 0 ? type : @"all",
    }].then(^id(NSDictionary *result) {
        NSArray *list = result[@"list"] ?: @[];
        NSMutableArray *items = [NSMutableArray array];
        for (NSDictionary *dict in list) {
            if([dict isKindOfClass:NSDictionary.class]) {
                [items addObject:[WKFavoriteItem fromMap:dict]];
            }
        }
        return items;
    });
}

-(AnyPromise*)toggleFavorite:(WKMessageModel*)message {
    if(!message || message.messageId == 0 || message.messageSeq == 0 || message.channel.channelId.length == 0) {
        return [AnyPromise promiseWithValue:@{@"is_favorite":@(0)}];
    }
    return [[WKAPIClient sharedClient] POST:@"message/favorite" parameters:@{
        @"message_id": [NSString stringWithFormat:@"%llu",message.messageId],
        @"message_seq": @(message.messageSeq),
        @"channel_id": message.channel.channelId ?: @"",
        @"channel_type": @(message.channel.channelType),
    }];
}

-(AnyPromise*)deleteFavorite:(WKFavoriteItem*)item {
    if(!item) {
        return [AnyPromise promiseWithValue:nil];
    }
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    if(item.favoriteId > 0) {
        params[@"ids"] = @[@(item.favoriteId)];
    }
    if(item.messageId.length > 0) {
        params[@"message_ids"] = @[item.messageId];
    }
    if(params.count == 0) {
        return [AnyPromise promiseWithValue:nil];
    }
    return [[WKAPIClient sharedClient] DELETE:@"message/favorite" parameters:params];
}

@end

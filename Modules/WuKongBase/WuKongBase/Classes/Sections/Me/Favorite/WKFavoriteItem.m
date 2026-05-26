//
//  WKFavoriteItem.m
//  WuKongBase
//

#import "WKFavoriteItem.h"
#import "WKMessageDB.h"

static NSString *WKFavString(id value) {
    if(!value || value == [NSNull null]) {
        return @"";
    }
    if([value isKindOfClass:NSString.class]) {
        return value;
    }
    return [NSString stringWithFormat:@"%@",value];
}

static NSInteger WKFavInteger(id value) {
    if(!value || value == [NSNull null]) {
        return 0;
    }
    return [value integerValue];
}

@implementation WKFavoriteItem

+(instancetype)fromMap:(NSDictionary *)dict {
    WKFavoriteItem *item = [WKFavoriteItem new];
    item.favoriteId = WKFavInteger(dict[@"id"]);
    item.messageId = WKFavString(dict[@"message_id"]);
    item.messageSeq = (uint32_t)WKFavInteger(dict[@"message_seq"]);
    item.channelId = WKFavString(dict[@"channel_id"]);
    item.channelType = WKFavInteger(dict[@"channel_type"]);
    item.author = WKFavString(dict[@"author"]);
    item.nickname = WKFavString(dict[@"nickname"]);
    item.messageType = WKFavInteger(dict[@"message_type"]);
    item.content = WKFavString(dict[@"content"]);
    item.imageURL = WKFavString(dict[@"image_url"]);
    item.createdAt = WKFavString(dict[@"created_at"]);
    item.updatedAt = WKFavString(dict[@"updated_at"]);
    [item fillSnapshotFromLocalMessageIfNeeded];
    return item;
}

-(BOOL)isImage {
    return self.messageType == WK_IMAGE || self.imageURL.length > 0;
}

-(WKMessageContent*)toMessageContent {
    if([self isImage]) {
        WKImageContent *imageContent = [WKImageContent new];
        imageContent.remoteUrl = self.imageURL ?: @"";
        return imageContent;
    }
    return [[WKTextContent alloc] initWithContent:self.content ?: @""];
}

-(void)fillSnapshotFromLocalMessageIfNeeded {
    BOOL needImageURL = [self isImage] && self.imageURL.length == 0;
    BOOL needText = self.messageType == WK_TEXT && self.content.length == 0;
    if(!needImageURL && !needText) {
        return;
    }
    
    WKMessage *message = nil;
    if(self.messageId.length > 0) {
        message = [[WKMessageDB shared] getMessageWithMessageId:(uint64_t)strtoull(self.messageId.UTF8String, NULL, 10)];
    }
    if(!message && self.channelId.length > 0 && self.messageSeq > 0) {
        message = [[WKMessageDB shared] getMessage:[[WKChannel alloc] initWith:self.channelId channelType:(uint8_t)self.channelType] messageSeq:self.messageSeq];
    }
    if(!message) {
        return;
    }
    
    if(needImageURL && message.contentType == WK_IMAGE && [message.content isKindOfClass:WKImageContent.class]) {
        WKImageContent *imageContent = (WKImageContent*)message.content;
        self.imageURL = imageContent.remoteUrl ?: @"";
    }else if(needText && message.contentType == WK_TEXT && [message.content isKindOfClass:WKTextContent.class]) {
        WKTextContent *textContent = (WKTextContent*)message.content;
        self.content = textContent.content ?: @"";
    }
}

@end

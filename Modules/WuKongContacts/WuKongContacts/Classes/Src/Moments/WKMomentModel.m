//
//  WKMomentModel.m
//  WuKongContacts
//

#import "WKMomentModel.h"

static id WKMomentValue(NSDictionary *dict, NSArray<NSString*> *keys) {
    if(![dict isKindOfClass:NSDictionary.class]) {
        return nil;
    }
    for(NSString *key in keys) {
        id value = dict[key];
        if(value && value != NSNull.null) {
            return value;
        }
    }
    return nil;
}

static NSString *WKMomentString(NSDictionary *dict, NSArray<NSString*> *keys) {
    id value = WKMomentValue(dict, keys);
    if(!value || value == NSNull.null) {
        return @"";
    }
    if([value isKindOfClass:NSString.class]) {
        return value;
    }
    return [NSString stringWithFormat:@"%@",value];
}

static NSInteger WKMomentInteger(NSDictionary *dict, NSArray<NSString*> *keys) {
    id value = WKMomentValue(dict, keys);
    return value && value != NSNull.null ? [value integerValue] : 0;
}

static BOOL WKMomentBool(NSDictionary *dict, NSArray<NSString*> *keys) {
    return WKMomentInteger(dict, keys) == 1;
}

@implementation WKMomentActor
+(WKMomentActor*)fromMap:(NSDictionary*)dictory type:(ModelMapType)type {
    WKMomentActor *actor = [WKMomentActor new];
    actor.uid = WKMomentString(dictory, @[@"uid",@"UID",@"user_id",@"UserID"]);
    actor.name = WKMomentString(dictory, @[@"name",@"Name",@"display_name",@"DisplayName"]);
    actor.avatar = WKMomentString(dictory, @[@"avatar",@"Avatar"]);
    actor.cover = WKMomentString(dictory, @[@"cover",@"Cover"]);
    return actor;
}
@end

@implementation WKMomentMedia
+(WKMomentMedia*)fromMap:(NSDictionary*)dictory type:(ModelMapType)type {
    WKMomentMedia *media = [WKMomentMedia new];
    media.mediaType = WKMomentString(dictory, @[@"media_type",@"MediaType",@"type",@"Type"]);
    media.mediaURL = WKMomentString(dictory, @[@"media_url",@"MediaURL",@"url",@"URL"]);
    media.coverURL = WKMomentString(dictory, @[@"cover_url",@"CoverURL",@"cover",@"Cover"]);
    media.width = WKMomentInteger(dictory, @[@"width",@"Width"]);
    media.height = WKMomentInteger(dictory, @[@"height",@"Height"]);
    media.duration = WKMomentInteger(dictory, @[@"duration",@"Duration"]);
    media.size = WKMomentInteger(dictory, @[@"size",@"Size"]);
    media.sortIndex = WKMomentInteger(dictory, @[@"sort_index",@"SortIndex"]);
    return media;
}
@end

@implementation WKMomentComment
+(WKMomentComment*)fromMap:(NSDictionary*)dictory type:(ModelMapType)type {
    WKMomentComment *comment = [WKMomentComment new];
    comment.commentId = WKMomentString(dictory, @[@"comment_id",@"CommentID",@"id",@"Id"]);
    comment.content = WKMomentString(dictory, @[@"content",@"Content"]);
    NSDictionary *userDict = WKMomentValue(dictory, @[@"user",@"User"]);
    if([userDict isKindOfClass:NSDictionary.class]) {
        comment.user = (WKMomentActor*)[WKMomentActor fromMap:userDict type:type];
    }
    comment.replyCommentId = WKMomentString(dictory, @[@"reply_comment_id",@"ReplyCommentID"]);
    comment.replyUid = WKMomentString(dictory, @[@"reply_uid",@"ReplyUID"]);
    comment.replyName = WKMomentString(dictory, @[@"reply_name",@"ReplyName"]);
    comment.canDelete = WKMomentBool(dictory, @[@"can_delete",@"CanDelete"]);
    comment.createdAt = WKMomentString(dictory, @[@"created_at",@"CreatedAt"]);
    return comment;
}
@end

@implementation WKMomentPost
+(WKMomentPost*)fromMap:(NSDictionary*)dictory type:(ModelMapType)type {
    WKMomentPost *post = [WKMomentPost new];
    post.postId = WKMomentString(dictory, @[@"post_id",@"PostID",@"id",@"Id"]);
    post.text = WKMomentString(dictory, @[@"text",@"Text",@"content",@"Content"]);
    NSDictionary *userDict = WKMomentValue(dictory, @[@"user",@"User"]);
    if([userDict isKindOfClass:NSDictionary.class]) {
        post.user = (WKMomentActor*)[WKMomentActor fromMap:userDict type:type];
    }
    post.visibilityType = WKMomentString(dictory, @[@"visibility_type",@"VisibilityType"]);
    post.locationName = WKMomentString(dictory, @[@"location_name",@"LocationName"]);
    post.locationAddress = WKMomentString(dictory, @[@"location_address",@"LocationAddress"]);
    post.canDelete = WKMomentBool(dictory, @[@"can_delete",@"CanDelete"]);
    post.likedByMe = WKMomentBool(dictory, @[@"liked_by_me",@"LikedByMe"]);
    post.createdAt = WKMomentString(dictory, @[@"created_at",@"CreatedAt"]);
    post.medias = [NSMutableArray array];
    for(NSDictionary *item in (NSArray*)WKMomentValue(dictory, @[@"medias",@"Medias"]) ?: @[]) {
        if([item isKindOfClass:NSDictionary.class]) {
            [post.medias addObject:(WKMomentMedia*)[WKMomentMedia fromMap:item type:type]];
        }
    }
    post.likes = [NSMutableArray array];
    for(NSDictionary *item in (NSArray*)WKMomentValue(dictory, @[@"likes",@"Likes"]) ?: @[]) {
        if([item isKindOfClass:NSDictionary.class]) {
            [post.likes addObject:(WKMomentActor*)[WKMomentActor fromMap:item type:type]];
        }
    }
    post.comments = [NSMutableArray array];
    for(NSDictionary *item in (NSArray*)WKMomentValue(dictory, @[@"comments",@"Comments"]) ?: @[]) {
        if([item isKindOfClass:NSDictionary.class]) {
            [post.comments addObject:(WKMomentComment*)[WKMomentComment fromMap:item type:type]];
        }
    }
    post.mentions = [NSMutableArray array];
    return post;
}

+(NSArray<WKMomentPost*>*)postsFromResult:(id)result {
    NSArray *list = nil;
    if([result isKindOfClass:NSArray.class]) {
        list = result;
    }else if([result isKindOfClass:NSDictionary.class]) {
        list = WKMomentValue(result, @[@"list",@"items",@"moments",@"data"]);
    }
    NSMutableArray *posts = [NSMutableArray array];
    for(NSDictionary *dict in list ?: @[]) {
        if([dict isKindOfClass:NSDictionary.class]) {
            [posts addObject:[WKMomentPost fromMap:dict type:ModelMapTypeAPI]];
        }
    }
    return posts;
}
@end

@implementation WKMomentProfile
+(WKMomentProfile*)fromMap:(NSDictionary*)dictory type:(ModelMapType)type {
    WKMomentProfile *profile = [WKMomentProfile new];
    profile.uid = WKMomentString(dictory, @[@"uid",@"UID"]);
    profile.cover = WKMomentString(dictory, @[@"cover",@"Cover"]);
    profile.version = WKMomentInteger(dictory, @[@"version",@"Version"]);
    return profile;
}
@end

@implementation WKMomentNotice
+(WKMomentNotice*)fromMap:(NSDictionary*)dictory type:(ModelMapType)type {
    WKMomentNotice *notice = [WKMomentNotice new];
    notice.noticeId = WKMomentInteger(dictory, @[@"id",@"Id"]);
    notice.noticeType = WKMomentString(dictory, @[@"notice_type",@"NoticeType",@"type",@"Type"]);
    notice.read = WKMomentBool(dictory, @[@"is_read",@"IsRead"]);
    notice.version = WKMomentInteger(dictory, @[@"version",@"Version"]);
    NSDictionary *fromUser = WKMomentValue(dictory, @[@"from_user",@"FromUser"]);
    if([fromUser isKindOfClass:NSDictionary.class]) {
        notice.fromUser = (WKMomentActor*)[WKMomentActor fromMap:fromUser type:type];
    }
    notice.postId = WKMomentString(dictory, @[@"post_id",@"PostID"]);
    notice.commentId = WKMomentString(dictory, @[@"comment_id",@"CommentID"]);
    notice.content = WKMomentString(dictory, @[@"content",@"Content",@"comment_content",@"CommentContent"]);
    notice.postText = WKMomentString(dictory, @[@"post_text",@"PostText",@"moment_text",@"MomentText",@"text",@"Text"]);
    notice.postCover = WKMomentString(dictory, @[@"post_cover",@"PostCover",@"cover",@"Cover",@"media_cover",@"MediaCover"]);
    notice.createdAt = WKMomentString(dictory, @[@"created_at",@"CreatedAt"]);
    return notice;
}

+(NSArray<WKMomentNotice*>*)noticesFromResult:(id)result {
    NSArray *list = [result isKindOfClass:NSArray.class] ? result : @[];
    NSMutableArray *items = [NSMutableArray array];
    for(NSDictionary *dict in list) {
        if([dict isKindOfClass:NSDictionary.class]) {
            [items addObject:[WKMomentNotice fromMap:dict type:ModelMapTypeAPI]];
        }
    }
    return items;
}
@end

@implementation WKMomentPublishMedia
@end

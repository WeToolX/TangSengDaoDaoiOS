//
//  WKMomentVM.m
//  WuKongContacts
//

#import "WKMomentVM.h"
#import <WuKongBase/WKAPIClient.h>

@implementation WKMomentVM

-(AnyPromise*)timelineWithPageIndex:(NSInteger)pageIndex pageSize:(NSInteger)pageSize {
    return [[WKAPIClient sharedClient] GET:@"moment/feed" parameters:@{@"page_index":@(pageIndex),@"page_size":@(pageSize)}].then(^id(id result) {
        return [WKMomentPost postsFromResult:result];
    });
}

-(AnyPromise*)userTimeline:(NSString*)uid pageIndex:(NSInteger)pageIndex pageSize:(NSInteger)pageSize {
    return [[WKAPIClient sharedClient] GET:[NSString stringWithFormat:@"users/%@/moments",uid ?: @""] parameters:@{@"page_index":@(pageIndex),@"page_size":@(pageSize)}].then(^id(id result) {
        return [WKMomentPost postsFromResult:result];
    });
}

-(AnyPromise*)profile:(NSString*)uid {
    return [[WKAPIClient sharedClient] GET:[NSString stringWithFormat:@"moment/profile/%@",uid ?: @""] parameters:nil].then(^id(NSDictionary *result) {
        return [WKMomentProfile fromMap:result type:ModelMapTypeAPI];
    });
}

-(AnyPromise*)setCover:(NSString*)cover {
    return [[WKAPIClient sharedClient] PUT:@"moment/profile/cover" parameters:@{@"cover":cover ?: @""}];
}

-(AnyPromise*)publishText:(NSString*)text imagePaths:(NSArray<NSString*>*)imagePaths video:(WKMomentPublishMedia*)video mention:(NSDictionary*)mention visibility:(NSDictionary*)visibility {
    NSMutableArray *images = [NSMutableArray array];
    NSInteger index = 0;
    for(NSString *path in imagePaths ?: @[]) {
        [images addObject:@{@"media_url":path ?: @"",@"width":@(0),@"height":@(0),@"size":@(0),@"sort_index":@(index++)}];
    }
    NSMutableDictionary *params = [@{
        @"text": text ?: @"",
        @"images": images,
        @"visibility": visibility ?: @{@"type":@"public",@"uids":@[],@"tag_ids":@[]},
        @"mention": mention ?: @{@"uids":@[],@"tag_ids":@[]},
        @"client_req_id": [NSString stringWithFormat:@"ios_moment_%lld",(long long)(NSDate.date.timeIntervalSince1970 * 1000)]
    } mutableCopy];
    if(video.mediaURL.length > 0) {
        params[@"video"] = @{
            @"media_url": video.mediaURL ?: @"",
            @"cover_url": video.coverURL ?: @"",
            @"width": @(video.width),
            @"height": @(video.height),
            @"duration": @(video.duration),
            @"size": @(video.size),
        };
    }
    return [[WKAPIClient sharedClient] POST:@"moment/publish" parameters:params];
}

-(AnyPromise*)toggleLike:(NSString*)postId {
    return [[WKAPIClient sharedClient] POST:[NSString stringWithFormat:@"moment/posts/%@/like",postId ?: @""] parameters:nil];
}

-(AnyPromise*)addComment:(NSString*)postId content:(NSString*)content replyCommentId:(NSString*)replyCommentId {
    NSMutableDictionary *params = [@{@"content":content ?: @""} mutableCopy];
    if(replyCommentId.length > 0) {
        params[@"reply_comment_id"] = replyCommentId;
    }
    return [[WKAPIClient sharedClient] POST:[NSString stringWithFormat:@"moment/posts/%@/comments",postId ?: @""] parameters:params];
}

-(AnyPromise*)deleteComment:(NSString*)postId commentId:(NSString*)commentId {
    return [[WKAPIClient sharedClient] DELETE:[NSString stringWithFormat:@"moment/posts/%@/comments/%@",postId ?: @"",commentId ?: @""] parameters:nil];
}

-(AnyPromise*)deletePost:(NSString*)postId {
    return [[WKAPIClient sharedClient] DELETE:[NSString stringWithFormat:@"moment/posts/%@",postId ?: @""] parameters:nil];
}

-(AnyPromise*)syncNoticesWithVersion:(NSInteger)version limit:(NSInteger)limit {
    return [[WKAPIClient sharedClient] GET:@"moment/notices/sync" parameters:@{@"version":@(version),@"limit":@(limit)}].then(^id(id result) {
        return [WKMomentNotice noticesFromResult:result];
    });
}

-(AnyPromise*)readNotices:(NSArray<NSNumber*>*)ids readAll:(BOOL)readAll {
    return [[WKAPIClient sharedClient] POST:@"moment/notices/read" parameters:@{@"ids":ids ?: @[],@"read_all":@(readAll ? 1 : 0)}];
}

-(void)uploadImageData:(NSData*)data type:(NSString*)type completion:(void(^)(NSString * _Nullable path, NSError * _Nullable error))completion {
    NSString *uploadType = type.length > 0 ? type : @"moment";
    [[WKAPIClient sharedClient] GET:[NSString stringWithFormat:@"file/upload?type=%@",uploadType] parameters:nil].then(^(NSDictionary *result) {
        NSString *url = result[@"url"];
        if(url.length == 0) {
            if(completion) {
                completion(nil,[NSError errorWithDomain:LLang(@"上传地址为空") code:-1 userInfo:nil]);
            }
            return;
        }
        [[WKAPIClient sharedClient] fileUpload:url data:data fileName:@"moment.jpg" progress:nil completeCallback:^(id  _Nullable resposeObject, NSError * _Nullable error) {
            if(error) {
                if(completion) completion(nil,error);
                return;
            }
            NSString *path = [resposeObject isKindOfClass:NSDictionary.class] ? resposeObject[@"path"] : nil;
            if(completion) completion(path,nil);
        }];
    }).catch(^(NSError *error) {
        if(completion) {
            completion(nil,error);
        }
    });
}

-(void)uploadFilePath:(NSString*)filePath type:(NSString*)type completion:(void(^)(NSString * _Nullable path, NSError * _Nullable error))completion {
    NSString *uploadType = type.length > 0 ? type : @"moment";
    [[WKAPIClient sharedClient] GET:[NSString stringWithFormat:@"file/upload?type=%@",uploadType] parameters:nil].then(^(NSDictionary *result) {
        NSString *url = result[@"url"];
        if(url.length == 0) {
            if(completion) completion(nil,[NSError errorWithDomain:LLang(@"上传地址为空") code:-1 userInfo:nil]);
            return;
        }
        [[WKAPIClient sharedClient] fileUpload:url fileURL:[NSURL fileURLWithPath:filePath].absoluteString progress:nil completeCallback:^(id  _Nullable resposeObject, NSError * _Nullable error) {
            NSString *path = [resposeObject isKindOfClass:NSDictionary.class] ? resposeObject[@"path"] : nil;
            if(completion) completion(path,error);
        }];
    }).catch(^(NSError *error) {
        if(completion) completion(nil,error);
    });
}

@end

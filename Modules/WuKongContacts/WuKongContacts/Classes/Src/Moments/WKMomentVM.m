//
//  WKMomentVM.m
//  WuKongContacts
//

#import "WKMomentVM.h"
#import <WuKongBase/WKAPIClient.h>

static NSString *WKMomentImageExtension(NSData *data) {
    if(data.length >= 4) {
        const unsigned char *bytes = data.bytes;
        if(bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) return @"jpg";
        if(bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) return @"png";
        if(bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) return @"gif";
        if(data.length >= 12 && bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 && bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50) return @"webp";
    }
    return @"jpg";
}

static NSString *WKMomentMimeType(NSString *extension) {
    NSString *ext = extension.lowercaseString;
    if([ext isEqualToString:@"png"]) return @"image/png";
    if([ext isEqualToString:@"gif"]) return @"image/gif";
    if([ext isEqualToString:@"webp"]) return @"image/webp";
    if([ext isEqualToString:@"mov"]) return @"video/quicktime";
    if([ext isEqualToString:@"m4v"]) return @"video/x-m4v";
    if([ext isEqualToString:@"mp4"]) return @"video/mp4";
    return @"image/jpeg";
}

static NSError *WKMomentUploadPathError(NSString *message) {
    return [NSError errorWithDomain:message code:-1 userInfo:nil];
}

@implementation WKMomentVM

-(NSString*)uploadURLPathForType:(NSString*)type extension:(NSString*)extension {
    NSString *uploadType = type.length > 0 ? type : @"moment";
    NSString *uid = WKApp.shared.loginInfo.uid ?: @"";
    NSString *ext = extension.length > 0 ? extension : @"jpg";
    if([uploadType isEqualToString:@"momentcover"]) {
        NSString *path = [NSString stringWithFormat:@"/%@/%@.%@", uid, NSUUID.UUID.UUIDString.lowercaseString, ext];
        NSString *encodedPath = [path stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet] ?: path;
        return [NSString stringWithFormat:@"file/upload?type=%@&path=%@", uploadType, encodedPath];
    }
    if(![uploadType isEqualToString:@"moment"]) {
        return [NSString stringWithFormat:@"file/upload?type=%@", uploadType];
    }
    NSString *path = [NSString stringWithFormat:@"/%@/%@.%@", uid, NSUUID.UUID.UUIDString.lowercaseString, ext];
    NSString *encodedPath = [path stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet] ?: path;
    return [NSString stringWithFormat:@"file/upload?type=%@&path=%@", uploadType, encodedPath];
}

-(AnyPromise*)timelineWithPageIndex:(NSInteger)pageIndex pageSize:(NSInteger)pageSize {
    return [[WKAPIClient sharedClient] GET:@"moment/feed" parameters:@{@"page_index":@(pageIndex),@"page_size":@(pageSize)}].then(^id(id result) {
        return [WKMomentPost postsFromResult:result];
    });
}

-(AnyPromise*)userTimeline:(NSString*)uid pageIndex:(NSInteger)pageIndex pageSize:(NSInteger)pageSize {
    return [[WKAPIClient sharedClient] GET:[NSString stringWithFormat:@"moment/feed/%@",uid ?: @""] parameters:@{@"page_index":@(pageIndex),@"page_size":@(pageSize)}].then(^id(id result) {
        return [WKMomentPost postsFromResult:result];
    });
}

-(AnyPromise*)detail:(NSString*)postId {
    return [[WKAPIClient sharedClient] GET:[NSString stringWithFormat:@"moment/posts/%@",postId ?: @""] parameters:nil].then(^id(NSDictionary *result) {
        return [WKMomentPost fromMap:result type:ModelMapTypeAPI];
    });
}

-(AnyPromise*)profile:(NSString*)uid {
    return [[WKAPIClient sharedClient] GET:[NSString stringWithFormat:@"moment/profile/%@",uid ?: @""] parameters:nil].then(^id(NSDictionary *result) {
        return [WKMomentProfile fromMap:result type:ModelMapTypeAPI];
    });
}

-(AnyPromise*)userState:(NSString*)uid {
    return [[WKAPIClient sharedClient] GET:[NSString stringWithFormat:@"moment/setting/%@",uid ?: @""] parameters:nil].then(^id(NSDictionary *result) {
        return [WKMomentUserState fromMap:result type:ModelMapTypeAPI];
    });
}

-(AnyPromise*)setCover:(NSString*)cover {
    return [[WKAPIClient sharedClient] PUT:@"moment/profile/cover" parameters:@{@"cover":cover ?: @""}];
}

-(AnyPromise*)publishText:(NSString*)text imagePaths:(NSArray<NSString*>*)imagePaths imageDatas:(NSArray<NSData*>*)imageDatas video:(WKMomentPublishMedia*)video mention:(NSDictionary*)mention visibility:(NSDictionary*)visibility clientReqID:(NSString*)clientReqID {
    NSMutableArray *images = [NSMutableArray array];
    NSInteger index = 1;
    for(NSString *path in imagePaths ?: @[]) {
        NSData *data = index - 1 < imageDatas.count ? imageDatas[index - 1] : nil;
        UIImage *image = data.length > 0 ? [UIImage imageWithData:data] : nil;
        NSInteger width = image.CGImage ? CGImageGetWidth(image.CGImage) : 0;
        NSInteger height = image.CGImage ? CGImageGetHeight(image.CGImage) : 0;
        [images addObject:@{@"media_url":path ?: @"",@"width":@(width),@"height":@(height),@"size":@(data.length),@"sort_index":@(index++)}];
    }
    NSString *requestID = clientReqID.length > 0 ? clientReqID : [NSString stringWithFormat:@"ios_moment_%@",NSUUID.UUID.UUIDString.lowercaseString];
    NSMutableDictionary *params = [@{
        @"text": text ?: @"",
        @"images": images,
        @"visibility": visibility ?: @{@"type":@"public",@"uids":@[],@"tag_ids":@[]},
        @"mention": mention ?: @{@"uids":@[],@"tag_ids":@[]},
        @"client_req_id": requestID
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
    NSString *extension = WKMomentImageExtension(data);
    NSString *mimeType = WKMomentMimeType(extension);
    NSData *uploadData = data;
    UIImage *image = [UIImage imageWithData:data];
    if(!image) {
        if(completion) completion(nil,WKMomentUploadPathError(LLang(@"图片数据无效")));
        return;
    }
    if([extension isEqualToString:@"jpg"] && data.length >= 3) {
        const unsigned char *bytes = data.bytes;
        if(!(bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF)) {
            uploadData = UIImageJPEGRepresentation(image, 0.9f);
            extension = @"jpg";
            mimeType = @"image/jpeg";
        }
    }
    [[WKAPIClient sharedClient] GET:[self uploadURLPathForType:uploadType extension:extension] parameters:nil].then(^(NSDictionary *result) {
        NSString *url = result[@"url"];
        if(url.length == 0) {
            if(completion) {
                completion(nil,[NSError errorWithDomain:LLang(@"上传地址为空") code:-1 userInfo:nil]);
            }
            return;
        }
        NSString *fileName = [NSString stringWithFormat:@"moment.%@",extension];
        [[WKAPIClient sharedClient] fileUpload:url data:uploadData fileName:fileName mimeType:mimeType progress:nil completeCallback:^(id  _Nullable resposeObject, NSError * _Nullable error) {
            if(error) {
                if(completion) completion(nil,error);
                return;
            }
            NSString *path = [resposeObject isKindOfClass:NSDictionary.class] ? resposeObject[@"path"] : nil;
            NSString *prefix = [uploadType isEqualToString:@"momentcover"] ? @"file/preview/momentcover/" : @"file/preview/moment/";
            if(path.length == 0 || ![path hasPrefix:prefix]) {
                if(completion) completion(nil,WKMomentUploadPathError(LLang(@"上传路径无效")));
                return;
            }
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
    NSString *ext = filePath.pathExtension.length > 0 ? filePath.pathExtension : @"mp4";
    [[WKAPIClient sharedClient] GET:[self uploadURLPathForType:uploadType extension:ext] parameters:nil].then(^(NSDictionary *result) {
        NSString *url = result[@"url"];
        if(url.length == 0) {
            if(completion) completion(nil,[NSError errorWithDomain:LLang(@"上传地址为空") code:-1 userInfo:nil]);
            return;
        }
        NSString *mimeType = WKMomentMimeType(ext);
        [[WKAPIClient sharedClient] fileUpload:url fileURL:[NSURL fileURLWithPath:filePath].absoluteString fileName:filePath.lastPathComponent mimeType:mimeType progress:nil completeCallback:^(id  _Nullable resposeObject, NSError * _Nullable error) {
            if(error) {
                if(completion) completion(nil,error);
                return;
            }
            NSString *path = [resposeObject isKindOfClass:NSDictionary.class] ? resposeObject[@"path"] : nil;
            if(path.length == 0 || ![path hasPrefix:@"file/preview/moment/"]) {
                if(completion) completion(nil,WKMomentUploadPathError(LLang(@"上传路径无效")));
                return;
            }
            if(completion) completion(path,nil);
        }];
    }).catch(^(NSError *error) {
        if(completion) completion(nil,error);
    });
}

@end

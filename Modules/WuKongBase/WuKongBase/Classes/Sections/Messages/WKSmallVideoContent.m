//
//  WKSmallVideoContent.m
//  WuKongBase
//

#import "WKSmallVideoContent.h"
#import "WuKongBase.h"
#import "WKVideoRecordUtil.h"
#import <AVFoundation/AVFoundation.h>
#import <WuKongIMSDK/WKFileUtil.h>

@interface WKSmallVideoContent ()
@property(nonatomic,copy) NSString *sourceVideoPath;
@property(nonatomic,copy) NSString *sourceCoverPath;
@end

@implementation WKSmallVideoContent

+ (instancetype)videoContentWithVideoPath:(NSString *)videoPath coverPath:(NSString *)coverPath {
    WKSmallVideoContent *content = [WKSmallVideoContent new];
    content.sourceVideoPath = [self normalizedPath:videoPath];
    content.sourceCoverPath = [self normalizedPath:coverPath];
    content.extension = @".mp4";
    content.thumbExtension = @".jpg";
    [content readVideoInfoIfNeeded];
    return content;
}

+ (instancetype)videoContentWithVideoPath:(NSString *)videoPath {
    return [self videoContentWithVideoPath:videoPath coverPath:nil];
}

+ (NSString *)normalizedPath:(NSString *)path {
    if (path.length == 0) {
        return @"";
    }
    if ([path hasPrefix:@"file://"]) {
        return [NSURL URLWithString:path].path ?: @"";
    }
    return path;
}

- (void)writeDataToLocalPath {
    [super writeDataToLocalPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (self.sourceVideoPath.length > 0) {
        [WKFileUtil createDirectoryIfNotExist:[self.localPath stringByDeletingLastPathComponent]];
        if ([fileManager fileExistsAtPath:self.localPath]) {
            [fileManager removeItemAtPath:self.localPath error:nil];
        }
        NSError *copyError;
        [fileManager copyItemAtPath:self.sourceVideoPath toPath:self.localPath error:&copyError];
        if (copyError) {
            WKLogError(@"copy small video fail: %@", copyError);
            [self setExtra:copyError.localizedDescription ?: LLang(@"视频文件复制失败") key:@"media_prepare_error"];
        }
    }
    [self writeCoverIfNeeded];
    [self readVideoInfoIfNeeded];
}

- (void)writeCoverIfNeeded {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:self.thumbPath]) {
        return;
    }
    [WKFileUtil createDirectoryIfNotExist:[self.thumbPath stringByDeletingLastPathComponent]];
    if (self.sourceCoverPath.length > 0 && [fileManager fileExistsAtPath:self.sourceCoverPath]) {
        NSError *copyError;
        [fileManager copyItemAtPath:self.sourceCoverPath toPath:self.thumbPath error:&copyError];
        if (copyError) {
            WKLogError(@"copy small video cover fail: %@", copyError);
            [self setExtra:copyError.localizedDescription ?: LLang(@"视频封面复制失败") key:@"media_prepare_error"];
            return;
        }
        [self setExtra:self.thumbPath key:@"video_cover_file"];
        return;
    }
    NSString *path = self.sourceVideoPath.length > 0 ? self.sourceVideoPath : self.localPath;
    if (path.length == 0 || ![fileManager fileExistsAtPath:path]) {
        [self setExtra:LLang(@"视频文件不存在") key:@"media_prepare_error"];
        return;
    }
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:path] options:nil];
    UIImage *cover = [WKVideoRecordUtil getVideoPreViewImage:asset];
    NSData *coverData = UIImageJPEGRepresentation(cover, 0.72f);
    if (coverData.length > 0) {
        BOOL written = [coverData writeToFile:self.thumbPath atomically:YES];
        if(written) {
            [self setExtra:self.thumbPath key:@"video_cover_file"];
        }else {
            [self setExtra:LLang(@"视频封面写入失败") key:@"media_prepare_error"];
        }
    }else {
        [self setExtra:LLang(@"视频封面生成失败") key:@"media_prepare_error"];
    }
}

- (void)readVideoInfoIfNeeded {
    NSString *path = self.sourceVideoPath.length > 0 ? self.sourceVideoPath : self.localPath;
    if (path.length == 0 || ![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return;
    }
    NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
    self.size = self.size > 0 ? self.size : [attrs fileSize];
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:path] options:nil];
    self.duration = self.duration > 0 ? self.duration : (NSInteger)ceil(CMTimeGetSeconds(asset.duration));
    AVAssetTrack *track = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    if (track && (self.width <= 0 || self.height <= 0)) {
        CGSize size = CGSizeApplyAffineTransform(track.naturalSize, track.preferredTransform);
        self.width = fabs(size.width);
        self.height = fabs(size.height);
    }
}

- (UIImage *)coverImage {
    return [UIImage imageWithContentsOfFile:self.thumbPath];
}

- (NSString *)coverURL {
    NSString *cover = [self getExtra:@"video_cover"];
    if (cover.length == 0) {
        cover = [self getExtra:@"cover"];
    }
    return cover ?: @"";
}

- (NSString *)durationText {
    NSInteger seconds = MAX(self.duration, 0);
    return [NSString stringWithFormat:@"%02ld:%02ld", (long)(seconds / 60), (long)(seconds % 60)];
}

- (NSDictionary *)encodeWithJSON {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"url"] = self.remoteUrl ?: @"";
    dict[@"cover"] = [self coverURL] ?: @"";
    dict[@"width"] = @(self.width);
    dict[@"height"] = @(self.height);
    dict[@"duration"] = @(self.duration);
    dict[@"size"] = @(self.size);
    return dict;
}

- (void)decodeWithJSON:(NSDictionary *)contentDic {
    self.remoteUrl = contentDic[@"url"] ?: contentDic[@"video_path"] ?: @"";
    NSString *cover = contentDic[@"cover"] ?: contentDic[@"cover_path"] ?: contentDic[@"video_cover"] ?: @"";
    if (cover.length > 0) {
        [self setExtra:cover key:@"video_cover"];
    }
    self.width = [contentDic[@"width"]?:contentDic[@"cover_width"]?:@(0) floatValue];
    self.height = [contentDic[@"height"]?:contentDic[@"cover_height"]?:@(0) floatValue];
    self.duration = [contentDic[@"duration"]?:contentDic[@"second"]?:@(0) integerValue];
    self.size = [contentDic[@"size"] longLongValue];
    self.extension = @".mp4";
    self.thumbExtension = @".jpg";
}

+ (NSNumber *)contentType {
    return @(WK_SMALLVIDEO);
}

- (NSString *)conversationDigest {
    return LLang(@"[小视频]");
}

- (NSString *)searchableWord {
    return LLang(@"[小视频]");
}

@end

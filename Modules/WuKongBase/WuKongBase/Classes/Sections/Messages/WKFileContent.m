//
//  WKFileContent.m
//  WuKongBase
//

#import "WKFileContent.h"
#import "WuKongBase.h"
#import <WuKongIMSDK/WKFileUtil.h>

@interface WKFileContent ()
@property(nonatomic,copy) NSString *sourcePath;
@end

@implementation WKFileContent

+ (instancetype)fileContentWithPath:(NSString *)path name:(NSString *)name size:(long long)size {
    WKFileContent *content = [WKFileContent new];
    content.sourcePath = path;
    content.name = name.length > 0 ? name : path.lastPathComponent;
    content.size = size;
    content.ext = [[content.name pathExtension] lowercaseString];
    content.extension = content.ext.length > 0 ? [NSString stringWithFormat:@".%@", content.ext] : @"";
    return content;
}

- (void)writeDataToLocalPath {
    [super writeDataToLocalPath];
    if (self.sourcePath.length == 0) {
        return;
    }
    if (![[NSFileManager defaultManager] isReadableFileAtPath:self.sourcePath]) {
        NSString *message = LLang(@"文件不存在或不可读");
        [self setExtra:message key:@"media_prepare_error"];
        WKLogError(@"file not readable: %@", self.sourcePath);
    }
}

- (NSString *)localPath {
    if (self.sourcePath.length > 0 && [[NSFileManager defaultManager] fileExistsAtPath:self.sourcePath]) {
        return self.sourcePath;
    }
    return [super localPath];
}

- (NSDictionary *)encodeWithJSON {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"url"] = self.remoteUrl ?: @"";
    dict[@"name"] = self.name ?: @"";
    dict[@"size"] = @(self.size);
    dict[@"ext"] = self.ext ?: @"";
    return dict;
}

- (void)decodeWithJSON:(NSDictionary *)contentDic {
    self.remoteUrl = contentDic[@"url"] ?: @"";
    self.name = contentDic[@"name"] ?: @"";
    self.size = [contentDic[@"size"] longLongValue];
    self.ext = contentDic[@"ext"] ?: [[self.name pathExtension] lowercaseString];
    self.extension = self.ext.length > 0 ? [NSString stringWithFormat:@".%@", self.ext] : @"";
}

+ (NSNumber *)contentType {
    return @(WK_FILE);
}

- (NSString *)conversationDigest {
    return LLang(@"[文件]");
}

- (NSString *)searchableWord {
    return self.name.length > 0 ? self.name : LLang(@"[文件]");
}

- (NSString *)displaySize {
    long long bytes = self.size;
    if (bytes <= 0 && self.localPath.length > 0) {
        NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:self.localPath error:nil];
        bytes = [attrs fileSize];
    }
    if (bytes >= 1024LL * 1024LL * 1024LL) {
        return [NSString stringWithFormat:@"%.1f GB", bytes / 1024.0 / 1024.0 / 1024.0];
    }
    if (bytes >= 1024LL * 1024LL) {
        return [NSString stringWithFormat:@"%.1f MB", bytes / 1024.0 / 1024.0];
    }
    if (bytes >= 1024LL) {
        return [NSString stringWithFormat:@"%.1f KB", bytes / 1024.0];
    }
    return [NSString stringWithFormat:@"%lld B", bytes];
}

@end

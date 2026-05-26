//
//  WKFileUploadTask.m
//  WuKongDataSource
//
//  Created by tt on 2020/1/15.
//

#import "WKFileUploadTask.h"
@interface WKFileUploadTask ()
@property(nonatomic,strong) NSMutableArray<NSURLSessionDataTask*> *tasks;

@end
@implementation WKFileUploadTask


- (instancetype)initWithMessage:(WKMessage *)message {
    self = [super initWithMessage:message];
    if(self) {
        [self initTasks];
    }
    return self;
}

-(void) initTasks {
   
    id<WKMediaProto> media = [self getMessageMedia:self.message];
    if(!media) {
        WKLogDebug(@"不是多媒体消息！");
        return;
    }
    NSError *prepareError = [self prepareErrorForMedia:media];
    if(prepareError) {
        self.status = WKTaskStatusError;
        self.error = prepareError;
        self.remoteUrl = @"";
        [self update];
        return;
    }
    
    NSString *randomFileName = [[[NSUUID UUID] UUIDString] stringByReplacingOccurrencesOfString:@"-" withString:@""];
    NSString *path = [NSString stringWithFormat:@"/%d/%@/%@%@",self.message.channel.channelType,self.message.channel.channelId,randomFileName,media.extension?:@""];
    NSString *fileUrl = [NSURL fileURLWithPath:media.localPath].absoluteString;
    
    // ---- 如果是声音文件，则上传转码后的副本也就是amr文件 ----
	     if([media isKindOfClass:[WKVoiceContent class]]) {
	         path = [NSString stringWithFormat:@"/%d/%@/%@%@",self.message.channel.channelType,self.message.channel.channelId,randomFileName,media.thumbExtension?:@""];
	         fileUrl = [NSURL fileURLWithPath:media.thumbPath].absoluteString;
	     }
    
    
    if(self.message.contentType == WK_SMALLVIDEO) { // 小视频
        __weak typeof(self) weakSelf = self;
        [self uploadVideoCoverImage:^{ // 先上传封面图,再上传视频
            if(!weakSelf || [weakSelf isTerminated]) {
                return;
            }
            WKLogDebug(@"封面上传成功！");
            [weakSelf createAndAddUploadTask:path sourceFileURL:fileUrl];
        }];
    }else {
        [self createAndAddUploadTask:path sourceFileURL:fileUrl];
	}
}

- (NSError *)prepareErrorForMedia:(id<WKMediaProto>)media {
    NSString *prepareMessage = [media getExtra:@"media_prepare_error"];
    if(prepareMessage.length > 0) {
        return [NSError errorWithDomain:@"WKFileUploadTask" code:-1 userInfo:@{NSLocalizedDescriptionKey: prepareMessage}];
    }
    NSString *path = [media isKindOfClass:[WKVoiceContent class]] ? media.thumbPath : media.localPath;
    if(path.length == 0 || ![[NSFileManager defaultManager] isReadableFileAtPath:path]) {
        return [NSError errorWithDomain:@"WKFileUploadTask" code:-2 userInfo:@{NSLocalizedDescriptionKey: LLang(@"文件不存在或不可读")}];
    }
    return nil;
}

// 获取上传地址
-(AnyPromise*) getUploadURL:(NSString*)path{
    NSURLComponents *components = [NSURLComponents componentsWithString:[NSString stringWithFormat:@"%@file/upload",[WKApp shared].config.fileBaseUrl]];
    components.queryItems = @[
        [NSURLQueryItem queryItemWithName:@"path" value:path ?: @""],
        [NSURLQueryItem queryItemWithName:@"type" value:@"chat"]
    ];
    return  [[WKAPIClient sharedClient] GETRaw:components.URL.absoluteString parameters:nil];
}



// 创建和添加下载上传任务
-(void) createAndAddUploadTask:(NSString*)path sourceFileURL:(NSString*)fileURL {
    
    id<WKMediaProto> media = [self getMessageMedia:self.message];
    if([self isTerminated]) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    [self getUploadURL:path].then(^(NSDictionary *result){
        if(!weakSelf || [weakSelf isTerminated]) {
            return;
        }
        NSString *uploadUrl = result[@"url"];
        NSURLSessionDataTask *task = [[WKAPIClient sharedClient] createFileUploadTask:uploadUrl fileURL:fileURL progress:^(NSProgress * _Nullable uploadProgress) {
            if(!weakSelf || [weakSelf isTerminated]) {
                return;
            }
            if(weakSelf.status == WKTaskStatusSuspend) {
                return;
            }
            weakSelf.progress = uploadProgress.fractionCompleted;
            weakSelf.status = WKTaskStatusProgressing;
            [weakSelf update];
        } completeCallback:^(id  _Nullable responseObj, NSError * _Nullable error) {
            if(!weakSelf || [weakSelf isTerminated]) {
                return;
            }
            if(error) {
                weakSelf.status = WKTaskStatusError;
                weakSelf.error = error;
                weakSelf.remoteUrl = @"";
            }else {
                 weakSelf.status = WKTaskStatusSuccess;
                weakSelf.error = nil;
                media.remoteUrl = responseObj[@"path"];
                weakSelf.remoteUrl = media.remoteUrl;
                
                WKLogDebug(@"上传结果：%@",responseObj);
            }
             [weakSelf update];
        }];
        [self.tasks addObject:task];
        if(weakSelf.status != WKTaskStatusSuspend) {
            [task resume]; // 这里直接执行了。如果WKTaskManager的执行task的resume 慢于这里可能会有问题（一般这里要慢，因为网络请求要比代码执行慢）
        }
    }).catch(^(NSError *error){
        if(!weakSelf || [weakSelf isTerminated]) {
            return;
        }
        weakSelf.status = WKTaskStatusError;
        weakSelf.error = error;
        weakSelf.remoteUrl = @"";
        [weakSelf update];
    });
}

// 上传封面图
-(void) uploadVideoCoverImage:(void(^)(void))successCallback {
    id<WKMediaProto> media = [self getMessageMedia:self.message];
    NSString *coverFileURL =[media getExtra:@"video_cover_file"];
    if([self isTerminated]) {
        return;
    }
    if(coverFileURL.length == 0 || ![[NSFileManager defaultManager] isReadableFileAtPath:coverFileURL]) {
        NSString *message = coverFileURL.length == 0 ? LLang(@"视频封面生成失败") : LLang(@"视频封面文件不存在或不可读");
        WKLogDebug(@"上传视频封面失败：%@", message);
        self.status = WKTaskStatusError;
        self.error = [NSError errorWithDomain:@"WKFileUploadTask" code:-3 userInfo:@{NSLocalizedDescriptionKey: message}];
        self.remoteUrl = @"";
        [self update];
        return;
    }
     NSString *randomFileName = [[[NSUUID UUID] UUIDString] stringByReplacingOccurrencesOfString:@"-" withString:@""];
    __weak typeof(self) weakSelf = self;
    NSString *path = [NSString stringWithFormat:@"/%d/%@/%@%@",self.message.channel.channelType,self.message.channel.channelId,randomFileName,media.thumbExtension.length > 0 ? media.thumbExtension : (media.extension ?: @"")];
    
    [self getUploadURL:path].then(^(NSDictionary*result){
        if(!weakSelf || [weakSelf isTerminated]) {
            return;
        }
        NSString *uploadUrl = result[@"url"];
        NSURLSessionDataTask *task = [[WKAPIClient sharedClient] createFileUploadTask:uploadUrl fileURL:[NSURL fileURLWithPath:coverFileURL].absoluteString progress:^(NSProgress * _Nullable uploadProgress) {
        } completeCallback:^(id  _Nullable responseObj, NSError * _Nullable error) {
            if(!weakSelf || [weakSelf isTerminated]) {
                return;
            }
            if(error) {
                weakSelf.status = WKTaskStatusError;
                weakSelf.error = error;
                weakSelf.remoteUrl = @"";
                 [weakSelf update];
                return;
            }
            [media setExtra:responseObj[@"path"] key:@"video_cover"];
            if(successCallback) {
                successCallback();
            }
        }];
        [weakSelf.tasks addObject:task];
        if(weakSelf.status != WKTaskStatusSuspend) {
            [task resume];
        }
    }).catch(^(NSError *error){
        if(!weakSelf || [weakSelf isTerminated]) {
            return;
        }
        weakSelf.status = WKTaskStatusError;
        weakSelf.error = error;
        weakSelf.remoteUrl = @"";
        [weakSelf update];
    });
    
    
}



-(void) resume {
    if(self.status == WKTaskStatusCancel || self.status == WKTaskStatusError || self.status == WKTaskStatusSuccess) {
        [self update];
        return;
    }
    self.status = WKTaskStatusProgressing;
    for (NSURLSessionDataTask *task in self.tasks) {
        [task resume];
    }
    [self update];
}

-(void) cancel {
    self.status = WKTaskStatusCancel;
    for (NSURLSessionDataTask *task in self.tasks) {
        [task cancel];
    }
    [self update];
}

- (void)suspend {
    self.status = WKTaskStatusSuspend;
    for (NSURLSessionDataTask *task in self.tasks) {
        [task suspend];
    }
    [self update];
}

-(NSMutableArray<NSURLSessionDataTask*>*) tasks {
    if(!_tasks) {
        _tasks = [NSMutableArray array];
    }
    return _tasks;
}

- (BOOL)isTerminated {
    return self.status == WKTaskStatusCancel || self.status == WKTaskStatusError || self.status == WKTaskStatusSuccess;
}

-(id<WKMediaProto>) getMessageMedia:(WKMessage*)message {
    if([message.content conformsToProtocol:@protocol(WKMediaProto)] ) {
        return (id<WKMediaProto>)message.content;
    }
    return nil;
}
@end

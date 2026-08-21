//
//  WKMessageFileDownloadTask.m
//  WuKongIMBase
//
//  Created by tt on 2020/1/16.
//

#import "WKMessageFileDownloadTask.h"

@implementation WKMessageFileDownloadTask

-(instancetype) initWithMessage:(WKMessage*)message; {
    self = [super init];
    if(self) {
        self.message = message;
    }
    return self;
}

- (NSString *)taskId {
    if(self.message.clientSeq > 0) {
        return [NSString stringWithFormat:@"%u",self.message.clientSeq];
    }
    if(self.message.clientMsgNo.length > 0) {
        return [NSString stringWithFormat:@"message_%@",self.message.clientMsgNo];
    }
    return [NSString stringWithFormat:@"message_%llu",self.message.messageId];
}


@end

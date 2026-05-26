//
//  WKRTCMessageContent.m
//  WuKongBase
//

#import "WKRTCMessageContent.h"
#import "WuKongBase.h"

static NSString *WKRTCMessageStringValue(id value) {
    if([value isKindOfClass:NSString.class]) {
        return value;
    }
    if([value respondsToSelector:@selector(stringValue)]) {
        return [value stringValue];
    }
    return @"";
}

static NSArray<NSString *> *WKRTCMessageStringArrayValue(id value) {
    if(![value isKindOfClass:NSArray.class]) {
        return @[];
    }
    NSMutableArray<NSString *> *items = [NSMutableArray array];
    for (id item in (NSArray *)value) {
        NSString *text = WKRTCMessageStringValue(item);
        if(text.length > 0) {
            [items addObject:text];
        }
    }
    return items.copy;
}

@implementation WKRTCMessageContent

- (NSDictionary *)encodeWithJSON {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"type"] = self.rtcType.length > 0 ? self.rtcType : @"rtc_notice";
    dict[@"call_id"] = self.callId ?: @"";
    dict[@"room_name"] = self.roomName ?: @"";
    dict[@"channel_id"] = self.channelId ?: @"";
    dict[@"channel_type"] = @(self.channelType);
    dict[@"call_type"] = self.callType == WKRTCCallTypeVideo ? @"video" : @"audio";
    dict[@"record_type"] = self.recordType ?: @"";
    dict[@"duration"] = @(self.duration);
    dict[@"from_uid"] = self.fromUid ?: @"";
    dict[@"target_uids"] = self.targetUids ?: @[];
    dict[@"answer_uid"] = self.answerUid ?: @"";
    dict[@"started_at"] = @(self.startedAt);
    dict[@"ended_at"] = @(self.endedAt);
    return dict.copy;
}

- (void)decodeWithJSON:(NSDictionary *)contentDic {
    self.rtcType = WKRTCMessageStringValue(contentDic[@"type"]);
    self.callId = WKRTCMessageStringValue(contentDic[@"call_id"]);
    self.roomName = WKRTCMessageStringValue(contentDic[@"room_name"]);
    self.channelId = WKRTCMessageStringValue(contentDic[@"channel_id"]);
    self.channelType = [contentDic[@"channel_type"] integerValue];
    self.callType = WKRTCCallTypeFromString(WKRTCMessageStringValue(contentDic[@"call_type"]));
    self.recordType = WKRTCMessageStringValue(contentDic[@"record_type"]);
    self.duration = [contentDic[@"duration"] integerValue];
    self.fromUid = WKRTCMessageStringValue(contentDic[@"from_uid"]);
    self.targetUids = WKRTCMessageStringArrayValue(contentDic[@"target_uids"]);
    self.answerUid = WKRTCMessageStringValue(contentDic[@"answer_uid"]);
    self.startedAt = [contentDic[@"started_at"] doubleValue];
    self.endedAt = [contentDic[@"ended_at"] doubleValue];
}

+ (NSNumber *)contentType {
    return @(WK_VIDEOCALL_DATA);
}

- (NSString *)conversationDigest {
    if([self isNotice]) {
        return self.callType == WKRTCCallTypeVideo ? LLang(@"[群视频通话进行中]") : LLang(@"[群语音通话进行中]");
    }
    return [NSString stringWithFormat:@"[%@]", [self recordTextForCurrentUid:[WKApp shared].loginInfo.uid]];
}

- (NSString *)searchableWord {
    return [self conversationDigest];
}

- (BOOL)isNotice {
    return [self.rtcType isEqualToString:@"rtc_notice"];
}

- (BOOL)isRecord {
    return [self.rtcType isEqualToString:@"rtc_record"];
}

- (WKRTCCallPayload *)toCallPayloadWithMessageChannel:(WKChannel *)messageChannel {
    WKRTCCallPayload *payload = [WKRTCCallPayload new];
    payload.callId = self.callId ?: @"";
    payload.roomName = self.roomName ?: @"";
    payload.channelId = self.channelId.length > 0 ? self.channelId : (messageChannel.channelId ?: @"");
    payload.channelType = self.channelType > 0 ? self.channelType : messageChannel.channelType;
    payload.callType = self.callType;
    payload.fromUid = self.fromUid ?: @"";
    return payload;
}

- (NSString *)recordTextForCurrentUid:(NSString *)currentUid {
    BOOL isCaller = currentUid.length > 0 && [self.fromUid isEqualToString:currentUid];
    if([self.recordType isEqualToString:@"answered"]) {
        return [NSString stringWithFormat:@"%@ %@", LLang(@"通话时长"), [self durationText]];
    }
    if([self.recordType isEqualToString:@"missed"]) {
        return isCaller ? LLang(@"对方未接听") : LLang(@"未接来电");
    }
    if([self.recordType isEqualToString:@"rejected"]) {
        return isCaller ? LLang(@"对方已拒绝") : LLang(@"已拒绝");
    }
    if([self.recordType isEqualToString:@"cancelled"]) {
        return LLang(@"通话已取消");
    }
    return self.callType == WKRTCCallTypeVideo ? LLang(@"视频通话") : LLang(@"语音通话");
}

- (NSString *)durationText {
    NSInteger seconds = MAX(0, self.duration);
    return [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)(seconds/3600), (long)((seconds%3600)/60), (long)(seconds%60)];
}

@end

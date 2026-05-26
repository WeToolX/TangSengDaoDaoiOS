//
//  WKRTCModels.m
//  WuKongBase
//

#import "WKRTCModels.h"
#import "WKApp.h"
#import "WKAvatarUtil.h"

NSString * const WKRTCSessionDidChangeNotification = @"WKRTCSessionDidChangeNotification";
NSString * const WKRTCMediaParticipantsDidChangeNotification = @"WKRTCMediaParticipantsDidChangeNotification";
NSString * const WKRTCNoticeDidReceiveNotification = @"WKRTCNoticeDidReceiveNotification";
NSString * const WKRTCChannelCallDidChangeNotification = @"WKRTCChannelCallDidChangeNotification";
NSString * const WKRTCMediaParticipantPresenceDidChangeNotification = @"WKRTCMediaParticipantPresenceDidChangeNotification";
NSString * const WKRTCMediaParticipantPresenceActionJoined = @"joined";
NSString * const WKRTCMediaParticipantPresenceActionLeft = @"left";

static NSString *WKRTCStringValue(id value) {
    if([value isKindOfClass:NSString.class]) {
        return value;
    }
    if([value respondsToSelector:@selector(stringValue)]) {
        return [value stringValue];
    }
    return @"";
}

static NSArray<NSString *> *WKRTCStringArrayValue(id value) {
    if(![value isKindOfClass:NSArray.class]) {
        return @[];
    }
    NSMutableArray<NSString *> *items = [NSMutableArray array];
    for (id item in (NSArray *)value) {
        NSString *text = WKRTCStringValue(item);
        if(text.length > 0) {
            [items addObject:text];
        }
    }
    return items.copy;
}

static NSString *WKRTCMessageForErrorCode(NSInteger code);

NSError *WKRTCError(NSInteger code, NSString *message) {
    NSString *safeMessage = message.length > 0 ? message : @"音视频操作失败";
    return [NSError errorWithDomain:@"WKRTCError"
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey:safeMessage}];
}

NSError *WKRTCNormalizeError(NSError *error, NSString *fallbackMessage) {
    if(!error) {
        return WKRTCError(-1, fallbackMessage);
    }
    NSString *message = WKRTCMessageForErrorCode(error.code);
    if(message.length == 0) {
        message = error.userInfo[NSLocalizedDescriptionKey];
    }
    if(message.length == 0 && error.domain.length > 0 && ![error.domain isEqualToString:NSCocoaErrorDomain]) {
        message = error.domain;
    }
    if(message.length == 0) {
        message = fallbackMessage.length > 0 ? fallbackMessage : @"音视频操作失败";
    }
    return WKRTCError(error.code, message);
}

static NSString *WKRTCMessageForErrorCode(NSInteger code) {
    switch (code) {
        case 40001:
            return @"对方或自己正在通话中";
        case 40003:
            return @"无权发起通话";
        case 40004:
            return @"通话已结束";
        case 40005:
            return @"邀请已过期";
        case 40006:
            return @"无权加入通话";
        case 40007:
            return @"无权关闭房间";
        case 40008:
            return @"已在其他设备接听";
        case 50001:
            return @"通话服务暂不可用，请稍后再试";
        case 50002:
            return @"来电通知发送失败，请稍后重试";
        case 50003:
            return @"通话状态查询失败，请稍后重试";
        default:
            return nil;
    }
}

NSString *WKRTCDisplayNameForUID(NSString *uid) {
    NSString *safeUID = WKRTCUIDFromParticipantID(uid);
    if(safeUID.length == 0) {
        return @"";
    }
    WKChannelInfo *info = [[WKSDK shared].channelManager getChannelInfo:[WKChannel personWithChannelID:safeUID]];
    if(info.remark.length > 0) {
        return info.remark;
    }
    if(info.displayName.length > 0) {
        return info.displayName;
    }
    if(info.name.length > 0) {
        return info.name;
    }
    return safeUID;
}

NSString *WKRTCAvatarURLForUID(NSString *uid) {
    NSString *safeUID = WKRTCUIDFromParticipantID(uid);
    if(safeUID.length == 0) {
        return @"";
    }
    WKChannelInfo *info = [[WKSDK shared].channelManager getChannelInfo:[WKChannel personWithChannelID:safeUID]];
    if(info.logo.length > 0) {
        return [WKAvatarUtil getFullAvatarWIthPath:info.logo];
    }
    return [WKAvatarUtil getAvatar:safeUID];
}

NSString *WKRTCUIDFromParticipantID(NSString *participantId) {
    NSString *text = WKRTCStringValue(participantId);
    if(text.length == 0) {
        return @"";
    }
    NSRange range = [text rangeOfString:@":"];
    if(range.location == NSNotFound || range.location == 0) {
        return text;
    }
    return [text substringToIndex:range.location];
}

WKRTCCallType WKRTCCallTypeFromString(NSString *callType) {
    if([callType isEqualToString:@"video"]) {
        return WKRTCCallTypeVideo;
    }
    return WKRTCCallTypeAudio;
}

@implementation WKRTCLiveKitInfo

+ (instancetype)modelWithDictionary:(NSDictionary *)dictionary {
    WKRTCLiveKitInfo *info = [WKRTCLiveKitInfo new];
    if(![dictionary isKindOfClass:NSDictionary.class]) {
        return info;
    }
    info.url = WKRTCStringValue(dictionary[@"url"]);
    info.token = WKRTCStringValue(dictionary[@"token"]);
    return info;
}

@end

@implementation WKRTCCallResp

+ (instancetype)modelWithDictionary:(NSDictionary *)dictionary {
    WKRTCCallResp *resp = [WKRTCCallResp new];
    if(![dictionary isKindOfClass:NSDictionary.class]) {
        return resp;
    }
    resp.callId = WKRTCStringValue(dictionary[@"call_id"]);
    resp.existing = [dictionary[@"existing"] boolValue];
    resp.roomName = WKRTCStringValue(dictionary[@"room_name"]);
    resp.expireAt = [dictionary[@"expire_at"] doubleValue];
    resp.status = WKRTCStringValue(dictionary[@"status"]);
    resp.permissions = WKRTCStringArrayValue(dictionary[@"permissions"]);
    resp.livekit = [WKRTCLiveKitInfo modelWithDictionary:dictionary[@"livekit"]];
    return resp;
}

- (BOOL)hasPermission:(NSString *)permission {
    if(permission.length == 0) {
        return NO;
    }
    return [self.permissions containsObject:permission];
}

@end

@implementation WKRTCCallPayload

+ (instancetype)modelWithDictionary:(NSDictionary *)dictionary {
    WKRTCCallPayload *payload = [WKRTCCallPayload new];
    if(![dictionary isKindOfClass:NSDictionary.class]) {
        return payload;
    }
    payload.callId = WKRTCStringValue(dictionary[@"call_id"]);
    payload.roomName = WKRTCStringValue(dictionary[@"room_name"]);
    payload.channelId = WKRTCStringValue(dictionary[@"channel_id"]);
    payload.channelType = [dictionary[@"channel_type"] integerValue];
    payload.callType = WKRTCCallTypeFromString(WKRTCStringValue(dictionary[@"call_type"]));
    payload.fromUid = WKRTCStringValue(dictionary[@"from_uid"]);
    payload.fromName = WKRTCStringValue(dictionary[@"from_name"]);
    payload.inviteUids = WKRTCStringArrayValue(dictionary[@"invite_uids"]);
    payload.expireAt = [dictionary[@"expire_at"] doubleValue];
    payload.answerUid = WKRTCStringValue(dictionary[@"answer_uid"]);
    payload.answerDeviceId = WKRTCStringValue(dictionary[@"answer_device_id"]);
    payload.reason = WKRTCStringValue(dictionary[@"reason"]);
    return payload;
}

+ (instancetype)payloadWithChannel:(WKChannel *)channel callType:(WKRTCCallType)callType {
    WKRTCCallPayload *payload = [WKRTCCallPayload new];
    payload.channelId = channel.channelId ?: @"";
    payload.channelType = channel.channelType;
    payload.callType = callType;
    payload.fromUid = [WKApp shared].loginInfo.uid ?: @"";
    return payload;
}

+ (instancetype)payloadWithChannelState:(WKRTCChannelStateResp *)state channel:(WKChannel *)channel {
    WKRTCCallPayload *payload = [WKRTCCallPayload new];
    payload.callId = state.callId ?: @"";
    payload.roomName = state.roomName ?: @"";
    payload.channelId = channel.channelId ?: @"";
    payload.channelType = channel.channelType;
    payload.callType = state.callType;
    payload.fromUid = state.fromUid ?: @"";
    payload.inviteUids = state.inviteUids ?: @[];
    payload.expireAt = state.expireAt;
    return payload;
}

- (NSString *)callTypeString {
    return self.callType == WKRTCCallTypeVideo ? @"video" : @"audio";
}

- (NSDictionary *)toDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"call_id"] = self.callId ?: @"";
    dict[@"room_name"] = self.roomName ?: @"";
    dict[@"channel_id"] = self.channelId ?: @"";
    dict[@"channel_type"] = @(self.channelType);
    dict[@"call_type"] = [self callTypeString];
    dict[@"from_uid"] = self.fromUid ?: @"";
    dict[@"from_name"] = self.fromName ?: @"";
    dict[@"invite_uids"] = self.inviteUids ?: @[];
    dict[@"expire_at"] = @(self.expireAt);
    dict[@"answer_uid"] = self.answerUid ?: @"";
    dict[@"answer_device_id"] = self.answerDeviceId ?: @"";
    dict[@"reason"] = self.reason ?: @"";
    return dict.copy;
}

@end

@implementation WKRTCChannelStateResp

+ (instancetype)modelWithDictionary:(NSDictionary *)dictionary {
    WKRTCChannelStateResp *resp = [WKRTCChannelStateResp new];
    if(![dictionary isKindOfClass:NSDictionary.class]) {
        return resp;
    }
    resp.existing = [dictionary[@"existing"] boolValue];
    resp.callId = WKRTCStringValue(dictionary[@"call_id"]);
    resp.roomName = WKRTCStringValue(dictionary[@"room_name"]);
    resp.status = WKRTCStringValue(dictionary[@"status"]);
    resp.callType = WKRTCCallTypeFromString(WKRTCStringValue(dictionary[@"call_type"]));
    resp.fromUid = WKRTCStringValue(dictionary[@"from_uid"]);
    resp.inviteUids = WKRTCStringArrayValue(dictionary[@"invite_uids"]);
    resp.expireAt = [dictionary[@"expire_at"] doubleValue];
    return resp;
}

@end

@implementation WKRTCJoinCodeResp

+ (instancetype)modelWithDictionary:(NSDictionary *)dictionary {
    WKRTCJoinCodeResp *resp = [WKRTCJoinCodeResp new];
    if(![dictionary isKindOfClass:NSDictionary.class]) {
        return resp;
    }
    resp.callId = WKRTCStringValue(dictionary[@"call_id"]);
    resp.joinCode = WKRTCStringValue(dictionary[@"join_code"]);
    resp.expireAt = [dictionary[@"expire_at"] doubleValue];
    return resp;
}

@end

@implementation WKRTCMediaParticipantState
@end

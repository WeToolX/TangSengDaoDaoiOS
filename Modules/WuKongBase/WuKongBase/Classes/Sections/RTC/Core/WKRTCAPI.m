//
//  WKRTCAPI.m
//  WuKongBase
//

#import "WKRTCAPI.h"
#import "WKAPIClient.h"
#import "WKLogs.h"
#import "UIDevice+Utils.h"

@implementation WKRTCAPI

+ (instancetype)shared {
    static WKRTCAPI *api;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        api = [WKRTCAPI new];
    });
    return api;
}

- (NSString *)deviceId {
    NSString *deviceId = [UIDevice getUUID];
    if(deviceId.length == 0) {
        WKLogError(@"音视频设备编号为空，无法继续调用通话接口");
    }
    return deviceId ?: @"";
}

- (AnyPromise *)startCallWithChannelId:(NSString *)channelId
                           channelType:(WKChannelType)channelType
                              callType:(WKRTCCallType)callType
                            inviteUids:(NSArray<NSString *> *)inviteUids
                             requestId:(NSString *)requestId {
    if(channelId.length == 0) {
        return [AnyPromise promiseWithValue:WKRTCError(-1, @"频道 ID 不能为空")];
    }
    if(requestId.length == 0) {
        return [AnyPromise promiseWithValue:WKRTCError(-1, @"请求 ID 不能为空")];
    }
    NSString *deviceId = [self deviceId];
    if(deviceId.length == 0) {
        return [AnyPromise promiseWithValue:WKRTCError(-1, @"设备 ID 不能为空")];
    }
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"request_id"] = requestId;
    params[@"channel_id"] = channelId;
    params[@"channel_type"] = @(channelType);
    params[@"call_type"] = callType == WKRTCCallTypeVideo ? @"video" : @"audio";
    params[@"device_id"] = deviceId;
    if(inviteUids.count > 0) {
        params[@"invite_uids"] = inviteUids;
    }
    WKLogDebug(@"音视频发起通话请求，频道：%@，类型：%@", channelId, params[@"call_type"]);
    return [[WKAPIClient sharedClient] POST:@"rtc/calls" parameters:params].then(^id(NSDictionary *dict, NSURLSessionDataTask *task){
        return [WKRTCCallResp modelWithDictionary:dict];
    }).catch(^(NSError *error){
        return WKRTCNormalizeError(error, @"发起通话失败");
    });
}

- (AnyPromise *)joinCall:(NSString *)callId joinCode:(NSString *)joinCode {
    if(callId.length == 0) {
        return [AnyPromise promiseWithValue:WKRTCError(-1, @"通话 ID 不能为空")];
    }
    NSString *deviceId = [self deviceId];
    if(deviceId.length == 0) {
        return [AnyPromise promiseWithValue:WKRTCError(-1, @"设备 ID 不能为空")];
    }
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"device_id"] = deviceId;
    params[@"join_code"] = joinCode ?: @"";
    WKLogDebug(@"音视频加入通话请求，通话编号：%@", callId);
    return [[WKAPIClient sharedClient] POST:[NSString stringWithFormat:@"rtc/calls/%@/join", callId] parameters:params].then(^id(NSDictionary *dict, NSURLSessionDataTask *task){
        return [WKRTCCallResp modelWithDictionary:dict];
    }).catch(^(NSError *error){
        return WKRTCNormalizeError(error, @"加入通话失败");
    });
}

- (AnyPromise *)rejectCall:(NSString *)callId {
    return [self postEmptyCallAction:@"reject" callId:callId fallback:@"拒绝通话失败"];
}

- (AnyPromise *)cancelCall:(NSString *)callId {
    return [self postEmptyCallAction:@"cancel" callId:callId fallback:@"取消通话失败"];
}

- (AnyPromise *)closeCall:(NSString *)callId reason:(NSString *)reason {
    if(callId.length == 0) {
        return [AnyPromise promiseWithValue:WKRTCError(-1, @"通话 ID 不能为空")];
    }
    NSString *safeReason = reason.length > 0 ? reason : @"hangup";
    WKLogDebug(@"音视频关闭房间请求，通话编号：%@，原因：%@", callId, safeReason);
    return [[WKAPIClient sharedClient] POST:[NSString stringWithFormat:@"rtc/calls/%@/close", callId]
                                parameters:@{@"reason":safeReason}
                                   headers:[self deviceHeaders]].catch(^(NSError *error){
        return WKRTCNormalizeError(error, @"关闭通话失败");
    });
}

- (AnyPromise *)leaveCall:(NSString *)callId {
    return [self postEmptyCallAction:@"leave" callId:callId fallback:@"离开通话失败"];
}

- (AnyPromise *)inviteCall:(NSString *)callId uids:(NSArray<NSString *> *)uids {
    if(callId.length == 0) {
        return [AnyPromise promiseWithValue:WKRTCError(-1, @"通话 ID 不能为空")];
    }
    if(uids.count == 0) {
        return [AnyPromise promiseWithValue:WKRTCError(-1, @"邀请成员不能为空")];
    }
    WKLogDebug(@"音视频邀请成员请求，通话编号：%@，人数：%ld", callId, (long)uids.count);
    return [[WKAPIClient sharedClient] POST:[NSString stringWithFormat:@"rtc/calls/%@/invite", callId]
                                parameters:@{@"uids":uids}
                                   headers:[self deviceHeaders]].catch(^(NSError *error){
        return WKRTCNormalizeError(error, @"邀请成员失败");
    });
}

- (AnyPromise *)createJoinCodeForCall:(NSString *)callId {
    if(callId.length == 0) {
        return [AnyPromise promiseWithValue:WKRTCError(-1, @"通话 ID 不能为空")];
    }
    WKLogDebug(@"音视频创建加入码请求，通话编号：%@", callId);
    return [[WKAPIClient sharedClient] POST:[NSString stringWithFormat:@"rtc/calls/%@/join_code", callId] parameters:nil headers:[self deviceHeaders]].then(^id(NSDictionary *dict, NSURLSessionDataTask *task){
        return [WKRTCJoinCodeResp modelWithDictionary:dict];
    }).catch(^(NSError *error){
        return WKRTCNormalizeError(error, @"创建加入码失败");
    });
}

- (AnyPromise *)channelStateWithChannelId:(NSString *)channelId channelType:(WKChannelType)channelType {
    if(channelId.length == 0) {
        return [AnyPromise promiseWithValue:WKRTCError(-1, @"频道 ID 不能为空")];
    }
    NSString *path = [NSString stringWithFormat:@"rtc/channels/%ld/%@/state", (long)channelType, channelId];
    WKLogDebug(@"音视频查询频道通话状态，频道：%@", channelId);
    return [[WKAPIClient sharedClient] GET:path parameters:nil].then(^id(NSDictionary *dict, NSURLSessionDataTask *task){
        return [WKRTCChannelStateResp modelWithDictionary:dict];
    }).catch(^(NSError *error){
        return WKRTCNormalizeError(error, @"查询通话状态失败");
    });
}

- (AnyPromise *)uploadDeviceToken:(NSString *)deviceToken deviceType:(NSString *)deviceType bundleId:(NSString *)bundleId {
    if(deviceToken.length == 0) {
        return [AnyPromise promiseWithValue:WKRTCError(-1, @"推送 token 不能为空")];
    }
    if(deviceType.length == 0) {
        return [AnyPromise promiseWithValue:WKRTCError(-1, @"设备类型不能为空")];
    }
    if(bundleId.length == 0) {
        return [AnyPromise promiseWithValue:WKRTCError(-1, @"Bundle ID 不能为空")];
    }
    WKLogDebug(@"音视频上传设备推送令牌，类型：%@，包标识：%@", deviceType, bundleId);
    return [[WKAPIClient sharedClient] POST:@"user/device_token" parameters:@{
        @"device_token": deviceToken,
        @"device_type": deviceType,
        @"bundle_id": bundleId
    }].catch(^(NSError *error){
        return WKRTCNormalizeError(error, @"上传设备 token 失败");
    });
}

- (AnyPromise *)postEmptyCallAction:(NSString *)action callId:(NSString *)callId fallback:(NSString *)fallback {
    if(callId.length == 0) {
        return [AnyPromise promiseWithValue:WKRTCError(-1, @"通话 ID 不能为空")];
    }
    WKLogDebug(@"音视频通话操作请求，动作：%@，通话编号：%@", action, callId);
    NSString *path = [NSString stringWithFormat:@"rtc/calls/%@/%@", callId, action];
    return [[WKAPIClient sharedClient] POST:path parameters:nil headers:[self deviceHeaders]].catch(^(NSError *error){
        return WKRTCNormalizeError(error, fallback);
    });
}

- (NSDictionary<NSString *,NSString *> *)deviceHeaders {
    NSString *deviceId = [self deviceId];
    if(deviceId.length == 0) {
        return @{};
    }
    return @{@"device_id":deviceId};
}

@end

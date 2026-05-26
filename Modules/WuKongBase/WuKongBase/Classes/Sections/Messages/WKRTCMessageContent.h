//
//  WKRTCMessageContent.h
//  WuKongBase
//

#import <WuKongIMSDK/WuKongIMSDK.h>
#import "WKConstant.h"
#import "WKRTCModels.h"

NS_ASSUME_NONNULL_BEGIN

/// RTC 持久消息内容，承载服务端文档中的 rtc_notice 和 rtc_record。
@interface WKRTCMessageContent : WKMessageContent

@property(nonatomic,copy) NSString *rtcType;              // rtc_notice 或 rtc_record。
@property(nonatomic,copy) NSString *callId;               // 通话 ID。
@property(nonatomic,copy) NSString *roomName;             // LiveKit 房间名，仅用于展示和排查。
@property(nonatomic,copy) NSString *channelId;            // 私聊对方 UID 或群编号。
@property(nonatomic,assign) WKChannelType channelType;    // 1 私聊，2 群聊。
@property(nonatomic,assign) WKRTCCallType callType;       // audio 或 video。
@property(nonatomic,copy) NSString *recordType;           // answered/missed/rejected/cancelled。
@property(nonatomic,assign) NSInteger duration;           // 通话时长，单位秒。
@property(nonatomic,copy) NSString *fromUid;              // 发起人 UID。
@property(nonatomic,strong) NSArray<NSString *> *targetUids;
@property(nonatomic,copy) NSString *answerUid;
@property(nonatomic,assign) NSTimeInterval startedAt;
@property(nonatomic,assign) NSTimeInterval endedAt;

- (BOOL)isNotice;
- (BOOL)isRecord;
- (NSString *)recordTextForCurrentUid:(NSString *)currentUid;
- (WKRTCCallPayload *)toCallPayloadWithMessageChannel:(WKChannel *_Nullable)messageChannel;

@end

NS_ASSUME_NONNULL_END

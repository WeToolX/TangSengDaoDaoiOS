//
//  WKMySettingManager.h
//  WuKongBase
//
//  Created by tt on 2021/8/18.
//

#import <Foundation/Foundation.h>
#import "WuKongBase.h"

NS_ASSUME_NONNULL_BEGIN

@interface WKMySettingManager : NSObject

+ (instancetype _Nonnull )shared;

@property(nonatomic,assign,readonly) BOOL newMsgNotice; // 新消息通知
@property(nonatomic,assign,readonly) BOOL msgShowDetail; // 通知是否显示详情
@property(nonatomic,assign,readonly) BOOL voiceOn; // 开启声音
@property(nonatomic,assign,readonly) BOOL shockOn; //  开启震动
@property(nonatomic,assign,readonly) BOOL searchByPhone; // 是否可以通过手机号搜索
@property(nonatomic,assign,readonly) BOOL searchByShort; // 是否可以通过短编号搜索

@property(nonatomic,assign,readonly) BOOL offlineProtection; // 断网保护

@property(nonatomic,assign,readonly) BOOL muteOfApp; // app静音

@property(nonatomic,assign,readonly) BOOL deviceLock; // 设备锁



/// 新消息通知
/// @param on <#on description#>
- (AnyPromise *)newMsgNotice:(BOOL)on;


/// 通知是否显示详情
/// @param on <#on description#>
- (AnyPromise *)msgShowDetail:(BOOL)on;

/// 开启声音
/// @param on <#on description#>
- (AnyPromise *)voiceOn:(BOOL)on;

/// 开启震动
/// @param on <#on description#>
- (AnyPromise *)shockOn:(BOOL)on;

/// 是否可以通过手机号搜索
/// @param on <#on description#>
-(AnyPromise*) searchByPhone:(BOOL)on;


/// 是否可以通过短编号搜索
/// @param on <#on description#>
-(AnyPromise*) searchByShort:(BOOL)on;

// 断网保护
-(AnyPromise*) offlineProtection:(BOOL)on;

// app静音
-(AnyPromise*) muteOfApp:(BOOL)on;

// 设备锁
-(AnyPromise*) deviceLock:(BOOL)on;

// 从服务端刷新登录用户设置
-(AnyPromise*) requestSetting;

@end

NS_ASSUME_NONNULL_END

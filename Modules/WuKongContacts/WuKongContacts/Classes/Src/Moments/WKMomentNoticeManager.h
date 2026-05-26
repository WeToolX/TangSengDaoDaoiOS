//
//  WKMomentNoticeManager.h
//  WuKongContacts
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define WK_NOTIFY_MOMENT_NOTICE_UPDATE @"notify.moment.notice.update"

@interface WKMomentNoticeManager : NSObject
+(instancetype)shared;
@property(nonatomic,assign) NSInteger unreadCount;
@property(nonatomic,assign) NSInteger version;
-(void)sync;
-(void)markAllRead;
@end

NS_ASSUME_NONNULL_END

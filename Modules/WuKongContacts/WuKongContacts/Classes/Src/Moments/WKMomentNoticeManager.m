//
//  WKMomentNoticeManager.m
//  WuKongContacts
//

#import "WKMomentNoticeManager.h"
#import "WKMomentVM.h"
#import <WuKongBase/WuKongBase.h>

static NSString * const WKMomentUnreadKey = @"moment.notice.unread";
static NSString * const WKMomentVersionKey = @"moment.notice.version";

@interface WKMomentNoticeManager ()
@property(nonatomic,strong) WKMomentVM *vm;
@end

@implementation WKMomentNoticeManager

+(instancetype)shared {
    static WKMomentNoticeManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [WKMomentNoticeManager new];
    });
    return manager;
}

-(instancetype)init {
    self = [super init];
    if(self) {
        _vm = [WKMomentVM new];
        _unreadCount = [NSUserDefaults.standardUserDefaults integerForKey:WKMomentUnreadKey];
        _version = [NSUserDefaults.standardUserDefaults integerForKey:WKMomentVersionKey];
    }
    return self;
}

-(void)setUnreadCount:(NSInteger)unreadCount {
    _unreadCount = unreadCount;
    [NSUserDefaults.standardUserDefaults setInteger:unreadCount forKey:WKMomentUnreadKey];
    [NSUserDefaults.standardUserDefaults synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:WK_NOTIFY_CONTACTS_HEADER_UPDATE object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:WK_NOTIFY_CONTACTS_TAB_REDDOT_UPDATE object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:WK_NOTIFY_MOMENT_NOTICE_UPDATE object:nil];
}

-(void)setVersion:(NSInteger)version {
    _version = version;
    [NSUserDefaults.standardUserDefaults setInteger:version forKey:WKMomentVersionKey];
}

-(void)sync {
    [self.vm syncNoticesWithVersion:self.version limit:50].then(^(NSArray<WKMomentNotice*> *notices) {
        NSInteger unread = self.unreadCount;
        NSInteger maxVersion = self.version;
        for(WKMomentNotice *notice in notices ?: @[]) {
            if(!notice.read) {
                unread += 1;
            }
            if(notice.version > maxVersion) {
                maxVersion = notice.version;
            }
        }
        self.version = maxVersion;
        self.unreadCount = unread;
    }).catch(^(NSError *error) {
    });
}

-(void)markAllRead {
    [self.vm readNotices:@[] readAll:YES].then(^{
        self.unreadCount = 0;
    }).catch(^(NSError *error) {
        self.unreadCount = 0;
    });
}

@end

//
//  WKMomentNoticeManager.m
//  WuKongContacts
//

#import "WKMomentNoticeManager.h"
#import "WKMomentVM.h"
#import <WuKongBase/WuKongBase.h>
#import <WuKongIMSDK/WuKongIMSDK.h>
#import <UIKit/UIKit.h>

static NSString * const WKMomentUnreadKey = @"moment.notice.unread";
static NSString * const WKMomentVersionKey = @"moment.notice.version";
static NSString * const WKMomentNoticeSyncCMD = @"momentNoticeSync";

@interface WKMomentNoticeManager ()<WKCMDManagerDelegate>
@property(nonatomic,strong) WKMomentVM *vm;
@property(nonatomic,assign) BOOL syncing;
@property(nonatomic,assign) BOOL needsResync;
@end

@implementation WKMomentNoticeManager

+(instancetype)shared {
    static WKMomentNoticeManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [WKMomentNoticeManager new];
        [[WKSDK shared].cmdManager addDelegate:manager];
    });
    return manager;
}

-(instancetype)init {
    self = [super init];
    if(self) {
        _vm = [WKMomentVM new];
        _unreadCount = [NSUserDefaults.standardUserDefaults integerForKey:[self cacheKey:WKMomentUnreadKey]];
        _version = [NSUserDefaults.standardUserDefaults integerForKey:[self cacheKey:WKMomentVersionKey]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[WKSDK shared].cmdManager removeDelegate:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)setUnreadCount:(NSInteger)unreadCount {
    _unreadCount = unreadCount;
    [NSUserDefaults.standardUserDefaults setInteger:unreadCount forKey:[self cacheKey:WKMomentUnreadKey]];
    [NSUserDefaults.standardUserDefaults synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:WK_NOTIFY_CONTACTS_HEADER_UPDATE object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:WK_NOTIFY_CONTACTS_TAB_REDDOT_UPDATE object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:WK_NOTIFY_MOMENT_NOTICE_UPDATE object:nil];
}

-(void)setVersion:(NSInteger)version {
    _version = version;
    [NSUserDefaults.standardUserDefaults setInteger:version forKey:[self cacheKey:WKMomentVersionKey]];
}

-(void)sync {
    if(![WKApp shared].isLogined) {
        return;
    }
    if(self.syncing) {
        self.needsResync = YES;
        return;
    }
    [self reloadCacheForCurrentUser];
    self.syncing = YES;
    [self.vm syncNoticesWithVersion:self.version limit:50].then(^(NSArray<WKMomentNotice*> *notices) {
        NSInteger baseVersion = self.version;
        NSInteger unread = self.unreadCount;
        NSInteger maxVersion = baseVersion;
        for(WKMomentNotice *notice in notices ?: @[]) {
            if(notice.version <= baseVersion) {
                continue;
            }
            if(!notice.read) {
                unread += 1;
            }
            if(notice.version > maxVersion) {
                maxVersion = notice.version;
            }
        }
        self.version = maxVersion;
        self.unreadCount = unread;
        [self finishSync];
    }).catch(^(NSError *error) {
        [self finishSync];
    });
}

-(void)finishSync {
    self.syncing = NO;
    if(self.needsResync) {
        self.needsResync = NO;
        [self sync];
    }
}

-(void)reloadCacheForCurrentUser {
    _unreadCount = [NSUserDefaults.standardUserDefaults integerForKey:[self cacheKey:WKMomentUnreadKey]];
    _version = [NSUserDefaults.standardUserDefaults integerForKey:[self cacheKey:WKMomentVersionKey]];
}

-(NSString*)cacheKey:(NSString*)key {
    NSString *uid = [WKApp shared].loginInfo.uid ?: @"";
    return uid.length > 0 ? [NSString stringWithFormat:@"%@_%@",uid,key] : key;
}

-(void)markAllRead {
    [self.vm readNotices:@[] readAll:YES].then(^{
        self.unreadCount = 0;
    }).catch(^(NSError *error) {
        self.unreadCount = 0;
    });
}

#pragma mark - WKCMDManagerDelegate

- (void)cmdManager:(WKCMDManager *)manager onCMD:(WKCMDModel *)model {
    if([model.cmd isEqualToString:WKMomentNoticeSyncCMD]) {
        [self sync];
    }
}

#pragma mark - Notifications

-(void)appWillEnterForeground:(NSNotification*)notification {
    [self sync];
}

@end

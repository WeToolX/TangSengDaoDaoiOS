//
//  WKContactsModule.m
//  WuKongContacts
//
//  Created by tt on 2019/12/7.
//

#import "WKContactsModule.h"
#import "WKContactsSync.h"
#import "WKContactsAddVC.h"
#import "WKUserInfoVC.h"
#import "WKContactsFriendRequestVC.h"
#import "WKMyGroupListVC.h"
#import "WKContactsLabelListVC.h"
#import "WKMomentTimelineVC.h"
#import "WKMomentNoticeManager.h"
#import "WKMomentVM.h"
@WKModule(WKContactsModule)

@interface WKContactsModule ()<WKChannelManagerDelegate>

@end

@implementation WKContactsModule


-(NSString*) moduleId {
    return @"WuKongContacts";
}

// 模块初始化
- (void)moduleInit:(WKModuleContext*)context{
    NSLog(@"【WuKongContacts】模块初始化！");
    
    __weak typeof(self) weakSelf = self;
    // 联系人同步
    [self setMethod:WKPOINT_SYNC_CONTACTS handler:^id _Nullable(id  _Nonnull param) {
        return [[WKContactsSync alloc] init];
    } category:WKPOINT_CATEGORY_SYNC];
    
    
     // 显示添加联系人界面
    [[WKApp shared] setMethod:WKPOINT_CONVERSATION_ADDCONTACTS handler:^id _Nullable(id  _Nonnull param) {
        WKContactsAddVC *vc = [WKContactsAddVC new];
        [[WKNavigationManager shared] pushViewController:vc animated:YES];
        return nil;
    }];
    
    
    // 提供联系人选择的数据
    [self setMethod:WKPOINT_CONTACTS_SELECT_DATA handler:^id _Nullable(id  _Nonnull param) {
//        NSArray<WKDBContactsModel*> *contactsList = [[WKDBContacts shared] queryVaild];
        NSArray<WKChannelInfo*> *channelInfos = [[WKChannelInfoDB shared] queryChannelInfosWithStatusAndFollow:WKChannelStatusNormal follow:WKChannelInfoFollowFriend];
        NSMutableArray *items = [NSMutableArray array];
        if(channelInfos) {
            for (WKChannelInfo *channelInfo in channelInfos) {
                if(channelInfo.channel.channelType != WK_PERSON) {
                    continue;
                }
                WKContactsSelect *contacts = [[WKContactsSelect alloc] init];
                contacts.uid =channelInfo.channel.channelId;
                contacts.name = channelInfo.name;
                contacts.displayName =channelInfo.displayName;
                contacts.avatar = [WKAvatarUtil getAvatar:channelInfo.channel.channelId];
                [items addObject:contacts];
            }
        }
        return items;
    }];
    
    
    // 新朋友item
    [self setMethod:@"contacts.header.newFriend" handler:^id _Nullable(id  _Nonnull param) {
        WKContactsHeaderItem *item = [WKContactsHeaderItem initWithSid:WK_CONTACTS_HEADER_ITEM_NEWFRIEND title:LLangW(@"新的朋友",weakSelf) icon:@"Contacts/Index/FriendNew" moduleID:[weakSelf moduleId] onClick:^{
            [[WKContactsManager shared] markAllFriendRequestToReaded]; // 好友请求标记为已读
            // 跳转
            [[WKNavigationManager shared] pushViewController:[WKContactsFriendRequestVC new] animated:YES];
        }];
        int count = [[WKContactsManager shared] getFriendRequestUnreadCount];
        if(count>0) {
            item.badgeValue = [NSString stringWithFormat:@"%d", [[WKContactsManager shared] getFriendRequestUnreadCount]];
        }
        
        return item;
    } category:WKPOINT_CATEGORY_CONTACTSITEM sort:9000];
    
    // 保存的群item
       [self setMethod:@"contacts.header.groupSave" handler:^id _Nullable(id  _Nonnull param) {
           WKContactsHeaderItem *item = [WKContactsHeaderItem initWithSid:WK_CONTACTS_HEADER_ITEM_NEWFRIEND title:LLangW(@"保存的群聊",weakSelf) icon:@"Contacts/Index/GroupSave" moduleID:[weakSelf moduleId] onClick:^{
               // 跳转
               [[WKNavigationManager shared] pushViewController:[WKMyGroupListVC new] animated:YES];
           }];
           return item;
       } category:WKPOINT_CATEGORY_CONTACTSITEM sort:8000];

    // 标签item
    [self setMethod:@"contacts.header.labels" handler:^id _Nullable(id  _Nonnull param) {
        WKContactsHeaderItem *item = [WKContactsHeaderItem initWithSid:@"contacts.header.labels" title:LLangW(@"标签",weakSelf) icon:@"Contacts/Index/Labels" moduleID:[weakSelf moduleId] onClick:^{
            [[WKNavigationManager shared] pushViewController:[WKContactsLabelListVC new] animated:YES];
        }];
        return item;
    } category:WKPOINT_CATEGORY_CONTACTSITEM sort:8500];

    // 朋友圈item
    [self setMethod:@"contacts.header.moments" handler:^id _Nullable(id  _Nonnull param) {
        WKContactsHeaderItem *item = [WKContactsHeaderItem initWithSid:@"contacts.header.moments" title:LLangW(@"朋友圈",weakSelf) icon:@"Contacts/Index/Moments" moduleID:[weakSelf moduleId] onClick:^{
            [[WKNavigationManager shared] pushViewController:[[WKMomentTimelineVC alloc] init] animated:YES];
        }];
        NSInteger count = [WKMomentNoticeManager shared].unreadCount;
        if(count > 0) {
            item.badgeValue = [NSString stringWithFormat:@"%ld",(long)count];
        }
        return item;
    } category:WKPOINT_CATEGORY_CONTACTSITEM sort:8600];

    [self setMethod:@"contacts.tab.moments" handler:^id _Nullable(id  _Nonnull param) {
        NSInteger count = [WKMomentNoticeManager shared].unreadCount;
        return count > 0 ? @(count) : nil;
    } category:WK_CONTACTS_CATEGORY_TAB_REDDOT sort:1000];

    [self setMethod:@"user.info.moments" handler:^id _Nullable(id  _Nonnull param) {
        NSString *uid = param[@"uid"];
        if(uid.length == 0) {
            return nil;
        }
        return @{
            @"height":@(0.0f),
            @"items":@[
                    @{
                        @"class":WKLabelItemModel.class,
                        @"label":LLangW(@"朋友圈",weakSelf),
                        @"onClick":^{
                            [[WKNavigationManager shared] pushViewController:[[WKMomentTimelineVC alloc] initWithUID:uid] animated:YES];
                        }
                    },
            ],
        };
    } category:WKPOINT_CATEGORY_USER_INFO_ITEM sort:3500];

    [self setMethod:@"user.info.momentState" handler:^id _Nullable(id  _Nonnull param) {
        NSString *uid = param[@"uid"];
        if(uid.length == 0 || [uid isEqualToString:[WKApp shared].loginInfo.uid]) {
            return nil;
        }
        NSMutableDictionary *context = param[@"context"];
        if(![context isKindOfClass:NSMutableDictionary.class]) {
            return nil;
        }
        NSString *stateKey = [NSString stringWithFormat:@"moment_state_%@",uid];
        NSString *loadingKey = [NSString stringWithFormat:@"moment_state_loading_%@",uid];
        WKMomentUserState *state = context[stateKey];
        if(!state && ![context[loadingKey] boolValue]) {
            context[loadingKey] = @(YES);
            void (^reload)(void) = param[@"reload"];
            [[WKMomentVM new] userState:uid].then(^(WKMomentUserState *result) {
                if(result) {
                    context[stateKey] = result;
                }
                [context removeObjectForKey:loadingKey];
                if(reload) {
                    reload();
                }
            }).catch(^(NSError *error) {
                [context removeObjectForKey:loadingKey];
            });
        }
        if(!state) {
            return nil;
        }
        NSString *value = LLangW(@"可互相查看",weakSelf);
        if(state.hideMyMoment && state.hideHisMoment) {
            value = [NSString stringWithFormat:@"%@ / %@",LLangW(@"不让他看",weakSelf),LLangW(@"不看他",weakSelf)];
        }else if(state.hideMyMoment) {
            value = LLangW(@"不让他看",weakSelf);
        }else if(state.hideHisMoment) {
            value = LLangW(@"不看他",weakSelf);
        }
        return @{
            @"height":@(0.0f),
            @"items":@[
                    @{
                        @"class":WKMultiLabelItemModel.class,
                        @"mode": @(WKMultiLabelItemModeLeftRight),
                        @"label":LLangW(@"朋友圈状态",weakSelf),
                        @"value":value,
                    },
            ],
        };
    } category:WKPOINT_CATEGORY_USER_INFO_ITEM sort:3450];

    [[WKMomentNoticeManager shared] sync];

    
}

// 模块启动
-(BOOL) moduleDidFinishLaunching:(WKModuleContext *)context{

    
    return true;
}

- (void)moduleDidDatabaseLoad:(WKModuleContext *)context {
    // 初始化db
    [[WKDBMigration shared] migrateDatabase:[self resourceBundle]];
}

@end

//
//  WKContactsLabelModel.m
//  WuKongContacts
//

#import "WKContactsLabelModel.h"
#import <WuKongIMSDK/WuKongIMSDK.h>

@implementation WKContactsLabelMember

+(instancetype)memberWithUID:(NSString*)uid {
    WKContactsLabelMember *member = [WKContactsLabelMember new];
    member.uid = uid ?: @"";
    WKChannelInfo *channelInfo = [[WKSDK shared].channelManager getChannelInfo:[WKChannel personWithChannelID:member.uid]];
    member.name = channelInfo.displayName ?: channelInfo.name ?: member.uid;
    member.avatar = [WKAvatarUtil getAvatar:member.uid];
    return member;
}

@end

@implementation WKContactsLabel

+(WKContactsLabel *)fromMap:(NSDictionary *)dictory type:(ModelMapType)type {
    WKContactsLabel *label = [WKContactsLabel new];
    label.tagId = [dictory[@"id"] integerValue];
    label.name = dictory[@"name"] ?: @"";
    label.sortNo = [dictory[@"sort_no"] integerValue];
    label.version = [dictory[@"version"] integerValue];
    label.isDeleted = [dictory[@"is_deleted"] integerValue];
    label.contactCount = [dictory[@"contact_count"] integerValue];
    label.members = [NSMutableArray array];
    return label;
}

-(NSArray<NSString *> *)memberUIDs {
    NSMutableArray *uids = [NSMutableArray array];
    for (WKContactsLabelMember *member in self.members) {
        if(member.uid && ![member.uid isEqualToString:@""]) {
            [uids addObject:member.uid];
        }
    }
    return uids;
}

- (NSMutableArray<WKContactsLabelMember *> *)members {
    if(!_members) {
        _members = [NSMutableArray array];
    }
    return _members;
}

@end

@implementation WKContactsLabelRelation

+(WKContactsLabelRelation *)fromMap:(NSDictionary *)dictory type:(ModelMapType)type {
    WKContactsLabelRelation *relation = [WKContactsLabelRelation new];
    relation.relationId = [dictory[@"id"] integerValue];
    relation.tagId = [dictory[@"tag_id"] integerValue];
    relation.toUid = dictory[@"to_uid"] ?: @"";
    relation.version = [dictory[@"version"] integerValue];
    relation.isDeleted = [dictory[@"is_deleted"] integerValue];
    return relation;
}

@end

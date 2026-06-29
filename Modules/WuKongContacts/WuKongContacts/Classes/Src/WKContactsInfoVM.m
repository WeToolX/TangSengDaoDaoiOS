//
//  WKContactsInfoVM.m
//  WuKongContacts
//
//  Created by tt on 2020/1/4.
//

#import "WKContactsInfoVM.h"

@implementation WKContactsInfoVM

-(AnyPromise*) getUserInfo:(NSString*)uid {
    return [[WKAPIClient sharedClient] GET:[NSString stringWithFormat:@"users/%@",uid] parameters:nil model:WKUserInfoResp.class];
}
-(AnyPromise*) applyFriend:(NSString*)uid remark:(NSString*)remark {
    return [self applyFriend:uid remark:remark vercode:@""];
}
-(AnyPromise*) applyFriend:(NSString*)uid remark:(NSString*)remark vercode:(NSString*)vercode {
    return [[WKAPIClient sharedClient] POST:@"friend/apply" parameters:@{@"to_uid":uid?:@"",@"remark":remark?:@"",@"vercode":vercode?:@"",@"token":vercode?:@""}];
}
@end

@implementation WKUserInfoResp

+(WKUserInfoResp*) fromMap:(NSDictionary*)dictory type:(ModelMapType)type {
    WKUserInfoResp *resp = [WKUserInfoResp new];
    resp.uid = dictory[@"uid"];
    resp.name = dictory[@"name"];
    resp.avatar = dictory[@"avatar"];
    resp.vercode = dictory[@"vercode"];
    return resp;
}

@end

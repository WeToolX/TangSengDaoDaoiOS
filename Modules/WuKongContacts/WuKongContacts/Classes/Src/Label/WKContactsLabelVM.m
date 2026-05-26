//
//  WKContactsLabelVM.m
//  WuKongContacts
//

#import "WKContactsLabelVM.h"

@implementation WKContactsLabelVM

-(AnyPromise*)labelsFull {
    return [[WKAPIClient sharedClient] GET:@"friend/tags/full" parameters:nil].then(^(NSDictionary *result) {
        NSArray *tagDicts = result[@"tags"];
        NSArray *relationDicts = result[@"relations"];
        NSMutableDictionary<NSNumber*, WKContactsLabel*> *tagMap = [NSMutableDictionary dictionary];
        NSMutableArray<WKContactsLabel*> *labels = [NSMutableArray array];
        for (NSDictionary *tagDict in tagDicts) {
            WKContactsLabel *label = [WKContactsLabel fromMap:tagDict type:ModelMapTypeAPI];
            if(label.isDeleted == 1) {
                continue;
            }
            tagMap[@(label.tagId)] = label;
            [labels addObject:label];
        }
        for (NSDictionary *relationDict in relationDicts) {
            WKContactsLabelRelation *relation = [WKContactsLabelRelation fromMap:relationDict type:ModelMapTypeAPI];
            if(relation.isDeleted == 1 || relation.toUid.length == 0) {
                continue;
            }
            WKContactsLabel *label = tagMap[@(relation.tagId)];
            if(label) {
                [label.members addObject:[WKContactsLabelMember memberWithUID:relation.toUid]];
            }
        }
        [labels sortUsingComparator:^NSComparisonResult(WKContactsLabel *obj1, WKContactsLabel *obj2) {
            if(obj1.sortNo == obj2.sortNo) {
                return obj1.tagId > obj2.tagId ? NSOrderedAscending : NSOrderedDescending;
            }
            return obj1.sortNo > obj2.sortNo ? NSOrderedAscending : NSOrderedDescending;
        }];
        return labels;
    });
}

-(AnyPromise*)createLabel:(NSString*)name uids:(NSArray<NSString*>*)uids {
    return [[WKAPIClient sharedClient] POST:@"friend/tags/create_with_contacts" parameters:@{
        @"name": name ?: @"",
        @"sort_no": @(0),
        @"uids": uids ?: @[],
    } model:WKContactsLabel.class];
}

-(AnyPromise*)updateLabel:(NSInteger)tagId name:(NSString*)name {
    return [[WKAPIClient sharedClient] PUT:[NSString stringWithFormat:@"friend/tags/%ld",(long)tagId] parameters:@{
        @"name": name ?: @"",
        @"sort_no": @(0),
    }];
}

-(AnyPromise*)addContacts:(NSArray<NSString*>*)uids toLabel:(NSInteger)tagId {
    if(!uids || uids.count == 0) {
        return [AnyPromise promiseWithValue:nil];
    }
    return [[WKAPIClient sharedClient] POST:[NSString stringWithFormat:@"friend/tags/%ld/contacts",(long)tagId] parameters:@{
        @"uids": uids,
    }];
}

-(AnyPromise*)removeContact:(NSString*)uid fromLabel:(NSInteger)tagId {
    return [[WKAPIClient sharedClient] DELETE:[NSString stringWithFormat:@"friend/tags/%ld/contacts/%@",(long)tagId,uid] parameters:nil];
}

-(AnyPromise*)deleteLabel:(NSInteger)tagId {
    return [[WKAPIClient sharedClient] DELETE:[NSString stringWithFormat:@"friend/tags/%ld",(long)tagId] parameters:nil];
}

@end

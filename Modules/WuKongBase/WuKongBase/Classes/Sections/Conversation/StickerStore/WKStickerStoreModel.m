//
//  WKStickerStoreModel.m
//  WuKongBase
//

#import "WKStickerStoreModel.h"

static id WKStickerValue(NSDictionary *dict, NSArray<NSString*> *keys) {
    for (NSString *key in keys) {
        id value = dict[key];
        if(value && value != NSNull.null) {
            return value;
        }
    }
    return nil;
}

static NSString *WKStickerString(NSDictionary *dict, NSArray<NSString*> *keys) {
    id value = WKStickerValue(dict, keys);
    if([value isKindOfClass:NSString.class]) {
        return value;
    }
    if([value respondsToSelector:@selector(stringValue)]) {
        return [value stringValue];
    }
    return @"";
}

static NSInteger WKStickerInteger(NSDictionary *dict, NSArray<NSString*> *keys) {
    id value = WKStickerValue(dict, keys);
    return [value respondsToSelector:@selector(integerValue)] ? [value integerValue] : 0;
}

static BOOL WKStickerBool(NSDictionary *dict, NSArray<NSString*> *keys) {
    id value = WKStickerValue(dict, keys);
    return [value respondsToSelector:@selector(boolValue)] ? [value boolValue] : NO;
}

@implementation WKStickerStorePackage

+(WKStickerStorePackage *)fromMap:(NSDictionary *)dictory type:(ModelMapType)type {
    WKStickerStorePackage *package = [WKStickerStorePackage new];
    package.packageId = WKStickerString(dictory, @[@"package_id", @"PackageID", @"packageId", @"category", @"Id", @"id"]);
    package.name = WKStickerString(dictory, @[@"name", @"Name", @"title", @"Title"]);
    package.icon = WKStickerString(dictory, @[@"icon", @"Icon", @"cover", @"Cover"]);
    package.cover = WKStickerString(dictory, @[@"cover", @"Cover", @"icon", @"Icon"]);
    package.desc = WKStickerString(dictory, @[@"description", @"Description", @"desc", @"Desc"]);
    package.tags = WKStickerString(dictory, @[@"tags", @"Tags"]);
    package.itemCount = WKStickerInteger(dictory, @[@"item_count", @"ItemCount", @"itemCount"]);
    package.sortNum = WKStickerInteger(dictory, @[@"sort_num", @"SortNum", @"sortNum"]);
    package.status = WKStickerInteger(dictory, @[@"status", @"Status"]);
    package.added = WKStickerBool(dictory, @[@"is_added", @"IsAdded", @"added", @"Added"]);
    return package;
}

-(WKStickerUserCategoryResp *)toUserCategory {
    WKStickerUserCategoryResp *resp = [WKStickerUserCategoryResp new];
    resp.category = self.packageId ?: @"";
    resp.cover = self.icon.length > 0 ? self.icon : self.cover;
    resp.title = self.name ?: @"";
    resp.desc = self.desc ?: @"";
    resp.sortNum = @(self.sortNum);
    return resp;
}

@end

@implementation WKStickerStoreItem

+(WKStickerStoreItem *)fromMap:(NSDictionary *)dictory type:(ModelMapType)type {
    WKStickerStoreItem *item = [WKStickerStoreItem new];
    item.itemId = WKStickerString(dictory, @[@"item_id", @"ItemID", @"itemId", @"custom_id", @"CustomID", @"id", @"Id"]);
    item.packageId = WKStickerString(dictory, @[@"package_id", @"PackageID", @"packageId"]);
    item.name = WKStickerString(dictory, @[@"name", @"Name"]);
    item.keyword = WKStickerString(dictory, @[@"keyword", @"Keyword"]);
    item.sortNum = WKStickerInteger(dictory, @[@"sort_num", @"SortNum", @"sortNum"]);
    item.originURL = WKStickerString(dictory, @[@"origin_url", @"OriginURL", @"originUrl"]);
    item.gifURL = WKStickerString(dictory, @[@"gif_url", @"GifURL", @"GIFURL", @"gifUrl"]);
    item.thumbURL = WKStickerString(dictory, @[@"thumb_url", @"ThumbURL", @"thumbUrl"]);
    item.originExt = WKStickerString(dictory, @[@"origin_ext", @"OriginExt", @"originExt"]);
    item.sourceMediaType = WKStickerString(dictory, @[@"source_media_type", @"SourceMediaType", @"sourceMediaType"]);
    item.width = WKStickerInteger(dictory, @[@"width", @"Width"]);
    item.height = WKStickerInteger(dictory, @[@"height", @"Height"]);
    return item;
}

-(NSString *)displayURL {
    if(self.gifURL.length > 0) {
        return self.gifURL;
    }
    if(self.originURL.length > 0) {
        return self.originURL;
    }
    return self.thumbURL ?: @"";
}

-(WKSticker *)toSticker {
    WKSticker *sticker = [WKSticker new];
    sticker.path = [self displayURL];
    sticker.category = self.packageId ?: @"";
    sticker.width = @(self.width);
    sticker.height = @(self.height);
    sticker.format = self.originExt.length > 0 ? self.originExt : self.sourceMediaType;
    sticker.sortNum = @(self.sortNum);
    return sticker;
}

@end

@implementation WKStickerStoreListItem

+(WKStickerStoreListItem *)fromMap:(NSDictionary *)dictory type:(ModelMapType)type {
    WKStickerStoreListItem *item = [WKStickerStoreListItem new];
    item.package = [WKStickerStorePackage fromMap:WKStickerValue(dictory, @[@"package", @"Package"]) ?: @{} type:type];
    item.added = WKStickerBool(dictory, @[@"is_added", @"IsAdded", @"added", @"Added"]);
    item.package.added = item.added;
    return item;
}

@end

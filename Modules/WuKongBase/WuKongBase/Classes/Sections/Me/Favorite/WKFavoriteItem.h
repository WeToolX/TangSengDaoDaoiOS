//
//  WKFavoriteItem.h
//  WuKongBase
//

#import <Foundation/Foundation.h>
#import <WuKongIMSDK/WuKongIMSDK.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKFavoriteItem : NSObject

@property(nonatomic,assign) NSInteger favoriteId;
@property(nonatomic,copy) NSString *messageId;
@property(nonatomic,assign) uint32_t messageSeq;
@property(nonatomic,copy) NSString *channelId;
@property(nonatomic,assign) NSInteger channelType;
@property(nonatomic,copy) NSString *author;
@property(nonatomic,copy) NSString *nickname;
@property(nonatomic,assign) NSInteger messageType;
@property(nonatomic,copy) NSString *content;
@property(nonatomic,copy) NSString *imageURL;
@property(nonatomic,copy) NSString *createdAt;
@property(nonatomic,copy) NSString *updatedAt;

+(instancetype)fromMap:(NSDictionary*)dict;
-(BOOL)isImage;
-(WKMessageContent*)toMessageContent;

@end

NS_ASSUME_NONNULL_END

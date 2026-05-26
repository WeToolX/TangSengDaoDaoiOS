//
//  WKContactsLabelModel.h
//  WuKongContacts
//

#import <WuKongBase/WuKongBase.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKContactsLabelMember : NSObject

@property(nonatomic,copy) NSString *uid;
@property(nonatomic,copy) NSString *name;
@property(nonatomic,copy) NSString *avatar;

+(instancetype)memberWithUID:(NSString*)uid;

@end

@interface WKContactsLabel : WKModel

@property(nonatomic,assign) NSInteger tagId;
@property(nonatomic,copy) NSString *name;
@property(nonatomic,assign) NSInteger sortNo;
@property(nonatomic,assign) NSInteger version;
@property(nonatomic,assign) NSInteger isDeleted;
@property(nonatomic,assign) NSInteger contactCount;
@property(nonatomic,strong) NSMutableArray<WKContactsLabelMember*> *members;

-(NSArray<NSString*>*)memberUIDs;

@end

@interface WKContactsLabelRelation : WKModel

@property(nonatomic,assign) NSInteger relationId;
@property(nonatomic,assign) NSInteger tagId;
@property(nonatomic,copy) NSString *toUid;
@property(nonatomic,assign) NSInteger version;
@property(nonatomic,assign) NSInteger isDeleted;

@end

NS_ASSUME_NONNULL_END

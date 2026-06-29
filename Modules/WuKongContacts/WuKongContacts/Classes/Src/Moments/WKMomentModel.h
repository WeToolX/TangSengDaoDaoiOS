//
//  WKMomentModel.h
//  WuKongContacts
//

#import <WuKongBase/WuKongBase.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKMomentActor : WKModel
@property(nonatomic,copy) NSString *uid;
@property(nonatomic,copy) NSString *name;
@property(nonatomic,copy) NSString *avatar;
@property(nonatomic,copy) NSString *cover;
@end

@interface WKMomentMedia : WKModel
@property(nonatomic,copy) NSString *mediaType;
@property(nonatomic,copy) NSString *mediaURL;
@property(nonatomic,copy) NSString *coverURL;
@property(nonatomic,assign) NSInteger width;
@property(nonatomic,assign) NSInteger height;
@property(nonatomic,assign) NSInteger duration;
@property(nonatomic,assign) NSInteger size;
@property(nonatomic,assign) NSInteger sortIndex;
@end

@interface WKMomentComment : WKModel
@property(nonatomic,copy) NSString *commentId;
@property(nonatomic,copy) NSString *content;
@property(nonatomic,strong,nullable) WKMomentActor *user;
@property(nonatomic,copy) NSString *replyCommentId;
@property(nonatomic,copy) NSString *replyUid;
@property(nonatomic,copy) NSString *replyName;
@property(nonatomic,assign) BOOL canDelete;
@property(nonatomic,copy) NSString *createdAt;
@end

@interface WKMomentPost : WKModel
@property(nonatomic,copy) NSString *postId;
@property(nonatomic,copy) NSString *text;
@property(nonatomic,strong,nullable) WKMomentActor *user;
@property(nonatomic,copy) NSString *visibilityType;
@property(nonatomic,copy) NSString *locationName;
@property(nonatomic,copy) NSString *locationAddress;
@property(nonatomic,strong) NSMutableArray<WKMomentMedia*> *medias;
@property(nonatomic,strong) NSMutableArray<WKMomentActor*> *likes;
@property(nonatomic,strong) NSMutableArray<WKMomentComment*> *comments;
@property(nonatomic,strong) NSMutableArray<WKMomentActor*> *mentions;
@property(nonatomic,assign) BOOL canDelete;
@property(nonatomic,assign) BOOL likedByMe;
@property(nonatomic,copy) NSString *createdAt;
+(NSArray<WKMomentPost*>*)postsFromResult:(id)result;
@end

@interface WKMomentProfile : WKModel
@property(nonatomic,copy) NSString *uid;
@property(nonatomic,copy) NSString *cover;
@property(nonatomic,assign) NSInteger version;
@end

@interface WKMomentUserState : WKModel
@property(nonatomic,assign) BOOL hideMyMoment;
@property(nonatomic,assign) BOOL hideHisMoment;
@end

@interface WKMomentNotice : WKModel
@property(nonatomic,assign) NSInteger noticeId;
@property(nonatomic,copy) NSString *noticeType;
@property(nonatomic,assign) BOOL read;
@property(nonatomic,assign) NSInteger version;
@property(nonatomic,strong,nullable) WKMomentActor *fromUser;
@property(nonatomic,copy) NSString *postId;
@property(nonatomic,copy) NSString *commentId;
@property(nonatomic,copy) NSString *content;
@property(nonatomic,copy) NSString *postText;
@property(nonatomic,copy) NSString *postCover;
@property(nonatomic,copy) NSString *createdAt;
+(NSArray<WKMomentNotice*>*)noticesFromResult:(id)result;
@end

@interface WKMomentPublishMedia : NSObject
@property(nonatomic,copy) NSString *mediaURL;
@property(nonatomic,copy) NSString *coverURL;
@property(nonatomic,assign) NSInteger width;
@property(nonatomic,assign) NSInteger height;
@property(nonatomic,assign) NSInteger duration;
@property(nonatomic,assign) NSInteger size;
@end

NS_ASSUME_NONNULL_END

//
//  WKMomentVM.h
//  WuKongContacts
//

#import <WuKongBase/WuKongBase.h>
#import "WKMomentModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface WKMomentVM : WKBaseVM
-(AnyPromise*)timelineWithPageIndex:(NSInteger)pageIndex pageSize:(NSInteger)pageSize;
-(AnyPromise*)userTimeline:(NSString*)uid pageIndex:(NSInteger)pageIndex pageSize:(NSInteger)pageSize;
-(AnyPromise*)profile:(NSString*)uid;
-(AnyPromise*)userState:(NSString*)uid;
-(AnyPromise*)setCover:(NSString*)cover;
-(AnyPromise*)publishText:(NSString*)text imagePaths:(NSArray<NSString*>*)imagePaths video:(nullable WKMomentPublishMedia*)video mention:(NSDictionary*)mention visibility:(NSDictionary*)visibility;
-(AnyPromise*)toggleLike:(NSString*)postId;
-(AnyPromise*)addComment:(NSString*)postId content:(NSString*)content replyCommentId:(nullable NSString*)replyCommentId;
-(AnyPromise*)deleteComment:(NSString*)postId commentId:(NSString*)commentId;
-(AnyPromise*)deletePost:(NSString*)postId;
-(AnyPromise*)syncNoticesWithVersion:(NSInteger)version limit:(NSInteger)limit;
-(AnyPromise*)readNotices:(NSArray<NSNumber*>*)ids readAll:(BOOL)readAll;
-(void)uploadImageData:(NSData*)data type:(NSString*)type completion:(void(^)(NSString * _Nullable path, NSError * _Nullable error))completion;
-(void)uploadFilePath:(NSString*)filePath type:(NSString*)type completion:(void(^)(NSString * _Nullable path, NSError * _Nullable error))completion;
@end

NS_ASSUME_NONNULL_END

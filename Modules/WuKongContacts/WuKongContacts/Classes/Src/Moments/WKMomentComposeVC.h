//
//  WKMomentComposeVC.h
//  WuKongContacts
//

#import <WuKongBase/WuKongBase.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKMomentComposeVC : WKBaseVC
@property(nonatomic,copy) void(^onPublished)(void);
@property(nonatomic,assign) BOOL textOnly;
-(void)setInitialImageDatas:(NSArray<NSData*>*)imageDatas;
-(void)setInitialVideoPath:(NSString*)videoPath cover:(UIImage*)cover;
@end

NS_ASSUME_NONNULL_END

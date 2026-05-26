//
//  WKFileContent.h
//  WuKongBase
//

#import <Foundation/Foundation.h>
#import <WuKongIMSDK/WuKongIMSDK.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKFileContent : WKMediaMessageContent

@property(nonatomic,copy) NSString *name;
@property(nonatomic,assign) long long size;
@property(nonatomic,copy) NSString *ext;

+ (instancetype)fileContentWithPath:(NSString *)path name:(NSString *)name size:(long long)size;

- (NSString *)displaySize;

@end

NS_ASSUME_NONNULL_END

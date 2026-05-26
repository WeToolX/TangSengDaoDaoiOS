//
//  WKBlacklistCell.h
//  WuKongBase
//
//  Created by tt on 2020/6/26.
//

#import <WuKongBase/WuKongBase.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKBlacklistModel : WKModel
@property(nonatomic,copy) NSString *uid;
@property(nonatomic,copy) NSString *name;
@property(nonatomic,copy) NSString *username;

@end

@interface WKBlacklistCell : WKCell

@end

NS_ASSUME_NONNULL_END

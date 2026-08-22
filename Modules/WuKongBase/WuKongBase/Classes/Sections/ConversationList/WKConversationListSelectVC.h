//
//  WKConversationSelectVC.h
//  WuKongBase
//
//  Created by tt on 2020/2/2.
//

#import "WuKongBase.h"
#import "WKConversationListSelectVM.h"
NS_ASSUME_NONNULL_BEGIN

@interface WKConversationListSelectVC : WKBaseTableVC<WKConversationListSelectVM*>


/**
 选中
 */
@property(nonatomic,copy) void(^onSelect)(WKChannel*channel);

/**
 多选完成
 */
@property(nonatomic,copy) void(^onSelectChannels)(NSArray<WKChannel*> *channels);

/// 是否允许多选
@property(nonatomic,assign) BOOL multiple;

@end


NS_ASSUME_NONNULL_END

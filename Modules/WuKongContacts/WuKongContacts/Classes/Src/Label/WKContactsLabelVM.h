//
//  WKContactsLabelVM.h
//  WuKongContacts
//

#import <WuKongBase/WuKongBase.h>
#import "WKContactsLabelModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface WKContactsLabelVM : WKBaseVM

-(AnyPromise*)labelsFull;
-(AnyPromise*)createLabel:(NSString*)name uids:(NSArray<NSString*>*)uids;
-(AnyPromise*)updateLabel:(NSInteger)tagId name:(NSString*)name;
-(AnyPromise*)addContacts:(NSArray<NSString*>*)uids toLabel:(NSInteger)tagId;
-(AnyPromise*)removeContact:(NSString*)uid fromLabel:(NSInteger)tagId;
-(AnyPromise*)deleteLabel:(NSInteger)tagId;

@end

NS_ASSUME_NONNULL_END

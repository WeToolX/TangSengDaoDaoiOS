//
//  WKMessageActionManager.m
//  WuKongBase
//
//  Created by tt on 2022/4/8.
//

#import "WKMessageActionManager.h"
#import "WKConversationListSelectVC.h"
@implementation WKMessageActionManager
static WKMessageActionManager *_instance;
+ (WKMessageActionManager *)shared {
    if (_instance == nil) {
        _instance = [[super alloc]init];
    }
    return _instance;
}

-(void) sendContent:(WKMessageContent *)messageContent toChannels:(NSArray<WKChannel *> *)channels {
    WKMessageContent *content = messageContent;
    if(![[WKApp shared] allowMessageForward:messageContent.realContentType]) {
        content = [[WKTextContent alloc] initWithContent:[messageContent conversationDigest]];
    }
    for(WKChannel *channel in channels) {
        [[WKSDK shared].chatManager forwardMessage:content channel:channel];
    }
}

-(void) forwardMessages:(NSArray<WKMessage*>*)messages{
    WKConversationListSelectVC *vc = [WKConversationListSelectVC new];
    vc.title = LLang(@"选择分享对象");
    vc.multiple = YES;
    [vc setOnSelectChannels:^(NSArray<WKChannel *> * _Nonnull channels) {
        [[WKNavigationManager shared] popViewControllerAnimated:YES];
        for(WKMessage *message in messages) {
            [self sendContent:message.content toChannels:channels];
        }
        [[WKNavigationManager shared].topViewController.view showHUDWithHide:LLang(@"发送成功")];
        
    }];
    [[WKNavigationManager shared] pushViewController:vc animated:YES];
}

-(void) forwardContent:(WKMessageContent*)messageContent complete:(void(^)(void))complete{
    WKConversationListSelectVC *vc = [WKConversationListSelectVC new];
    vc.title = LLang(@"选择分享对象");
    vc.multiple = YES;
    [vc setOnSelectChannels:^(NSArray<WKChannel *> * _Nonnull channels) {
        if(complete) {
            complete();
        }else {
            [[WKNavigationManager shared] popViewControllerAnimated:YES];
        }
        [self sendContent:messageContent toChannels:channels];
        [[WKNavigationManager shared].topViewController.view showHUDWithHide:LLang(@"发送成功")];
        
    }];
    [[WKNavigationManager shared] pushViewController:vc animated:YES];
}

-(void) sendContentToFriend:(WKMessageContent*)messageContent complete:(void(^__nullable)(void))complete {
    WKConversationListSelectVC *vc = [WKConversationListSelectVC new];
    vc.title = LLang(@"选择分享对象");
    vc.multiple = YES;
    [vc setOnSelectChannels:^(NSArray<WKChannel *> * _Nonnull channels) {
        if(complete) {
            complete();
        }else {
            [[WKNavigationManager shared] popViewControllerAnimated:YES];
        }
        for(WKChannel *channel in channels) {
            [[WKSDK shared].chatManager sendMessage:messageContent channel:channel];
        }
        [[WKNavigationManager shared].topViewController.view showHUDWithHide:LLang(@"发送成功")];
        
    }];
    [[WKNavigationManager shared] pushViewController:vc animated:YES];
}

@end

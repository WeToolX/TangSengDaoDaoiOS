//
//  WKConversationSelectVC.m
//  WuKongBase
//
//  Created by tt on 2020/2/2.
//

#import "WKConversationListSelectVC.h"
#import "WKConversationWrapModel.h"
#import <SDWebImage/SDWebImage.h>
#import "WKResource.h"
#import "UIView+WK.h"
#import "WKLabelItemCell.h"
#import "WKIconTitleItemCell.h"
@interface WKConversationListSelectVC ()<WKChannelManagerDelegate,WKConversationListSelectVMDelegate>
@end

@implementation WKConversationListSelectVC


- (instancetype)init
{
    self = [super init];
    if (self) {
        self.viewModel = [WKConversationListSelectVM new];
        self.viewModel.delegate = self;
    }
    return self;
}

- (void)viewDidLoad {
    self.viewModel.multiple = self.multiple;
    [super viewDidLoad];
    [self addDelegates];
    if(self.multiple) {
        [self refreshSelectionBar];
    }
}
-(void) addDelegates {
    // 频道信息监听
    [[[WKSDK shared] channelManager] addDelegate:self];
}

-(void) removeDelegates {
    // 移除频道监听
    [[[WKSDK shared] channelManager] removeDelegate:self];
}
-(void) dealloc {
    [self removeDelegates];
}

-(UIImage*) imageName:(NSString*)name {
    return [WKApp.shared loadImage:name moduleID:@"WuKongBase"];
//    return [[WKResource shared] resourceForImage:name podName:@"WuKongBase_images"];
}

#pragma mark WKConversationListSelectVMDelegate

- (void)conversationListSelectVM:(WKConversationListSelectVM *)vm didSelected:(NSArray<WKChannel *> *)channels {
    if(self.onSelectChannels) {
        self.onSelectChannels(channels);
        return;
    }
    if(self.onSelect) {
        self.onSelect(channels[0]);
    }
}

- (void)conversationListSelectVM:(WKConversationListSelectVM *)vm didChangeSelection:(NSArray<WKChannel *> *)channels {
    [self refreshSelectionBar];
}

- (void)refreshSelectionBar {
    if(!self.multiple) {
        return;
    }
    UIButton *selectAllButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [selectAllButton setTitle:self.viewModel.isAllSelected ? LLang(@"取消全选") : LLang(@"全选") forState:UIControlStateNormal];
    [selectAllButton sizeToFit];
    [selectAllButton addTarget:self action:@selector(selectAllPressed) forControlEvents:UIControlEventTouchUpInside];

    UIButton *finishButton = [UIButton buttonWithType:UIButtonTypeSystem];
    NSString *title = self.viewModel.selectedChannels.count > 0 ? [NSString stringWithFormat:@"%@(%lu)", LLang(@"完成"), (unsigned long)self.viewModel.selectedChannels.count] : LLang(@"完成");
    [finishButton setTitle:title forState:UIControlStateNormal];
    [finishButton setTitleColor:[WKApp shared].config.navBarButtonColor forState:UIControlStateNormal];
    finishButton.enabled = self.viewModel.selectedChannels.count > 0;
    finishButton.alpha = finishButton.enabled ? 1.0f : 0.5f;
    [finishButton sizeToFit];
    [finishButton addTarget:self action:@selector(finishPressed) forControlEvents:UIControlEventTouchUpInside];

    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, selectAllButton.lim_width + finishButton.lim_width + 12.0f, 30.0f)];
    selectAllButton.lim_left = 0.0f;
    selectAllButton.lim_centerY_parent = container;
    finishButton.lim_left = selectAllButton.lim_right + 12.0f;
    finishButton.lim_centerY_parent = container;
    [container addSubview:selectAllButton];
    [container addSubview:finishButton];
    self.rightView = container;
}

- (void)selectAllPressed {
    [self.viewModel toggleSelectAll];
}

- (void)finishPressed {
    if(self.viewModel.selectedChannels.count == 0) {
        return;
    }
    if(self.onSelectChannels) {
        self.onSelectChannels(self.viewModel.selectedChannels);
    }
}

#pragma mark -- WKChannelManagerDelegate
-(void) channelInfoUpdate:(WKChannelInfo*)channelInfo {
    [self reloadData];
    if(self.multiple) {
        [self refreshSelectionBar];
    }
}
@end

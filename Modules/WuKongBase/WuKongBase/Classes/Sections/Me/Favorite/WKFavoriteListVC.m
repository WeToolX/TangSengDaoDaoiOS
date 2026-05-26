//
//  WKFavoriteListVC.m
//  WuKongBase
//

#import "WKFavoriteListVC.h"
#import "WuKongBase.h"
#import "WKFavoriteVM.h"
#import "WKFavoriteDetailVC.h"
#import "WKApp.h"
#import "WKConstant.h"
#import "WKNavigationManager.h"
#import "UIView+WKCommon.h"
#import "UIView+WK.h"
#import <SDWebImage/SDWebImage.h>

@interface WKFavoriteCell : UITableViewCell
@property(nonatomic,strong) UIView *cardView;
@property(nonatomic,strong) UILabel *contentLbl;
@property(nonatomic,strong) UIImageView *thumbView;
@property(nonatomic,strong) UILabel *metaLbl;
-(void)refresh:(WKFavoriteItem*)item;
@end

@implementation WKFavoriteCell

+(NSString*)cellId {
    return @"WKFavoriteCell";
}

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if(self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = UIColor.clearColor;
        [self.contentView addSubview:self.cardView];
        [self.cardView addSubview:self.contentLbl];
        [self.cardView addSubview:self.thumbView];
        [self.cardView addSubview:self.metaLbl];
    }
    return self;
}

-(void)layoutSubviews {
    [super layoutSubviews];
    self.cardView.frame = CGRectMake(12.0f, 6.0f, self.contentView.lim_width - 24.0f, self.contentView.lim_height - 12.0f);
    CGFloat right = self.cardView.lim_width - 12.0f;
    if(!self.thumbView.hidden) {
        self.thumbView.frame = CGRectMake(self.cardView.lim_width - 76.0f, 12.0f, 64.0f, 64.0f);
        right = self.thumbView.lim_left - 10.0f;
    }
    self.contentLbl.frame = CGRectMake(12.0f, 12.0f, right - 12.0f, 52.0f);
    self.metaLbl.frame = CGRectMake(12.0f, self.cardView.lim_height - 28.0f, self.cardView.lim_width - 24.0f, 18.0f);
}

-(void)refresh:(WKFavoriteItem *)item {
    self.contentLbl.text = [item isImage] ? (item.content.length > 0 ? item.content : LLang(@"[图片]")) : item.content;
    self.metaLbl.text = [NSString stringWithFormat:@"%@  %@",item.nickname.length > 0 ? item.nickname : item.author,item.createdAt ?: @""];
    self.thumbView.hidden = ![item isImage];
    if([item isImage]) {
        [self.thumbView sd_setImageWithURL:[[WKApp shared] getImageFullUrl:item.imageURL]];
    }else {
        self.thumbView.image = nil;
    }
}

-(UIView*)cardView {
    if(!_cardView) {
        _cardView = [UIView new];
        _cardView.backgroundColor = WKApp.shared.config.cellBackgroundColor;
        _cardView.layer.cornerRadius = 7.0f;
    }
    return _cardView;
}

-(UILabel*)contentLbl {
    if(!_contentLbl) {
        _contentLbl = [UILabel new];
        _contentLbl.numberOfLines = 2;
        _contentLbl.font = [WKApp.shared.config appFontOfSize:15.0f];
        _contentLbl.textColor = WKApp.shared.config.defaultTextColor;
    }
    return _contentLbl;
}

-(UIImageView*)thumbView {
    if(!_thumbView) {
        _thumbView = [UIImageView new];
        _thumbView.contentMode = UIViewContentModeScaleAspectFill;
        _thumbView.clipsToBounds = YES;
        _thumbView.layer.cornerRadius = 4.0f;
        _thumbView.backgroundColor = [UIColor colorWithWhite:0.94f alpha:1.0f];
    }
    return _thumbView;
}

-(UILabel*)metaLbl {
    if(!_metaLbl) {
        _metaLbl = [UILabel new];
        _metaLbl.font = [WKApp.shared.config appFontOfSize:12.0f];
        _metaLbl.textColor = [UIColor colorWithWhite:0.58f alpha:1.0f];
    }
    return _metaLbl;
}

@end

@interface WKFavoriteListVC ()<UITableViewDataSource,UITableViewDelegate>
@property(nonatomic,strong) UITableView *tableView;
@property(nonatomic,strong) NSMutableArray<WKFavoriteItem*> *items;
@property(nonatomic,strong) WKFavoriteVM *vm;
@property(nonatomic,assign) NSInteger page;
@property(nonatomic,assign) BOOL loading;
@property(nonatomic,assign) BOOL hasMore;
@end

@implementation WKFavoriteListVC

-(NSString*)langTitle {
    return LLang(@"我的收藏");
}

-(void)viewDidLoad {
    [super viewDidLoad];
    self.vm = [WKFavoriteVM new];
    self.items = [NSMutableArray array];
    self.page = 1;
    self.hasMore = YES;
    self.view.backgroundColor = WKApp.shared.config.backgroundColor;
    [self.view addSubview:self.tableView];
    [self requestFirstPage];
}

-(void)requestFirstPage {
    self.page = 1;
    self.hasMore = YES;
    [self requestData:YES];
}

-(void)requestData:(BOOL)reset {
    if(self.loading) {
        return;
    }
    self.loading = YES;
    __weak typeof(self) weakSelf = self;
    if(reset) {
        [self.view showHUD];
    }
    [self.vm favoritesWithPage:self.page limit:20 type:@"all"].then(^id(NSArray<WKFavoriteItem*> *list) {
        [weakSelf.view hideHud];
        [weakSelf.tableView.refreshControl endRefreshing];
        weakSelf.loading = NO;
        if(reset) {
            [weakSelf.items removeAllObjects];
        }
        [weakSelf.items addObjectsFromArray:list];
        weakSelf.hasMore = list.count >= 20;
        [weakSelf.tableView reloadData];
        return nil;
    }).catch(^(NSError *error) {
        [weakSelf.view hideHud];
        [weakSelf.tableView.refreshControl endRefreshing];
        weakSelf.loading = NO;
        [weakSelf.view showHUDWithHide:error.domain];
    });
}

-(UITableView*)tableView {
    if(!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:[self visibleRect] style:UITableViewStylePlain];
        _tableView.backgroundColor = UIColor.clearColor;
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.tableFooterView = [UIView new];
        [_tableView registerClass:WKFavoriteCell.class forCellReuseIdentifier:[WKFavoriteCell cellId]];
        UIRefreshControl *refresh = [UIRefreshControl new];
        [refresh addTarget:self action:@selector(requestFirstPage) forControlEvents:UIControlEventValueChanged];
        _tableView.refreshControl = refresh;
    }
    return _tableView;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.items.count;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WKFavoriteCell *cell = [tableView dequeueReusableCellWithIdentifier:[WKFavoriteCell cellId] forIndexPath:indexPath];
    [cell refresh:self.items[indexPath.row]];
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    WKFavoriteItem *item = self.items[indexPath.row];
    if([item isImage]) {
        return 98.0f;
    }
    CGFloat width = WKScreenWidth - 48.0f;
    CGRect rect = [item.content boundingRectWithSize:CGSizeMake(width, 44.0f) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[WKApp.shared.config appFontOfSize:15.0f]} context:nil];
    return MAX(82.0f, rect.size.height + 48.0f);
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [[WKNavigationManager shared] pushViewController:[[WKFavoriteDetailVC alloc] initWithItem:self.items[indexPath.row]] animated:YES];
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if(editingStyle != UITableViewCellEditingStyleDelete) {
        return;
    }
    WKFavoriteItem *item = self.items[indexPath.row];
    __weak typeof(self) weakSelf = self;
    [self.vm deleteFavorite:item].then(^id(id value) {
        [weakSelf.items removeObject:item];
        [weakSelf.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        return nil;
    }).catch(^(NSError *error) {
        [weakSelf.view showHUDWithHide:error.domain];
    });
}

-(NSString*)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return LLang(@"删除");
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if(!self.hasMore || self.loading || self.items.count == 0) {
        return;
    }
    CGFloat threshold = scrollView.contentSize.height - scrollView.lim_height - 80.0f;
    if(scrollView.contentOffset.y > threshold) {
        self.page += 1;
        [self requestData:NO];
    }
}

@end

//
//  WKStickerStoreListVC.m
//  WuKongBase
//

#import "WKStickerStoreListVC.h"
#import "WKStickerStoreVM.h"
#import "WKStickerStoreDetailVC.h"
#import "WKStickerMyPackagesVC.h"
#import "WuKongBase.h"
#import "UIView+WK.h"
#import "UIView+WKCommon.h"

@interface WKStickerStorePackageCell : UITableViewCell

@property(nonatomic,strong) UIImageView *iconView;
@property(nonatomic,strong) UILabel *nameLbl;
@property(nonatomic,strong) UILabel *descLbl;
@property(nonatomic,strong) UIButton *actionBtn;
@property(nonatomic,strong) WKStickerStoreListItem *item;
@property(nonatomic,copy) void(^onAction)(WKStickerStoreListItem *item);

-(void)refresh:(WKStickerStoreListItem*)item;

@end

@implementation WKStickerStorePackageCell

+(NSString*)cellId {
    return @"WKStickerStorePackageCell";
}

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if(self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = WKApp.shared.config.cellBackgroundColor;
        [self.contentView addSubview:self.iconView];
        [self.contentView addSubview:self.nameLbl];
        [self.contentView addSubview:self.descLbl];
        [self.contentView addSubview:self.actionBtn];
    }
    return self;
}

-(UIImageView *)iconView {
    if(!_iconView) {
        _iconView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 54.0f, 54.0f)];
        _iconView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _iconView;
}

-(UILabel *)nameLbl {
    if(!_nameLbl) {
        _nameLbl = [UILabel new];
        _nameLbl.textColor = WKApp.shared.config.defaultTextColor;
        _nameLbl.font = [WKApp.shared.config appFontOfSize:18.0f];
    }
    return _nameLbl;
}

-(UILabel *)descLbl {
    if(!_descLbl) {
        _descLbl = [UILabel new];
        _descLbl.textColor = WKApp.shared.config.tipColor;
        _descLbl.font = [WKApp.shared.config appFontOfSize:14.0f];
    }
    return _descLbl;
}

-(UIButton *)actionBtn {
    if(!_actionBtn) {
        _actionBtn = [[UIButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 88.0f, 38.0f)];
        _actionBtn.layer.cornerRadius = 19.0f;
        _actionBtn.layer.masksToBounds = YES;
        _actionBtn.titleLabel.font = [WKApp.shared.config appFontOfSizeMedium:17.0f];
        [_actionBtn addTarget:self action:@selector(actionPressed) forControlEvents:UIControlEventTouchUpInside];
    }
    return _actionBtn;
}

-(void)refresh:(WKStickerStoreListItem *)item {
    self.item = item;
    WKStickerStorePackage *package = item.package;
    [self.iconView lim_setImageWithURL:[WKApp.shared getFileFullUrl:package.icon.length > 0 ? package.icon : package.cover]];
    self.nameLbl.text = package.name;
    self.descLbl.text = package.desc.length > 0 ? package.desc : [NSString stringWithFormat:LLang(@"%ld个表情"),(long)package.itemCount];
    NSString *title = item.added ? LLang(@"移除") : LLang(@"添加");
    [self.actionBtn setTitle:title forState:UIControlStateNormal];
    if(item.added) {
        self.actionBtn.backgroundColor = [UIColor colorWithRed:245.0f/255.0f green:245.0f/255.0f blue:245.0f/255.0f alpha:1.0f];
        [self.actionBtn setTitleColor:[UIColor colorWithRed:210.0f/255.0f green:0.0f blue:10.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
    }else {
        self.actionBtn.backgroundColor = WKApp.shared.config.navBarButtonColor;
        [self.actionBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
}

-(void)layoutSubviews {
    [super layoutSubviews];
    self.iconView.lim_left = 24.0f;
    self.iconView.lim_top = (self.contentView.lim_height - self.iconView.lim_height)/2.0f;
    self.actionBtn.lim_left = self.contentView.lim_width - self.actionBtn.lim_width - 20.0f;
    self.actionBtn.lim_top = (self.contentView.lim_height - self.actionBtn.lim_height)/2.0f;
    self.nameLbl.lim_left = self.iconView.lim_right + 18.0f;
    self.nameLbl.lim_top = 26.0f;
    self.nameLbl.lim_width = self.actionBtn.lim_left - self.nameLbl.lim_left - 12.0f;
    self.nameLbl.lim_height = 24.0f;
    self.descLbl.lim_left = self.nameLbl.lim_left;
    self.descLbl.lim_top = self.nameLbl.lim_bottom + 8.0f;
    self.descLbl.lim_width = self.nameLbl.lim_width;
    self.descLbl.lim_height = 20.0f;
}

-(void)actionPressed {
    if(self.onAction) {
        self.onAction(self.item);
    }
}

@end

@interface WKStickerStoreListVC ()<UITableViewDataSource,UITableViewDelegate>

@property(nonatomic,strong) UITableView *tableView;
@property(nonatomic,strong) UIButton *manageBtn;
@property(nonatomic,strong) WKStickerStoreVM *vm;
@property(nonatomic,strong) NSMutableArray<WKStickerStoreListItem*> *items;

@end

@implementation WKStickerStoreListVC

-(instancetype)init {
    self = [super init];
    if(self) {
        _vm = [WKStickerStoreVM new];
        _items = [NSMutableArray array];
    }
    return self;
}

-(void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.tableView];
    self.rightView = self.manageBtn;
    [self requestData];
}

-(NSString *)langTitle {
    return LLang(@"表情商店");
}

-(UIButton *)manageBtn {
    if(!_manageBtn) {
        _manageBtn = [[UIButton alloc] init];
        [_manageBtn setTitle:LLang(@"管理") forState:UIControlStateNormal];
        [_manageBtn setTitleColor:WKApp.shared.config.defaultTextColor forState:UIControlStateNormal];
        _manageBtn.titleLabel.font = [WKApp.shared.config appFontOfSize:15.0f];
        [_manageBtn sizeToFit];
        [_manageBtn addTarget:self action:@selector(managePressed) forControlEvents:UIControlEventTouchUpInside];
    }
    return _manageBtn;
}

-(UITableView *)tableView {
    if(!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:[self visibleRect] style:UITableViewStylePlain];
        _tableView.backgroundColor = WKApp.shared.config.cellBackgroundColor;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.tableFooterView = [UIView new];
        [_tableView registerClass:WKStickerStorePackageCell.class forCellReuseIdentifier:[WKStickerStorePackageCell cellId]];
    }
    return _tableView;
}

-(void)requestData {
    __weak typeof(self) weakSelf = self;
    [self.vm storePackages:nil pageIndex:1 pageSize:100].then(^(NSArray<WKStickerStoreListItem*> *items) {
        [weakSelf.items removeAllObjects];
        [weakSelf.items addObjectsFromArray:items ?: @[]];
        [weakSelf.tableView reloadData];
    }).catch(^(NSError *error) {
        [weakSelf.view showHUDWithHide:error.domain];
    });
}

-(void)managePressed {
    [[WKNavigationManager shared] pushViewController:[WKStickerMyPackagesVC new] animated:YES];
}

-(void)toggleItem:(WKStickerStoreListItem*)item {
    if(item.package.packageId.length == 0) {
        [self.view showHUDWithHide:LLang(@"表情包不存在")];
        return;
    }
    __weak typeof(self) weakSelf = self;
    self.view.userInteractionEnabled = NO;
    AnyPromise *promise = item.added ? [self.vm removePackage:item.package.packageId] : [self.vm addPackage:item.package.packageId];
    promise.then(^{
        weakSelf.view.userInteractionEnabled = YES;
        item.added = !item.added;
        item.package.added = item.added;
        [weakSelf.tableView reloadData];
        [[WKStickerManager shared] loadUserCategory];
    }).catch(^(NSError *error) {
        weakSelf.view.userInteractionEnabled = YES;
        [weakSelf.view showHUDWithHide:error.domain];
    });
}

#pragma mark - UITableView

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.items.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WKStickerStorePackageCell *cell = [tableView dequeueReusableCellWithIdentifier:[WKStickerStorePackageCell cellId] forIndexPath:indexPath];
    WKStickerStoreListItem *item = self.items[indexPath.row];
    [cell refresh:item];
    __weak typeof(self) weakSelf = self;
    cell.onAction = ^(WKStickerStoreListItem *item) {
        [weakSelf toggleItem:item];
    };
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 108.0f;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    WKStickerStoreListItem *item = self.items[indexPath.row];
    WKStickerStoreDetailVC *vc = [[WKStickerStoreDetailVC alloc] initWithPackage:item.package];
    __weak typeof(self) weakSelf = self;
    vc.onChanged = ^{
        [weakSelf requestData];
    };
    [[WKNavigationManager shared] pushViewController:vc animated:YES];
}

@end

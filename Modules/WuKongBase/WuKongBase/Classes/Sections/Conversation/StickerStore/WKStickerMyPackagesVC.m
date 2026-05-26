//
//  WKStickerMyPackagesVC.m
//  WuKongBase
//

#import "WKStickerMyPackagesVC.h"
#import "WKStickerStoreVM.h"
#import "WuKongBase.h"
#import "UIView+WK.h"
#import "UIView+WKCommon.h"

@interface WKStickerMyPackageCell : UITableViewCell

@property(nonatomic,strong) UIImageView *iconView;
@property(nonatomic,strong) UILabel *nameLbl;
@property(nonatomic,strong) UIButton *removeBtn;
@property(nonatomic,strong) WKStickerStorePackage *package;
@property(nonatomic,copy) void(^onRemove)(WKStickerStorePackage *package);

-(void)refresh:(WKStickerStorePackage*)package;

@end

@implementation WKStickerMyPackageCell

+(NSString*)cellId {
    return @"WKStickerMyPackageCell";
}

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if(self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = WKApp.shared.config.cellBackgroundColor;
        [self.contentView addSubview:self.iconView];
        [self.contentView addSubview:self.nameLbl];
        [self.contentView addSubview:self.removeBtn];
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

-(UIButton *)removeBtn {
    if(!_removeBtn) {
        _removeBtn = [[UIButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 88.0f, 38.0f)];
        _removeBtn.layer.cornerRadius = 19.0f;
        _removeBtn.layer.masksToBounds = YES;
        _removeBtn.backgroundColor = [UIColor colorWithRed:245.0f/255.0f green:245.0f/255.0f blue:245.0f/255.0f alpha:1.0f];
        [_removeBtn setTitle:LLang(@"移除") forState:UIControlStateNormal];
        [_removeBtn setTitleColor:[UIColor colorWithRed:210.0f/255.0f green:0.0f blue:10.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
        _removeBtn.titleLabel.font = [WKApp.shared.config appFontOfSizeMedium:17.0f];
        [_removeBtn addTarget:self action:@selector(removePressed) forControlEvents:UIControlEventTouchUpInside];
    }
    return _removeBtn;
}

-(void)refresh:(WKStickerStorePackage *)package {
    self.package = package;
    [self.iconView lim_setImageWithURL:[WKApp.shared getFileFullUrl:package.icon.length > 0 ? package.icon : package.cover]];
    self.nameLbl.text = package.name;
}

-(void)layoutSubviews {
    [super layoutSubviews];
    self.iconView.lim_left = 24.0f;
    self.iconView.lim_top = (self.contentView.lim_height - self.iconView.lim_height)/2.0f;
    self.removeBtn.lim_left = self.contentView.lim_width - self.removeBtn.lim_width - 20.0f;
    self.removeBtn.lim_top = (self.contentView.lim_height - self.removeBtn.lim_height)/2.0f;
    self.nameLbl.lim_left = self.iconView.lim_right + 18.0f;
    self.nameLbl.lim_top = 0.0f;
    self.nameLbl.lim_width = self.removeBtn.lim_left - self.nameLbl.lim_left - 12.0f;
    self.nameLbl.lim_height = self.contentView.lim_height;
}

-(void)removePressed {
    if(self.onRemove) {
        self.onRemove(self.package);
    }
}

@end

@interface WKStickerMyPackagesVC ()<UITableViewDataSource,UITableViewDelegate>

@property(nonatomic,strong) WKStickerStoreVM *vm;
@property(nonatomic,strong) UITableView *tableView;
@property(nonatomic,strong) NSMutableArray<WKStickerStorePackage*> *items;

@end

@implementation WKStickerMyPackagesVC

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
    [self requestData];
}

-(NSString *)langTitle {
    return LLang(@"我的表情");
}

-(UITableView *)tableView {
    if(!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:[self visibleRect] style:UITableViewStylePlain];
        _tableView.backgroundColor = WKApp.shared.config.cellBackgroundColor;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.tableFooterView = [UIView new];
        [_tableView registerClass:WKStickerMyPackageCell.class forCellReuseIdentifier:[WKStickerMyPackageCell cellId]];
    }
    return _tableView;
}

-(void)requestData {
    __weak typeof(self) weakSelf = self;
    [self.vm myPackages].then(^(NSArray<WKStickerStorePackage*> *items) {
        [weakSelf.items removeAllObjects];
        [weakSelf.items addObjectsFromArray:items ?: @[]];
        [weakSelf.tableView reloadData];
    }).catch(^(NSError *error) {
        [weakSelf.view showHUDWithHide:error.domain];
    });
}

-(void)removePackage:(WKStickerStorePackage*)package {
    __weak typeof(self) weakSelf = self;
    [self.vm removePackage:package.packageId].then(^{
        [weakSelf.items removeObject:package];
        [weakSelf.tableView reloadData];
        [[WKStickerManager shared] loadUserCategory];
    }).catch(^(NSError *error) {
        [weakSelf.view showHUDWithHide:error.domain];
    });
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.items.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WKStickerMyPackageCell *cell = [tableView dequeueReusableCellWithIdentifier:[WKStickerMyPackageCell cellId] forIndexPath:indexPath];
    [cell refresh:self.items[indexPath.row]];
    __weak typeof(self) weakSelf = self;
    cell.onRemove = ^(WKStickerStorePackage *package) {
        [weakSelf removePackage:package];
    };
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 108.0f;
}

@end

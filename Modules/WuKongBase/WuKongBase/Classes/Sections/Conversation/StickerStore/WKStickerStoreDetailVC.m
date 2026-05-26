//
//  WKStickerStoreDetailVC.m
//  WuKongBase
//

#import "WKStickerStoreDetailVC.h"
#import "WKStickerStoreVM.h"
#import "WKStickerImageView.h"
#import "WuKongBase.h"
#import "UIView+WK.h"
#import "UIView+WKCommon.h"

@interface WKStickerStoreItemCell : UICollectionViewCell

@property(nonatomic,strong) WKStickerImageView *stickerView;
-(void)refresh:(WKStickerStoreItem*)item;

@end

@implementation WKStickerStoreItemCell

+(NSString*)cellId {
    return @"WKStickerStoreItemCell";
}

-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        _stickerView = [[WKStickerImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 78.0f, 78.0f)];
        [self.contentView addSubview:_stickerView];
    }
    return self;
}

-(void)refresh:(WKStickerStoreItem *)item {
    self.stickerView.stickerURL = [WKApp.shared getFileFullUrl:[item displayURL]];
    self.stickerView.isPlay = YES;
}

-(void)layoutSubviews {
    [super layoutSubviews];
    self.stickerView.lim_left = (self.contentView.lim_width - self.stickerView.lim_width)/2.0f;
    self.stickerView.lim_top = (self.contentView.lim_height - self.stickerView.lim_height)/2.0f;
}

@end

@interface WKStickerStoreHeaderCell : UICollectionViewCell
@end

@implementation WKStickerStoreHeaderCell
+(NSString*)cellId {
    return @"WKStickerStoreHeaderCell";
}
@end

@interface WKStickerStoreDetailVC ()<UICollectionViewDataSource,UICollectionViewDelegateFlowLayout>

@property(nonatomic,strong) WKStickerStoreVM *vm;
@property(nonatomic,strong) WKStickerStorePackage *package;
@property(nonatomic,strong) NSMutableArray<WKStickerStoreItem*> *items;
@property(nonatomic,strong) UICollectionView *collectionView;
@property(nonatomic,strong) UIView *headerView;
@property(nonatomic,strong) UIButton *actionBtn;
@property(nonatomic,strong) UILabel *nameLbl;
@property(nonatomic,strong) UILabel *descLbl;

@end

@implementation WKStickerStoreDetailVC

-(instancetype)initWithPackage:(WKStickerStorePackage *)package {
    self = [super init];
    if(self) {
        _package = package;
        _vm = [WKStickerStoreVM new];
        _items = [NSMutableArray array];
    }
    return self;
}

-(void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.collectionView];
    [self requestData];
}

-(NSString *)langTitle {
    return self.package.name ?: LLang(@"表情详情");
}

-(UIView *)headerView {
    if(!_headerView) {
        _headerView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, WKScreenWidth, 150.0f)];
        _headerView.backgroundColor = WKApp.shared.config.backgroundColor;
        [_headerView addSubview:self.nameLbl];
        [_headerView addSubview:self.descLbl];
        [_headerView addSubview:self.actionBtn];
    }
    return _headerView;
}

-(UILabel *)nameLbl {
    if(!_nameLbl) {
        _nameLbl = [[UILabel alloc] initWithFrame:CGRectMake(18.0f, 32.0f, WKScreenWidth - 150.0f, 28.0f)];
        _nameLbl.font = [WKApp.shared.config appFontOfSizeMedium:22.0f];
        _nameLbl.textColor = WKApp.shared.config.defaultTextColor;
        _nameLbl.text = self.package.name;
    }
    return _nameLbl;
}

-(UILabel *)descLbl {
    if(!_descLbl) {
        _descLbl = [[UILabel alloc] initWithFrame:CGRectMake(18.0f, self.nameLbl.lim_bottom + 12.0f, WKScreenWidth - 150.0f, 24.0f)];
        _descLbl.font = [WKApp.shared.config appFontOfSize:16.0f];
        _descLbl.textColor = WKApp.shared.config.tipColor;
        _descLbl.text = self.package.desc;
    }
    return _descLbl;
}

-(UIButton *)actionBtn {
    if(!_actionBtn) {
        _actionBtn = [[UIButton alloc] initWithFrame:CGRectMake(WKScreenWidth - 120.0f, 42.0f, 96.0f, 44.0f)];
        _actionBtn.layer.cornerRadius = 22.0f;
        _actionBtn.layer.masksToBounds = YES;
        _actionBtn.titleLabel.font = [WKApp.shared.config appFontOfSizeMedium:17.0f];
        [_actionBtn addTarget:self action:@selector(actionPressed) forControlEvents:UIControlEventTouchUpInside];
        [self refreshActionBtn];
    }
    return _actionBtn;
}

-(UICollectionView *)collectionView {
    if(!_collectionView) {
        UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
        layout.minimumLineSpacing = 18.0f;
        layout.minimumInteritemSpacing = 4.0f;
        _collectionView = [[UICollectionView alloc] initWithFrame:[self visibleRect] collectionViewLayout:layout];
        _collectionView.backgroundColor = WKApp.shared.config.backgroundColor;
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        _collectionView.contentInset = UIEdgeInsetsMake(0.0f, 10.0f, 20.0f, 10.0f);
        [_collectionView registerClass:WKStickerStoreItemCell.class forCellWithReuseIdentifier:[WKStickerStoreItemCell cellId]];
        [_collectionView registerClass:WKStickerStoreHeaderCell.class forCellWithReuseIdentifier:[WKStickerStoreHeaderCell cellId]];
        _collectionView.alwaysBounceVertical = YES;
    }
    return _collectionView;
}

-(void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.collectionView.frame = [self visibleRect];
}

-(void)refreshActionBtn {
    NSString *title = self.package.added ? LLang(@"已添加") : LLang(@"添加");
    [self.actionBtn setTitle:title forState:UIControlStateNormal];
    if(self.package.added) {
        self.actionBtn.backgroundColor = [WKApp.shared.config.navBarButtonColor colorWithAlphaComponent:0.18f];
        [self.actionBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.actionBtn.enabled = NO;
    }else {
        self.actionBtn.backgroundColor = WKApp.shared.config.navBarButtonColor;
        [self.actionBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.actionBtn.enabled = YES;
    }
}

-(void)requestData {
    __weak typeof(self) weakSelf = self;
    [self.vm packageDetail:self.package.packageId].then(^(WKStickerStorePackage *package, NSArray<WKStickerStoreItem*> *items) {
        weakSelf.package.name = package.name.length > 0 ? package.name : weakSelf.package.name;
        weakSelf.package.desc = package.desc.length > 0 ? package.desc : weakSelf.package.desc;
        weakSelf.nameLbl.text = weakSelf.package.name;
        weakSelf.descLbl.text = weakSelf.package.desc;
        [weakSelf.items removeAllObjects];
        [weakSelf.items addObjectsFromArray:items ?: @[]];
        [weakSelf.collectionView reloadData];
    }).catch(^(NSError *error) {
        [weakSelf.view showHUDWithHide:error.domain];
    });
}

-(void)actionPressed {
    __weak typeof(self) weakSelf = self;
    [self.view showHUD];
    [self.vm addPackage:self.package.packageId].then(^{
        [weakSelf.view hideHud];
        weakSelf.package.added = YES;
        [weakSelf refreshActionBtn];
        if(weakSelf.onChanged) {
            weakSelf.onChanged();
        }
        [[WKStickerManager shared] loadUserCategory];
    }).catch(^(NSError *error) {
        [weakSelf.view hideHud];
        [weakSelf.view showHUDWithHide:error.domain];
    });
}

#pragma mark - UICollectionView

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 2;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return section == 0 ? 1 : self.items.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0) {
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[WKStickerStoreHeaderCell cellId] forIndexPath:indexPath];
        for (UIView *subview in cell.contentView.subviews) {
            [subview removeFromSuperview];
        }
        [cell.contentView addSubview:self.headerView];
        return cell;
    }
    WKStickerStoreItemCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[WKStickerStoreItemCell cellId] forIndexPath:indexPath];
    [cell refresh:self.items[indexPath.item]];
    return cell;
}

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0) {
        return CGSizeMake(WKScreenWidth - 20.0f, 150.0f);
    }
    CGFloat width = floor((WKScreenWidth - 20.0f) / 5.0f);
    return CGSizeMake(width, 92.0f);
}

@end

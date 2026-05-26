//
//  WKStickerPackageContentView.m
//  WuKongBase
//

#import "WKStickerPackageContentView.h"
#import "WKStickerStoreVM.h"
#import "WKCollectionViewGridLayout.h"
#import "WKStickerGIFCell.h"
#import "WKLottieStickerContent.h"
#import "WKStickerPackage.h"
#import "WuKongBase.h"
#import "UIView+WK.h"

@interface WKStickerPackageContentView ()<UICollectionViewDataSource,UICollectionViewDelegate>

@property(nonatomic,strong) UICollectionView *collectionView;
@property(nonatomic,strong) WKStickerStoreVM *vm;
@property(nonatomic,strong) WKStickerUserCategoryResp *categoryResp;
@property(nonatomic,strong) NSMutableArray<WKSticker*> *stickers;
@property(nonatomic,strong) UIImageView *tabIconView;
@property(nonatomic,assign) BOOL selectedInner;

@end

@implementation WKStickerPackageContentView

-(instancetype)initWithCategory:(WKStickerUserCategoryResp *)category {
    self = [super init];
    if(self) {
        _categoryResp = category;
        _vm = [WKStickerStoreVM new];
        _stickers = [NSMutableArray array];
        [self addSubview:self.collectionView];
    }
    return self;
}

-(void)loadData {
    if(self.stickers.count > 0 || self.categoryResp.category.length == 0) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    [self.vm packageDetail:self.categoryResp.category].then(^(WKStickerStorePackage *package, NSArray<WKStickerStoreItem*> *items) {
        [weakSelf.stickers removeAllObjects];
        for (WKStickerStoreItem *item in items) {
            WKSticker *sticker = [item toSticker];
            sticker.isPlay = weakSelf.selected;
            [weakSelf.stickers addObject:sticker];
        }
        [weakSelf.collectionView reloadData];
    });
}

-(UIView *)customTabView {
    if(!_tabIconView) {
        _tabIconView = [[UIImageView alloc] init];
        _tabIconView.contentMode = UIViewContentModeScaleAspectFit;
        [_tabIconView lim_setImageWithURL:[WKApp.shared getFileFullUrl:self.categoryResp.cover]];
    }
    return _tabIconView;
}

- (void)setSelected:(BOOL)selected {
    BOOL change = self.selectedInner != selected;
    self.selectedInner = selected;
    if(change) {
        [self.collectionView reloadData];
    }
    if(!selected) {
        NSArray<WKStickerGIFCell*> *cells = self.collectionView.visibleCells;
        for (WKStickerGIFCell *cell in cells) {
            [cell onEndDisplay];
        }
    }
}

- (BOOL)selected {
    return self.selectedInner;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.collectionView.lim_size = self.lim_size;
}

+(WKCollectionViewGridLayout *)newGridLayout {
    WKCollectionViewGridLayout *layout = [WKCollectionViewGridLayout new];
    layout.itemSpacing = 10.0f;
    layout.lineSpacing = 10.0f;
    layout.lineSize = 0.0f;
    layout.lineItemCount = 5;
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    layout.sectionsStartOnNewLine = NO;
    return layout;
}

-(UICollectionView*)collectionView {
    if(!_collectionView) {
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:[[self class] newGridLayout]];
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        _collectionView.backgroundColor = UIColor.clearColor;
        [_collectionView registerClass:[WKStickerGIFCell class] forCellWithReuseIdentifier:[WKStickerGIFCell reuseIdentifier]];
    }
    return _collectionView;
}

#pragma mark - UICollectionViewDataSource && UICollectionViewDelegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.stickers.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [collectionView dequeueReusableCellWithReuseIdentifier:[WKStickerGIFCell reuseIdentifier] forIndexPath:indexPath];
}

-(void)collectionView:(UICollectionView *)collectionView willDisplayCell:(WKStickerGIFCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    WKSticker *sticker = self.stickers[indexPath.row];
    sticker.isPlay = self.selected;
    [cell refresh:sticker];
    [cell onWillDisplay];
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(WKStickerGIFCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    [cell onEndDisplay];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    WKSticker *sticker = self.stickers[indexPath.row];
    WKLottieStickerContent *content = [WKLottieStickerContent new];
    content.url = sticker.path;
    content.category = sticker.category;
    content.placeholder = sticker.placeholder;
    content.format = sticker.format;
    [self.context sendMessage:content];
}

@end

//
//  WKContactsLabelEditVC.m
//  WuKongContacts
//

#import "WKContactsLabelEditVC.h"
#import "WKContactsLabelVM.h"
#import <WuKongBase/WKContactsSelectVC.h>

static CGFloat const WKLabelMemberCellWidth = 74.0f;
static CGFloat const WKLabelMemberCellHeight = 86.0f;

@interface WKContactsLabelMemberCell : UICollectionViewCell

@property(nonatomic,strong) WKUserAvatar *avatarView;
@property(nonatomic,strong) UILabel *nameLbl;
@property(nonatomic,strong) UILabel *deleteBadge;
@property(nonatomic,strong) WKContactsLabelMember *member;
@property(nonatomic,assign) BOOL deleteMode;

-(void)refreshMember:(WKContactsLabelMember*)member deleteMode:(BOOL)deleteMode;

@end

@implementation WKContactsLabelMemberCell

+(NSString*)cellId {
    return @"WKContactsLabelMemberCell";
}

-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        [self.contentView addSubview:self.avatarView];
        [self.contentView addSubview:self.nameLbl];
        [self.contentView addSubview:self.deleteBadge];
    }
    return self;
}

-(WKUserAvatar *)avatarView {
    if(!_avatarView) {
        _avatarView = [[WKUserAvatar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 34.0f, 34.0f)];
    }
    return _avatarView;
}

-(UILabel *)nameLbl {
    if(!_nameLbl) {
        _nameLbl = [[UILabel alloc] init];
        _nameLbl.textAlignment = NSTextAlignmentCenter;
        _nameLbl.textColor = WKApp.shared.config.tipColor;
        _nameLbl.font = [WKApp.shared.config appFontOfSize:12.0f];
        _nameLbl.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    return _nameLbl;
}

-(UILabel *)deleteBadge {
    if(!_deleteBadge) {
        _deleteBadge = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 16.0f, 16.0f)];
        _deleteBadge.text = @"-";
        _deleteBadge.textAlignment = NSTextAlignmentCenter;
        _deleteBadge.textColor = [UIColor whiteColor];
        _deleteBadge.font = [WKApp.shared.config appFontOfSizeSemibold:14.0f];
        _deleteBadge.backgroundColor = [UIColor colorWithRed:232.0f/255.0f green:104.0f/255.0f blue:116.0f/255.0f alpha:1.0f];
        _deleteBadge.layer.cornerRadius = 8.0f;
        _deleteBadge.layer.masksToBounds = YES;
    }
    return _deleteBadge;
}

-(void)refreshMember:(WKContactsLabelMember *)member deleteMode:(BOOL)deleteMode {
    self.member = member;
    self.deleteMode = deleteMode;
    self.avatarView.url = member.avatar;
    self.nameLbl.text = member.name ?: @"";
    self.deleteBadge.hidden = !deleteMode;
}

-(void)layoutSubviews {
    [super layoutSubviews];
    self.avatarView.lim_top = 8.0f;
    self.avatarView.lim_left = (self.contentView.lim_width - self.avatarView.lim_width)/2.0f;
    self.deleteBadge.lim_left = self.avatarView.lim_right - self.deleteBadge.lim_width/2.0f;
    self.deleteBadge.lim_top = self.avatarView.lim_top - self.deleteBadge.lim_height/2.0f;
    self.nameLbl.lim_left = 2.0f;
    self.nameLbl.lim_top = self.avatarView.lim_bottom + 8.0f;
    self.nameLbl.lim_width = self.contentView.lim_width - 4.0f;
    self.nameLbl.lim_height = 34.0f;
}

@end

@interface WKContactsLabelActionCell : UICollectionViewCell

@property(nonatomic,strong) UIImageView *iconView;
-(void)refreshAdd:(BOOL)add;

@end

@implementation WKContactsLabelActionCell

+(NSString*)cellId {
    return @"WKContactsLabelActionCell";
}

-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        [self.contentView addSubview:self.iconView];
    }
    return self;
}

-(UIImageView *)iconView {
    if(!_iconView) {
        _iconView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 34.0f, 34.0f)];
        _iconView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _iconView;
}

-(void)refreshAdd:(BOOL)add {
    NSString *imageName = add ? @"Conversation/Setting/MemberAdd" : @"Conversation/Setting/MemberDelete";
    self.iconView.image = [WKApp.shared loadImage:imageName moduleID:@"WuKongBase"];
}

-(void)layoutSubviews {
    [super layoutSubviews];
    self.iconView.lim_top = 8.0f;
    self.iconView.lim_left = (self.contentView.lim_width - self.iconView.lim_width)/2.0f;
}

@end

@interface WKContactsLabelEditVC ()<UICollectionViewDataSource,UICollectionViewDelegateFlowLayout,UITextFieldDelegate>

@property(nonatomic,strong) WKContactsLabelVM *vm;
@property(nonatomic,strong,nullable) WKContactsLabel *label;
@property(nonatomic,strong) NSMutableArray<WKContactsLabelMember*> *members;
@property(nonatomic,strong) NSArray<NSString*> *originUIDs;
@property(nonatomic,strong) UIScrollView *scrollView;
@property(nonatomic,strong) UIView *contentView;
@property(nonatomic,strong) UITextField *nameField;
@property(nonatomic,strong) UIView *nameSection;
@property(nonatomic,strong) UILabel *memberTitleLbl;
@property(nonatomic,strong) UICollectionView *collectionView;
@property(nonatomic,strong) UIButton *saveBtn;
@property(nonatomic,strong) UIButton *deleteLabelBtn;
@property(nonatomic,assign) BOOL deleteMode;

@end

@implementation WKContactsLabelEditVC

-(instancetype)initWithSelectedUIDs:(NSArray<NSString *> *)uids {
    self = [super init];
    if(self) {
        _vm = [WKContactsLabelVM new];
        _members = [NSMutableArray array];
        for (NSString *uid in uids) {
            [_members addObject:[WKContactsLabelMember memberWithUID:uid]];
        }
        _originUIDs = @[];
    }
    return self;
}

-(instancetype)initWithLabel:(WKContactsLabel *)label {
    self = [super init];
    if(self) {
        _vm = [WKContactsLabelVM new];
        _label = label;
        _members = [NSMutableArray arrayWithArray:label.members ?: @[]];
        _originUIDs = [label memberUIDs];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.scrollView];
    [self.scrollView addSubview:self.contentView];
    [self.contentView addSubview:self.nameSection];
    [self.contentView addSubview:self.memberTitleLbl];
    [self.contentView addSubview:self.collectionView];
    if(self.label) {
        [self.contentView addSubview:self.deleteLabelBtn];
    }
    [self.navigationBar setRightView:self.saveBtn];
    self.nameField.text = self.label.name ?: @"";
    [self refreshSaveState];
}

-(NSString *)langTitle {
    if(self.label) {
        return self.label.name ?: LLang(@"标签");
    }
    return LLang(@"保存为标签");
}

-(UIScrollView *)scrollView {
    if(!_scrollView) {
        _scrollView = [[UIScrollView alloc] initWithFrame:[self visibleRect]];
        _scrollView.backgroundColor = WKApp.shared.config.backgroundColor;
        _scrollView.alwaysBounceVertical = YES;
    }
    return _scrollView;
}

-(UIView *)contentView {
    if(!_contentView) {
        _contentView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, WKScreenWidth, [self visibleRect].size.height)];
    }
    return _contentView;
}

-(UIView *)nameSection {
    if(!_nameSection) {
        _nameSection = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 10.0f, WKScreenWidth, 80.0f)];
        _nameSection.backgroundColor = WKApp.shared.config.cellBackgroundColor;
        UILabel *titleLbl = [[UILabel alloc] initWithFrame:CGRectMake(6.0f, 0.0f, WKScreenWidth - 12.0f, 34.0f)];
        titleLbl.text = LLang(@"标签名字");
        titleLbl.textColor = WKApp.shared.config.tipColor;
        titleLbl.font = [WKApp.shared.config appFontOfSize:13.0f];
        [_nameSection addSubview:titleLbl];
        [_nameSection addSubview:self.nameField];
    }
    return _nameSection;
}

-(UITextField *)nameField {
    if(!_nameField) {
        _nameField = [[UITextField alloc] initWithFrame:CGRectMake(6.0f, 34.0f, WKScreenWidth - 12.0f, 46.0f)];
        _nameField.placeholder = LLang(@"例如家人、朋友");
        _nameField.textColor = WKApp.shared.config.defaultTextColor;
        _nameField.font = [WKApp.shared.config appFontOfSize:15.0f];
        _nameField.delegate = self;
        [_nameField addTarget:self action:@selector(textFieldChanged) forControlEvents:UIControlEventEditingChanged];
    }
    return _nameField;
}

-(UILabel *)memberTitleLbl {
    if(!_memberTitleLbl) {
        _memberTitleLbl = [[UILabel alloc] initWithFrame:CGRectMake(6.0f, self.nameSection.lim_bottom, WKScreenWidth - 12.0f, 36.0f)];
        _memberTitleLbl.text = LLang(@"成员");
        _memberTitleLbl.textColor = WKApp.shared.config.tipColor;
        _memberTitleLbl.font = [WKApp.shared.config appFontOfSize:13.0f];
    }
    return _memberTitleLbl;
}

-(UICollectionView *)collectionView {
    if(!_collectionView) {
        UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
        layout.minimumLineSpacing = 6.0f;
        layout.minimumInteritemSpacing = 2.0f;
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0.0f, self.memberTitleLbl.lim_bottom, WKScreenWidth, 172.0f) collectionViewLayout:layout];
        _collectionView.backgroundColor = WKApp.shared.config.cellBackgroundColor;
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        _collectionView.scrollEnabled = NO;
        [_collectionView registerClass:WKContactsLabelMemberCell.class forCellWithReuseIdentifier:[WKContactsLabelMemberCell cellId]];
        [_collectionView registerClass:WKContactsLabelActionCell.class forCellWithReuseIdentifier:[WKContactsLabelActionCell cellId]];
    }
    return _collectionView;
}

-(UIButton *)saveBtn {
    if(!_saveBtn) {
        _saveBtn = [[UIButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 70.0f, 34.0f)];
        [_saveBtn setTitle:LLang(@"保存") forState:UIControlStateNormal];
        _saveBtn.titleLabel.font = [WKApp.shared.config appFontOfSize:14.0f];
        _saveBtn.layer.cornerRadius = 17.0f;
        _saveBtn.layer.masksToBounds = YES;
        [_saveBtn addTarget:self action:@selector(savePressed) forControlEvents:UIControlEventTouchUpInside];
    }
    return _saveBtn;
}

-(UIButton *)deleteLabelBtn {
    if(!_deleteLabelBtn) {
        _deleteLabelBtn = [[UIButton alloc] initWithFrame:CGRectMake(6.0f, self.collectionView.lim_bottom + 28.0f, WKScreenWidth - 12.0f, 34.0f)];
        [_deleteLabelBtn setTitle:LLang(@"删除标签") forState:UIControlStateNormal];
        _deleteLabelBtn.titleLabel.font = [WKApp.shared.config appFontOfSize:15.0f];
        _deleteLabelBtn.backgroundColor = [UIColor colorWithRed:219.0f/255.0f green:43.0f/255.0f blue:47.0f/255.0f alpha:1.0f];
        _deleteLabelBtn.layer.cornerRadius = 17.0f;
        _deleteLabelBtn.layer.masksToBounds = YES;
        [_deleteLabelBtn addTarget:self action:@selector(deleteLabelPressed) forControlEvents:UIControlEventTouchUpInside];
    }
    return _deleteLabelBtn;
}

-(void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.scrollView.frame = [self visibleRect];
    self.contentView.lim_width = WKScreenWidth;
    self.collectionView.lim_height = [self collectionHeight];
    self.deleteLabelBtn.lim_top = self.collectionView.lim_bottom + 28.0f;
    CGFloat contentHeight = self.label ? self.deleteLabelBtn.lim_bottom + 30.0f : self.collectionView.lim_bottom + 30.0f;
    self.contentView.lim_height = MAX(contentHeight, self.scrollView.lim_height + 1.0f);
    self.scrollView.contentSize = CGSizeMake(WKScreenWidth, self.contentView.lim_height);
}

-(CGFloat)collectionHeight {
    NSInteger count = self.members.count + 2;
    NSInteger columnCount = MAX((NSInteger)(WKScreenWidth / WKLabelMemberCellWidth), 1);
    NSInteger rowCount = (count + columnCount - 1) / columnCount;
    return MAX(rowCount * WKLabelMemberCellHeight, WKLabelMemberCellHeight);
}

-(void)textFieldChanged {
    if(self.nameField.text.length > 50) {
        self.nameField.text = [self.nameField.text substringToIndex:50];
    }
    self.navigationBar.title = self.label ? self.nameField.text : self.navigationBar.title;
    [self refreshSaveState];
}

-(void)refreshSaveState {
    BOOL enabled = self.nameField.text.length > 0 && self.members.count > 0;
    self.saveBtn.enabled = enabled;
    UIColor *normal = WKApp.shared.config.navBarButtonColor;
    UIColor *disable = [normal colorWithAlphaComponent:0.22f];
    self.saveBtn.backgroundColor = enabled ? normal : disable;
    [self.saveBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

#pragma mark - Actions

-(void)addMemberPressed {
    WKContactsSelectVC *vc = [WKContactsSelectVC new];
    vc.title = LLang(@"选择联系人");
    vc.showBack = YES;
    vc.mode = WKContactsModeMulti;
    vc.selecteds = [self currentUIDs];
    vc.disables = [self currentUIDs];
    __weak typeof(self) weakSelf = self;
    vc.onFinishedSelect = ^(NSArray<NSString *> *uids) {
        [weakSelf resetMembersWithUIDs:uids];
        [[WKNavigationManager shared] popViewControllerAnimated:YES];
    };
    [[WKNavigationManager shared] pushViewController:vc animated:YES];
}

-(void)toggleDeleteMode {
    self.deleteMode = !self.deleteMode;
    [self.collectionView reloadData];
}

-(void)savePressed {
    [self.view endEditing:YES];
    NSString *name = [self.nameField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if(name.length == 0) {
        [self.view showHUDWithHide:LLang(@"请输入标签名字")];
        return;
    }
    if(self.members.count == 0) {
        [self.view showHUDWithHide:LLang(@"请选择成员")];
        return;
    }
    __weak typeof(self) weakSelf = self;
    [self.view showHUD];
    if(!self.label) {
        [self.vm createLabel:name uids:[self currentUIDs]].then(^{
            [weakSelf saveSuccess];
        }).catch(^(NSError *error) {
            [weakSelf.view hideHud];
            [weakSelf.view showHUDWithHide:error.domain];
        });
        return;
    }
    [self saveExistingLabel:name];
}

-(void)saveExistingLabel:(NSString*)name {
    NSMutableArray<AnyPromise*> *tasks = [NSMutableArray array];
    if(![name isEqualToString:self.label.name]) {
        [tasks addObject:[self.vm updateLabel:self.label.tagId name:name]];
    }
    NSArray *currentUIDs = [self currentUIDs];
    NSMutableArray *adds = [NSMutableArray array];
    for (NSString *uid in currentUIDs) {
        if(![self.originUIDs containsObject:uid]) {
            [adds addObject:uid];
        }
    }
    if(adds.count > 0) {
        [tasks addObject:[self.vm addContacts:adds toLabel:self.label.tagId]];
    }
    for (NSString *uid in self.originUIDs) {
        if(![currentUIDs containsObject:uid]) {
            [tasks addObject:[self.vm removeContact:uid fromLabel:self.label.tagId]];
        }
    }
    __weak typeof(self) weakSelf = self;
    [self runTasks:tasks index:0].then(^{
        [weakSelf saveSuccess];
    }).catch(^(NSError *error) {
        [weakSelf.view hideHud];
        [weakSelf.view showHUDWithHide:error.domain];
    });
}

-(AnyPromise*)runTasks:(NSArray<AnyPromise*>*)tasks index:(NSInteger)index {
    if(index >= tasks.count) {
        return [AnyPromise promiseWithValue:nil];
    }
    __weak typeof(self) weakSelf = self;
    return tasks[index].then(^{
        return [weakSelf runTasks:tasks index:index + 1];
    });
}

-(void)saveSuccess {
    [self.view hideHud];
    if(self.onSaved) {
        self.onSaved();
    }
    if(self.popToViewController) {
        [self.navigationController popToViewController:self.popToViewController animated:YES];
        return;
    }
    [[WKNavigationManager shared] popViewControllerAnimated:YES];
}

-(void)deleteLabelPressed {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:LLang(@"提示") message:LLang(@"标签中的联系人不会被删除，是否删除标签？") preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:LLang(@"取消") style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:LLang(@"确定") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf.view showHUD];
        [weakSelf.vm deleteLabel:weakSelf.label.tagId].then(^{
            [weakSelf saveSuccess];
        }).catch(^(NSError *error) {
            [weakSelf.view hideHud];
            [weakSelf.view showHUDWithHide:error.domain];
        });
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

-(NSArray<NSString*>*)currentUIDs {
    NSMutableArray *uids = [NSMutableArray array];
    for (WKContactsLabelMember *member in self.members) {
        if(member.uid.length > 0 && ![uids containsObject:member.uid]) {
            [uids addObject:member.uid];
        }
    }
    return uids;
}

-(void)resetMembersWithUIDs:(NSArray<NSString*>*)uids {
    NSMutableArray *members = [NSMutableArray array];
    for (NSString *uid in uids) {
        if(uid.length > 0) {
            [members addObject:[WKContactsLabelMember memberWithUID:uid]];
        }
    }
    self.members = members;
    [self refreshSaveState];
    [self.collectionView reloadData];
    [self.view setNeedsLayout];
}

#pragma mark - UICollectionView

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.members.count + 2;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.item < self.members.count) {
        WKContactsLabelMemberCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[WKContactsLabelMemberCell cellId] forIndexPath:indexPath];
        [cell refreshMember:self.members[indexPath.item] deleteMode:self.deleteMode];
        return cell;
    }
    WKContactsLabelActionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[WKContactsLabelActionCell cellId] forIndexPath:indexPath];
    [cell refreshAdd:indexPath.item == self.members.count];
    return cell;
}

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(WKLabelMemberCellWidth, WKLabelMemberCellHeight);
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.item < self.members.count) {
        if(self.deleteMode) {
            [self.members removeObjectAtIndex:indexPath.item];
            [self refreshSaveState];
            [self.collectionView reloadData];
            [self.view setNeedsLayout];
        }
        return;
    }
    if(indexPath.item == self.members.count) {
        [self addMemberPressed];
    }else {
        [self toggleDeleteMode];
    }
}

#pragma mark - UITextFieldDelegate

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *text = [textField.text stringByReplacingCharactersInRange:range withString:string];
    return text.length <= 50;
}

@end

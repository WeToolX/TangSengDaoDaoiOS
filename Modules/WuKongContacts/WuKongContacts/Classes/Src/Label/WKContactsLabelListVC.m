//
//  WKContactsLabelListVC.m
//  WuKongContacts
//

#import "WKContactsLabelListVC.h"
#import "WKContactsLabelVM.h"
#import "WKContactsLabelEditVC.h"
#import <WuKongBase/WKContactsSelectVC.h>

@interface WKContactsLabelListCell : UITableViewCell

@property(nonatomic,strong) UILabel *nameLbl;

@end

@implementation WKContactsLabelListCell

+(NSString*)cellId {
    return @"WKContactsLabelListCell";
}

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if(self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = WKApp.shared.config.cellBackgroundColor;
        [self.contentView addSubview:self.nameLbl];
    }
    return self;
}

-(UILabel *)nameLbl {
    if(!_nameLbl) {
        _nameLbl = [[UILabel alloc] init];
        _nameLbl.font = [WKApp.shared.config appFontOfSize:15.0f];
        _nameLbl.textColor = WKApp.shared.config.defaultTextColor;
    }
    return _nameLbl;
}

-(void)layoutSubviews {
    [super layoutSubviews];
    self.nameLbl.lim_left = 6.0f;
    self.nameLbl.lim_top = 0.0f;
    self.nameLbl.lim_width = self.contentView.lim_width - 12.0f;
    self.nameLbl.lim_height = self.contentView.lim_height;
}

@end

@interface WKContactsLabelListVC ()<UITableViewDataSource,UITableViewDelegate>

@property(nonatomic,strong) UITableView *tableView;
@property(nonatomic,strong) UIButton *createBtn;
@property(nonatomic,strong) WKContactsLabelVM *vm;
@property(nonatomic,strong) NSArray<WKContactsLabel*> *labels;

@end

@implementation WKContactsLabelListVC

- (instancetype)init {
    self = [super init];
    if(self) {
        _vm = [WKContactsLabelVM new];
        _labels = @[];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.tableView];
    [self.navigationBar setRightView:self.createBtn];
    [self requestData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

-(NSString *)langTitle {
    return LLang(@"标签");
}

-(void)requestData {
    __weak typeof(self) weakSelf = self;
    [self.vm labelsFull].then(^(NSArray<WKContactsLabel*> *labels) {
        weakSelf.labels = labels ?: @[];
        [weakSelf.tableView reloadData];
    }).catch(^(NSError *error) {
        [weakSelf.view showHUDWithHide:error.domain];
    });
}

-(UIButton *)createBtn {
    if(!_createBtn) {
        _createBtn = [[UIButton alloc] init];
        [_createBtn setTitle:LLang(@"新建") forState:UIControlStateNormal];
        [_createBtn setTitleColor:WKApp.shared.config.navBarButtonColor forState:UIControlStateNormal];
        _createBtn.titleLabel.font = [WKApp.shared.config appFontOfSize:14.0f];
        [_createBtn sizeToFit];
        [_createBtn addTarget:self action:@selector(createPressed) forControlEvents:UIControlEventTouchUpInside];
    }
    return _createBtn;
}

-(UITableView *)tableView {
    if(!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:[self visibleRect] style:UITableViewStylePlain];
        _tableView.backgroundColor = WKApp.shared.config.backgroundColor;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.tableFooterView = [UIView new];
        [_tableView registerClass:WKContactsLabelListCell.class forCellReuseIdentifier:[WKContactsLabelListCell cellId]];
    }
    return _tableView;
}

-(void)createPressed {
    WKContactsSelectVC *vc = [WKContactsSelectVC new];
    vc.title = LLang(@"选择联系人");
    vc.showBack = YES;
    vc.mode = WKContactsModeMulti;
    __weak typeof(self) weakSelf = self;
    vc.onFinishedSelect = ^(NSArray<NSString *> *uids) {
        WKContactsLabelEditVC *editVC = [[WKContactsLabelEditVC alloc] initWithSelectedUIDs:uids];
        editVC.popToViewController = weakSelf;
        editVC.onSaved = ^{
            [weakSelf requestData];
        };
        [[WKNavigationManager shared] pushViewController:editVC animated:YES];
    };
    [[WKNavigationManager shared] pushViewController:vc animated:YES];
}

#pragma mark - UITableView

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.labels.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WKContactsLabelListCell *cell = [tableView dequeueReusableCellWithIdentifier:[WKContactsLabelListCell cellId] forIndexPath:indexPath];
    WKContactsLabel *label = self.labels[indexPath.row];
    NSInteger count = label.members.count > 0 ? label.members.count : label.contactCount;
    cell.nameLbl.text = [NSString stringWithFormat:@"%@(%ld)",label.name ?: @"",(long)count];
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 42.0f;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    WKContactsLabel *label = self.labels[indexPath.row];
    WKContactsLabelEditVC *vc = [[WKContactsLabelEditVC alloc] initWithLabel:label];
    __weak typeof(self) weakSelf = self;
    vc.onSaved = ^{
        [weakSelf requestData];
    };
    [[WKNavigationManager shared] pushViewController:vc animated:YES];
}

@end

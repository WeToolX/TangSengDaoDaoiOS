//
//  WKAccountDestroyVC.m
//  WuKongBase
//

#import "WKAccountDestroyVC.h"
#import "WKAccountDestroyCodeVC.h"

@interface WKAccountDestroyVC ()

@property(nonatomic,strong) UIScrollView *scrollView;
@property(nonatomic,strong) UIView *contentView;
@property(nonatomic,strong) UIButton *destroyBtn;
@property(nonatomic,strong) UIButton *cancelBtn;

@end

@implementation WKAccountDestroyVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.scrollView];
    [self.scrollView addSubview:self.contentView];
    [self.view addSubview:self.destroyBtn];
    [self.view addSubview:self.cancelBtn];
    [self buildContent];
}

- (NSString *)langTitle {
    return @"";
}

- (void)buildContent {
    CGFloat x = 20.0f;
    CGFloat y = 35.0f;
    NSString *phone = [self maskedPhone];
    UILabel *titleLbl = [self label:[NSString stringWithFormat:@"%@:%@", LLang(@"注销账号"), phone] fontSize:24.0f color:[WKApp shared].config.defaultTextColor];
    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:titleLbl.text];
    NSRange phoneRange = [titleLbl.text rangeOfString:phone];
    if(phoneRange.location != NSNotFound) {
        [attr addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:238.0f/255.0f green:73.0f/255.0f blue:91.0f/255.0f alpha:1.0f] range:phoneRange];
    }
    titleLbl.attributedText = attr;
    titleLbl.frame = CGRectMake(x, y, WKScreenWidth - x * 2, 34.0f);
    [self.contentView addSubview:titleLbl];
    y = titleLbl.lim_bottom + 35.0f;
    
    UILabel *descLbl = [self label:LLang(@"账号注销是不可恢复的操作，请您仔细考虑，谨慎操作，操作前务必审慎阅读、充分理解以下内容。") fontSize:19.0f color:[WKApp shared].config.defaultTextColor];
    descLbl.frame = CGRectMake(x, y, WKScreenWidth - x * 2, [self heightForText:descLbl.text font:descLbl.font width:WKScreenWidth - x * 2]);
    [self.contentView addSubview:descLbl];
    y = descLbl.lim_bottom + 28.0f;
    
    UILabel *noticeLbl = [self label:LLang(@"注销须知:") fontSize:18.0f color:[WKApp shared].config.tipColor];
    noticeLbl.frame = CGRectMake(x, y, WKScreenWidth - x * 2, 28.0f);
    [self.contentView addSubview:noticeLbl];
    y = noticeLbl.lim_bottom + 18.0f;
    
    NSArray *items = @[
        LLang(@"账号处于安全状态:\n您的账号未被他人盗取，账号不存在被封禁等风险。"),
        LLang(@"全部财产均已结清:\n账号内不存在已充值的相关财产。"),
        LLang(@"绑定目前可用的安全手机:\n用于确认当前账号的身份归属情况。"),
    ];
    for (NSInteger i = 0; i < items.count; i++) {
        UILabel *numLbl = [self numberLabel:i + 1];
        numLbl.lim_left = x;
        numLbl.lim_top = y + 2.0f;
        [self.contentView addSubview:numLbl];
        
        UILabel *itemLbl = [self label:items[i] fontSize:18.0f color:[WKApp shared].config.tipColor];
        CGFloat itemX = x + 48.0f;
        itemLbl.frame = CGRectMake(itemX, y, WKScreenWidth - itemX - x, [self heightForText:itemLbl.text font:itemLbl.font width:WKScreenWidth - itemX - x]);
        [self.contentView addSubview:itemLbl];
        y = itemLbl.lim_bottom + 22.0f;
    }
    
    UILabel *specialLbl = [self label:LLang(@"特别说明:") fontSize:18.0f color:[WKApp shared].config.tipColor];
    specialLbl.frame = CGRectMake(x, y, WKScreenWidth - x * 2, 28.0f);
    [self.contentView addSubview:specialLbl];
    y = specialLbl.lim_bottom + 18.0f;
    
    NSArray *specials = @[
        LLang(@"1、账号注销申请时即放弃该账号在卿航IM软件所有涉及相关数据，包括但不限于该账号的资产、权益、记录等一切内容，将视为您自愿放弃。"),
        LLang(@"2、账号成功注销后，您将无法登录。"),
        LLang(@"3、已成功注销的账号无法进行找回。"),
    ];
    for (NSString *text in specials) {
        UILabel *label = [self label:text fontSize:17.0f color:[WKApp shared].config.tipColor];
        label.frame = CGRectMake(x, y, WKScreenWidth - x * 2, [self heightForText:text font:label.font width:WKScreenWidth - x * 2]);
        [self.contentView addSubview:label];
        y = label.lim_bottom + 16.0f;
    }
    
    self.contentView.lim_height = y + 30.0f;
    self.scrollView.contentSize = CGSizeMake(WKScreenWidth, self.contentView.lim_height);
}

- (UILabel *)label:(NSString *)text fontSize:(CGFloat)fontSize color:(UIColor *)color {
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.textColor = color;
    label.font = [[WKApp shared].config appFontOfSize:fontSize];
    label.numberOfLines = 0;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    return label;
}

- (UILabel *)numberLabel:(NSInteger)number {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 28.0f, 28.0f)];
    label.text = [NSString stringWithFormat:@"%ld", (long)number];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    label.font = [[WKApp shared].config appFontOfSize:16.0f];
    label.backgroundColor = [UIColor colorWithRed:250.0f/255.0f green:72.0f/255.0f blue:84.0f/255.0f alpha:1.0f];
    label.layer.masksToBounds = YES;
    label.layer.cornerRadius = 14.0f;
    return label;
}

- (CGFloat)heightForText:(NSString *)text font:(UIFont *)font width:(CGFloat)width {
    CGRect rect = [text boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX)
                                     options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                  attributes:@{NSFontAttributeName:font}
                                     context:nil];
    return ceil(rect.size.height) + 4.0f;
}

- (NSString *)maskedPhone {
    NSString *phone = [WKApp shared].loginInfo.extra[@"phone"] ?: @"";
    if(phone.length >= 8) {
        return [NSString stringWithFormat:@"%@****%@", [phone substringToIndex:3], [phone substringFromIndex:phone.length - 4]];
    }
    return phone.length > 0 ? phone : @"";
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat buttonBottom = [WKApp shared].config.visibleEdgeInsets.bottom + 18.0f;
    CGFloat buttonHeight = 52.0f;
    CGFloat space = 18.0f;
    CGFloat buttonWidth = (self.view.lim_width - 40.0f - space) / 2.0f;
    self.destroyBtn.frame = CGRectMake(20.0f, self.view.lim_height - buttonBottom - buttonHeight, buttonWidth, buttonHeight);
    self.cancelBtn.frame = CGRectMake(self.destroyBtn.lim_right + space, self.destroyBtn.lim_top, buttonWidth, buttonHeight);
    self.scrollView.frame = CGRectMake(0.0f, self.navigationBar.lim_bottom, self.view.lim_width, self.destroyBtn.lim_top - self.navigationBar.lim_bottom - 10.0f);
    self.contentView.frame = CGRectMake(0.0f, 0.0f, self.view.lim_width, self.contentView.lim_height);
}

- (UIScrollView *)scrollView {
    if(!_scrollView) {
        _scrollView = [[UIScrollView alloc] init];
    }
    return _scrollView;
}

- (UIView *)contentView {
    if(!_contentView) {
        _contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, WKScreenWidth, 0)];
    }
    return _contentView;
}

- (UIButton *)destroyBtn {
    if(!_destroyBtn) {
        _destroyBtn = [self button:LLang(@"注销账号") color:[UIColor redColor]];
        [_destroyBtn addTarget:self action:@selector(destroyPressed) forControlEvents:UIControlEventTouchUpInside];
    }
    return _destroyBtn;
}

- (UIButton *)cancelBtn {
    if(!_cancelBtn) {
        _cancelBtn = [self button:LLang(@"取消") color:[WKApp shared].config.themeColor];
        [_cancelBtn addTarget:self action:@selector(backPressed) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelBtn;
}

- (UIButton *)button:(NSString *)title color:(UIColor *)color {
    UIButton *button = [[UIButton alloc] init];
    [button setTitle:title forState:UIControlStateNormal];
    button.backgroundColor = color;
    button.layer.masksToBounds = YES;
    button.layer.cornerRadius = 26.0f;
    button.titleLabel.font = [[WKApp shared].config appFontOfSizeMedium:18.0f];
    return button;
}

- (void)destroyPressed {
    [[WKNavigationManager shared] pushViewController:[WKAccountDestroyCodeVC new] animated:YES];
}

@end

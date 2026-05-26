//
//  WKAccountDestroyCodeVC.m
//  WuKongBase
//

#import "WKAccountDestroyCodeVC.h"

@interface WKAccountDestroyCodeVC ()<UITextFieldDelegate>

@property(nonatomic,strong) UITextField *codeField;
@property(nonatomic,strong) UIButton *sendBtn;
@property(nonatomic,strong) NSTimer *timer;
@property(nonatomic,assign) NSInteger seconds;

@end

@implementation WKAccountDestroyCodeVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = LLang(@"请输入验证码");
    [self.view addSubview:self.codeField];
    [self.view addSubview:self.sendBtn];
    [self.finishBtn setTitle:LLang(@"确定") forState:UIControlStateNormal];
    [self.finishBtn addTarget:self action:@selector(confirmPressed) forControlEvents:UIControlEventTouchUpInside];
    self.finishBtn.enabled = NO;
    self.finishBtn.layer.cornerRadius = 22.0f;
    self.finishBtn.lim_width = 88.0f;
    self.finishBtn.lim_height = 44.0f;
    self.rightView = self.finishBtn;
    [self requestSMSCode];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat top = self.navigationBar.lim_bottom + 22.0f;
    self.codeField.frame = CGRectMake(20.0f, top, self.view.lim_width - 180.0f, 56.0f);
    self.sendBtn.frame = CGRectMake(self.view.lim_width - 150.0f, top + 7.0f, 130.0f, 42.0f);
}

- (UITextField *)codeField {
    if(!_codeField) {
        _codeField = [[UITextField alloc] init];
        _codeField.placeholder = LLang(@"请输入验证码");
        _codeField.font = [[WKApp shared].config appFontOfSize:18.0f];
        _codeField.keyboardType = UIKeyboardTypeNumberPad;
        _codeField.delegate = self;
        [_codeField addTarget:self action:@selector(codeChanged) forControlEvents:UIControlEventEditingChanged];
    }
    return _codeField;
}

- (UIButton *)sendBtn {
    if(!_sendBtn) {
        _sendBtn = [[UIButton alloc] init];
        _sendBtn.backgroundColor = [[WKApp shared].config.themeColor colorWithAlphaComponent:0.25f];
        _sendBtn.layer.masksToBounds = YES;
        _sendBtn.layer.cornerRadius = 21.0f;
        _sendBtn.titleLabel.font = [[WKApp shared].config appFontOfSize:15.0f];
        [_sendBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_sendBtn addTarget:self action:@selector(requestSMSCode) forControlEvents:UIControlEventTouchUpInside];
    }
    return _sendBtn;
}

- (void)codeChanged {
    self.finishBtn.enabled = self.codeField.text.length > 0;
}

- (void)requestSMSCode {
    self.sendBtn.enabled = NO;
    [self.view showHUD];
    __weak typeof(self) weakSelf = self;
    [[WKAPIClient sharedClient] POST:@"user/sms/destroy" parameters:nil].then(^{
        [weakSelf.view hideHud];
        [weakSelf startCountDown];
    }).catch(^(NSError *error) {
        [weakSelf.view hideHud];
        [weakSelf.view showHUDWithHide:error.domain];
        weakSelf.sendBtn.enabled = YES;
        [weakSelf.sendBtn setTitle:LLang(@"重新获取") forState:UIControlStateNormal];
    });
}

- (void)startCountDown {
    [self.timer invalidate];
    self.seconds = 60;
    [self updateSendButton];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(tick) userInfo:nil repeats:YES];
}

- (void)tick {
    self.seconds--;
    [self updateSendButton];
    if(self.seconds <= 0) {
        [self.timer invalidate];
        self.timer = nil;
        self.sendBtn.enabled = YES;
        [self.sendBtn setTitle:LLang(@"重新获取") forState:UIControlStateNormal];
    }
}

- (void)updateSendButton {
    self.sendBtn.enabled = NO;
    [self.sendBtn setTitle:[NSString stringWithFormat:LLang(@"重新获取%ld s"), (long)self.seconds] forState:UIControlStateNormal];
}

- (void)confirmPressed {
    NSString *code = self.codeField.text ?: @"";
    if(code.length == 0) {
        return;
    }
    [self.view showHUD];
    __weak typeof(self) weakSelf = self;
    [[WKAPIClient sharedClient] DELETE:[NSString stringWithFormat:@"user/destroy/%@", code] parameters:nil].then(^{
        [weakSelf.view hideHud];
        [[WKApp shared] logout];
    }).catch(^(NSError *error) {
        [weakSelf.view hideHud];
        [weakSelf.view showHUDWithHide:error.domain];
    });
}

- (void)dealloc {
    [self.timer invalidate];
}

@end

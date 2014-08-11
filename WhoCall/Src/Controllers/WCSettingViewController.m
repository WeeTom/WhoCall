//
//  WCSettingViewController.m
//  WhoCall
//
//  Created by Wang Xiaolei on 11/17/13.
//  Copyright (c) 2013 Wang Xiaolei. All rights reserved.
//

@import AddressBook;
#import "MDWCGlobal.h"
#import "WCSettingViewController.h"
#import "WCCallInspector.h"
#import "WCAddressBook.h"
#import "UIAlertView+MKBlockAdditions.h"

#define AppKey @"935527504"
#define AppSecret @"4fb83603c7904cd9861895a17ce1530c"
#define RedirectURL @"http://www.mingdao.com"

@interface WCSettingViewController () <MDAuthPanelDelegate>
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicator;
@property (weak, nonatomic) IBOutlet UISwitch *authSwitch;

@end

@implementation WCSettingViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MDAPIManagerNewTokenSetNotification object:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newTokenSet:) name:MDAPIManagerNewTokenSetNotification object:nil];
    self.authSwitch.on = [MDWCGlobal authed];
    
    WCCallInspector *inspector = [WCCallInspector sharedInspector];
    self.switchLiar.on = inspector.handleLiarPhone;
    self.switchLocation.on = inspector.handlePhoneLocation;
    self.switchContact.on = inspector.handleContactName;
}

- (void)viewDidAppear:(BOOL)animated {
    // 触发弹出通讯录授权，第一次启动app后就弹出，避免在第一次来电的时候才弹
    [WCAddressBook defaultAddressBook];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
}

- (IBAction)onSettingValueChanged:(UISwitch *)sender
{
    WCCallInspector *inspector = [WCCallInspector sharedInspector];
    if (sender == self.switchLiar) {
        inspector.handleLiarPhone = sender.on;
    } else if (sender == self.switchLocation) {
        inspector.handlePhoneLocation = sender.on;
    } else if (sender == self.switchContact) {
        inspector.handleContactName = sender.on;
        if (sender.on) {
            // 根据通讯录的访问权限，有不同的处理
            switch (ABAddressBookGetAuthorizationStatus()) {
                case kABAuthorizationStatusNotDetermined:
                {
                    ABAddressBookRef addrBook = ABAddressBookCreateWithOptions(nil, NULL);
                    ABAddressBookRequestAccessWithCompletion(addrBook, ^(bool granted, CFErrorRef error){
                        if (!granted) {
                            sender.on = NO;
                            inspector.handleContactName = NO;
                            [inspector saveSettings];
                        }
                        CFRelease(addrBook);
                    });
                    break;
                }
                case kABAuthorizationStatusDenied:
                {
                    sender.on = NO;
                    [UIAlertView alertViewWithTitle:nil
                                            message:NSLocalizedString(@"SETTING_CONTACT_NO_ACCESS", nil)
                                  cancelButtonTitle:NSLocalizedString(@"I_KNOW", nil)];
                    break;
                }
                default:
                    break;
            }
        }
    }
    [inspector saveSettings];
}

- (IBAction)mingdaoAuth:(id)sender {
    if (self.authSwitch.on) {
        [self authorizeByMingdaoApp];
    } else {
        // TODO:...
    }
}

#pragma mark -
#pragma mark - AuthMethod
- (void)authorizeByMingdaoApp
{
    self.authSwitch.enabled = NO;
    [self.indicator startAnimating];
    if (![MDAuthenticator authorizeByMingdaoAppWithAppKey:AppKey appSecret:AppSecret]) {
        // 未安装明道App
        [self authorizeByMingdaoMobilePage];
    }
}

- (void)authorizeByMingdaoMobilePage
{
    // 通过 @MDAuthPanel 进行web验证
    MDAuthPanel *panel = [[MDAuthPanel alloc] initWithFrame:self.view.bounds appKey:AppKey appSecret:AppSecret redirectURL:RedirectURL state:nil];
    panel.authDelegate = self;
    [self.view.window addSubview:panel];
    [panel show];
}

#pragma mark -
#pragma mark - MDAuthPanelAuthDelegate
- (void)mingdaoAuthPanel:(MDAuthPanel *)panel didFinishAuthorizeWithResult:(NSDictionary *)result
{
    // @MDAuthPanel 验证结束 返回结果
    [panel hide];
    NSString *errorStirng= result[MDAuthErrorKey];
    if (errorStirng) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Failed!" message:errorStirng delegate:nil cancelButtonTitle:@"Done" otherButtonTitles:nil];
        [alertView show];
        [MDAPIManager sharedManager].accessToken = @"0";
    } else {
        NSString *accessToken = result[MDAuthAccessTokenKey];
        //    NSString *refeshToken = result[MDAuthRefreshTokenKey];
        //    NSString *expireTime = result[MDAuthExpiresTimeKeyl];
        [MDAPIManager sharedManager].accessToken = accessToken;
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Succeed!" message:[NSString stringWithFormat:@"token = %@", accessToken] delegate:nil cancelButtonTitle:@"Done" otherButtonTitles:nil];
        [alertView show];
    }
}


#pragma mark -
#pragma mark - Notification
- (void)newTokenSet:(NSNotification *)notification
{
    if ([[MDAPIManager sharedManager].accessToken isEqualToString:@"0"]) {
        self.authSwitch.on = NO;
        self.authSwitch.enabled = YES;
        [self.indicator stopAnimating];
    } else {
        [[[MDAPIManager sharedManager] loadAllUsersWithHandler:^(NSArray *objects, NSError *error) {
            if (error) {
                self.authSwitch.on = NO;
                self.authSwitch.enabled = YES;
                [self.indicator stopAnimating];
                return ;
            } else {
                [MDWCGlobal saveContacts:objects];
                self.authSwitch.on = YES;
                self.authSwitch.enabled = YES;
                [self.indicator stopAnimating];
            }
        }] start];
    }
}
@end

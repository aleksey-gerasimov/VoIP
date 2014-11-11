/*
 * Copyright (C) 2014 Xianwen Chen <xianwen@xianwenchen.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 */

#import "XCLoginViewController.h"
#import "XCCallViewController.h"
#import "XCPjsua.h"

@interface XCLoginViewController ()

@property (weak, nonatomic) IBOutlet UIButton *callButton;

@property (weak, nonatomic) IBOutlet UITextField *loginTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;

@end

@implementation XCLoginViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
  
  self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
  self.activityIndicator.hidden = YES;
#warning hardcode center
  [self.activityIndicator setCenter: CGPointMake(160.f, 265.f)];
  [self.view addSubview: self.activityIndicator];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (IBAction)login:(id)sender
{
  // You should change the 1st and the 2nd parameter to your own user name and password
  [[XCPjsua sharedXCPjsua] startPjsipAndRegisterOnServer:"ekiga.net" withUserName: (char*)[self.loginTextField.text UTF8String] andPassword: (char*)[self.passwordTextField.text UTF8String] callback:^(BOOL success){
    [self loginCompleted:success];
  }];
  [self.activityIndicator startAnimating];
}

- (IBAction)makeCall:(id)sender
{
    //[[XCPjsua sharedXCPjsua] makeCallTo:"sip:gerasimov.test2@ekiga.net"];
}

- (void)loginCompleted:(BOOL)success
{
  XCCallViewController* callViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"callViewController"];
  
  dispatch_async(dispatch_get_main_queue(), ^{
    if (success) {
      UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Login Succeeded"
                                                      message:nil
                                                     delegate:nil
                                            cancelButtonTitle:@"OK"
                                            otherButtonTitles:nil];
      [alert show];
      [self.navigationController pushViewController:callViewController animated:YES];
      [self.activityIndicator stopAnimating];
      self.callButton.hidden = NO;
    } else {
      UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Login Failed"
                                                      message:nil
                                                     delegate:nil
                                            cancelButtonTitle:@"OK"
                                            otherButtonTitles:nil];
      [alert show];
      [self.activityIndicator stopAnimating];
      self.callButton.hidden = YES;
    }
  });
}

@end

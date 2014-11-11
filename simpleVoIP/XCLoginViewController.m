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
#import "XCPjsua.h"

@interface XCLoginViewController ()

@property (weak, nonatomic) IBOutlet UIButton *callButton;

@end

@implementation XCLoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)login:(id)sender
{
    // You should change the 1st and the 2nd parameter to your own user name and password
    [[XCPjsua sharedXCPjsua] startPjsipAndRegisterOnServer:"ekiga.net"
                                              withUserName:"gerasimov.test2"
                                               andPassword:"123!@#qaz"
                                                  callback:^(BOOL success){
                                                      [self loginCompleted:success];
                                                  }];
}

- (IBAction)makeCall:(id)sender
{
    [[XCPjsua sharedXCPjsua] makeCallTo:"sip:ysirko@ekiga.net"];
}

- (void)loginCompleted:(BOOL)success
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (success) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Login Succeeded"
                                                            message:nil
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];

            self.callButton.hidden = NO;
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Login Failed"
                                                            message:nil
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];

            self.callButton.hidden = YES;
        }
    });
}

@end

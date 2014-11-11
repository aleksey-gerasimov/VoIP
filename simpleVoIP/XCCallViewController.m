//
//  XCCallViewController.m
//  simpleVoIP
//
//  Created by Admin on 11/11/14.
//  Copyright (c) 2014 Xianwen Chen. All rights reserved.
//

#import "XCCallViewController.h"
#import "XCPjsua.h"

@interface XCCallViewController()

@end

@implementation XCCallViewController

- (void)viewDidLoad {
  
}

- (IBAction)callButtonTouchUpInside:(id)sender {
  NSLog(@"Call");
  [[XCPjsua sharedXCPjsua] makeCallTo:"sip:gerasimov.test2@ekiga.net"];
}

- (IBAction)cancelButtonTouchUpInside:(id)sender {
  NSLog(@"Cancel");
}


@end

//
//  ViewController.m
//  WebViewDemo
//
//  Created by x on 14-4-4.
//  Copyright (c) 2014年 x. All rights reserved.
//

#import "ViewController.h"
#import "HZWebViewController.h"

#import "UIView+Screenshot.h"
#import "UIImage+Blur.h"

@interface ViewController ()

@end

@implementation ViewController

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
- (IBAction)load:(id)sender {
  
  HZWebViewController *webViewController = [HZWebViewController new];
  //    webViewController.mode = HZWebBrowserModeNavigation;
  webViewController.mode = HZWebBrowserModeModal;
  webViewController.URL = [NSURL URLWithString:@"http://www.apple.com"];
  [self presentViewController:webViewController animated:YES completion:^{}];
  
}

@end

//
//  HZWebViewController.h
//  mgpyh
//
//  Created by x on 14-4-4.
//  Copyright (c) 2014年 x. All rights reserved.
//

#import <UIKit/UIKit.h>



typedef enum {
	HZWebBrowserModeNavigation,
	HZWebBrowserModeModal,
} HZWebBrowserMode;

@interface XToolBar : UIToolbar {}@end

@interface HZWebViewController : UIViewController <UIWebViewDelegate>

@property (strong, nonatomic) NSURL *URL;
@property (nonatomic, assign) HZWebBrowserMode mode;



- (void)load;
- (void)clear;

@end

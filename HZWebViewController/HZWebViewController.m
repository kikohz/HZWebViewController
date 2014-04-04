//
//  HZWebViewController.m
//  mgpyh
//
//  Created by x on 14-4-4.
//  Copyright (c) 2014年 x. All rights reserved.
//

#import "HZWebViewController.h"
#import "UIView+Screenshot.h"
#import "UIImage+Blur.h"
#import "NJKWebViewProgress.h"
#import "NJKWebViewProgressView.h"

#define HZFSystemVersion          ([[[UIDevice currentDevice] systemVersion] floatValue])
#define HZUIColorFromRGB(colorRed,colorGreen,colorBlue)  [UIColor colorWithRed:(colorRed)/255.0 green:(colorGreen)/255.0 blue:(colorBlue)/255.0 alpha:1.0]
#define HZPNGIMAGE(NAME)          [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:(NAME) ofType:@"png"]]

#define HZ_App_Frame_Height        [[UIScreen mainScreen] applicationFrame].size.height
#define HZ_App_Frame_Width         [[UIScreen mainScreen] applicationFrame].size.width

#define kNavBarHeight                   44
#define kTooBarHeight                   44
CGFloat const HZProgressBarHeight = 2.5;
NSInteger const HZProgresstagId = 222122323;

@implementation XToolBar
- (UIImage *)createImage:(UIColor *)color
{
  CGRect rect=CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
  UIGraphicsBeginImageContext(rect.size);
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGContextSetFillColorWithColor(context, [color CGColor]);
  CGContextFillRect(context, rect);
  
  UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return theImage;
}
- (void)drawRect:(CGRect)rect {
  if(HZFSystemVersion >= 7.0f){
    //        [PBPNGIMAGE(@"pb_tabbar_background_os7") drawInRect:rect];
    [[self createImage:[UIColor whiteColor]] drawInRect:rect];
  }
  else
    [HZPNGIMAGE(@"pb_tabbar_background") drawInRect:rect];
}
@end

@interface HZWebViewController () <UIPopoverControllerDelegate ,UIActionSheetDelegate,NJKWebViewProgressDelegate>

@property (strong, nonatomic) UIWebView *webView;
@property (strong, nonatomic) UIBarButtonItem *stopLoadingButton;
@property (strong, nonatomic) UIBarButtonItem *reloadButton;
@property (strong, nonatomic) UIBarButtonItem *backButton;
@property (strong, nonatomic) UIBarButtonItem *forwardButton;

@property (strong, nonatomic) UIPopoverController *activitiyPopoverController;

@property (nonatomic,strong) NJKWebViewProgress *progressProxy;

@property (nonatomic,strong) UILabel *titleLb;
@property (nonatomic,strong) XToolBar *toolBar;

@end

@implementation HZWebViewController


- (void)load
{
  NSURLRequest *request = [NSURLRequest requestWithURL:self.URL];
  [self.webView loadRequest:request];
  
}

- (void)clear
{
  [self.webView loadHTMLString:@"" baseURL:nil];
  self.titleLb.text = @"";
  self.title = @"";
}

#pragma mark - View controller lifecycle
- (void)dealloc
{
  
}
- (UIViewController *)getCurrentRootViewController {
  
  UIViewController *result;
  
  // Try to find the root view controller programmically
  
  // Find the top window (that is not an alert view or other window)
  UIWindow *topWindow = [[UIApplication sharedApplication] keyWindow];
  if (topWindow.windowLevel != UIWindowLevelNormal)
  {
    NSArray *windows = [[UIApplication sharedApplication] windows];
    for(topWindow in windows)
    {
      if (topWindow.windowLevel == UIWindowLevelNormal)
        break;
    }
  }
  
  UIView *rootView = [[topWindow subviews] objectAtIndex:0];
  id nextResponder = [rootView nextResponder];
  
  if ([nextResponder isKindOfClass:[UIViewController class]])
    result = nextResponder;
  else if ([topWindow respondsToSelector:@selector(rootViewController)] && topWindow.rootViewController != nil)
    result = topWindow.rootViewController;
  else
    NSAssert(NO, @"ShareKit: Could not find a root view controller.  You can assign one manually by calling [[SHK currentHelper] setRootViewController:YOURROOTVIEWCONTROLLER].");
	
  return result;
}
- (void)viewDidLoad
{
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor whiteColor];
  self.view.userInteractionEnabled = YES;
  
  //blur background
  UIImageView *backgroundView = [[UIImageView alloc] initWithFrame:self.view.frame];
  UIImage *screensImage = [[self getCurrentRootViewController].view screenshot];
  screensImage = [screensImage applyBlurWithRadius:5 tintColor:nil saturationDeltaFactor:1.8 maskImage:nil];
  [backgroundView setImage:screensImage];
  [self.view addSubview:backgroundView];
  //webview
  self.webView = [[UIWebView alloc] init];
  self.webView.scalesPageToFit = YES;
  self.webView.backgroundColor = [UIColor whiteColor];
  self.webView.opaque = NO;
  
  [self.view addSubview:self.webView];
  
  
  
  //progress
  _progressProxy = [[NJKWebViewProgress alloc] init];
  
  
  [self setupToolBarItems];
  //PBWebBrowserModeModal 模式自定义nav   ios7 以下PBWebBrowserModeNavigation 也自定义nav
  if(self.mode == HZWebBrowserModeModal){
    CGRect webViewRect = self.view.frame;
    
    if(HZFSystemVersion >= 7.0){
      self.edgesForExtendedLayout = UIRectEdgeNone;
      self.webView.frame = CGRectMake(webViewRect.origin.x, 20+HZProgressBarHeight, webViewRect.size.width, webViewRect.size.height-kTooBarHeight-20-HZProgressBarHeight);
    }
  }
  else if (self.mode == HZWebBrowserModeNavigation){
    CGRect webViewRect = self.view.frame;
    self.webView.frame = CGRectMake(webViewRect.origin.x, kNavBarHeight, webViewRect.size.width, webViewRect.size.height-kNavBarHeight-kTooBarHeight);
    [self setpNavBar];
  
  }
  
  
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  //版本地狱ios7 并且是PBWebBrowserModeNavigation 模式就隐藏系统的nav用自定义的
  if(self.mode == HZWebBrowserModeNavigation){
    [self.navigationController setNavigationBarHidden:YES animated:YES];
  }
  self.webView.delegate = _progressProxy;
  _progressProxy.webViewProxyDelegate = self;
  _progressProxy.progressDelegate = self;
  if (self.URL) {
    [self load];
  }
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  [self clear];
  [self.webView stopLoading];
  self.webView.delegate = nil;
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
  [self.navigationController setNavigationBarHidden:NO animated:YES];
}

#pragma mark - Helpers

- (void)setpNavBar
{
  CGRect navRect = CGRectMake(0, 0, self.view.bounds.size.width, kNavBarHeight);
  if(HZFSystemVersion >= 7.0f){
    navRect.origin.y = 20;
  }
  
  UIView *navView = [[UIView alloc] initWithFrame:navRect];
  navView.backgroundColor = HZUIColorFromRGB(246,246,246);
  UIButton *backBt = [UIButton buttonWithType:UIButtonTypeCustom];
  UIImage *image = HZPNGIMAGE(@"navigationbar_back");
  
  [backBt setBackgroundImage:image forState:UIControlStateNormal];
  CGSize imageSize = image.size;
  backBt.frame = CGRectMake(10, 5, imageSize.width, imageSize.height);
  [backBt addTarget:self action:@selector(back:) forControlEvents:UIControlEventTouchUpInside];
  [navView addSubview:backBt];
  [self.view addSubview:navView];
  
  self.titleLb = [[UILabel alloc] initWithFrame:CGRectMake(backBt.frame.size.width+5, 0, navRect.size.width-(backBt.frame.origin.x+backBt.frame.size.width+10)-5, kNavBarHeight)];
  self.titleLb.numberOfLines = 1;
  self.titleLb.textAlignment = NSTextAlignmentCenter;
  self.titleLb.backgroundColor = [UIColor clearColor];
  [navView addSubview:self.titleLb];
}



- (UIImage *)leftTriangleImage
{
  static UIImage *image;
  
  static dispatch_once_t predicate;
  dispatch_once(&predicate, ^{
    CGSize size = CGSizeMake(14.0f, 16.0f);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0f);
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0.0f, 8.0f)];
    [path addLineToPoint:CGPointMake(14.0f, 0.0f)];
    [path addLineToPoint:CGPointMake(14.0f, 16.0f)];
    [path closePath];
    [path fill];
    
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
  });
  
  return image;
}

- (UIImage *)rightTriangleImage
{
  
  static UIImage *rightTriangleImage;
  
  static dispatch_once_t predicate;
  dispatch_once(&predicate, ^{
    UIImage *leftTriangleImage = [self leftTriangleImage];
    
    CGSize size = leftTriangleImage.size;
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGFloat x_mid = size.width / 2.0f;
    CGFloat y_mid = size.height / 2.0f;
    
    CGContextTranslateCTM(context, x_mid, y_mid);
    
    CGContextRotateCTM(context, M_PI);
    [leftTriangleImage drawAtPoint:CGPointMake((x_mid * -1), (y_mid * -1))];
    
    rightTriangleImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
  });
  
  return rightTriangleImage;
  
  
}

- (void)setupToolBarItems
{
  
  self.toolBar = [[XToolBar alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height-kTooBarHeight, self.view.frame.size.width, kTooBarHeight)];
  self.toolBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
  [self.toolBar setBarStyle:UIBarStyleBlackTranslucent];
  self.toolBar.backgroundColor = [UIColor clearColor];
  [self.view addSubview:self.toolBar];
  
  
  self.stopLoadingButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop
                                                                         target:self.webView
                                                                         action:@selector(stopLoading)];
  
  self.reloadButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                                    target:self.webView
                                                                    action:@selector(reload)];
  
  self.backButton = [[UIBarButtonItem alloc] initWithImage:[self leftTriangleImage]
                                                     style:UIBarButtonItemStylePlain
                                                    target:self.webView
                                                    action:@selector(goBack)];
  
  self.forwardButton = [[UIBarButtonItem alloc] initWithImage:[self rightTriangleImage]
                                                        style:UIBarButtonItemStylePlain
                                                       target:self.webView
                                                       action:@selector(goForward)];
  
  self.backButton.enabled = NO;
  self.forwardButton.enabled = NO;
  
  UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithImage:HZPNGIMAGE(@"navigationbar_back") style:UIBarButtonItemStylePlain target:self action:@selector(back:)];
  
  
  UIBarButtonItem *actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                                target:self
                                                                                action:@selector(action:)];
  
  UIBarButtonItem *space_ = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                                          target:nil
                                                                          action:nil];
  space_.width = 35.0f;
  
  self.toolbarItems = @[closeButton,space_,self.stopLoadingButton, space_, self.backButton, space_, self.forwardButton, space_, actionButton];
  [self.toolBar setItems:self.toolbarItems animated:YES];
}

- (void)toggleState
{
  self.backButton.enabled = self.webView.canGoBack;
  self.forwardButton.enabled = self.webView.canGoForward;
  
  NSMutableArray *toolbarItems = [self.toolbarItems mutableCopy];
  if (self.webView.loading) {
    toolbarItems[2] = self.stopLoadingButton;
  } else {
    toolbarItems[2] = self.reloadButton;
  }
  self.toolbarItems = [toolbarItems copy];
  
  [self.toolBar setItems:self.toolbarItems animated:YES];
}

- (void)finishLoad
{
  [self toggleState];
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

//显示加载进度view
- (NJKWebViewProgressView *)setupHZProgressSubviewWithTintColor:(UIColor *)tintColor{
  
  NJKWebViewProgressView *progressView;
	for (UIView *subview in [self.view subviews])
	{
		if (subview.tag == HZProgresstagId)
		{
			progressView = (NJKWebViewProgressView *)subview;
		}
	}
	
	if(!progressView)
	{
    progressView =  [[NJKWebViewProgressView alloc] initWithFrame:CGRectMake(0, 20, 320, HZProgressBarHeight)];
		progressView.tag = HZProgresstagId;
    //		progressView.backgroundColor = tintColor;
		[self.view addSubview:progressView];
	}
	else
	{
		CGRect progressFrame = progressView.frame;
		progressFrame.origin.y = 20;
		progressView.frame = progressFrame;
	}
	
	return progressView;
  
}
- (void)viewUpdatesForPercentage:(float)percentage andTintColor:(UIColor *)tintColor
{
	NJKWebViewProgressView *progressView = [self setupHZProgressSubviewWithTintColor:tintColor];
  [progressView setProgress:percentage animated:YES];
  return;
}
#pragma mark - Button actions
- (void)back:(id)sender
{
  if(self.mode == HZWebBrowserModeNavigation)
    [self.navigationController popViewControllerAnimated:YES];
  else
    [self dismissViewControllerAnimated:YES completion:nil];
  
}
- (void)action:(id)sender
{
  UIActionSheet *moreSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"用Safari打开",@"复制链接", nil];
  [moreSheet showInView:self.view];
}

#pragma mark - Web view delegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
  if ([[request.URL absoluteString] hasPrefix:@"sms:"]) {
    [[UIApplication sharedApplication] openURL:request.URL];
    return NO;
  }
  
  if ([[request.URL absoluteString] hasPrefix:@"http://www.youtube.com/v/"] ||
      [[request.URL absoluteString] hasPrefix:@"http://itunes.apple.com/"] ||
      [[request.URL absoluteString] hasPrefix:@"https://itunes.apple.com/"] ||
      [[request.URL absoluteString] hasPrefix:@"http://phobos.apple.com/"]) {
    [[UIApplication sharedApplication] openURL:request.URL];
    return NO;
  }
  
  return YES;
}
- (void)webViewDidStartLoad:(UIWebView *)webView
{
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
  [self toggleState];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
  [self finishLoad];
  self.title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
  self.titleLb.text = self.title;
  self.URL = self.webView.request.URL;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
  [self finishLoad];
}

#pragma mark - Popover controller delegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
  self.activitiyPopoverController = nil;
}


#pragma mark
#pragma mark NJKWebViewProgressDelegate
- (void)webViewProgress:(NJKWebViewProgress *)webViewProgress updateProgress:(float)progress
{
  
  if(progress >= 1.0000f)
    self.webView.backgroundColor = [UIColor clearColor];
  [self viewUpdatesForPercentage:progress andTintColor:[UIColor redColor]];
  if (progress == 0.0) {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [UIView animateWithDuration:0.27 animations:^{
      
    }];
  }
  if (progress == 1.0) {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
  }
}

#pragma mark UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
  switch (buttonIndex) {
    case 0:
      [[UIApplication sharedApplication] openURL:self.URL];
      break;
    case 1:{
      UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
      pasteboard.string = self.URL.absoluteString;
    }
      break;
    default:
      break;
  }
}


@end

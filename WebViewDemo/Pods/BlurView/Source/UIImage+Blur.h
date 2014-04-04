//
//  UIImage+Blur.h
//  BFServiceStation
//
//  Created by x on 14-3-21.
//  Copyright (c) 2014年 Baofeng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Blur)
- (UIImage *)applyBlurWithRadius:(CGFloat)blurRadius tintColor:(UIColor *)tintColor saturationDeltaFactor:(CGFloat)saturationDeltaFactor maskImage:(UIImage *)maskImage;
@end

//
//  YCErrorHandler.h
//  ZKSforce_Test
//
//  Created by Yaroslav Chyzh on 6/12/16.
//  Copyright © 2016 Yaroslav Chyzh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface YCErrorHandler : NSObject

+ (void)handleErrorWithText:(NSString *)errorText showOnController:(UIViewController *)viewController;

@end

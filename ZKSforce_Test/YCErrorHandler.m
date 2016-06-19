//
//  YCErrorHandler.m
//  ZKSforce_Test
//
//  Created by Yaroslav Chyzh on 6/12/16.
//  Copyright © 2016 Yaroslav Chyzh. All rights reserved.
//

#import "YCErrorHandler.h"

@implementation YCErrorHandler

+ (void)handleErrorWithText:(NSString *)errorText showOnController:(UIViewController *)viewController {
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Error"
                                                                             message:errorText
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK"
                                                        style:UIAlertActionStyleDefault
                                                      handler:nil]];
    
    [viewController presentViewController:alertController animated:YES completion:nil];
}

@end

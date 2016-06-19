//
//  YCLoginViewController.h
//  ZKSforce_Test
//
//  Created by Yaroslav Chyzh on 6/1/16.
//  Copyright © 2016 Yaroslav Chyzh. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol YCLoginViewControllerDelegate;


@interface YCLoginViewController : UIViewController

@property (weak, nonatomic) id <YCLoginViewControllerDelegate> delegate;

@property (readonly) NSString *accessToken;
@property (readonly) NSString *refreshToken;
@property (readonly) NSString *instanceUrl;

@end

@protocol YCLoginViewControllerDelegate

@required

- (void)loginOAuth:(YCLoginViewController *)oAuthViewController error:(NSError *)error;


@end
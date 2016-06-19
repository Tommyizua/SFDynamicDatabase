//
//  YCLoginViewController.m
//  ZKSforce_Test
//
//  Created by Yaroslav Chyzh on 6/1/16.
//  Copyright © 2016 Yaroslav Chyzh. All rights reserved.
//

#import "YCLoginViewController.h"
#import "YCListTableViewController.h"
#import "NSURL+Additions.h"


@interface YCLoginViewController () <UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (strong, nonatomic) NSString *accessToken;
@property (strong, nonatomic) NSString *refreshToken;
@property (strong, nonatomic) NSString *instanceUrl;

@end

@implementation YCLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.webView.delegate = self;
    
    NSURLRequest *loginRequest = [NSURLRequest requestWithURL:[self loginURL]];
    
    [self.webView loadRequest:loginRequest];
}

#pragma mark - Help Methods

- (NSURL *)loginURL {
    
    NSString *urlString = [NSString stringWithFormat:kUrlTemplate, kConsumerKey, kRedirectUrl, kTouch];
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    return url;
}

- (void)showActivityIndicators:(BOOL)isShows {
    
    if (isShows) {
        
        [self.activityIndicator startAnimating];
        
    } else if (self.activityIndicator.isAnimating) {
        
        [self.activityIndicator stopAnimating];
    }
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = isShows;
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)myWebView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    NSURL *requestUrl = [request URL];
    
    NSString *urlString = [requestUrl absoluteString];
    
    NSRange range = [urlString rangeOfString:kRedirectUrl];
    
    if (range.length > 0 && range.location == 0) {
        
        NSString *newInstanceURL = [requestUrl parameterWithName:kInstanceUrl];
        
        if (newInstanceURL) {
            
            self.instanceUrl = newInstanceURL;
        }
        
        NSString *newRefreshToken = [requestUrl parameterWithName:kRefreshToken];
        
        if (newRefreshToken) {
            
            self.refreshToken = newRefreshToken;
        }
        
        NSString *newAccessToken = [requestUrl parameterWithName:kAccessToken];
        
        if (newAccessToken) {
            
            self.accessToken = newAccessToken;
            
            
            [self.delegate loginOAuth:self error:nil];
            
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        
        return NO;
    }
    
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    
    [self showActivityIndicators:YES];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    
    [self showActivityIndicators:NO];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(nullable NSError *)error {
    
    [self showActivityIndicators:NO];
}

@end

//
//  NSURL+Additions.m
//  ZKSforce_Test
//
//  Created by Yaroslav Chyzh on 6/3/16.
//  Copyright © 2016 Yaroslav Chyzh. All rights reserved.
//

#import "NSURL+Additions.h"

@implementation NSURL (Additions)

- (NSString *)parameterWithName:(NSString *)name {
    
    NSString *urlString = [self absoluteString];
    NSString *value = nil;
    
    NSString *regex = [NSString stringWithFormat:@"%@=[^\\s&]+", name];
    
    NSRange regexRange = [urlString rangeOfString:regex options:NSRegularExpressionSearch];
    
    if (regexRange.location != NSNotFound) {
        
        NSString *valueFullString = [urlString substringWithRange:regexRange];
        NSInteger variableNameLength = [name length]+1;
        NSString *valueString = [valueFullString substringWithRange:NSMakeRange(variableNameLength, regexRange.length - variableNameLength)];
        value = [valueString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    }
    
    return value;
}

@end

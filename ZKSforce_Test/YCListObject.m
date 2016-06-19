//
//  ListObject.m
//  ZKSforce_Test
//
//  Created by Yaroslav Chyzh on 6/13/16.
//  Copyright © 2016 Yaroslav Chyzh. All rights reserved.
//

#import "YCListObject.h"

@implementation YCListObject

+ (instancetype)objectWithName:(NSString *)title andObjectsArray:(NSArray *)objectArray {
    
    YCListObject *object = [YCListObject new];
    
    object.title = title;
    object.objectArray = objectArray;
    
    return object;
}

@end

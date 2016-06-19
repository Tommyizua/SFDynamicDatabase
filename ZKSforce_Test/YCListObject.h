//
//  ListObject.h
//  ZKSforce_Test
//
//  Created by Yaroslav Chyzh on 6/13/16.
//  Copyright © 2016 Yaroslav Chyzh. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    YCListObjectTypeAttituted,
    YCListObjectTypeRelationship
} YCListObjectType;

@interface YCListObject : NSObject

+ (instancetype)objectWithName:(NSString *)title andObjectsArray:(NSArray *)objectArray;

@property (assign, nonatomic) YCListObjectType objectType;
@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSArray *objectArray;

@end

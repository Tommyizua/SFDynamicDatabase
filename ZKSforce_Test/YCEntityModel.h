//
//  ObjectModel.h
//  ZKSforce_Test
//
//  Created by Yaroslav Chyzh on 6/8/16.
//  Copyright © 2016 Yaroslav Chyzh. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YCEntityModel : NSObject

@property (strong, nonatomic) NSString *entityName;
@property (strong, nonatomic) NSArray *attributeNames;
@property (strong, nonatomic) NSArray *relationshipNames;

+ (instancetype)modelWithZKSObject:(ZKSObject *)zksObject;

@end

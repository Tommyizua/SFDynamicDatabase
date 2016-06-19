//
//  ObjectModel.m
//  ZKSforce_Test
//
//  Created by Yaroslav Chyzh on 6/8/16.
//  Copyright © 2016 Yaroslav Chyzh. All rights reserved.
//

#import "YCEntityModel.h"

@interface YCEntityModel() <NSCoding>

@end

@implementation YCEntityModel

+ (instancetype)modelWithZKSObject:(ZKSObject *)zksObject {
    
    YCEntityModel *object = [YCEntityModel new];
    
    object.entityName = zksObject.type;
    
    NSMutableArray *fields = [NSMutableArray array];
    
    NSMutableArray *relationshipNames = [NSMutableArray array];
    
    for (id objKey in zksObject.fields.allKeys) {
        
        id value = [zksObject fieldValue:objKey];
        
        if ([value isKindOfClass:[ZKSObject class]]) {
            
            ZKSObject *superObject = value;
            
            [relationshipNames addObject:superObject.type];
            
        } else if (![value isKindOfClass:[NSString class]]) {
            
            NSLog(@"\nmodelWithZKSObject wrong kind: %@", value);
            continue;
            
        } else {
            
            [fields addObject:objKey];
        }
    }
    
    object.attributeNames = [NSArray arrayWithArray:fields];
    
    object.relationshipNames = relationshipNames;
    
    return object;
}

- (id)initWithCoder:(NSCoder *)coder {
    
    self = [super init];
    
    if (self != nil) {
        
        self.entityName = [coder decodeObjectForKey:kType];
        
        self.attributeNames = [coder decodeObjectForKey:kFields];
        
        self.relationshipNames = [coder decodeObjectForKey:kRelationshipNames];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    
    [coder encodeObject:self.entityName forKey:kType];
    
    [coder encodeObject:self.attributeNames forKey:kFields];
    
    [coder encodeObject:self.relationshipNames forKey:kRelationshipNames];
}

@end

//
//  DataManager.h
//  ZKSforce_Test
//
//  Created by Yaroslav Chyzh on 6/1/16.
//  Copyright © 2016 Yaroslav Chyzh. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YCDataManager : NSObject

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

+ (YCDataManager *)sharedManager;

- (void)saveContext;

- (NSURL *)applicationDocumentsDirectory;

- (void)createDatabaseWithRecords:(NSArray *)records;

- (NSArray *)fetchSortedAllObjects;
- (NSArray *)fetchObjectWithId:(NSString *)identifier typeName:(NSString *)typeName;

@end

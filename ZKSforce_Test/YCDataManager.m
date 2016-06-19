//
//  DataManager.m
//  ZKSforce_Test
//
//  Created by Yaroslav Chyzh on 6/1/16.
//  Copyright © 2016 Yaroslav Chyzh. All rights reserved.
//

#import "YCDataManager.h"
#import "YCEntityModel.h"


@interface YCDataManager()

@property (strong, nonatomic) NSArray *entityModelArray;
@property (strong, nonatomic) NSMutableDictionary *createdEntitiesDict;

@end

@implementation YCDataManager


+ (YCDataManager *)sharedManager {
    
    static YCDataManager *manager = nil;
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        manager = [[YCDataManager alloc] init];
    });
    
    return manager;
}

#pragma mark - Getter methods

- (NSMutableDictionary *)createdEntitiesDict {
    
    if (!_createdEntitiesDict) {
        
        _createdEntitiesDict = [NSMutableDictionary dictionary];
    }
    
    return _createdEntitiesDict;
}

- (NSArray *)entityModelArray {
    
    if (!_entityModelArray) {
        
        _entityModelArray = [NSArray new];
        
        NSObject *savedArray = [self loadFromFile:kEntityModel];
        
        if (savedArray != nil && [savedArray isKindOfClass:[NSArray class]]) {
            
            _entityModelArray = [NSArray arrayWithArray:(NSArray *)savedArray];
            
        }
    }
    
    return _entityModelArray;
}

#pragma mark - Save-Load from file

- (void)saveObject:(NSObject *)object toFile:(NSString *)name {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *appFile = [documentsDirectory stringByAppendingPathComponent:name];
    
    [NSKeyedArchiver archiveRootObject:object toFile:appFile];
}

- (NSObject *)loadFromFile:(NSString *)name {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *appFile = [documentsDirectory stringByAppendingPathComponent:name];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:appFile]) {
        
        return [NSKeyedUnarchiver unarchiveObjectWithFile:appFile];
        
    } else {
        
        NSLog(@"No File: %@", name) ;
        return nil ;
    }
    
}

#pragma mark - Help Methods

- (NSRelationshipDescription *)createRelationshipForDestionationEntity:(NSEntityDescription *)entity {
    
    NSRelationshipDescription *relationship = [NSRelationshipDescription new];
    
    [relationship setName:entity.name];
    [relationship setDestinationEntity:entity];
    
    [relationship setMinCount:0];
    [relationship setMaxCount:1];
    [relationship setDeleteRule:NSNullifyDeleteRule];
    [relationship setOptional:YES];
    
    return relationship;
}

- (NSEntityDescription *)createEntityWithAttributesWithModel:(YCEntityModel *)model {
    
    NSEntityDescription *entityDescription = [NSEntityDescription new];
    
    entityDescription.name = model.entityName;
    entityDescription.managedObjectClassName = model.entityName;
    
    
    NSMutableArray *properties = [NSMutableArray array];
    
    for (id name in model.attributeNames) {
        
        NSAttributeDescription *attribute = [NSAttributeDescription new];
        
        [attribute setName:name];
        
        [attribute setAttributeType:NSStringAttributeType];
        
        [attribute setOptional:YES];
        [attribute setIndexed:YES];
        
        [properties addObject:attribute];
    }
    
    for (NSString *relationshipName in model.relationshipNames) {
        
        NSEntityDescription *createdEntity = [self.createdEntitiesDict objectForKey:relationshipName];
        
        if (!createdEntity) {
            
            YCEntityModel *entityModel = [self findEntityModelWithName:relationshipName];
            
            if (entityModel == nil) {
                
                NSLog(@"entityModel == nil for name: %@", relationshipName);
                
            } else {
                
                NSEntityDescription *newEntityDescription = [self createEntityWithAttributesWithModel:entityModel];
                
                [self.createdEntitiesDict setObject:newEntityDescription forKey:relationshipName];
                
                
                NSRelationshipDescription *relationship = [self createRelationshipForDestionationEntity:newEntityDescription];
                
                [properties addObject:relationship];
            }
            
        } else {
            
            NSRelationshipDescription *relationship = [self createRelationshipForDestionationEntity:createdEntity];
            
            [properties addObject:relationship];
        }
    }
    
    [entityDescription setProperties:properties];
    
    return entityDescription;
}

- (NSSortDescriptor *)getSortDescriptorIfPosibleWithKey:(NSString *)key entity:(NSEntityDescription *)entity {
    
    NSAttributeDescription *attributeDescription = [entity.attributesByName objectForKey:key];
    
    NSSortDescriptor *sortDescriptor;
    
    if (attributeDescription) {
        
        sortDescriptor = [[NSSortDescriptor alloc] initWithKey:key
                                                     ascending:YES
                                                      selector:@selector(localizedCaseInsensitiveCompare:)];
    }
    
    return sortDescriptor;
}

- (void)fillModalArrayWithRecords:(NSArray *)records {
    
    NSMutableSet *entityNameSet = [NSMutableSet set];
    
    NSMutableArray *objectsArray = [NSMutableArray array];
    
    for (ZKSObject *object in records) {
        
        YCEntityModel *objectModel = [YCEntityModel modelWithZKSObject:object];
        
        if (![entityNameSet containsObject:objectModel.entityName]) {
            
            [entityNameSet addObject:objectModel.entityName];
            
            [objectsArray addObject:objectModel];
        }
    }
    
    self.entityModelArray = [NSArray arrayWithArray:objectsArray];
    
    [self saveObject:self.entityModelArray toFile:kEntityModel];
}

- (YCEntityModel *)findEntityModelWithName:(NSString *)entityName {
    
    for (YCEntityModel *model in self.entityModelArray) {
        
        if ([model.entityName isEqualToString:entityName]) {
            
            return model;
        }
    }
    
    return nil;
}

#pragma mark - Fetch requests

- (NSArray *)fetchSortedAllObjects {
    
    NSMutableArray *responseArray = [NSMutableArray new];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    for (NSEntityDescription *entityDescription in self.managedObjectModel.entities) {
        
        [fetchRequest setEntity:entityDescription];
        
        
        NSArray *keys = [NSArray arrayWithObjects:kName, kLastName, nil];
        
        NSMutableArray *sortDescriptorArray = [NSMutableArray array];
        
        for (NSString *key in keys) {
            
            NSSortDescriptor *sortDescriptor = [self getSortDescriptorIfPosibleWithKey:key
                                                                                entity:entityDescription];
            if (sortDescriptor != nil) {
                
                [sortDescriptorArray addObject:sortDescriptor];
            }
        }
        
        [fetchRequest setSortDescriptors:sortDescriptorArray];
        
        
        NSError *error = nil;
        
        NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest
                                                                           error:&error];
        
        if (error) {
            
            NSLog(@"Error fetch: %@", error.localizedDescription);
            
        } else {
            
            [responseArray addObjectsFromArray:fetchedObjects];
        }
    }
    
    return responseArray;
}

- (NSArray *)fetchObjectWithId:(NSString *)identifier typeName:(NSString *)typeName {
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:typeName inManagedObjectContext:self.managedObjectContext];
    
    NSArray *fetchedObjects;
    
    if (entityDescription != nil) {
        
        [fetchRequest setEntity:entityDescription];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"Id == %@", identifier];
        
        fetchRequest.predicate = predicate;
        
        NSError *error = nil;
        
        fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest
                                                                  error:&error];
        if (error) {
            
            NSLog(@"Error fetch: %@", error.localizedDescription);
        }
        
    }
    
    return fetchedObjects;
}

#pragma mark - Dynamic Base

- (void)createDatabaseWithRecords:(NSArray *)records {
    
    [self fillModalArrayWithRecords:records];
    
    [self clearDatabase];
    
    NSMutableDictionary *superObjectsDict = [NSMutableDictionary dictionary];
    
    for (ZKSObject *object in records) {
        
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:object.type
                                                             inManagedObjectContext:self.managedObjectContext];
        
        NSManagedObject *managedObject = [[NSManagedObject alloc] initWithEntity:entityDescription
                                                  insertIntoManagedObjectContext:self.managedObjectContext];
        
        
        for (id key in object.fields.allKeys) {
            
            id value = [object fieldValue:key];
            
            if ([value isKindOfClass:[ZKSObject class]]) {
                
                ZKSObject *superObject = value;
                
                [superObjectsDict setObject:superObject forKey:managedObject.objectID];
                
            } else if (![value isKindOfClass:[NSString class]]) {
                
                NSLog(@"CreateBase wrong kind to insert: %@", value);
                continue;
                
            } else {
                
                [managedObject setValue:value forKey:key];
            }
            
        }
        
        [self.managedObjectContext insertObject:managedObject];
    }
    
    [self setValuesRelationshipsWithZKObjectsDict:superObjectsDict];
    
    
    [self saveContext];
}

- (void)setValuesRelationshipsWithZKObjectsDict:(NSDictionary *)zkObjetsDict {
    
    for (NSManagedObjectID *objectId in zkObjetsDict.allKeys) {
        
        ZKSObject *superObject = [zkObjetsDict objectForKey:objectId];
        
        NSArray *managedObjectArray = [self fetchObjectWithId:superObject.id typeName:superObject.type];
        
        if (managedObjectArray.count == 0) {
            
            NSLog(@"managedObjects empty, need to create ManagedObject");
            
        } else {
            
            NSManagedObject *managedObjectWithRelationship = [self.managedObjectContext objectWithID:objectId];
            
            NSManagedObject *managedObjectForInsert = [managedObjectArray firstObject];
            
            [managedObjectWithRelationship setValue:managedObjectForInsert forKey:superObject.type];
        }
    }
    
}

- (void)clearDatabase {
    
    NSArray *entities = self.managedObjectModel.entities;
    
    for (NSEntityDescription *entity in entities) {
        
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:entity.name];
        
        NSBatchDeleteRequest *deleteRequest = [[NSBatchDeleteRequest alloc] initWithFetchRequest:fetchRequest];
        
        NSError *error = nil;
        
        @try {
            
            [self.persistentStoreCoordinator executeRequest:deleteRequest
                                                withContext:self.managedObjectContext
                                                      error:&error];
            
        } @catch (NSException *exception) {
            
            NSLog(@"%@", exception.reason);
            
            NSLog(@"error clear: %@", error.localizedDescription);
            
        } @finally {
            
            NSLog(@"Data cleared for: %@", entity.name);
        }
    }
    
    [self saveContext];
}

#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "com.yaroslav.chyzh.ZKSforce_Test" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)createModel {
    
    NSManagedObjectModel *model = [NSManagedObjectModel new];
    
    for (YCEntityModel *model in self.entityModelArray) {
        
        NSString *typeName = model.entityName;
        
        if (![self.createdEntitiesDict objectForKey:typeName]) {
            
            NSEntityDescription *entityDescription = [self createEntityWithAttributesWithModel:model];
            
            [self.createdEntitiesDict setObject:entityDescription forKey:typeName];
        }
    }
    
    [model setEntities:self.createdEntitiesDict.allValues];
    
    return model;
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    
    if (_managedObjectModel != nil) {
        
        return _managedObjectModel;
    }
    
    //    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"ZKSforce_Test" withExtension:@"momd"];
    //    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    
    _managedObjectModel = [self createModel];
    
    // setup persistent store coordinator
    NSString *cachedPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    
    NSURL *storeURL = [NSURL fileURLWithPath:[cachedPath stringByAppendingPathComponent:@"ZKSforce_Test.cache"]];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:_managedObjectModel];
    
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        
        // inconsistent model/store
        [[NSFileManager defaultManager] removeItemAtURL:storeURL error:NULL];
        
        // retry once
        if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
    
    // create MOC
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:_persistentStoreCoordinator];
    
    
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"ZKSforce_Test.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    
    NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption:@YES,
                              NSInferMappingModelAutomaticallyOption:@YES};
    
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

@end

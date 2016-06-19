//
//  YCListTableViewController.m
//  ZKSforce_Test
//
//  Created by Yaroslav Chyzh on 6/1/16.
//  Copyright © 2016 Yaroslav Chyzh. All rights reserved.
//

#import "YCListTableViewController.h"
#import "YCLoginViewController.h"
#import "NSURL+Additions.h"
#import "YCDataManager.h"
#import "YCObjectDetailTableViewController.h"
#import "YCErrorHandler.h"
#import "YCListObject.h"


@interface YCListTableViewController () <YCLoginViewControllerDelegate>

@property (nonatomic, assign) BOOL isLogged;
@property (nonatomic, strong) NSArray *listObjectArray;
@property (nonatomic, strong) NSMutableArray *records;

@property (nonatomic, assign) NSUInteger enterCount;
@property (nonatomic, assign) NSUInteger exitCount;

@end

@implementation YCListTableViewController

static NSString *showAccountDetailIdentifier = @"showAccountDetail";


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:0/255.0
                                                                           green:120/255.0
                                                                            blue:255/255.0
                                                                           alpha:1.0];
    
    [self.navigationController.navigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObject:[UIColor whiteColor]
                                                                                                forKey:NSForegroundColorAttributeName]];
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
//    [self fetchDataFromDataBase]; self.isLogged = YES;  //uncommit for debug cached data
    
    if (!self.isLogged) {
        
        UIViewController *loginVC = [self.storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([YCLoginViewController class])];
        
        if ([loginVC isKindOfClass:[YCLoginViewController class]]) {
            
            ((YCLoginViewController *)loginVC).delegate = self;
            
            [self presentViewController:loginVC animated:YES completion:nil];
            
        } else {
            
            NSLog(@"Error getting YCLoginViewController!");
        }
    }
}

#pragma mark - Getter Methods

- (NSMutableArray *)records {
    
    if (!_records) {
        
        _records = [NSMutableArray array];
    }
    
    return _records;
}

#pragma mark - Help methods

- (void)createDataBaseWithRecords:(NSArray *)records {
    
    [[YCDataManager sharedManager] createDatabaseWithRecords:records];
    
    [self fetchDataFromDataBase];
}

- (void)fetchDataFromDataBase {
    
    NSArray *records = [[YCDataManager sharedManager] fetchSortedAllObjects];
    
    self.listObjectArray =  [self groupObjectsInArray:records];
    
    [self.tableView reloadData];
}

- (void)getObjects {
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [self getContacts];
    
    [self getLeads];
    
    [self getAccounts];
}

- (void)getAccounts {
    
    NSString *queryString = @"Select Id, Name, Phone, BillingCity, Industry FROM Account order by Name";
    
    [self makeQueryWithQueryString:queryString];
}

- (void)getContacts {
    
    NSString *queryString = @"Select Id, FirstName, LastName, Account.Id FROM Contact order by LastName";
    
    [self makeQueryWithQueryString:queryString];
}

- (void)getLeads {
    
    NSString *queryString = @"Select Id, Name, Phone FROM Lead order by Name";
    
    [self makeQueryWithQueryString:queryString];
}

- (void)makeQueryWithQueryString:(NSString *)queryString {
    
    self.enterCount += 1;
    
    [[ZKServerSwitchboard switchboard] query:queryString
                                      target:self
                                    selector:@selector(queryResult:error:context:)
                                     context:nil];
}

- (void)queryResult:(ZKQueryResult *)result error:(NSError *)error context:(id)context {
    
    self.exitCount += 1;
    
    NSLog(@"queryResult:%@ error:%@ context:%@", result, error, context);
    
    if (result && !error) {
        
        NSArray *records = [result records];
        
        [self.records addObjectsFromArray:records];
        
        if (self.enterCount == self.exitCount) {
            
            [self createDataBaseWithRecords:self.records];
        }
        
    } else if (error) {
        
        [YCErrorHandler handleErrorWithText:error.localizedDescription showOnController:self];
    }
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (NSArray *)groupObjectsInArray:(NSArray *)array {
    
    NSMutableArray *groupedArray = [NSMutableArray array];
    
    NSArray *entitiesArray =  [YCDataManager sharedManager].managedObjectModel.entities;
    
    
    for (NSEntityDescription *entity in entitiesArray) {
        
        NSString *entityName = entity.name;
        
        
        NSMutableArray *objectArray = [NSMutableArray array];
        
        for (NSManagedObject *managedObject in array) {
            
            if ([entityName isEqualToString:managedObject.entity.name]) {
                
                [objectArray addObject:managedObject];
            }
            
        }
        
        YCListObject *listObject = [YCListObject objectWithName:entityName
                                                andObjectsArray:objectArray];
        
        
        [groupedArray addObject:listObject];
    }
    
    return groupedArray;
}

#pragma mark - YCLoginViewControllerDelegate

- (void)loginOAuth:(YCLoginViewController *)oAuthViewController error:(NSError *)error {
    
    self.isLogged = YES;
    
    NSLog(@"loginOAuth: %@ error: %@", oAuthViewController, error);
    
    if ([oAuthViewController accessToken] && !error) {
        
        [[ZKServerSwitchboard switchboard] setApiUrlFromOAuthInstanceUrl:[oAuthViewController instanceUrl]];
        [[ZKServerSwitchboard switchboard] setSessionId:[oAuthViewController accessToken]];
        [[ZKServerSwitchboard switchboard] setOAuthRefreshToken:[oAuthViewController refreshToken]];
        
        [self getObjects];
        
    } else if (error) {
        
        [YCErrorHandler handleErrorWithText:error.localizedDescription showOnController:self];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return self.listObjectArray.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    YCListObject *listObject = [self.listObjectArray objectAtIndex:section];
    
    return listObject.objectArray.count > 0 ? listObject.objectArray.count : 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    cell.textLabel.text = @"No data";
    cell.detailTextLabel.text = nil;
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    if (self.listObjectArray.count > 0) {
        
        YCListObject *listObject = [self.listObjectArray objectAtIndex:indexPath.section];
        
        if (listObject.objectArray.count > 0) {
            
            NSManagedObject *object = [listObject.objectArray objectAtIndex:indexPath.row];
            
            NSAttributeDescription *attribute = [object.entity.attributesByName objectForKey:kName];
            
            if (attribute.name == nil) {
                
                attribute = [object.entity.attributesByName objectForKey:kLastName];
                
                if (attribute.name == nil) {
                    
                    NSLog(@"\nattribute.name == nil!");
                }
            }
            
            cell.textLabel.text = [object valueForKey:attribute.name];
            
            cell.detailTextLabel.text = [object valueForKey:kId];
            
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    UIColor *backgroundColor = self.navigationController.navigationBar.barTintColor;
    
    UILabel *myLabel = [[UILabel alloc] init];
    myLabel.frame = CGRectMake(16, 5, CGRectGetWidth(tableView.frame), 16);
    myLabel.font = [UIFont boldSystemFontOfSize:18];
    
    YCListObject *listObject = [self.listObjectArray objectAtIndex:section];
    
    myLabel.text = listObject.title;
    [myLabel setTextColor:[UIColor whiteColor]];
    
    UIView *headerView = [[UIView alloc] init];
    [headerView addSubview:myLabel];
    [headerView setBackgroundColor:backgroundColor];
    
    return headerView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    YCListObject *listObject = [self.listObjectArray objectAtIndex:indexPath.section];
    
    if (listObject.objectArray.count > 0) {
        
        NSManagedObject *model = [listObject.objectArray objectAtIndex:indexPath.row];
        
        [self performSegueWithIdentifier:showAccountDetailIdentifier sender:model];
    }
    
}

#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:showAccountDetailIdentifier] && [sender isKindOfClass:[NSManagedObject class]]) {
        
        NSManagedObject *managedObject = sender;
        
        if ([segue.destinationViewController isKindOfClass:[YCObjectDetailTableViewController class]]) {
            
            YCObjectDetailTableViewController *objectDetailTVC = segue.destinationViewController;
            
            objectDetailTVC.managedObject = managedObject;
        }
        
    }
    
}

@end

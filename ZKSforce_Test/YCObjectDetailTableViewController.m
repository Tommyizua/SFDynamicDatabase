//
//  YCObjectDetailTableViewController.m
//  ZKSforce_Test
//
//  Created by Yaroslav Chyzh on 6/10/16.
//  Copyright © 2016 Yaroslav Chyzh. All rights reserved.
//

#import "YCObjectDetailTableViewController.h"
#import "YCDetailTableViewCell.h"
#import "YCDataManager.h"
#import "YCErrorHandler.h"
#import "YCListObject.h"


@interface YCObjectDetailTableViewController () <UITextFieldDelegate>

@property (strong, nonatomic) NSArray *dataRows;

@end

@implementation YCObjectDetailTableViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = self.managedObject.entity.name;
    
    NSEntityDescription *entityDescription = self.managedObject.entity;
    
    NSMutableArray *array = [NSMutableArray array];
    
    YCListObject *listObjectAttitues = [YCListObject objectWithName:@"Details" andObjectsArray:entityDescription.attributesByName.allKeys];
    listObjectAttitues.objectType = YCListObjectTypeAttituted;
    
    YCListObject *listObjectRelationships = [YCListObject objectWithName:@"References" andObjectsArray:entityDescription.relationshipsByName.allKeys];
    listObjectRelationships.objectType = YCListObjectTypeRelationship;
    
    if (listObjectAttitues.objectArray.count > 0) {
        
        [array addObject:listObjectAttitues];
    }
    
    if (listObjectRelationships.objectArray.count > 0) {
        
        [array addObject:listObjectRelationships];
    }
    
    self.dataRows = [NSArray arrayWithArray:array];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return self.dataRows.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    YCListObject *listObject = [self.dataRows objectAtIndex:section];
    
    return listObject.objectArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *detailCellIdentifier = @"Cell";
    static NSString *objectCellIdentifier = @"CellWithObject";
    
    UITableViewCell *cell;
    
    YCListObject *listObject = [self.dataRows objectAtIndex:indexPath.section];
    
    NSString *title = [listObject.objectArray objectAtIndex:indexPath.row];
    
    id value = [self.managedObject valueForKey:title];
    
    if (listObject.objectType == YCListObjectTypeAttituted) {
        
        YCDetailTableViewCell *detailCell = [tableView dequeueReusableCellWithIdentifier:detailCellIdentifier];
        
        detailCell.titleLabel.text = [NSString stringWithFormat:@"%@:", title];
        
        detailCell.valueTextField.delegate = self;
        
        if (value) {
            
            detailCell.valueTextField.text = value;
            
        } else {
            
            detailCell.valueTextField.placeholder = @"empty";
        }
        
        cell = detailCell;
        
    } else if (listObject.objectType == YCListObjectTypeRelationship && [value isKindOfClass:[NSManagedObject class]]) {
        
        NSManagedObject *managedObject = value;
        
        NSAttributeDescription *attribute = [managedObject.entity.attributesByName objectForKey:kName];
        
        if (attribute.name == nil) {
            
            attribute = [managedObject.entity.attributesByName objectForKey:kLastName];
            
            if (attribute.name == nil) {
                
                NSLog(@"\nattribute.name == nil!");
            }
        }
        
        cell = [tableView dequeueReusableCellWithIdentifier:objectCellIdentifier];
        
        cell.textLabel.text = [NSString stringWithFormat:@"%@:", title];
        
        cell.detailTextLabel.text = [managedObject valueForKey:attribute.name];
        
    } else {
        
        NSLog(@"\nUndefined value: %@ for key: %@", value, title);
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    UIColor *backgroundColor = self.navigationController.navigationBar.barTintColor;
    
    UILabel *myLabel = [[UILabel alloc] init];
    myLabel.frame = CGRectMake(16, 5, CGRectGetWidth(tableView.frame), 16);
    myLabel.font = [UIFont boldSystemFontOfSize:18];
    
    YCListObject *listObject = [self.dataRows objectAtIndex:section];
    
    myLabel.text = listObject.title;
    [myLabel setTextColor:[UIColor whiteColor]];
    
    UIView *headerView = [[UIView alloc] init];
    [headerView addSubview:myLabel];
    [headerView setBackgroundColor:backgroundColor];
    
    return headerView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    
    YCListObject *listObject = [self.dataRows objectAtIndex:indexPath.section];
    
    if (listObject.objectType == YCListObjectTypeRelationship) {
        
        if (listObject.objectArray.count > 0) {
            
            id value = [self.managedObject valueForKey:[listObject.objectArray firstObject]];
            
            YCObjectDetailTableViewController *detailVC = [self.storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([YCObjectDetailTableViewController class])];
            
            if ([value isKindOfClass:[NSManagedObject class]]) {
                
                detailVC.managedObject = value;
                
                [self showViewController:detailVC sender:nil];
                
            } else {
                
                NSLog(@"\nvalue: %@", value);
                
                NSString *errorText = [NSString stringWithFormat:@"value isn't NSManagedObject type!"];
                
                [YCErrorHandler handleErrorWithText:errorText showOnController:self];
            }
            
        } else {
            
            NSString *errorText = [NSString stringWithFormat:@"listObject.objectArray empty!"];
            
            [YCErrorHandler handleErrorWithText:errorText showOnController:self];
        }
        
    }
    
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    [textField resignFirstResponder];
    
    return YES;
}

@end

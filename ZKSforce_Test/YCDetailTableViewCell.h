//
//  YCDetailTableViewCell.h
//  ZKSforce_Test
//
//  Created by Yaroslav Chyzh on 6/11/16.
//  Copyright © 2016 Yaroslav Chyzh. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YCDetailTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UITextField *valueTextField;

@end

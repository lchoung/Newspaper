//
//  FBUReviewTableViewCell.h
//  NewsPaper
//
//  Created by Lillian Choung on 7/13/14.
//  Copyright (c) 2014 Facebook. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FBUReviewTableViewController.h"

@interface FBUReviewTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIButton *cellTitle;
@property (weak, nonatomic) IBOutlet UIButton *cellAuthor;
@property (weak, nonatomic) IBOutlet UIButton *button;
@end

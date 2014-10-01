// Copyright 2004-present Facebook. All Rights Reserved.

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
@interface NewsFeedViewController : UITableViewController 
- (id)initWithStyle:(UITableViewStyle)style source:(PFObject *)group title:(NSString *)title;
@property (nonatomic) int index;
@property (nonatomic) int max;
- (PFObject *)postForIndex:(NSInteger)index;
@end


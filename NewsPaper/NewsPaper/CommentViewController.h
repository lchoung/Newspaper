//
//  CommentViewController.h
//  NewsPaper
//
//  Created by Keegan Mendonca on 7/25/14.
//  Copyright (c) 2014 Facebook. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Parse/Parse.h"
@interface CommentViewController : UITableViewController
- (id)initWithStyle:(UITableViewStyle)style post:(PFObject *)post;
@end

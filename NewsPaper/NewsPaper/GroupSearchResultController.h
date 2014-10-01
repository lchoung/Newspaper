//
//  GroupSearchResultController.h
//  NewsPaper
//
//  Created by Keegan Mendonca on 7/25/14.
//  Copyright (c) 2014 Facebook. All rights reserved.
//

#import <Parse/Parse.h>

@interface GroupSearchResultController : PFQueryTableViewController
- (id) initWithStyle:(UITableViewStyle)style query:(PFQuery *)query;
@end

//
//  ProfileViewController.h
//  NewsPaper
//
//  Created by Keegan Mendonca on 7/17/14.
//  Copyright (c) 2014 Facebook. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface ProfileViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIImageView *profilePicture;
@property (weak, nonatomic) IBOutlet UIImageView *profileBlurPicture;
@property (weak, nonatomic) IBOutlet UITableView *postTable;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil userId:(NSString *)userId;
-(void) setUser:(PFUser *)user;
@end

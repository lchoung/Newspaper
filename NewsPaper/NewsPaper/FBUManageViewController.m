//
//  FBUManageViewController.m
//  NewsPaper
//
//  Created by Lillian Choung on 7/14/14.
//  Copyright (c) 2014 Facebook. All rights reserved.
//

#import "FBUManageViewController.h"
#import "DesignConstants.h"
#import "Parse/Parse.h"
#import "LoginViewController.h"
#import "FBUAppDelegate.h"
#import "FBUBackgroundLayer.h"

@interface FBUManageViewController ()
@property (strong, nonatomic) FBUReviewTableViewController *rvc;
@property (strong, nonatomic) FBUDraftTableViewController *dvc;
@property (strong, nonatomic) ProfileViewController *pvc;

@property (weak, nonatomic) IBOutlet UIView *postsView;
@property (weak, nonatomic) IBOutlet UIView *editView;
@property (weak, nonatomic) IBOutlet UIView *reviewView;
@property (weak, nonatomic) IBOutlet UIView *logoutView;

@property (weak, nonatomic) IBOutlet UIButton *reviewButton;
@property (weak, nonatomic) IBOutlet UIButton *editButton;
@property (weak, nonatomic) IBOutlet UIButton *postsButton;
@property (weak, nonatomic) IBOutlet UIView *contView;

@property (weak, nonatomic) IBOutlet UIButton *review;
@property (weak, nonatomic) IBOutlet UIButton *edit;
@property (weak, nonatomic) IBOutlet UIButton *posts;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *v1;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *v2;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *v3;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *v4;

@end

@implementation FBUManageViewController

- (IBAction)toReview:(id)sender
{
    [self.navigationController pushViewController:self.rvc animated:YES];
}

- (IBAction)toEdit:(id)sender
{
    [self.navigationController pushViewController:self.dvc animated:YES];
}

- (IBAction)toPosts:(id)sender
{
    [self.navigationController pushViewController:self.pvc animated:YES];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[UINavigationBar appearance] setTitleTextAttributes:TITLEATTRIBUTES];
    }
    return self;
}

- (void)viewDidLoad
{
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;
    if (screenHeight + screenWidth < 810) {
        self.v1.constant = 80;
        self.v2.constant = 25;
        self.v3.constant = 25;
        self.v4.constant = 25;
        
    }
    [super viewDidLoad];
    self.title = @"Manage";
    self.view.backgroundColor = BACKGROUNDCOLOR;
    self.reviewButton.tintColor = TEXTCOLOR;
    self.editButton.tintColor = TEXTCOLOR;
    self.postsButton.tintColor = TEXTCOLOR;

    //Round corners for button's views
    self.reviewView.layer.cornerRadius = 5;
    self.reviewView.layer.masksToBounds = YES;
    self.editView.layer.cornerRadius = 5;
    self.editView.layer.masksToBounds = YES;
    self.postsView.layer.cornerRadius = 5;
    self.postsView.layer.masksToBounds = YES;
    self.logoutView.layer.cornerRadius = 5;
    self.logoutView.layer.masksToBounds = YES;
}
- (IBAction)logout:(id)button
{
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    currentInstallation[@"channels"] = @[];
    [currentInstallation saveInBackground];
    [[PFFacebookUtils session] close];
    [PFUser logOut];
    FBUAppDelegate *appDelegate = (FBUAppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[[LoginViewController alloc] init]];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void)viewDidAppear:(BOOL)animated
{
    self.rvc =[[FBUReviewTableViewController alloc]initWithStyle:UITableViewStylePlain];
    self.dvc = [[FBUDraftTableViewController alloc] initWithNibName:nil bundle:nil];
    self.pvc = [[ProfileViewController alloc] initWithNibName:nil bundle:nil];
    [super viewDidAppear:animated];
}
@end

//
//  Copyright (c) 2013 Parse. All rights reserved.

#import "LoginViewController.h"
#import <Parse/Parse.h>
#import "FBUAppDelegate.h"
#import "NewsFeedViewController.h"
#import "FBUManageViewController.h"
#import "GroupViewController.h"
#import "DesignConstants.h"
#import "PXAlertView+Customization.h"
#import "FBUBackgroundLayer.h"

@implementation LoginViewController


#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationController.navigationBarHidden = YES;
    UIGraphicsBeginImageContext(self.view.frame.size);
    [[UIImage imageNamed:@"background.png"] drawInRect:self.view.bounds];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:image];
    self.messageLabel.textColor = TEXTCOLOR;
    self.messageLabel.font = TEXTFONT;
    self.messageLabel.textAlignment = NSTextAlignmentCenter;
    [PFFacebookUtils initializeFacebook];
    [self.loginView setUserInteractionEnabled:NO];
    [self.loginView setTooltipBehavior:FBLoginViewTooltipBehaviorDisable];
    [[UINavigationBar appearance] setTitleTextAttributes:TITLEATTRIBUTES];
    // Check if user is cached and linked to Facebook, if so, bypass login
    if ([PFUser currentUser] && [PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]){
        [self.navigationController pushViewController:[[NewsFeedViewController alloc] initWithStyle:UITableViewStylePlain] animated:NO];
    }
}


#pragma mark - Login mehtods

/* Login to facebook method */
- (IBAction)loginButtonTouchHandler:(id)sender
{
    // Set permissions required from the facebook user account
    NSArray *permissionsArray = @[ @"public_profile"];
    [_activityIndicator setHidden:NO];
    [_activityIndicator startAnimating];
    // Login PFUser using facebook
    [PFFacebookUtils logInWithPermissions:permissionsArray block:^(PFUser *user, NSError *error) {
        [_activityIndicator stopAnimating]; // Hide loading indicator
        if (!user) {
            if (!error) {
                [PXAlertView showAlertWithTitle:@"Log In Error" message:@"Uh oh. The user cancelled the Facebook login." cancelTitle:@"Dismiss" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
            } else {
                [PXAlertView showAlertWithTitle:@"Log In Error" message:@"" cancelTitle:@"Dismiss" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
            }
        } else {
            FBRequest *request = [FBRequest requestForMe];
            [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                // handle response
                if (!error) {
                    // Parse the data received
                    NSDictionary *userData = (NSDictionary *)result;
                    
                    NSString *facebookID = userData[@"id"];
                    
                    NSURL *pictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large&return_ssl_resources=1", facebookID]];
                    
                    NSMutableDictionary *userProfile = [NSMutableDictionary dictionaryWithCapacity:7];
                    
                    if (facebookID) {
                        userProfile[@"facebookId"] = facebookID;
                    }
                    
                    if (userData[@"name"]) {
                        userProfile[@"name"] = userData[@"name"];
                    }
                    
                    if (userData[@"location"][@"name"]) {
                        userProfile[@"location"] = userData[@"location"][@"name"];
                    }
                    
                    if (userData[@"gender"]) {
                        userProfile[@"gender"] = userData[@"gender"];
                    }
                    
                    if (userData[@"birthday"]) {
                        userProfile[@"birthday"] = userData[@"birthday"];
                    }
                    
                    if (userData[@"relationship_status"]) {
                        userProfile[@"relationship"] = userData[@"relationship_status"];
                    }
                    
                    if ([pictureURL absoluteString]) {
                        userProfile[@"pictureURL"] = [pictureURL absoluteString];
                    }
                    if (![PFUser currentUser][@"approvedPosts"]) {
                        [[PFUser currentUser] setObject:[[NSMutableArray alloc] init] forKey:@"approvedPosts"];
                    }
                    if (![PFUser currentUser][@"groups"]) {
                        [[PFUser currentUser] setObject:[[NSMutableArray alloc] init] forKey:@"groups"];
                    }
                    if (![PFUser currentUser][@"newsfeed"]) {
                        [[PFUser currentUser] setObject:[[NSMutableArray alloc] init] forKey:@"newsfeed"];
                    }
                    if (![PFUser currentUser][@"pendingPosts"]) {
                        [[PFUser currentUser] setObject:[[NSMutableArray alloc] init] forKey:@"pendingPosts"];
                    }
                    if (![PFUser currentUser][@"postIds"]) {
                        [[PFUser currentUser] setObject:[[NSMutableArray alloc] init] forKey:@"postIds"];
                    }
                    if (![PFUser currentUser][@"groupIds"]) {
                        [[PFUser currentUser] setObject:[[NSMutableArray alloc] init] forKey:@"groupIds"];
                    }
                    if (![PFUser currentUser][@"credibility"]) {
                        [[PFUser currentUser] setObject:@0 forKey:@"credibility"];
                    }
                    if (![PFUser currentUser][@"adminGroups"]) {
                        [[PFUser currentUser] setObject:[[NSMutableArray alloc] init] forKey:@"adminGroups"];
                    }
                    
                    [[PFUser currentUser] setObject:userProfile forKey:@"profile"];
                    [[PFUser currentUser] setObject:userProfile[@"name"] forKey:@"name"];
                    [[PFUser currentUser] save];
                    
                } else if ([[[[error userInfo] objectForKey:@"error"] objectForKey:@"type"]
                            isEqualToString: @"OAuthException"]) { // Since the request failed, we can check if it was due to an invalid session
                    NSLog(@"The facebook session was invalidated");
                } else {
                    NSLog(@"Some other error: %@", error);
                }
            }];
            
            [_activityIndicator startAnimating]; // Show loading indicator until login is finished
            self.navigationController.navigationBarHidden = NO;
            
            FBUAppDelegate *appDelegate = (FBUAppDelegate *)[[UIApplication sharedApplication] delegate];
            // Override point for customization after application launch.
            //Create a tab bar and initialize view controllers
            UITabBarController *tabBarController  = [[UITabBarController alloc] init];
            NewsFeedViewController *newsFeed = [[NewsFeedViewController alloc] initWithStyle:UITableViewStylePlain];
            UINavigationController *newsFeedNav = [[UINavigationController alloc] initWithRootViewController:newsFeed];
            FBUManageViewController *manage = [[FBUManageViewController alloc] init];
            UINavigationController *manageNav = [[UINavigationController alloc] initWithRootViewController:manage];
            GroupViewController *groups = [[GroupViewController alloc] initWithStyle:UITableViewStylePlain];
            UINavigationController *groupsNav = [[UINavigationController alloc]initWithRootViewController:groups];
                        //Set the titles on the tab bar
            [manage setTitle:@"Manage"];
            [newsFeed setTitle:@"News Feed"];
            [groups setTitle:@"Publications"];
            //Assign the controllers to the tab bar
            NSArray *controllers = [NSArray arrayWithObjects:newsFeedNav, manageNav, groupsNav, nil];
            [tabBarController setViewControllers:controllers];
            [UITabBarItem.appearance setTitleTextAttributes:
             @{NSForegroundColorAttributeName : BARTEXTCOLOR}
                                                   forState:UIControlStateNormal];
            [UITabBarItem.appearance setTitleTextAttributes:
             @{NSForegroundColorAttributeName : ACCENTCOLOR}
                                                   forState:UIControlStateSelected];
            UITabBar *tabBar = (UITabBar *)tabBarController.tabBar;
            UITabBarItem *item1 = [tabBar.items objectAtIndex:0];
            item1.image = [[UIImage imageNamed:@"activity_feed.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
            item1.selectedImage = [UIImage imageNamed:@"activity_feed.png"];
            UITabBarItem *item2 = [tabBar.items objectAtIndex:1];
            item2.image = [[UIImage imageNamed:@"edit_user.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
            item2.selectedImage = [UIImage imageNamed:@"edit_user.png"];
            UITabBarItem *item3 = [tabBar.items objectAtIndex:2];
            item3.image = [[UIImage imageNamed:@"magazine.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
            item3.selectedImage = [UIImage imageNamed:@"magazine.png"];
            [tabBarController setSelectedIndex:2];
            //Add tab bar to window
            [appDelegate.window addSubview:tabBarController.view];
            appDelegate.window.rootViewController = tabBarController;
            
        }
    }];
    
}

@end

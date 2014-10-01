//
//  FBUAppDelegate.m
//  NewsPaper
//
//  Created by Keegan Mendonca on 7/10/14.
//  Copyright (c) 2014 Facebook. All rights reserved.
//

#import "FBUAppDelegate.h"
#import "GroupViewController.h"
#import "LoginViewController.h"
#import "NewsFeedViewController.h"
#import "FBUManageViewController.h"
#import "ProfileViewController.h"
#import "Parse/Parse.h"
#import "DesignConstants.h"
#import "UIImage+ImageEffects.h"
#import <HockeySDK/HockeySDK.h>

@implementation FBUAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //Set up Parse, FB, HockeyApp, Parse Push
    NSLog(@"%g",  NSFoundationVersionNumber);
    [Parse setApplicationId:@"cMQLYNLSqoXzPALFmulSiTiJvdljC6dsiey7gweQ"
                  clientKey:@"Wte43ZEeCf6zG9jKpp1IkXglhED9Dk7W0xiQKUXu"];
    [PFFacebookUtils initializeFacebook];
    [FBLoginView class];
    [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:@"6a95da971badd3aed82b2f99acac514d"];
    [[BITHockeyManager sharedHockeyManager] startManager];
    [[BITHockeyManager sharedHockeyManager].authenticator
     authenticateInstallation];
    
    [application registerForRemoteNotificationTypes:
     UIRemoteNotificationTypeBadge |
     UIRemoteNotificationTypeAlert |
     UIRemoteNotificationTypeSound];
    
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [[UINavigationBar appearance] setTintColor:ACCENTCOLOR];
    [[UITabBar appearance] setTintColor:ACCENTCOLOR];
    [[UINavigationBar appearance] setBarStyle:BARSTYLE];
    [[UITabBar appearance] setBarStyle:BARSTYLE];
    [[UITabBar appearance] setBarTintColor:BARCOLOR];
    [[UINavigationBar appearance] setBarTintColor:BARCOLOR];
     [[UIBarButtonItem appearanceWhenContainedIn:[UINavigationBar class], nil]
      setTitleTextAttributes:TITLEATTRIBUTES forState:UIControlStateNormal];
    [[UIBarButtonItem appearanceWhenContainedIn:[UINavigationBar class], nil]
     setTitleTextAttributes:TITLEATTRIBUTES forState:UIControlStateSelected];
    if(![PFUser currentUser]) {
        self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[[LoginViewController alloc] init]];
    } else {
        if ([[PFInstallation currentInstallation][@"channels"] containsObject:[@"u"stringByAppendingString:[PFUser currentUser].objectId]]) {
            PFInstallation *currentInstallation = [PFInstallation currentInstallation];
            [[PFUser currentUser] addUniqueObject:[@"u"stringByAppendingString:[PFUser currentUser].objectId] forKey:@"channels"];
            currentInstallation[@"channels"] = [PFUser currentUser][@"channels"];
            [currentInstallation saveEventually];
            [[PFUser currentUser] saveEventually];
        }
        // Override point for customization after application launch.
        //Create a tab bar and initialize view controllers
        UITabBarController *tabBarController  = [[UITabBarController alloc] init];
        NewsFeedViewController *newsFeed = [[NewsFeedViewController alloc] initWithStyle:UITableViewStylePlain];
        UINavigationController *newsFeedNav = [[UINavigationController alloc] initWithRootViewController:newsFeed];
        newsFeedNav.title = @"Feed";
        FBUManageViewController *manage = [[FBUManageViewController alloc] init];
        UINavigationController *manageNav = [[UINavigationController alloc] initWithRootViewController:manage];
        manageNav.title = @"Manage";
        GroupViewController *groups = [[GroupViewController alloc] initWithStyle:UITableViewStylePlain];
        UINavigationController *groupsNav = [[UINavigationController alloc] initWithRootViewController:groups];
        groupsNav.title = @"Publications";
        //Assign the controllers to the tab bar
        NSArray *controllers = [NSArray arrayWithObjects:newsFeedNav, manageNav, groupsNav, nil];
        [tabBarController setViewControllers:controllers];
        //Assign the controllers to the tab bar
        [UITabBarItem.appearance setTitleTextAttributes:
         @{NSForegroundColorAttributeName : BARTEXTCOLOR}
                                               forState:UIControlStateNormal];
        [UITabBarItem.appearance setTitleTextAttributes:
         @{NSForegroundColorAttributeName : ACCENTCOLOR}
                                               forState:UIControlStateSelected];

        [[UITabBarItem appearance] setTitleTextAttributes:
         [NSDictionary dictionaryWithObjectsAndKeys:
          BARTEXTCOLOR, NSForegroundColorAttributeName,
          TINYTITLETEXTFONT, TINYTITLETEXTFONT,
          nil] forState:UIControlStateNormal];

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
        [tabBarController setSelectedIndex:0];
        [self.window addSubview:tabBarController.view];
        self.window.rootViewController = tabBarController;
    }
    self.window.backgroundColor = BACKGROUNDCOLOR;
    [self.window makeKeyAndVisible];
    return YES;
}

//Parse push functions
- (void)application:(UIApplication *)application
didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)newDeviceToken {
    // Store the deviceToken in the current installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:newDeviceToken];
    if ([PFUser currentUser]) {
        currentInstallation[@"channels"] = [PFUser currentUser][@"channels"];
    }
    [currentInstallation saveEventually];
}

- (void)application:(UIApplication *)application
didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [PFPush handlePush:userInfo];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [FBAppCall handleOpenURL:url
                  sourceApplication:sourceApplication
                        withSession:[PFFacebookUtils session]];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [FBAppCall handleDidBecomeActiveWithSession:[PFFacebookUtils session]];
}
@end

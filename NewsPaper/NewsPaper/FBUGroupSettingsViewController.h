//
//  FBUGroupSettingsViewController.h
//  NewsPaper
//
//  Created by Lillian Choung on 7/17/14.
//  Copyright (c) 2014 Facebook. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface FBUGroupSettingsViewController : UIViewController

-(id)initWithEdit:(BOOL)edit
            group:(PFObject *)group;

@end

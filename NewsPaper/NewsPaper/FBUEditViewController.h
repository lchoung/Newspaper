//
//  FBUEditViewController.h
//  NewsPaper
//
//  Created by Lillian Choung on 7/21/14.
//  Copyright (c) 2014 Facebook. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <Parse/Parse.h>

@interface FBUEditViewController : UIViewController
- (id)initWithPost:(PFObject *)post;
@end
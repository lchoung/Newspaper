//
//  NewsArticleController.h
//  NewsPaper
//
//  Created by Keegan Mendonca on 7/22/14.
//  Copyright (c) 2014 Facebook. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "NewsFeedViewController.h"
@interface NewsArticleController : UIViewController
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil object:(PFObject *)post;
- (id) initWithGallery:(BOOL)hasGallery post:(PFObject *)post;
@property (nonatomic, strong) NewsFeedViewController *owner;
@end

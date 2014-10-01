//
//  FBUReviewTableViewController.m
//  NewsPaper
//
//  Created by Lillian Choung on 7/13/14.
//  Copyright (c) 2014 Facebook. All rights reserved.
//

#import "FBUReviewTableViewController.h"
#import "FBUReviewTableViewCell.h"
#import "NewsArticleController.h"
#import "ProfileViewController.h"
#import <Parse/Parse.h>
#import "DesignConstants.h"
#import "PXAlertView+Customization.h"
#import "FBUBackgroundLayer.h"

@interface FBUReviewTableViewController () <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>
@property (nonatomic, copy) NSMutableDictionary *titles;
@property (nonatomic, strong) NSMutableDictionary *posts;
@property (nonatomic, copy) NSMutableArray *ids;
@property (strong, nonatomic) PFUser *user;
@property (nonatomic, strong) NSMutableArray *adminGroups;
@property (strong, nonatomic) NSIndexPath *postPath;
@property (nonatomic, copy) NSString *postComment;
@property (strong, nonatomic) NSMutableDictionary *hasGallery;
@property (strong, nonatomic) UIImageView *placeHolderView;
@property (assign, nonatomic) BOOL hasLoaded;
@end

@implementation FBUReviewTableViewController
- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        _hasLoaded = false;
        [self getData];
    }
    return self;
}

- (void)showPlaceholder
{
    if (_hasLoaded) {
        [self.view addSubview: self.placeHolderView];
    }
}
- (void)getData
{
    _user = [PFUser currentUser];
    _titles = [[NSMutableDictionary alloc] init];
    _ids = [[NSMutableArray alloc] init];
    _adminGroups = _user[@"adminGroups"];
    _posts = [NSMutableDictionary dictionary];
    _hasGallery = [[NSMutableDictionary alloc] init];
    [_user refreshInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (!error) {
            if ([self.user[@"pendingTitles"] isKindOfClass:[NSNull class]]
                || [self.user[@"pendingIds"] isKindOfClass:[NSNull class]]
                || [self.user[@"pendingPosts"] count] != [self.user[@"pendingTitles"] count]) {
                self.user[@"pendingPosts"] = [NSMutableArray array];
                self.user[@"pendingTitles"] = [NSMutableArray array];
                [self.user saveInBackground];
                NSDictionary *params = @{@"userId" : self.user.objectId};
                [PFCloud callFunctionInBackground:@"fixUser" withParameters:params block:nil];
                return;
            }
            if ([_user[@"pendingPosts"] count] == 0) {
                [self showPlaceholder];
            }
            int __block i = 0;
            int __block j = 0;
        for (NSString *postId in _user[@"pendingPosts"])
        {
            PFQuery *query = [PFQuery queryWithClassName:@"Post"];
            query.cachePolicy = kPFCachePolicyCacheElseNetwork;
            [query getObjectInBackgroundWithId:postId block:^(PFObject *post, NSError *error) {
                i++;
                if (!error) {
                    NSLog(@"_posts: %@", _posts);

                    if ([_adminGroups containsObject:post[@"groupId"]])
                    {
                        j++;
                        _posts[postId] = post;
                        _titles[postId] = post[@"title"];
                        if (post[@"gallery"])
                        {
                            _hasGallery[postId] = @YES;
                        } else {
                            _hasGallery[postId] = @NO;
                        }
                        [_ids addObject: postId];
                        [self.tableView reloadData];
                        [self.tableView reloadInputViews];
                        if (j == 0 && i == [_user[@"pendingPosts"] count]) {
                            [self showPlaceholder];
                        }
                        if (j != 0)
                        {
                            if ([_placeHolderView isDescendantOfView:self.view])
                            {
                                [_placeHolderView removeFromSuperview];
                                self.tableView.backgroundColor = BACKGROUNDCOLOR;
                            }
                        }
                    }
                } else {
                    NSLog(@"%@", error);
                }
            }];
        }
        }
    }];

    NSArray *userGroups = _user[@"groupIds"];
    for (NSString *groupId in userGroups)
    {
        PFQuery *query = [PFQuery queryWithClassName:@"Group"];
        query.cachePolicy = kPFCachePolicyNetworkOnly;
        [query getObjectInBackgroundWithId:groupId block:^(PFObject *object, NSError *error) {
            PFObject *group = object;
            NSNumber *cred = group[@"cred"][[[PFUser currentUser] objectId]];
            if (cred.intValue >= ((NSNumber *)group[@"minCred"]).intValue && !([_adminGroups containsObject:groupId]))
            {
                [_adminGroups addObject:groupId];
                [[PFUser currentUser] addUniqueObject:[@"g"stringByAppendingString:groupId] forKey:@"channels"];
                PFInstallation *currentInstallation = [PFInstallation currentInstallation];
                currentInstallation[@"channels"] = [PFUser currentUser][@"channels"];
                [currentInstallation saveEventually];
                [[PFUser currentUser] saveEventually];
            }
        }];
    }
}

-(void)refresh:(UIRefreshControl *)ref
{
    NSLog(@"Refreshing");
    [self.user refreshInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (!error) {
            if ([self.user[@"pendingTitles"] isKindOfClass:[NSNull class]]
                || [self.user[@"pendingIds"] isKindOfClass:[NSNull class]]
                || [self.user[@"pendingPosts"] count] != [self.user[@"pendingTitles"] count]) {
                self.user[@"pendingPosts"] = [NSMutableArray array];
                self.user[@"pendingTitles"] = [NSMutableArray array];
                [self.user saveInBackground];
                [PXAlertView showAlertWithTitle:@"Error" message:@"Loading posts to review failed." cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
                NSDictionary *params = @{@"userId" : self.user.objectId};
                [PFCloud callFunctionInBackground:@"fixUser" withParameters:params block:nil];
                if (ref) {
                    [ref endRefreshing];
                }
                return;
            }
            [self getData];
            [self.tableView reloadData];
            [self.tableView reloadInputViews];
            if (ref) {
                [ref endRefreshing];
            }
        } else {
            [ref endRefreshing];
            [PXAlertView showAlertWithTitle:@"Error" message:@"Unable to refresh data. Try again later" cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
            NSLog(@"%@", error);
        }
    }];
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _hasLoaded = true;
    self.tableView.allowsSelection = NO;
    self.tableView.backgroundColor = [UIColor whiteColor];
    [self.tableView setSeparatorColor:SEPARATORCOLOR];
    
    //Set up placeholder
    NSLog(@"view did load");
    CGRect placeHolderFrame = self.navigationController.view.frame;
    self.placeHolderView = [[UIImageView alloc]initWithFrame: placeHolderFrame];
    self.placeHolderView.image = [UIImage imageNamed:@"placeholderReview"];
    self.placeHolderView.contentMode = UIViewContentModeScaleAspectFill;
    
    UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
    refresh.tintColor = REFCOLOR;
    [refresh addTarget:self
                action:@selector(refresh:)
      forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refresh;
    self.tableView.rowHeight = 72;
    [self showPlaceholder];
    if ([_ids count] != 0)
    {
        if ([_placeHolderView isDescendantOfView:self.view])
        {
            [_placeHolderView removeFromSuperview];
            self.tableView.backgroundColor = BACKGROUNDCOLOR;
        }
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{

    if ([self.titles count] != [self.ids count]) {
        return 0;
    }
    return [self.ids count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}
-(void) viewDidAppear:(BOOL)animated
{
    if ([self.titles count] != [self.ids count]) {
        
        self.user[@"pendingPosts"] = [NSMutableArray array];
        self.user[@"pendingTitles"] = [NSMutableArray array];
        [self.user saveInBackground];
        [PXAlertView showAlertWithTitle:@"Error" message:@"Loading posts to review failed." cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
        NSDictionary *params = @{@"userId" : self.user.objectId};
        [PFCloud callFunctionInBackground:@"fixUser" withParameters:params block:nil];
    }
        [self showPlaceholder];
    if ([_ids count] != 0)
    {
        if ([_placeHolderView isDescendantOfView:self.view])
        {
            [_placeHolderView removeFromSuperview];
            self.tableView.backgroundColor = BACKGROUNDCOLOR;
        }
    }
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Try to grab a cell from the unused cell pool
    FBUReviewTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reviewCell"];
    // If there are no cells available, make one
    if (!cell) {
        [tableView registerNib:[UINib nibWithNibName:@"FBUReviewTableViewCell" bundle:nil] forCellReuseIdentifier:@"reviewCell"];
        cell = [tableView dequeueReusableCellWithIdentifier:@"reviewCell"];
    }
    
    //Every other row should be white
    if ((indexPath.row % 2) == 0)
    {
        [cell setBackgroundColor:[UIColor whiteColor]];
    } else {
            [cell setBackgroundColor:[UIColor clearColor]];
    }
    
    // Set the properties of the cell
    PFObject *post = self.posts[self.ids[indexPath.row]];
    if(post) {
        NSString *authorName = [post[@"authorName"] uppercaseString];
        if ([[PFUser currentUser].objectId isEqualToString:post[@"author"]]) {
            [cell.button setHidden:YES];
        } else {
            [cell.button setHidden:NO];
        }
        NSArray *arr = [authorName componentsSeparatedByString:@" "];
        NSString *firstName = arr[0];
        [cell.cellAuthor setTitle:firstName forState:UIControlStateNormal];
    } else {
        PFQuery *query = [PFQuery queryWithClassName:@"Post"];
        query.cachePolicy = kPFCachePolicyCacheElseNetwork;
        [query getObjectInBackgroundWithId:self.ids[indexPath.row] block:^(PFObject *post, NSError *error) {
            if(!error) {
                self.posts[self.ids[indexPath.row]] = post;
                if ([[PFUser currentUser].objectId isEqualToString:post[@"author"]]) {
                    [cell.button removeFromSuperview];
                }
                NSString *authorName = post[@"authorName"];
                NSArray *arr = [authorName componentsSeparatedByString:@" "];
                NSString *firstName = arr[0];
                [cell.cellAuthor setTitle:firstName forState:UIControlStateNormal];
            }
        }];
    }
    // Set the position of the button
    [cell.button addTarget:self action:@selector(viewPost:) forControlEvents:UIControlEventTouchUpInside];
    //[cell.contentView addSubview:button];
    [cell.cellTitle addTarget:self action:@selector(viewPost:) forControlEvents:UIControlEventTouchUpInside];
    [cell.cellAuthor addTarget:self action:@selector(viewPost:) forControlEvents:UIControlEventTouchUpInside];

    NSString *title = [self.titles[self.ids[indexPath.row]] stringByAppendingString:@"\n\n"];
    [cell.cellTitle setTitle:title
                    forState:UIControlStateNormal];
    return cell;
}

- (IBAction)viewPost:(id)sender
{
    // Figure out which post was clicked
    CGPoint buttonPosition = [sender convertPoint:CGPointZero
                                           toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    if (indexPath) {
        UIAlertView *loadingAlert = [[UIAlertView alloc] initWithTitle:@"Loading" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
        if (ALERT) {
            [loadingAlert show];
        }
        PFObject *post = self.posts[self.ids[indexPath.row]];
        if(post) {
            NewsArticleController *postViewController;
            if ([_hasGallery[self.ids[indexPath.row]] boolValue])
            {
                postViewController = [[NewsArticleController alloc] initWithGallery:YES post:post];
            } else {
                postViewController = [[NewsArticleController alloc] initWithGallery:NO post:post];
            }

            [postViewController setTitle:post[@"title"]];
            [self.navigationController pushViewController:postViewController animated:YES];
            [loadingAlert dismissWithClickedButtonIndex:-1 animated:YES];
        } else {
            PFQuery *query = [PFQuery queryWithClassName:@"Post"];
            query.cachePolicy = kPFCachePolicyCacheElseNetwork;
            [query getObjectInBackgroundWithId:self.ids[indexPath.row] block:^(PFObject *post, NSError *error) {
                if(!error) {
                    self.posts[self.ids[indexPath.row]] = post;
                    NewsArticleController *postViewController;
                    if ([_hasGallery[self.ids[indexPath.row]] boolValue])
                    {
                        postViewController = [[NewsArticleController alloc] initWithGallery:YES post:post];
                    } else {
                        postViewController = [[NewsArticleController alloc] initWithGallery:NO post:post];
                    }

                    [postViewController setTitle:@""];
                    [self.navigationController pushViewController:postViewController animated:YES];
                    [loadingAlert dismissWithClickedButtonIndex:-1 animated:YES];
                } else {
                    [loadingAlert dismissWithClickedButtonIndex:-1 animated:YES];
                    [PXAlertView showAlertWithTitle:@"Error" message:@"Unable to load post. Try again later" cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
                }
            }];
        }
    }
}



@end

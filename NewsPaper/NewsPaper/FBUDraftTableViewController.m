//
//  FBUDraftTableViewController.m
//  NewsPaper
//
//  Created by Lillian Choung on 7/14/14.
//  Copyright (c) 2014 Facebook. All rights reserved.
//

#import "FBUDraftTableViewController.h"
#import "FBUDraftTableViewCell.h"
#import "FBUEditViewController.h"
#import <Parse/Parse.h>
#import "DesignConstants.h"
#import "CommentViewController.h"
#import "NewsFeedViewController.h"
#import "PXAlertView+Customization.h"
#import "FBUBackgroundLayer.h"

@interface FBUDraftTableViewController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) NSMutableArray *posts;
@property (nonatomic, strong) UIImageView *placeHolderView;
@property (assign, nonatomic) BOOL hasLoaded;
@end

@implementation FBUDraftTableViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        _hasLoaded = false;
        // Add listener for "accept" button
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector: @selector(editPost:)
                                                     name: @"editPost"
                                                   object:nil];
        // Get post data and store it in self.posts
        PFQuery *query = [PFQuery queryWithClassName:@"Post"];
        NSString *userID = [PFUser currentUser].objectId;
        // Placeholder query until implement reviewing posts + users logic
        [query whereKey:@"author" equalTo:userID];
        [query whereKey:@"draft" equalTo:[NSNumber numberWithBool:YES]];
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
                _posts = [NSMutableArray arrayWithArray:objects];
                if (!_posts) {
                    _posts = [NSMutableArray array];
                }
                if ([_posts count] != 0)
                {
                    if ([_placeHolderView isDescendantOfView:self.view])
                    {
                        [_placeHolderView removeFromSuperview];
                        self.tableView.backgroundColor = BACKGROUNDCOLOR;
                    }
                } else  {
                    [self showPlaceholder];
                }
                [self.tableView reloadData];
            } else {
                NSLog(@"%@", error);
            }
        }];
        // Update the table
    }
    return self;
}

- (void)showPlaceholder
{
    NSLog(@"placeholder view: %@", self.placeHolderView);
    self.tableView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview: self.placeHolderView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _hasLoaded = true;

    //Set up placeholder view stuff
    CGRect placeHolderFrame = self.tableView.frame;
    NSLog(@"view: %@", self.view);
    NSLog(@"PLACEHODLER FRAME %@", NSStringFromCGRect(placeHolderFrame));
    self.placeHolderView = [[UIImageView alloc]initWithFrame: placeHolderFrame];
    self.placeHolderView.image = [UIImage imageNamed:@"placeholderEdit"];
    self.placeHolderView.contentMode = UIViewContentModeScaleAspectFill;
    
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.tableView.allowsSelection = NO;
    self.tableView.backgroundColor = BACKGROUNDCOLOR;
    [self.tableView setSeparatorColor:SEPARATORCOLOR];
    self.tableView.rowHeight = 96;
    self.tableView.allowsSelection = NO;
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.tintColor = REFCOLOR;
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:refreshControl];
    
    NSLog(@"COUNT: %ld", [_posts count]);
    if ([self.posts count] == 0) {
        [self showPlaceholder];
    } else {
        if ([_placeHolderView isDescendantOfView:self.view])
        {
            [_placeHolderView removeFromSuperview];
            self.tableView.backgroundColor = BACKGROUNDCOLOR;
        }
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [self refresh:nil];
}

- (void)editPost:(id)sender
{
    // Figure out which post was clicked
    CGPoint buttonPosition = [sender convertPoint:CGPointZero
                                           toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    NSLog(@"%@", indexPath);
    if (indexPath){
        PFObject *post = [self.posts objectAtIndex:indexPath.row];
        FBUEditViewController *evc = [[FBUEditViewController alloc] initWithPost:post];
        evc.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:evc animated:YES];
        
    }
}
- (void)viewComment:(id)sender
{
    // Figure out which post was clicked
    CGPoint buttonPosition = [sender convertPoint:CGPointZero
                                           toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    if (indexPath){
        PFObject *post = [self.posts objectAtIndex:indexPath.row];
        NSLog(@"POST:%@", post);
        CommentViewController *cvc = [[CommentViewController alloc] initWithStyle:UITableViewStylePlain post:post];
        [self.navigationController pushViewController:cvc animated:YES];
        
    }
}
- (void)viewGroup:(id)sender
{
    // Figure out which post was clicked
    CGPoint buttonPosition = [sender convertPoint:CGPointZero
                                           toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    if (indexPath){
        PFObject *post = [self.posts objectAtIndex:indexPath.row];
        NSLog(@"POST:%@", post);
        NSString *groupId = post[@"groupId"];
        NSString *groupName = post[@"group"];
        UIAlertView *loadingAlert = [[UIAlertView alloc] initWithTitle:@"Loading" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
        if (ALERT) {
            [loadingAlert show];
        }
        PFQuery *query = [PFQuery queryWithClassName:@"Group"];
        [query getObjectInBackgroundWithId:groupId block:^(PFObject *object, NSError *error) {
            if (!error) {
                NewsFeedViewController *nvc = [[NewsFeedViewController alloc] initWithStyle:UITableViewStylePlain source:object title:groupName];
                [self.navigationController pushViewController:nvc animated:YES];
                [loadingAlert dismissWithClickedButtonIndex:-1 animated:YES];
            } else {
                [loadingAlert dismissWithClickedButtonIndex:-1 animated:YES];
                [PXAlertView showAlertWithTitle:@"Error" message:@"Unable to view publication. Try again later" cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
            }
        }];
    }
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void)refresh:(UIRefreshControl *)ref
{
    _posts = [NSMutableArray array];
    PFQuery *query = [PFQuery queryWithClassName:@"Post"];
    NSString *userID = [PFUser currentUser].objectId;
    // Placeholder query until implement reviewing posts + users logic
    [query whereKey:@"author" equalTo:userID];
    [query whereKey:@"draft" equalTo:[NSNumber numberWithBool:YES]];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            _posts = [NSMutableArray arrayWithArray:objects];
            if (!_posts) {
                _posts = [NSMutableArray array];
            }
            if ([_posts count] != 0)
            {
                if ([_placeHolderView isDescendantOfView:self.view])
                {
                    [_placeHolderView removeFromSuperview];
                    self.tableView.backgroundColor = BACKGROUNDCOLOR;
                }
            } else {
                [self showPlaceholder];
            }
            [self.tableView reloadData];
            [self.tableView reloadInputViews];
            if (ref) {
                [ref endRefreshing];
            }
        } else {
            [ref endRefreshing];
            [PXAlertView showAlertWithTitle:@"Error" message:@"Unable to refresh. Try again later." cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
            NSLog(@"%@", error);
        }
    }];
    [self.tableView reloadData];
}
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSLog(@"Number of rows in section: %ld", (unsigned long)[self.posts count]);
    if ([self.posts count] == 0) {
        [self showPlaceholder];
    } else {
        if ([_placeHolderView isDescendantOfView:self.view])
        {
            [_placeHolderView removeFromSuperview];
            self.tableView.backgroundColor = BACKGROUNDCOLOR;
        }
    }
    return [self.posts count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //Try to grab a cell from the unused cell pool
    FBUDraftTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"draftCell"];
    //If there are no cells available, make one
    if (!cell) {
        [tableView registerNib:[UINib nibWithNibName:@"FBUDraftTableViewCell" bundle:nil] forCellReuseIdentifier:@"draftCell"];
        cell = [tableView dequeueReusableCellWithIdentifier:@"draftCell"];
    }
    
    if((indexPath.row % 2) == 0)
    {
        [cell setBackgroundColor:[UIColor whiteColor]];
    } else {
        [cell setBackgroundColor:[UIColor clearColor]];
    }

    cell.group.titleLabel.frame = CGRectMake(0, 0, 160, 30);
    [cell.edit addTarget:self action:@selector(editPost:) forControlEvents: UIControlEventTouchUpInside];
    [cell.group addTarget:self action:@selector(editPost:) forControlEvents: UIControlEventTouchUpInside];
    [cell.click addTarget:self action:@selector(editPost:) forControlEvents: UIControlEventTouchUpInside];

    PFObject *post = self.posts[indexPath.row];
    NSString *title = post[@"title"];
    NSString *group = [post[@"group"] uppercaseString];
    if ([post[@"comments"] count]) {
        NSString *comm;
        if ([post[@"comments"] count] == 1) {
            comm = [NSString stringWithFormat:@"View %lu comment", [post[@"comments"] count]];
        } else {
            comm = [NSString stringWithFormat:@"View %lu comments", [post[@"comments"] count]];
        }
        [cell.comment addTarget:self action:@selector(viewComment:) forControlEvents: UIControlEventTouchUpInside];
        [cell.comment setTitle:comm forState:UIControlStateNormal];
        [cell.comment setTitle:comm forState:UIControlStateHighlighted];
        [cell.comment setTitleColor:BARCOLOR forState:UIControlStateNormal];
        [cell.comment setTitleColor:BARCOLOR forState:UIControlStateHighlighted];

    } else {
        [cell.comment setTitle:@"No comments to view" forState:UIControlStateNormal];
        [cell.comment setTitle:@"No comments to view" forState:UIControlStateHighlighted];
        [cell.comment setTitleColor:BARCOLOR forState:UIControlStateNormal];
        [cell.comment setTitleColor:BARCOLOR forState:UIControlStateHighlighted];
    }
    [cell.group setTitle:group forState:UIControlStateNormal];
    [cell.group setTitle:group forState:UIControlStateHighlighted];
    cell.title.text = title;
    return cell;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        UIAlertView *loadingAlert = [[UIAlertView alloc] initWithTitle:@"Loading" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
        if (ALERT) {
            [loadingAlert show];
        }
        PFObject *post = self.posts[indexPath.row];
        NSString *postId = post.objectId;
        NSString *groupId = post[@"groupId"];
        NSString *postTitle = post[@"title"];
        NSDictionary *params = @{@"postId" : postId, @"groupId" : groupId, @"postTitle": postTitle};
        [PFCloud callFunctionInBackground:@"deletePost" withParameters:params block:^(id object, NSError *error) {
            if (!error) {
                [self.posts removeObjectAtIndex:indexPath.row];
                [self.tableView reloadData];
                [loadingAlert dismissWithClickedButtonIndex:-1 animated:NO];
            } else {
                [loadingAlert dismissWithClickedButtonIndex:-1 animated:NO];
                [PXAlertView showAlertWithTitle:@"Error" message:@"Could not save changes" cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
            }
        }];
    }
}
@end

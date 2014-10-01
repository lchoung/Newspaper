//
//  CommentViewController.m
//  NewsPaper
//
//  Created by Keegan Mendonca on 7/25/14.
//  Copyright (c) 2014 Facebook. All rights reserved.
//

#import "CommentViewController.h"
#import "DesignConstants.h"
#import "FBUBackgroundLayer.h"

@interface CommentViewController ()
@property (nonatomic, strong) NSMutableArray * data;
@property (nonatomic, strong) PFObject *post;
@end

@implementation CommentViewController

- (id)initWithStyle:(UITableViewStyle)style post:(PFObject *)post
{
    self = [super initWithStyle:style];
    if (self) {
        _post = post;
        _data  = [[NSMutableArray alloc]initWithArray:post[@"comment"]];
        self.title = [NSString stringWithFormat:@"%@ comments", post[@"title"]];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    CAGradientLayer *bgLayer = [FBUBackgroundLayer blueGradient];
    bgLayer.frame = self.view.bounds;
    [self.view.layer insertSublayer:bgLayer atIndex:0];
    self.tableView.backgroundColor = [UIColor clearColor];
    [self.tableView setSeparatorColor:SEPARATORCOLOR];
    self.tableView.allowsSelection = NO;
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.tintColor = REFCOLOR;
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:refreshControl];
    [self refresh:nil];
}
-(void)refresh:(UIRefreshControl *)ref
{
    [self.post refreshInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        [self.data setArray:self.post[@"comments"]];
        [self.tableView reloadData];
        [ref endRefreshing];
    }];
}
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.data count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    cell.textLabel.text = self.data[indexPath.row];
    cell.textLabel.textColor = TEXTCOLOR;
    if ((indexPath.row % 2) == 0)
    {
        [cell setBackgroundColor:[UIColor whiteColor]];
    } else {
        [cell setBackgroundColor:[UIColor clearColor]];
    }
    return cell;
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
        NSMutableArray *data = self.data;
        [self.post removeObject:data[indexPath.row] forKey:@"comments"];
        [self.post saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (!error) {
                self.data = data;
                [self.tableView reloadData];
                [loadingAlert dismissWithClickedButtonIndex:-1 animated:YES];
            } else {
                [loadingAlert dismissWithClickedButtonIndex:-1 animated:YES];
                self.post[@"comments"] = self.data;
                UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Could not save changes" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [errorAlert show];
            }
        }];
    }
}


@end

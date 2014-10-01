//
//  GroupViewController.m
//  NewsPaper
//
//  Created by Keegan Mendonca on 7/14/14.
//  Copyright (c) 2014 Facebook. All rights reserved.
//

#import "GroupViewController.h"
#import <Parse/Parse.h>
#import "NewsFeedViewController.h"
#import "FBUGroupSettingsViewController.h"
#import "GroupSearchResultController.h"
#import "DesignConstants.h"
#import "PXAlertView+Customization.h"
#import "FBUBackgroundLayer.h"

@interface GroupViewController () <UIAlertViewDelegate>
@property (nonatomic, strong) NSMutableArray *groups;
@property (nonatomic, strong) NSMutableDictionary *groupId;
@property (nonatomic, strong) NSMutableArray *ids;
@property (strong, nonatomic) NSMutableCharacterSet *delimiters;
@property (strong, nonatomic) NSMutableSet *tags;
@end

@implementation GroupViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        if ([[PFInstallation currentInstallation][@"channels"] containsObject:[@"u"stringByAppendingString:[PFUser currentUser].objectId]]) {
            PFInstallation *currentInstallation = [PFInstallation currentInstallation];
            [[PFUser currentUser] addUniqueObject:[@"u"stringByAppendingString:[PFUser currentUser].objectId] forKey:@"channels"];
            currentInstallation[@"channels"] = [PFUser currentUser][@"channels"];
            [currentInstallation saveEventually];
        }
        _tags = [NSMutableSet set];
        CAGradientLayer *bgLayer = [FBUBackgroundLayer blueGradient];
        bgLayer.frame = self.view.bounds;
        [self.view.layer insertSublayer:bgLayer atIndex:0];
        [[UINavigationBar appearance] setTitleTextAttributes:TITLEATTRIBUTES];
        _groups = [PFUser currentUser][@"groups"];
        _ids = [PFUser currentUser][@"groupIds"];
        for (NSString *groupId in _ids) {
            PFQuery *tagQuery = [PFQuery queryWithClassName:@"Group"];
            tagQuery.cachePolicy = kPFCachePolicyCacheElseNetwork;
            [tagQuery getObjectInBackgroundWithId:groupId block:^(PFObject *group, NSError *error) {
                if (!error) {
                    [_tags addObjectsFromArray:group[@"tags"]];
                }
            }];
        }
        _groupId = [NSMutableDictionary dictionary];
        [[PFUser currentUser] refreshInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            if (!error) {
                _groups = [PFUser currentUser][@"groups"];
                _ids = [PFUser currentUser][@"groupIds"];
                for (NSString *groupId in _ids) {
                    PFQuery *tagQuery = [PFQuery queryWithClassName:@"Group"];
                    tagQuery.cachePolicy = kPFCachePolicyCacheElseNetwork;
                    [tagQuery getObjectInBackgroundWithId:groupId block:^(PFObject *group, NSError *error) {
                        if (!error) {
                            [_tags addObjectsFromArray:group[@"tags"]];
                        }
                    }];
                }
                [self.tableView reloadData];
                PFInstallation *currentInstallation = [PFInstallation currentInstallation];
                [[PFUser currentUser] addUniqueObject:[@"u"stringByAppendingString:[PFUser currentUser].objectId] forKey:@"channels"];
                currentInstallation[@"channels"] = [PFUser currentUser][@"channels"];
                [currentInstallation saveInBackground];
                [[PFUser currentUser] saveInBackground];
            }
        }];
    }
    return self;
}

-(void)refresh:(UIRefreshControl *)ref
{
    [[PFUser currentUser] refreshInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (!error) {
            _groups = [PFUser currentUser][@"groups"];
            _ids = [PFUser currentUser][@"groupIds"];
            if ([_groups count] != [_ids count]) {
                [PFUser currentUser][@"groups"] = [NSMutableArray array];
                [PFUser currentUser][@"groupIds"] = [NSMutableArray array];
                [[PFUser currentUser] saveInBackground];
                [PXAlertView showAlertWithTitle:@"Error" message:@"Loading groups failed." cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
                NSDictionary *params = @{@"userId" : [PFUser currentUser].objectId};
                [PFCloud callFunctionInBackground:@"fixUser" withParameters:params block:nil];
                return;
            }
            for (NSString *groupId in _ids) {
                PFQuery *tagQuery = [PFQuery queryWithClassName:@"Group"];
                tagQuery.cachePolicy = kPFCachePolicyCacheElseNetwork;
                [tagQuery getObjectInBackgroundWithId:groupId block:^(PFObject *group, NSError *error) {
                    if (!error) {
                        [_tags addObjectsFromArray:group[@"tags"]];
                    }
                }];
            }
            [ref endRefreshing];
            [self.tableView reloadData];
        } else if (error.code == 101){
            [PXAlertView showAlertWithTitle:@"Error" message:@"Try logging out and on again." cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
            return;
        }
    }];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.backgroundColor = BACKGROUNDCOLOR;
    [self.tableView setSeparatorColor:SEPARATORCOLOR];
    self.title = @"Publications";
    self.tableView.allowsSelection = NO;
    UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(newGroupPrompt:)];
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    self.navigationItem.rightBarButtonItem = add;
    UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
    [refresh addTarget:self
                action:@selector(refresh:)
      forControlEvents:UIControlEventValueChanged];
    refresh.tintColor = REFCOLOR;
    self.refreshControl = refresh;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    _groups = [PFUser currentUser][@"groups"];
    _ids = [PFUser currentUser][@"groupIds"];
    _groupId = [NSMutableDictionary dictionary];
    [[PFUser currentUser] refreshInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        _groups = [PFUser currentUser][@"groups"];
        _ids = [PFUser currentUser][@"groupIds"];
        if ([_groups count] != [_ids count]) {
            [PFUser currentUser][@"groups"] = [NSMutableArray array];
            [PFUser currentUser][@"groupIds"] = [NSMutableArray array];
            [[PFUser currentUser] saveInBackground];
            [PXAlertView showAlertWithTitle:@"Error" message:@"Loading groups failed." cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
            NSDictionary *params = @{@"userId" : [PFUser currentUser].objectId};
            [PFCloud callFunctionInBackground:@"fixUser" withParameters:params block:nil];
            return;
        }
        [self.tableView reloadData];
    }];
    self.delimiters = [[NSMutableCharacterSet alloc] init];
    [self.delimiters formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [self.delimiters formUnionWithCharacterSet:[NSCharacterSet punctuationCharacterSet]];
    [self.delimiters formUnionWithCharacterSet:[NSCharacterSet punctuationCharacterSet]];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)newGroupPrompt:(UIButton *)button
{
    //Introduce group settings modal
    FBUGroupSettingsViewController *groupSettings = [[FBUGroupSettingsViewController alloc] initWithEdit:NO group:nil];
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:groupSettings];
    navigation.navigationBar.translucent = NO;
    [self presentViewController:navigation animated:YES completion:nil];
}

#pragma mark - Table view data source
-(void)addGroup:(UIButton *)button
{
    UITextField *text = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
    [PXAlertView showAlertWithTitle:@"Subscribe to publication" message:@"Enter publication name or list of tags. Or you can just press search for suggested groups" cancelTitle:@"Cancel" otherTitles:@[@"Search"] contentView:text completion:^(BOOL cancelled, NSInteger buttonIndex) {
        if (!cancelled) {
            UIAlertView *loadingAlert = [[UIAlertView alloc] initWithTitle:@"Loading" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
            if (ALERT) {
                [loadingAlert show];
            }
            NSString *groupName = text.text;
            if (![groupName length]) { //Just pressed search
                [loadingAlert dismissWithClickedButtonIndex:-1 animated:NO];
                [self suggestedGroups];
                return;
            }

            PFQuery *query = [PFQuery queryWithClassName:@"Group"];
            [query whereKey:@"name" equalTo:groupName];
            [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                [self updateGroups:(NSArray *)objects err:(NSError *)error alert:(UIAlertView *)loadingAlert name:(NSString *)groupName cont:YES];
            }];
        }
    }];
}
- (void) suggestedGroups
{
    PFQuery *query = [PFQuery queryWithClassName:@"Group"];
    [query whereKey:@"tags" containedIn:[self.tags allObjects]];
    GroupSearchResultController *groups = [[GroupSearchResultController alloc] initWithStyle:UITableViewStylePlain query:query];
    [self.navigationController pushViewController:groups animated:NO];
}
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.row;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([_groups count] != [_ids count]) {
        return 0;
    }
    return [self.groups count] + 1; //Extra row for the add button
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row) {
        return 40;
    }
    return 60;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITableViewCell *cell;
    if (indexPath.row == 0) //If it is the first row show the add button
    {
        cell = [[UITableViewCell alloc] initWithFrame:CGRectMake(0, 0, 320, 60)];
        [cell setBackgroundColor:[UIColor clearColor]];
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        btn.backgroundColor = [UIColor whiteColor];
        btn.titleLabel.font = [UIFont fontWithName:@"AppleSDGothicNeo-Bold" size:18.0];
        btn.tintColor = DARKBLUE;
        btn.frame = CGRectMake(0,20,320,40);
        [btn setTitle:@"Subscribe to a publication" forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(addGroup:) forControlEvents:UIControlEventTouchUpInside];
        [cell.contentView addSubview:btn];
        
    } else if (indexPath.row < [self.groups count] + 1) {
        cell = [[UITableViewCell alloc] initWithFrame:CGRectMake(0, 0, 320, 40)];
        [cell setBackgroundColor:[UIColor clearColor]];
        self.groupId[self.groups[indexPath.row - 1]] = self.ids[indexPath.row - 1];
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        if (indexPath.row %2 == 0) //Every other row
        {
            btn.backgroundColor = [UIColor whiteColor];
            [cell setBackgroundColor:[UIColor whiteColor]];
        }
        btn.tintColor = TEXTCOLOR;
        btn.titleLabel.font = TEXTFONT;
        btn.frame = CGRectMake(0,0,320,40);
        [btn setTitle:self.groups[indexPath.row - 1] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(userPressed:) forControlEvents:UIControlEventTouchUpInside];
        [cell.contentView addSubview:btn];
    }
    return cell;
}

-(void)userPressed:(UIButton *)button
{
    NSString *group = [[button titleLabel] text];
    NSString *objectId = self.groupId[group];
    if (objectId) {
        UIAlertView *loadingAlert = [[UIAlertView alloc] initWithTitle:@"Loading" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
        if (ALERT) {
            [loadingAlert show];
        }
        NSLog(@"%@", [PFUser currentUser]);
        PFQuery *query = [PFQuery queryWithClassName:@"Group"];
        query.cachePolicy = kPFCachePolicyNetworkElseCache;
        [query getObjectInBackgroundWithId:objectId block:^(PFObject *groupObject, NSError *error) {
            NSLog(@"%@", groupObject);
            if (!error) {
                NewsFeedViewController *article = [[NewsFeedViewController alloc] initWithStyle:UITableViewStylePlain source:groupObject title:group];
                NSLog(@"%@", groupObject[@"newsfeed"]);
                [self.navigationController pushViewController:article
                                                     animated:YES];
                [loadingAlert dismissWithClickedButtonIndex:-1 animated:YES];
            } else {
                [loadingAlert dismissWithClickedButtonIndex:-1 animated:YES];
                [PXAlertView showAlertWithTitle:@"Opening publication failed." message:@"Try again later" cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
            }
        }];
    }
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        UIAlertView *loadingAlert = [[UIAlertView alloc] initWithTitle:@"Loading" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
        if (ALERT) {
            [loadingAlert show];
        }
        NSMutableArray *groups = [NSMutableArray arrayWithArray:self.groups];
        if (![[PFUser currentUser][@"adminGroups"] containsObject:self.ids[indexPath.row - 1]]) {
            [groups removeObjectAtIndex:indexPath.row - 1];
            [PFUser currentUser][@"groups"] = groups;
            [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (!error) {
                    PFQuery *query = [PFQuery queryWithClassName:@"Group"];
                    query.cachePolicy = kPFCachePolicyNetworkElseCache;
                    [query getObjectInBackgroundWithId:self.ids[indexPath.row - 1] block:^(PFObject *groupObject, NSError *error) {
                        if (!error) {
                            [groupObject removeObject:[PFUser currentUser].objectId forKey:@"memberIds"];
                            [groupObject removeObject:[PFUser currentUser][@"name"] forKey:@"members"];
                            [groupObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                                if (!error) {
                                    [loadingAlert dismissWithClickedButtonIndex:-1 animated:YES];
                                    [self.groups removeObjectAtIndex:indexPath.row - 1];
                                    [self.ids removeObjectAtIndex:indexPath.row - 1];
                                    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                                    NSDictionary *params = @{@"userId" : [PFUser currentUser].objectId};
                                    [PFCloud callFunctionInBackground:@"fixUser" withParameters:params block:nil];
                                } else {
                                    [loadingAlert dismissWithClickedButtonIndex:-1 animated:YES];
                                    [PXAlertView showAlertWithTitle:@"Error deleting group" message:@"" cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
                                    [PFUser currentUser][@"groups"] = self.groups;
                                }
                            }];
                        } else {
                            [loadingAlert dismissWithClickedButtonIndex:-1 animated:YES];
                            [PXAlertView showAlertWithTitle:@"Error deleting group" message:@"" cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
                            [PFUser currentUser][@"groups"] = self.groups;
                        }
                    }];
                } else {
                    [loadingAlert dismissWithClickedButtonIndex:-1 animated:YES];
                    [PXAlertView showAlertWithTitle:@"Error deleting group" message:@"" cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
                    [PFUser currentUser][@"groups"] = self.groups;
                }
            }];
        } else {
            PFQuery *query = [PFQuery queryWithClassName:@"Group"];
            [query getObjectInBackgroundWithId:self.ids[indexPath.row - 1] block:^(PFObject *object, NSError *error) {
                if (!error) {
                    if (![object[@"creator"] isEqualToString:[PFUser currentUser].objectId]) {
                        [groups removeObjectAtIndex:indexPath.row - 1];
                        [PFUser currentUser][@"groups"] = groups;
                        [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                            if (!error) {
                                PFQuery *query = [PFQuery queryWithClassName:@"Group"];
                                query.cachePolicy = kPFCachePolicyNetworkElseCache;
                                [query getObjectInBackgroundWithId:self.ids[indexPath.row - 1] block:^(PFObject *groupObject, NSError *error) {
                                    if (!error) {
                                        [groupObject removeObject:[PFUser currentUser].objectId forKey:@"memberIds"];
                                        [groupObject removeObject:[PFUser currentUser][@"name"] forKey:@"members"];
                                        [groupObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                                            if (!error) {
                                                [loadingAlert dismissWithClickedButtonIndex:-1 animated:YES];
                                                [self.groups removeObjectAtIndex:indexPath.row - 1];
                                                [self.ids removeObjectAtIndex:indexPath.row - 1];
                                                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                                                NSDictionary *params = @{@"userId" : [PFUser currentUser].objectId};
                                                [PFCloud callFunctionInBackground:@"fixUser" withParameters:params block:nil];
                                            } else {
                                                [loadingAlert dismissWithClickedButtonIndex:-1 animated:YES];
                                                [PXAlertView showAlertWithTitle:@"Error deleting group" message:@"" cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
                                                [PFUser currentUser][@"groups"] = self.groups;
                                            }
                                        }];
                                    } else {
                                        [loadingAlert dismissWithClickedButtonIndex:-1 animated:YES];
                                        [PXAlertView showAlertWithTitle:@"Error deleting group" message:@"" cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
                                        [PFUser currentUser][@"groups"] = self.groups;
                                    }
                                }];
                            } else {
                                [loadingAlert dismissWithClickedButtonIndex:-1 animated:YES];
                                [PXAlertView showAlertWithTitle:@"Error deleting group" message:@"" cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
                                [PFUser currentUser][@"groups"] = self.groups;
                            }
                        }];
                    } else {
                        [loadingAlert dismissWithClickedButtonIndex:-1 animated:YES];
                        [PXAlertView showAlertWithTitle:@"Error deleting group" message:@"You are the creator" cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
                    }
                } else {
                    [loadingAlert dismissWithClickedButtonIndex:-1 animated:YES];
                    [PXAlertView showAlertWithTitle:@"Error deleting group" message:@"" cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
                }
            }];
            
        }
    }
}

-(void)updateGroups:(NSArray *)objects err:(NSError *)error alert:(UIAlertView *)loadingAlert name:(NSString *)groupName cont:(BOOL)proceed;
{
    if(!error) {
            if(!proceed) {
                [loadingAlert dismissWithClickedButtonIndex:-1 animated:YES];
                [PXAlertView showAlertWithTitle:@"Unable to save changes" message:@"Try again later" cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
            } else {
                //Make array of tags to search for out of the input
                NSMutableArray *tags = [[NSMutableArray alloc] init];
                for(NSString *tag in [[groupName lowercaseString] componentsSeparatedByCharactersInSet:self.delimiters]) {
                    if(tag.length) {
                        [tags addObject:tag];
                    }
                }
                [loadingAlert dismissWithClickedButtonIndex:-1 animated:YES];

                //Look for group that matches the name inputted
                PFQuery *nameQuery = [PFQuery queryWithClassName:@"Group"];
                [nameQuery whereKey:@"name" equalTo:groupName];

                //Look for groups that have all the tags inputted
                PFQuery *tagsQuery = [PFQuery queryWithClassName:@"Group"];
                [tagsQuery whereKey:@"tags" containsAllObjectsInArray:tags];

                //Create a compound query that will search for objects in both above queries
                PFQuery *compoundQuery = [PFQuery orQueryWithSubqueries:@[nameQuery, tagsQuery]];
                [compoundQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                    GroupSearchResultController *groups = [[GroupSearchResultController alloc] initWithStyle:UITableViewStylePlain query:compoundQuery];
                    [self.navigationController pushViewController:groups animated:YES];
                }];

            }
    } else {
        [loadingAlert dismissWithClickedButtonIndex:-1 animated:YES];
        [PXAlertView showAlertWithTitle:@"Error" message:@"Try again later" cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
    }
    
}

@end

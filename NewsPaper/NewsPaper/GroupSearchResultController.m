//
//  GroupSearchResultController.m
//  NewsPaper
//
//  Created by Keegan Mendonca on 7/25/14.
//  Copyright (c) 2014 Facebook. All rights reserved.
//

#import "GroupSearchResultController.h"
#import "DesignConstants.h"
#import "PXAlertView+Customization.h"
#import "FBUBackgroundLayer.h"

@interface GroupSearchResultController () <UIAlertViewDelegate>
@property (nonatomic, strong) PFQuery *queryForTable;
@property (nonatomic, strong) NSIndexPath *groupPath;
@end

@implementation GroupSearchResultController

- (id) initWithStyle:(UITableViewStyle)style query:(PFQuery *)query;
{
    self = [super initWithStyle:style];
    if (self) {
        CAGradientLayer *bgLayer = [FBUBackgroundLayer blueGradient];
        bgLayer.frame = self.view.bounds;
        [self.view.layer insertSublayer:bgLayer atIndex:0];
        self.loadingViewEnabled = YES;
        self.paginationEnabled = NO;
        self.pullToRefreshEnabled = YES;
        self.queryForTable = query;
        self.title = @"Search results";
        [self loadObjects];
    }
    return self;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    // go through all of the subviews until you find a PFLoadingView subclass
    for (UIView *subview in self.view.subviews)
    {
        if ([subview class] == NSClassFromString(@"PFLoadingView"))
        {
            for (UIView *loadingViewSubview in subview.subviews) {
                loadingViewSubview.hidden = YES;
                if ([loadingViewSubview isKindOfClass:[UILabel class]])
                {
                    UILabel *label = (UILabel *)loadingViewSubview;
                    label.hidden = YES;
                    //code to remove and put in new view.
                }
                
                if ([loadingViewSubview isKindOfClass:[UIActivityIndicatorView class]])
                {
                    UIActivityIndicatorView *activityIndicatorView = (UIActivityIndicatorView *)loadingViewSubview;
                    activityIndicatorView.hidden = YES;
                    [activityIndicatorView stopAnimating];
                    //code to remove and put in new view.
                }
            }
        }
    }
    self.tableView.allowsSelection = NO;
    self.tableView.backgroundColor = BACKGROUNDCOLOR;
    [self.tableView setSeparatorColor:SEPARATORCOLOR];
    // Do any additional setup after loading the view.
}

- (PFTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object
{
    PFTableViewCell *cell = [[PFTableViewCell alloc] init];
    [cell setBackgroundColor:[UIColor clearColor]];
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btn.tintColor = TEXTCOLOR;
    btn.titleLabel.font = TEXTFONT;
    btn.frame = CGRectMake(0,20,320,20);
    [btn setTitle:object[@"name"] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(userPressed:) forControlEvents:UIControlEventTouchUpInside];
    [cell.contentView addSubview:btn];
    return cell;
}
-(void)userPressed:(UIButton *)sender
{
    CGPoint buttonPosition = [sender convertPoint:CGPointZero
                                           toView:self.tableView];
    self.groupPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    NSString *message = [NSString stringWithFormat:@"Subscribe to publication %@", [self objectAtIndexPath:self.groupPath][@"name"]];
    [PXAlertView showAlertWithTitle:@"Subscribe to publication" message:message cancelTitle:@"Cancel" otherTitles:@[@"Subscribe"] completion:^(BOOL cancelled, NSInteger buttonIndex) {
        if (!cancelled) {
            UIAlertView *loadingAlert = [[UIAlertView alloc] initWithTitle:@"Loading" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
            if (ALERT) {
                [loadingAlert show];
            }
            PFUser *user = [PFUser currentUser];
            PFObject *group = [self objectAtIndexPath:self.groupPath];
            NSString *groupName = group[@"name"];
            for(NSString *currentGroup in user[@"groups"])
            {
                if([currentGroup isEqualToString:groupName]) {
                    [loadingAlert dismissWithClickedButtonIndex:1 animated:YES];
                    [PXAlertView showAlertWithTitle:@"Error" message:@"You cannot add current publications" cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
                    return;
                }
            }
            if(![groupName length]) {
                groupName = group[@"name"];
            }
            NSString *userId = [user objectId];
            NSString *username = user[@"name"];
            NSMutableArray *groupMembers = group[@"members"];
            if(!groupMembers) {
                groupMembers = [[NSMutableArray alloc] init];
            }
            [groupMembers addObject:username];
            NSMutableArray *groupMemberIds = group[@"memberIds"];
            if(!groupMemberIds) {
                groupMemberIds = [[NSMutableArray alloc] init];
            }
            [groupMemberIds addObject:userId];
            group[@"members"] = groupMembers;
            group[@"memberIds"] = groupMemberIds;
            
            NSString *groupId = [group objectId];
            NSMutableArray *memberGroups = user[@"groups"];
            if(!memberGroups) {
                memberGroups = [[NSMutableArray alloc] init];
            }
            [memberGroups addObject:groupName];
            NSMutableArray *memberGroupIds = user[@"groupIds"];
            if(!memberGroupIds) {
                memberGroupIds = [[NSMutableArray alloc] init];
            }
            [memberGroupIds addObject:groupId];
            user[@"groups"] = memberGroups;
            user[@"groupIds"] = memberGroupIds;
            [group saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if(!error)
                {
                    NSDictionary *params = @{@"userId" : [PFUser currentUser].objectId};
                    [PFCloud callFunctionInBackground:@"fixUser" withParameters:params block:^(id object, NSError *error) {
                        if (!error) {
                            [loadingAlert dismissWithClickedButtonIndex:-1 animated:YES];
                            [[PFUser currentUser] refreshInBackgroundWithBlock:nil];
                            [PXAlertView showAlertWithTitle:@"Group Found" message:[@"Succesfully subscribed to: " stringByAppendingString:groupName] cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
                        } else {
                            NSMutableArray *pendingPosts  = [NSMutableArray array];
                            [pendingPosts addObjectsFromArray:user[@"pendingPosts"]];
                            NSMutableArray *pendingTitles  = [NSMutableArray array];
                            [pendingTitles addObjectsFromArray:user[@"pendingTitles"]];
                            [pendingPosts addObjectsFromArray:group[@"pendingPosts"]];
                            [pendingTitles addObjectsFromArray:group[@"pendingTitles"]];
                            
                            [user saveInBackground];
                            [self.tableView reloadData];
                            [loadingAlert dismissWithClickedButtonIndex:-1 animated:YES];
                            [PXAlertView showAlertWithTitle:@"Group Found" message:[@"Succesfully subscribed to: " stringByAppendingString:groupName] cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
                        }
                    }];
                } else {
                    //Undo changes if unable to save
                    [memberGroups removeObject:groupName];
                    [memberGroupIds removeObject:groupId];
                    user[@"groups"] = memberGroups;
                    user[@"groupIds"] = memberGroupIds;
                    [loadingAlert dismissWithClickedButtonIndex:-1 animated:YES];
                    [PXAlertView showAlertWithTitle:@"Unable to save changes" message:@"Try again later" cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
                }
            }];
            
        }
    }];
}

@end

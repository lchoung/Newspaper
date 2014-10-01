//
//  ProfileViewController.m
//  NewsPaper
//
//  Created by Keegan Mendonca on 7/17/14.
//  Copyright (c) 2014 Facebook. All rights reserved.
//

#import "ProfileViewController.h"
#import "NewsArticleController.h"
#import "DesignConstants.h"
#import "UIImage+ImageEffects.h"
#import "PXAlertView+Customization.h"
#import "FBUBackgroundLayer.h"

//Currently have set limit to 25, can change to up to 1000 later
static int tableSize = 25;

@interface ProfileViewController () <UITableViewDataSource, NSURLConnectionDelegate, UIAlertViewDelegate>
@property (strong, nonatomic) NSMutableArray *postTitles;
@property (strong, nonatomic) NSMutableArray *postIds;
@property (strong, nonatomic) NSMutableDictionary *preLoadData;
@property (strong, nonatomic) NSMutableData *imageData;
@property (strong, nonatomic) UIAlertView *loadingAlert;
@property (strong, nonatomic) UIImage *profileImage;
@property (strong, nonatomic) UIImage *profileBlurImage;
@property (nonatomic, assign) BOOL loaded;
@property (nonatomic, strong) NSString * curImageAuthor;
@property (strong, nonatomic) PFUser *user;
@property (strong, nonatomic) NSMutableDictionary *hasGallery;
@property (strong, nonatomic) UIRefreshControl *refreshControl;

@property (weak, nonatomic) IBOutlet UILabel *crednum;
@property (weak, nonatomic) IBOutlet UILabel *postnum;

@end

@implementation ProfileViewController
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _user = [PFUser currentUser];
        NSDictionary *params = @{@"userId" : _user.objectId};
        [PFCloud callFunctionInBackground:@"fixUser" withParameters:params block:nil];
        [self setInfo];
        _loaded = false;
        _refreshControl = [[UIRefreshControl alloc] init];
        [_refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
        _refreshControl.tintColor = REFCOLOR;
    }
    return self;
}
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil userId:(NSString *)userId
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _refreshControl = [[UIRefreshControl alloc] init];
        [_refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
        _refreshControl.tintColor = REFCOLOR;
        PFQuery *query = [PFUser query];
        query.cachePolicy = kPFCachePolicyNetworkElseCache;
        [query getObjectInBackgroundWithId:userId block:^(PFObject *object, NSError *error) {
            if (!error) {
                _user = (PFUser *) object;
                NSDictionary *params = @{@"userId" : _user.objectId};
                [PFCloud callFunctionInBackground:@"fixUser" withParameters:params block:nil];
                [self setInfo];
                [self viewDidLoad];
            } else {
                NSLog(@"Error %@", error);
            }
        }];
    }
    return self;
}
-(void) setUser:(PFUser *)user
{
    _user = user;
    NSDictionary *params = @{@"userId" : _user.objectId};
    [PFCloud callFunctionInBackground:@"fixUser" withParameters:params block:nil];
    [self.postTable reloadData];
    [self setInfo];
}
//Deals with initialization that occurs regardless of the user.
- (void)setInfo
{
    NSLog(@"Setting info");
    NSString *authorName = self.user[@"name"];
    NSArray *arr = [authorName componentsSeparatedByString:@" "];
    NSString *firstName = @"";
    if ([arr count]) {
        firstName = arr[0];
    }
    self.title = firstName;
    self.preLoadData = [NSMutableDictionary dictionary];
    self.postIds = [NSMutableArray array];
    self.postTitles = [NSMutableArray array];
    self.hasGallery = [NSMutableDictionary dictionary];
    
    PFQuery *query = [PFQuery queryWithClassName:@"Post"];
    query.cachePolicy = kPFCachePolicyNetworkElseCache;
    [query whereKey:@"author" equalTo:self.user.objectId];
    [query whereKey:@"draft" equalTo:[NSNumber numberWithBool:NO]];
    [query whereKey:@"approved" equalTo:[NSNumber numberWithBool:YES]];
    query.limit = tableSize;
    [query orderByDescending:@"createdAt"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            self.preLoadData = [NSMutableDictionary dictionary];
            self.postIds = [NSMutableArray array];
            self.postTitles = [NSMutableArray array];
            NSLog(@"QUERY");
            self.title = firstName;
            for (PFObject *post in objects) {
                NSLog(@"self.postTitles BEFORE QUERY are: %@", self.postTitles);
                [self.postTitles addObject:post[@"title"]];
                NSLog(@"self.postTitles AFTER QUERY are: %@", self.postTitles);
                [self.postIds addObject:post.objectId];
                if (post[@"gallery"])
                {
                    self.hasGallery[post.objectId] = @YES;
                } else {
                    self.hasGallery[post.objectId] = @NO;
                }
            }
            NSLog(@"Succesful till here");
            [self.postTable reloadData];
        } else {
            NSLog(@"%@", error);
        }
    }];
    
    
    NSLog(@"%@", self.user);
    if (![self.user.objectId isEqualToString:self.curImageAuthor] && [self.user objectForKey:@"profile"][@"pictureURL"]) {
        self.imageData = nil;
        self.imageData = [[NSMutableData alloc] init]; // the data will be loaded in here
        self.profileImage = nil;
        self.profileBlurImage = nil;
        self.profileBlurPicture.image = nil;
        self.profilePicture.image = nil;
        NSString *facebookId = [self.user objectForKey:@"profile"][@"facebookId"];
        NSString *urlString = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?width=400&height=400",facebookId];
        NSURL *pictureURL = [NSURL URLWithString:urlString];
        NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:pictureURL
                                                                  cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                              timeoutInterval:2.0f];
        // Run network request asynchronously
        NSURLConnection *urlConnection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self];
        if (!urlConnection) {
            NSLog(@"Failed to download picture");
        }
    }
    
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    self.crednum.text = [NSString stringWithFormat:@"%@",self.user[@"credibility"]];
    self.postnum.text = [NSString stringWithFormat:@"%@",self.user[@"pubNumber"]];
    return [self.postTitles count] + 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"index is %ld", indexPath.row);
    int row = indexPath.row - 1;
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    [cell setBackgroundColor:[UIColor clearColor]];
    if (!indexPath.row) {
        UILabel *lbl;
        if ([self.postTitles count]) {
            lbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, 320, 20)];
            lbl.textAlignment = NSTextAlignmentCenter;
            lbl.text = [[NSString stringWithFormat:@"%@'s posts", self.title] uppercaseString];
            lbl.font = [UIFont fontWithName:@"AppleSDGothicNeo-Bold" size:16.0];
        } else {
            lbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, 320, 20)];
            lbl.textAlignment = NSTextAlignmentCenter;
            lbl.text = [NSString stringWithFormat:@"%@ has no posts yet :(", self.title];
            lbl.font = [UIFont fontWithName:@"AppleSDGothicNeo-Light" size:16.0];
        }
        lbl.textColor = REFCOLOR;
        lbl.tintColor = REFCOLOR;
        [cell.contentView addSubview:lbl];
    } else {
        if(indexPath.row % 2)
        {
            cell.backgroundColor = [UIColor whiteColor];
        }
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        btn.tintColor = TEXTCOLOR;
        btn.frame = CGRectMake(0, 10, 320, 20);
        btn.titleLabel.font = TEXTFONT;
        //Set cred label
        if ([self.postTitles count] > row && self.postTitles[row]) {
            [btn setTitle:self.postTitles[row] forState:UIControlStateNormal];
            [btn addTarget:self action:@selector(userPressed:) forControlEvents:UIControlEventTouchUpInside];
            [cell.contentView addSubview:btn];
            if ([self.postIds count] > row && !self.preLoadData[self.postIds[row]]) {
                PFQuery *query = [PFQuery queryWithClassName:@"Post"];
                query.cachePolicy = kPFCachePolicyNetworkElseCache;
                NSLog(@"ROW   %@", self.postIds[row]);
                [query getObjectInBackgroundWithId:self.postIds[row] block:^(PFObject *postObject, NSError *error) {
                    if (!error) {
                        if ([self.postIds count] > row) {
                            self.preLoadData[self.postIds[row]] = postObject;
                        }
                    } else {
                        NSLog(@"%@", error);
                    }
                }];
            }
        }
    }
    return cell;
}
-(void)userPressed:(UIButton *)button
{
    if (ALERT) {
        [self.loadingAlert show];
    }
    CGPoint buttonPosition = [button convertPoint:CGPointZero
                                            toView:self.postTable];
    NSIndexPath *indexPath = [self.postTable indexPathForRowAtPoint:buttonPosition];
    int row = indexPath.row - 1;
    if ([self.postIds count] > row) {
        NSString* objectId = self.postIds[row];
        if (self.preLoadData[objectId]) {
            BOOL hasGallery;
            NSLog(@"has gallery: %@", self.hasGallery[objectId]);
            if ([self.hasGallery[objectId] boolValue])
            {
                hasGallery = YES;
            } else {
                hasGallery = NO;
            }
            NewsArticleController *postViewController = [[NewsArticleController alloc] initWithGallery:hasGallery post:self.preLoadData[objectId]];
            [self.navigationController pushViewController:postViewController animated:YES];
            [self.loadingAlert dismissWithClickedButtonIndex:-1 animated:YES];
        } else {
            PFQuery *query = [PFQuery queryWithClassName:@"Post"];
            query.cachePolicy = kPFCachePolicyCacheElseNetwork;
            [query getObjectInBackgroundWithId:objectId block:^(PFObject *postObject, NSError *error) {
                if (!error) {
                    self.preLoadData[objectId] = postObject;
                    NewsArticleController *postViewController = [[NewsArticleController alloc] initWithNibName:nil bundle:nil object:self.preLoadData[objectId]];
                    [self.navigationController pushViewController:postViewController animated:YES];
                    [self.loadingAlert dismissWithClickedButtonIndex:-1 animated:YES];
                } else {
                    [self.loadingAlert dismissWithClickedButtonIndex:-1 animated:YES];
                    [PXAlertView showAlertWithTitle:@"Could not load post" message:@"Try again later" cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
                }
            }];
        }
    }
}
-(void)refresh:(UIRefreshControl *)ref
{
    NSLog(@"REFERSHING");
    [self.user refreshInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (!error) {
            [self setInfo];
            self.crednum.text = [NSString stringWithFormat:@"%@",self.user[@"credibility"]];
            self.postnum.text = [NSString stringWithFormat:@"%@",self.user[@"pubNumber"]];
            [ref endRefreshing];
        } else {
            [ref endRefreshing];
            [PXAlertView showAlertWithTitle:@"Error" message:@"Unable to refresh data. Try again later" cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
            NSLog(@"%@", error);
        }
    }];
    
}
- (void)viewDidLoad
{
    NSLog(@"View Did Load was called");
    [super viewDidLoad];
    if (!_loaded && self.user) {
        [self setInfo];
        NSLog(@"Set info");
    }
    self.profilePicture.contentMode = UIViewContentModeScaleAspectFill;
    //Colors
    self.view.backgroundColor = BACKGROUNDCOLOR;
    self.postTable.allowsSelection = NO;
    self.postTable.backgroundColor = [UIColor clearColor];
    [self.postTable setSeparatorColor:SEPARATORCOLOR];
    self.postTable.rowHeight = 40;
    self.loadingAlert = [[UIAlertView alloc] initWithTitle:@"Loading" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    if (ALERT) {
        [self.loadingAlert show];
    }
    [self.postTable setDataSource:self];
    [self.loadingAlert dismissWithClickedButtonIndex:-1 animated:YES];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(searchUser:)];
    if (![[self.postTable subviews] containsObject:_refreshControl]) {
        [self.postTable addSubview:_refreshControl];
    }
    self.profilePicture.image = self.profileImage;
    self.profileBlurPicture.image = self.profileBlurImage;
}

- (void)searchUser:(id)search
{
    UITextField *text = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
    [PXAlertView showAlertWithTitle:@"View Person" message:@"Enter Full Name as it appears on Facebook" cancelTitle:@"Cancel" otherTitles:@[@"Search"] contentView:text completion:^(BOOL cancelled, NSInteger buttonIndex) {
        if (!cancelled) {
            NSLog(@"SOMETHING");
            NSString *username = text.text;
            if (username.length < 2) {
                [PXAlertView showAlertWithTitle:@"Please enter in a user's name" message:@"" cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
            } else {
                UIAlertView *loadingAlert = [[UIAlertView alloc] initWithTitle:@"Loading" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
                if (ALERT) {
                    [loadingAlert show];
                }
                if ([username isEqualToString:self.user[@"name"]]) {
                    [loadingAlert dismissWithClickedButtonIndex:-1 animated:YES];
                    self.user = [PFUser currentUser];
                    self.crednum.text = [NSString stringWithFormat:@"%@",self.user[@"credibility"]];
                    self.postnum.text = [NSString stringWithFormat:@"%@",self.user[@"pubNumber"]];
                    [self setInfo];
                    [self viewDidLoad];
                    return;
                } else {
                    PFQuery *query = [PFUser query];
                    [query whereKey:@"name" equalTo:username];
                    [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                        if (!error) {
                            if (object) {
                                self.user = (PFUser *)object;
                                self.crednum.text = [NSString stringWithFormat:@"%@",self.user[@"credibility"]];
                                self.postnum.text = [NSString stringWithFormat:@"%@",self.user[@"pubNumber"]];
                                [self setInfo];
                                [self viewDidLoad];
                                [loadingAlert dismissWithClickedButtonIndex:-1 animated:YES];
                                return;
                            }
                        } else {
                            [loadingAlert dismissWithClickedButtonIndex:-1 animated:NO];
                            [PXAlertView showAlertWithTitle:@"User not found" message:@"Try using their Facebook name" cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {
                            }];
                            return;
                        }
                    }];
                }
            }
        }
    }];
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.imageData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    self.profileImage = [UIImage imageWithData:self.imageData];
    self.profileImage = [self.profileImage imageByCroppingImageToSize:400];
    
    //BezierPath
    UIBezierPath *bezierPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, 400, 400)];
    
    // Create an image context containing the original UIImage.
    UIGraphicsBeginImageContext(self.profileImage.size);
    
    // Clip to the bezier path and clear that portion of the image.
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextAddPath(context,bezierPath.CGPath);
    CGContextClip(context);
    
    // Draw here when the context is clipped
    [self.profileImage drawAtPoint:CGPointZero];
    
    // Build a new UIImage from the image context.
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.profileBlurImage = [self.profileImage applyLightEffect];
    
    self.profileImage = newImage;
    _loaded = true;
    self.profilePicture.image = self.profileImage;
    self.profileBlurPicture.image = self.profileBlurImage;
    self.curImageAuthor = self.user.objectId;
    [self refresh:nil];
    NSLog(@"refreshed");
}
-(void)viewWillAppear:(BOOL)animated
{
    NSDictionary *params = @{@"userId" : _user.objectId};
    [PFCloud callFunctionInBackground:@"fixUser" withParameters:params block:^(id object, NSError *error) {
        if (!error) {
            [self.user refreshInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                [self setInfo];
            }];
        }
    }];
}
@end

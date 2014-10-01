//
//  NewsArticleController.m
//  NewsPaper
//
//  Created by Keegan Mendonca on 7/22/14.
//  Copyright (c) 2014 Facebook. All rights reserved.
//

#import "NewsArticleController.h"
#import "CXPhotoBrowser.h"
#import <QuartzCore/QuartzCore.h>
#import <Parse/Parse.h>
#import "DesignConstants.h"
#import "FBUBackgroundLayer.h"
#import "PXAlertView+Customization.h"
#import "UIImage+ImageEffects.h"
#import "ProfileViewController.h"

@interface NewsArticleController ()
<CXPhotoBrowserDataSource, CXPhotoBrowserDelegate>
{
    NSArray *imageURLs;
    
    //CXBrowserNavBarView *navBarView;
}
@property (nonatomic, strong) CXPhotoBrowser *browser;
@property (nonatomic, strong) NSMutableArray *photoDataSource;
@property (weak, nonatomic) IBOutlet UIImageView *thumbnail;
@property (strong, nonatomic) PFObject *post;
@property (strong, nonatomic) UIImage *image;
@property (strong, nonatomic) UIImage *profileImageData;
@property (weak, nonatomic) IBOutlet UITextView *text;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicator;
@property (nonatomic) BOOL animating;
@property (weak, nonatomic) IBOutlet UIButton *openImage;
@property (strong, nonatomic) UIAlertView *loadingAlert;
@property (strong, nonatomic) NSString *postComment;
@property (weak, nonatomic) IBOutlet UIImageView *profileImage;
@property (weak, nonatomic) IBOutlet UILabel *postAuthor;
@property (weak, nonatomic) IBOutlet UIButton *postTitle;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *groupName;
@property (strong, nonatomic) NSMutableData *imageData;
@property (weak, nonatomic) IBOutlet UIButton *star;
@property (strong, nonatomic) PFUser *author;
@property (strong, nonatomic) PFObject *group;

@property (nonatomic, assign) BOOL hasGallery;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *height;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textHeight;
@property (weak, nonatomic) IBOutlet UIView *contBox;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *boxHeight;

@end

@implementation NewsArticleController

- (id) initWithGallery:(BOOL)hasGallery post:(PFObject *)post
{
    //init function that will take into account whether there is a photo or not
    self = [self initWithNibName:@"NewsArticleController" bundle:nil object:post];
    self.hasGallery = hasGallery;
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil object:(PFObject *)post
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _imageData = [NSMutableData data];
        self.post = post;
        [self downloadData];
        PFQuery *groupQuery = [PFQuery queryWithClassName:@"Group"];
        [groupQuery getObjectInBackgroundWithId:post[@"groupId"] block:^(PFObject *object, NSError *error) {
            self.group = object;
        }];

        //Is it a draft?
        BOOL check = ([post[@"draft"] boolValue] && ![[PFUser currentUser].objectId isEqualToString:post[@"author"]]);
        if (check) {
            UIBarButtonItem *approveItem = [[UIBarButtonItem alloc] initWithTitle:@"Approve" style:UIBarButtonItemStylePlain target:self action:@selector(acceptPost:)];
            [approveItem setTitleTextAttributes:APPROVEATTRIBUTES forState:UIControlStateNormal];
            [approveItem setTitleTextAttributes:APPROVEATTRIBUTES forState:UIControlStateHighlighted];
            self.navigationItem.rightBarButtonItems = @[[[UIBarButtonItem alloc] initWithTitle:@"Feedback" style:UIBarButtonItemStylePlain target:self action:@selector(commentPost:)], [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],approveItem, [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
        } else {
            self.navigationItem.rightBarButtonItem = nil;
            self.title = @"";
        }
        self.navigationItem.leftBarButtonItem = self.navigationItem.backBarButtonItem;
        _postComment = [NSMutableString string];
        self.animating = YES;
        self.photoDataSource = [[NSMutableArray alloc] init];
        self.browser = [[CXPhotoBrowser alloc] initWithDataSource:self delegate:self];
        if(!post[@"gallery"]) {
            self.animating = NO;
        } else {
            PFQuery *galleryQuery = [PFQuery queryWithClassName:@"Gallery"];
            [galleryQuery getObjectInBackgroundWithId:post[@"gallery"] block:^(PFObject *galleryObject, NSError *error) {
                NSArray *gallery = galleryObject[@"photoIds"];
                for (NSString *image in gallery) {
                    PFQuery *query = [PFQuery queryWithClassName:@"Image"];
                    [query getObjectInBackgroundWithId:image block:^(PFObject *object, NSError *error) {
                        if (!error) {
                            PFFile *imageData = (PFFile *) object[@"imageFile"];
                            [imageData getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                                if (!error) {
                                    UIImage *downloadedImage = [[UIImage alloc] initWithData:data];
                                    if(![self.photoDataSource count]) {
                                        self.image = downloadedImage;
                                        self.thumbnail.contentMode = UIViewContentModeScaleAspectFit;
                                        [self.thumbnail setImage:self.image];
                                        self.animating = NO;
                                        [self.indicator setHidden:YES];
                                        [self.openImage setEnabled:YES];
                                    }
                                    [self.photoDataSource addObject:[[CXPhoto alloc]initWithImage:downloadedImage]];
                                } else {
                                    NSLog(@"%@", error);
                                }
                            }];
                        } else {
                            NSLog(@"%@", error);
                        }
                    }];
                }
                
            }];
        }
    }
    return self;
}
-(void)popSelf
{
    [self.navigationController popViewControllerAnimated:YES];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = BACKGROUNDCOLOR;
    self.postAuthor.text = [self.post[@"authorName"] uppercaseString];
    self.postAuthor.textColor = [UIColor lightGrayColor];
    [self.postTitle setTitle:self.post[@"title"] forState:UIControlStateNormal];
    [self.postTitle setTitle:self.post[@"title"] forState:UIControlStateHighlighted];
    [self.postTitle setUserInteractionEnabled:NO];

    self.indicator.tintColor = REFCOLOR;
    self.loadingAlert = [[UIAlertView alloc] initWithTitle:@"Loading" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    self.view.backgroundColor = BACKGROUNDCOLOR;
    self.text.editable = NO;
    self.text.backgroundColor = [UIColor whiteColor];
    self.text.layer.cornerRadius = 5;
    self.text.layer.masksToBounds = YES;
    self.text.textColor = TEXTCOLOR;
    self.text.font = TEXTFONT;
    
    self.contBox.layer.cornerRadius = 5;
    self.contBox.layer.masksToBounds = YES;
    
    //Set the time tag
    NSString *age;
    NSDate *updateTime = self.post.createdAt;
    double timeSincePost = -[updateTime timeIntervalSinceNow] ;
    if (timeSincePost < 60) {
        age = @"now";
    } else if (timeSincePost < 3599) {
        age = [NSString stringWithFormat:@"%d min", (int)(timeSincePost / 60)];
    } else if (timeSincePost < 86399) {
        age = [NSString stringWithFormat:@"%d hr", (int)(timeSincePost / 3600)];
    } else if (timeSincePost < 604799) {
        age = [NSString stringWithFormat:@"%d d", (int)(timeSincePost / 86400)];
    } else if (timeSincePost < 2419199) {
        age = [NSString stringWithFormat:@"%d wk", (int)(timeSincePost / 604800)];
    } else {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
        [dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
        age = [NSString stringWithFormat:@"%@", [dateFormatter stringFromDate:updateTime]];
    }
    self.dateLabel.text = age;
    self.groupName.text = [self.post[@"group"] uppercaseString];
    self.thumbnail.contentMode = UIViewContentModeScaleAspectFit;
    self.thumbnail.contentMode = UIViewContentModeTop;
    if(self.animating) {
        [self.indicator startAnimating];
        [self.openImage setEnabled:NO];
    } else {
        [self.indicator setHidden:YES];
    }
    if (!self.post[@"gallery"]) {
        [self.thumbnail setFrame:CGRectMake(self.thumbnail.frame.origin.x, self.thumbnail.frame.origin.y, 0, self.thumbnail.frame.size.height)];
        [self.openImage setFrame:CGRectMake(self.thumbnail.frame.origin.x, self.thumbnail.frame.origin.x, 0,  self.thumbnail.frame.size.height)];
        self.height.constant = -150;
        [self.text updateConstraints];
    } else {
        [self.thumbnail setFrame:CGRectMake(self.thumbnail.frame.origin.x, self.thumbnail.frame.origin.y, 320, self.thumbnail.frame.size.height)];
        [self.openImage setFrame:CGRectMake(self.thumbnail.frame.origin.x, self.thumbnail.frame.origin.x, 320,  self.thumbnail.frame.size.height)];
        self.height.constant = 10;
        [self.thumbnail setImage:self.image];
        [self.openImage setEnabled:YES];
        
    }
    self.text.text = self.post[@"text"];
    UISwipeGestureRecognizer *rightRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(rightSwipeHandle:)];
    rightRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    [rightRecognizer setNumberOfTouchesRequired:1];
    
    //add gestureRecognizer
    [self.view addGestureRecognizer:rightRecognizer];
    
    UISwipeGestureRecognizer *leftRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(leftSwipeHandle:)];
    leftRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    [leftRecognizer setNumberOfTouchesRequired:1];
    
    [self.view addGestureRecognizer:leftRecognizer];

    //profile image stuff
    self.profileImage.contentMode = UIViewContentModeScaleAspectFit;
    self.profileImage.image = self.profileImageData;
    self.profileImage.layer.cornerRadius = 5;
    self.profileImage.layer.masksToBounds = YES;

    //star color
    if ([self.post[@"voters"]  containsObject:[PFUser currentUser].objectId]) {
        [self.star setImage:[UIImage imageNamed:@"blueStar.png"] forState:UIControlStateNormal];
    } else {
        [self.star setImage:[UIImage imageNamed:@"greyStar.png"] forState:UIControlStateNormal];
    }
}
-(void)rightSwipeHandle:(UISwipeGestureRecognizer*)right
{
    if (ALERT) {
        if (self.owner.index == 0) {
            return;
        }
        [self.loadingAlert show];
        self.animating = YES;
        [self.indicator setHidden:NO];
        [self.indicator startAnimating];
        self.owner.index = self.owner.index - 1;
        self.post = [self.owner postForIndex:self.owner.index];
        [self reload];
    }
}
-(void)leftSwipeHandle:(UISwipeGestureRecognizer*)left
{
    if (ALERT) {
        if (self.owner.index == self.owner.max) {
            return;
        }
        [self.loadingAlert show];
        self.animating = YES;
        [self.indicator setHidden:NO];
        [self.indicator startAnimating];
        self.owner.index = self.owner.index + 1;
        self.post = [self.owner postForIndex:self.owner.index];
        
        [self reload];
    }
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)showBrowserWithPush:(id)sender
{
    if (self.post[@"gallery"]) {
        [self.browser setInitialPageIndex:0];
        [self.navigationController pushViewController:self.browser animated:YES];
    }
}
- (void) reload{
    self.photoDataSource = [[NSMutableArray alloc] init];
    if (![self.postAuthor.text isEqualToString:[self.post[@"authorName"] uppercaseString]]) {
        self.author = nil;
        [self downloadData];
    }
    if (![self.groupName.text isEqualToString:[self.post[@"group"] uppercaseString]]) {
        self.group = nil;
        PFQuery *groupQuery = [PFQuery queryWithClassName:@"Group"];
        [groupQuery getObjectInBackgroundWithId:self.post[@"groupId"] block:^(PFObject *object, NSError *error) {
            self.group = object;
        }];
    }
    self.image = nil;
    self.browser = [[CXPhotoBrowser alloc] initWithDataSource:self delegate:self];
    if(!self.post[@"gallery"]) {
        self.animating = NO;
    } else {
        PFQuery *galleryQuery = [PFQuery queryWithClassName:@"Gallery"];
        [galleryQuery getObjectInBackgroundWithId:self.post[@"gallery"] block:^(PFObject *galleryObject, NSError *error) {
            if (!error) {
                NSArray *gallery = galleryObject[@"photoIds"];
                for (NSString *image in gallery) {
                    PFQuery *query = [PFQuery queryWithClassName:@"Image"];
                    [query getObjectInBackgroundWithId:image block:^(PFObject *object, NSError *error) {
                        if (!error) {
                            PFFile *imageData = (PFFile *) object[@"imageFile"];
                            [imageData getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                                if (!error) {
                                    UIImage *profileImage = [[UIImage alloc] initWithData:data];
                                    if(![self.photoDataSource count]) {
                                        self.image = profileImage;
                                        self.thumbnail.contentMode = UIViewContentModeScaleAspectFit;
                                        [self.thumbnail setImage:self.image];
                                        self.animating = NO;
                                        [self.indicator setHidden:YES];
                                        [self.openImage setEnabled:YES];
                                        [self.loadingAlert dismissWithClickedButtonIndex:-1 animated:YES];
                                    }
                                    [self.photoDataSource addObject:[[CXPhoto alloc]initWithImage:profileImage]];
                                } else {
                                    NSLog(@"%@", error);
                                }
                            }];
                        } else {
                            NSLog(@"%@", error);
                        }
                    }];
                }
            } else {
                NSLog(@"%@", error);
            }
        }];
    }
    self.postAuthor.text = [self.post[@"authorName"] uppercaseString];
    self.postAuthor.textColor = [UIColor lightGrayColor];
    [self.postTitle setTitle:self.post[@"title"] forState:UIControlStateNormal];
    [self.postTitle setTitle:self.post[@"title"] forState:UIControlStateHighlighted];
    self.indicator.tintColor = REFCOLOR;
    NSString *age;
    NSDate *updateTime = self.post.createdAt;
    double timeSincePost = -[updateTime timeIntervalSinceNow] ;
    if (timeSincePost < 60) {
        age = @"now";
    } else if (timeSincePost < 3599) {
        age = [NSString stringWithFormat:@"%d min", (int)(timeSincePost / 60)];
    } else if (timeSincePost < 86399) {
        age = [NSString stringWithFormat:@"%d hrs", (int)(timeSincePost / 3600)];
    } else if (timeSincePost < 604799) {
        age = [NSString stringWithFormat:@"%d d", (int)(timeSincePost / 86400)];
    } else if (timeSincePost < 2419199) {
        age = [NSString stringWithFormat:@"%d wk", (int)(timeSincePost / 604800)];
    } else {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
        [dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
        age = [NSString stringWithFormat:@"%@", [dateFormatter stringFromDate:updateTime]];
    }
    self.dateLabel.text = age;
    self.groupName.text = [self.post[@"group"] uppercaseString];
    self.thumbnail.contentMode = UIViewContentModeScaleAspectFit;
    self.thumbnail.contentMode = UIViewContentModeTop;
    self.text.editable = NO;
    if(self.animating) {
        [self.indicator startAnimating];
        [self.openImage setEnabled:NO];
    } else {
        [self.indicator setHidden:YES];
        [self.loadingAlert dismissWithClickedButtonIndex:-1 animated:YES];
    }
    if (!self.post[@"gallery"]) {
        self.thumbnail.image = nil;
        [self.thumbnail setFrame:CGRectMake(-1, 1, 0, 0)];
        [self.openImage setFrame:CGRectMake(-1, 1, 0, 0)];
        self.height.constant = -150;
        [self.text updateConstraints];
    } else {
        [self.thumbnail setFrame:CGRectMake(self.thumbnail.frame.origin.x, self.thumbnail.frame.origin.y, 320, self.thumbnail.frame.size.height)];
        [self.openImage setFrame:CGRectMake(self.thumbnail.frame.origin.x, self.thumbnail.frame.origin.x, 320,  self.thumbnail.frame.size.height)];
        self.height.constant = 10;
        [self.thumbnail setImage:self.image];
        [self.openImage setEnabled:YES];
        [self.loadingAlert dismissWithClickedButtonIndex:-1 animated:YES];
    }
    self.text.text = self.post[@"text"];
    if ([self.post[@"voters"]  containsObject:[PFUser currentUser].objectId]) {
        [self.star setImage:[UIImage imageNamed:@"blueStar.png"] forState:UIControlStateNormal];
    } else {
        [self.star setImage:[UIImage imageNamed:@"greyStar.png"] forState:UIControlStateNormal];
    }
}
- (NSUInteger)numberOfPhotosInPhotoBrowser:(CXPhotoBrowser *)photoBrowser
{
    return [self.photoDataSource count];
}
- (id <CXPhotoProtocol>)photoBrowser:(CXPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index
{
    if (index < self.photoDataSource.count) {
        return [self.photoDataSource objectAtIndex:index];
    }
    return nil;
}
#pragma mark - CXPhotoBrowserDelegate
- (BOOL)supportReload
{
    return YES;
}
#pragma mark - PhotBrower Actions
- (void)photoBrowserDidTapDoneButton:(UIButton *)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (IBAction)commentPost:(id)sender
{
    UITextField *text = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
    [PXAlertView showAlertWithTitle:@"Give feedback" message:@"Enter feedback for post" cancelTitle:@"Cancel" otherTitles:@[@"Done"] contentView:text completion:^(BOOL cancelled, NSInteger buttonIndex) {
        self.postComment = text.text;
        if (!cancelled) {
            [self commentOnPost];
        }
    }];
}
- (void)commentOnPost
{
    if (self.postComment.length < 1) {
        [PXAlertView showAlertWithTitle:@"Please enter in some feedback" message:@"" cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
        return;
    }
    UIAlertView *loadingAlert = [[UIAlertView alloc] initWithTitle:@"Loading" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    if (ALERT) {
        [loadingAlert show];
    }
    NSString *commentString = [NSString stringWithFormat:@"%@: %@", [PFUser currentUser][@"name"], self.postComment];
    [self.post addObject:commentString forKey:@"comments"];
    [self.post saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            [loadingAlert dismissWithClickedButtonIndex:-1 animated:YES];
            [PXAlertView showAlertWithTitle:@"Feedback saved" message:@"Succesfully saved suggestions" cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
            PFPush *push = [[PFPush alloc] init];
            [push setChannel:[@"u"stringByAppendingString:self.post[@"author"]]];
            [push setMessage:commentString];
            [push sendPushInBackground];
        } else {
            [loadingAlert dismissWithClickedButtonIndex:-1 animated:YES];
            [PXAlertView showAlertWithTitle:@"Unable to save feedback" message:@"Try again later" cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
        }
    }];
}
-(void)downloadData
{
    self.profileImageData = nil;
    self.profileImage.image = nil;
    self.imageData = [NSMutableData data];
    PFQuery *query = [PFUser query];
    query.cachePolicy = kPFCachePolicyNetworkElseCache;
    [query getObjectInBackgroundWithId:self.post[@"author"] block:^(PFObject *object, NSError *error) {
        if (!error) {
            self.author = (PFUser *) object;
            //Grab profile picture asynchronously
            if ([object objectForKey:@"profile"][@"pictureURL"]) {
                NSURL *pictureURL = [NSURL URLWithString:[object objectForKey:@"profile"][@"pictureURL"]];
                NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:pictureURL
                                                                          cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                                      timeoutInterval:2.0f];
                NSURLConnection *urlConnection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self];
                if (!urlConnection) {
                    NSLog(@"Failed to download picture");
                }
            }
        }
        else {
            NSLog(@"Couldn't get profile image");
        }
    }];
    
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.imageData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    self.profileImageData = [UIImage imageWithData:self.imageData];
    self.profileImageData = [self.profileImageData scaledToWidth:200];
    self.profileImageData = [self.profileImageData imageByCroppingImageToSize:200.0f];
    self.profileImage.contentMode = UIViewContentModeScaleAspectFit;
    self.profileImage.image = self.profileImageData;
    self.profileImage.layer.cornerRadius = 5;
    self.profileImage.layer.masksToBounds = YES;
    
}
- (IBAction)starPressed:(id)sender
{
    [self.star setImage:[UIImage imageNamed:@"blueStar.png"] forState:UIControlStateNormal];
    if(!([self.post[@"voters"]
          containsObject:[PFUser currentUser].objectId]))
    {
        [self.post incrementKey:@"votes"];
        [self.post addObject:[PFUser currentUser].objectId forKey:@"voters"];
        [self.post saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (!error) {
                NSString *userId = self.post[@"author"];
                NSString *groupId = self.post[@"groupId"];
                NSDictionary *params = @{@"userId" : userId, @"groupId" : groupId};
                NSDictionary *param = @{@"userId" : userId};
                [PFCloud callFunctionInBackground:@"fixUser" withParameters:param block:nil];
                [PFCloud callFunctionInBackground:@"updateUser" withParameters:params block:nil];
            } else {
                [PXAlertView showAlertWithTitle:@"Could not star post" message:@"Try again later" cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
                [self.star setImage:[UIImage imageNamed:@"greyStar.png"] forState:UIControlStateNormal];
                
            }
        }];
    } else{
        [PXAlertView showAlertWithTitle:@"Post already starred" message:@"Unstar post?" cancelTitle:@"Cancel" otherTitle:@"Yes" completion:^(BOOL cancelled, NSInteger buttonIndex) {
            if (!cancelled) {
                [self.star setImage:[UIImage imageNamed:@"greyStar.png"] forState:UIControlStateNormal];
                [self.post incrementKey:@"votes" byAmount:@-1];
                [self.post removeObject:[PFUser currentUser].objectId forKey:@"voters"];
                [self.post saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if (!error) {
                        NSString *userId = self.post[@"author"];
                        NSString *groupId = self.post[@"groupId"];
                        NSDictionary *params = @{@"userId" : userId, @"groupId" : groupId};
                        NSDictionary *param = @{@"userId" : userId};
                        [PFCloud callFunctionInBackground:@"fixUser" withParameters:param block:nil];                            [PFCloud callFunctionInBackground:@"updateUser" withParameters:params block:nil];
                    } else {
                        [PXAlertView showAlertWithTitle:@"Could not unstar post" message:@"Try again later" cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
                        [self.star setImage:[UIImage imageNamed:@"blueStar.png"] forState:UIControlStateNormal];
                    }
                }];
            }
        }];

    }
}
- (IBAction)userPressed:(id)sender
{
    if (self.author) {
        ProfileViewController *pvc = [[ProfileViewController alloc] initWithNibName:nil bundle:nil userId:self.author.objectId];
        [pvc setUser:self.author];
        [self.navigationController pushViewController:pvc animated:YES];
    } else {
        PFQuery *query = [PFUser query];
        query.cachePolicy = kPFCachePolicyNetworkElseCache;
        [query getObjectInBackgroundWithId:self.post[@"author"] block:^(PFObject *object, NSError *error) {
            if (!error) {
                self.author = (PFUser *) object;
                ProfileViewController *pvc = [[ProfileViewController alloc] initWithNibName:nil bundle:nil userId:self.author.objectId];
                [pvc setUser:self.author];
                [self.navigationController pushViewController:pvc animated:YES];
            }
        }];
    }
}
- (IBAction)groupPressed:(id)sender
{
    if (self.group) {
        NewsFeedViewController *nvc = [[NewsFeedViewController alloc] initWithStyle:UITableViewStylePlain source:self.group title:self.groupName.text];
        [self.navigationController pushViewController:nvc animated:YES];
    } else {
        PFQuery *query = [PFQuery queryWithClassName:@"Group"];
        query.cachePolicy = kPFCachePolicyNetworkElseCache;
        [query getObjectInBackgroundWithId:self.post[@"groupId"] block:^(PFObject *object, NSError *error) {
            if (!error) {
                self.group = object;
                NewsFeedViewController *nvc = [[NewsFeedViewController alloc] initWithStyle:UITableViewStylePlain source:self.group title:self.groupName.text];
                [self.navigationController pushViewController:nvc animated:YES];
            }
        }];
    }
}
- (IBAction)acceptPost:(id)sender
{
    UIAlertView *loadingAlert = [[UIAlertView alloc] initWithTitle:@"Loading" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    if (ALERT) {
        [loadingAlert show];
    }
        NSDictionary *params = @{@"postId" : self.post.objectId, @"postTitle" : self.post[@"title"]};
        [PFCloud callFunctionInBackground:@"approvePost" withParameters:params block:^(id object, NSError *error) {
            if (!error) {
                [[PFUser currentUser] refreshInBackgroundWithBlock:nil];
                [loadingAlert dismissWithClickedButtonIndex:-1 animated:YES];
                [PXAlertView showAlertWithTitle:@"Success" message:@"Approved post" cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {
                    [self.navigationController popViewControllerAnimated:YES];
                }];
            } else {
                [loadingAlert dismissWithClickedButtonIndex:-1 animated:YES];
                [PXAlertView showAlertWithTitle:@"Error" message:@"Unable to save changes. Try again later" cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
            }
        }];
}

- (void)viewWillLayoutSubviews
{
    //Measure the size of the text
    NSStringDrawingContext *ctx = [NSStringDrawingContext new];
    CGRect textRect = [self.text.text boundingRectWithSize:self.view.frame.size options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:self.text.font} context:ctx];

    //Depends on whether a picture is there or not
    self.textHeight.constant = textRect.size.height + 30;
    if (self.hasGallery)
    {
        self.boxHeight.constant = textRect.size.height + 230;
        if (self.textHeight.constant > 190) {
            self.textHeight.constant = 190;
        }
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        CGFloat screenWidth = screenRect.size.width;
        CGFloat screenHeight = screenRect.size.height;
        if (screenHeight + screenWidth < 810 && self.textHeight.constant > 120) {
            self.textHeight.constant = 120;
        }
    } else {
        self.boxHeight.constant = textRect.size.height + 90;
    }

}
@end

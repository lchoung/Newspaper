// Copyright 2004-present Facebook. All Rights Reserved.

#import "NewsFeedViewController.h"
#import <Parse/Parse.h>
#import "NewsArticleController.h"
#import "FBUGroupSettingsViewController.h"
#import "FBUNewsFeedTableViewCell.h"
#import "FBUNewsNoImageTableViewCell.h"
#import "FBUPostViewController.h"
#import "FBUEditViewController.h"
#import "FBUBackgroundLayer.h"
#import "DesignConstants.h"
#import "UIImage+ImageEffects.h"
#import "PXAlertView+Customization.h"

@interface NewsFeedViewController ()
@property (nonatomic, copy) NSArray *titles;
@property (nonatomic, copy) NSArray *ids;
@property(nonatomic, strong)NSString *titleString;
@property (strong, nonatomic) NSMutableDictionary *preLoadData;
@property (nonatomic) PFObject *group;
@property (strong, nonatomic) NSMutableDictionary *descriptionData;

@property (strong, nonatomic) NSMutableDictionary *authorImageData;
@property (strong, nonatomic) NSMutableDictionary *authorData; //Names of authors, key by post
@property (strong, nonatomic) NSMutableDictionary *authorId; //Ids of authors, key by post
@property (strong, nonatomic) NSMutableDictionary *admin; //Admin status of authors (key by post)
@property (strong, nonatomic) NSMutableDictionary *adminGroups;

@property (strong, nonatomic) NSMutableDictionary *votes;

@property (strong, nonatomic) NSMutableDictionary *groupColors;
@property (strong, nonatomic) NSMutableDictionary *groupData;
@property (strong, nonatomic) NSMutableDictionary *groupId;

@property (strong, nonatomic) NSMutableDictionary *voters;
@property (strong, nonatomic) NSMutableDictionary *voterImages;


@property (strong, nonatomic) NSMutableDictionary *imageData;
@property (strong, nonatomic) NSMutableDictionary *urlData;
@property (strong, nonatomic) NSString *currentAuthor;
@property (strong, nonatomic) NSMutableArray *hasImages;
@property (strong, nonatomic) NSMutableDictionary *postsWithAuthor;
@property (strong, nonatomic) NSMutableDictionary *timeData;
@property (nonatomic) int loadedCount;
@end

@implementation NewsFeedViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.index = 0;
        [[UINavigationBar appearance] setTitleTextAttributes:TITLEATTRIBUTES];
        [self.tableView setBackgroundColor: BACKGROUNDCOLOR];
        if ([[PFInstallation currentInstallation][@"channels"] containsObject:[@"u"stringByAppendingString:[PFUser currentUser].objectId]]) {
            PFInstallation *currentInstallation = [PFInstallation currentInstallation];
            [[PFUser currentUser] addUniqueObject:[@"u"stringByAppendingString:[PFUser currentUser].objectId] forKey:@"channels"];
            currentInstallation[@"channels"] = [PFUser currentUser][@"channels"];
            [currentInstallation saveEventually];
            [[PFUser currentUser] saveEventually];
        }
        _timeData = [NSMutableDictionary dictionary];
        _postsWithAuthor = [NSMutableDictionary dictionary];
        _urlData = [NSMutableDictionary dictionary];
        _titles = [PFUser currentUser][@"newsfeed"];
        _ids = [PFUser currentUser][@"postIds"];
        [self refresh:nil];
        _descriptionData = [NSMutableDictionary dictionary];
        _authorData = [NSMutableDictionary dictionary];
        _authorImageData = [NSMutableDictionary dictionary];
        _titleString = @"News";
        _preLoadData = [NSMutableDictionary dictionary];
        _imageData = [NSMutableDictionary dictionary];
        _hasImages = [self fillWithNos:[[NSMutableArray alloc]init]];
        _groupData = [NSMutableDictionary dictionary];
        _groupId = [NSMutableDictionary dictionary];
        _groupColors = [NSMutableDictionary dictionary];
        _authorId = [NSMutableDictionary dictionary];
        _adminGroups = [NSMutableDictionary dictionary];
        _admin = [NSMutableDictionary dictionary];
        _votes = [NSMutableDictionary dictionary];
        _voters = [NSMutableDictionary dictionary];
        _voterImages = [NSMutableDictionary dictionary];
        
        UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(makePost:)];
        self.navigationItem.rightBarButtonItem = addButton;
        self.loadedCount = 0;
    }
    return self;
}
- (id)initWithStyle:(UITableViewStyle)style source:(PFObject *)group title:(NSString *)title
{
    self = [super initWithStyle:style];
    if (self) {
        CAGradientLayer *bgLayer = [FBUBackgroundLayer blueGradient];
        bgLayer.frame = self.view.bounds;
        [self.view.layer insertSublayer:bgLayer atIndex:0];
        self.index = 0;
        _urlData = [NSMutableDictionary dictionary];
        _timeData = [NSMutableDictionary dictionary];
        _postsWithAuthor = [NSMutableDictionary dictionary];
        _titles = group[@"newsfeed"];
        _ids = group[@"postIds"];
        _descriptionData = [NSMutableDictionary dictionary];
        _authorData = [NSMutableDictionary dictionary];
        _authorImageData = [NSMutableDictionary dictionary];
        _titleString = title;
        _group = group;
        [self refresh:nil];
        _preLoadData = [NSMutableDictionary dictionary];
        _imageData = [NSMutableDictionary dictionary];
        _hasImages = [self fillWithNos:[[NSMutableArray alloc]init]];
        _groupData = [NSMutableDictionary dictionary];
        _groupColors = [NSMutableDictionary dictionary];
        _authorId = [NSMutableDictionary dictionary];
        _votes = [NSMutableDictionary dictionary];
        _voters = [NSMutableDictionary dictionary];
        _voterImages = [NSMutableDictionary dictionary];
        _adminGroups = [NSMutableDictionary dictionary];
        _admin = [NSMutableDictionary dictionary];
    }
    self.loadedCount = 0;
    UIBarButtonItem *more = [[UIBarButtonItem alloc] initWithTitle:@"..." style:UIBarButtonItemStylePlain target:self action:@selector(showOptions:)];
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(makePost:)];
    self.navigationItem.rightBarButtonItems = [[NSArray alloc] initWithObjects:more, addButton, nil];
    return self;
}

- (NSMutableArray *)fillWithNos:(NSMutableArray *)array
{
    for (int i = 0; i < [self.ids count]; i++)
    {
        [array addObject:[NSNumber numberWithBool:NO]];
    }
    return array;
}

// Refresh Data Function
-(void)refresh:(UIRefreshControl *)ref
{
    if (!self.group) {
        [[PFUser currentUser] refreshInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            if (!error) {
                BOOL needsUpdate = ([_titles count] != [[PFUser currentUser][@"newsfeed"] count]);
                _titles = [PFUser currentUser][@"newsfeed"];
                _ids = [PFUser currentUser][@"postIds"];
                if ([_titles count] != [_ids count]) {
                    [PFUser currentUser][@"newsfeed"] = [NSMutableArray array];
                    [PFUser currentUser][@"postIds"] = [NSMutableArray array];
                    [[PFUser currentUser] saveInBackground];
                    [PXAlertView showAlertWithTitle:@"Error" message:@"Loading posts failed." cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
                    NSDictionary *params = @{@"userId" : [PFUser currentUser].objectId};
                    [PFCloud callFunctionInBackground:@"fixUser" withParameters:params block:nil];
                    return;
                }
                if (needsUpdate && ref) {
                    self.postsWithAuthor = [NSMutableDictionary dictionary];
                    self.authorImageData = [NSMutableDictionary dictionary];
                }
                _loadedCount = [_ids count];
                [self getPostData];
                [self.tableView reloadData];
                [ref endRefreshing];
            } else if (error.code == 101){
                [PXAlertView showAlertWithTitle:@"Error" message:@"Try logging out and on again." cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
                return;
            }
            
        }];
    } else {
        [self.group refreshInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            BOOL needsUpdate = ([_titles count] != [self.group[@"newsfeed"] count]);
            _titles = self.group[@"newsfeed"];
            _ids = self.group[@"postIds"];
            if ([_titles count] != [_ids count]) {
                self.group[@"newsfeed"] = [NSMutableArray array];
                self.group[@"postIds"] = [NSMutableArray array];
                [self.group saveInBackground];
                [PXAlertView showAlertWithTitle:@"Error" message:@"Loading posts failed." cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
                NSDictionary *params = @{@"groupId" : self.group.objectId};
                [PFCloud callFunctionInBackground:@"fixGroup" withParameters:params block:nil];
                return;
            }
            if (needsUpdate && ref) {
                self.postsWithAuthor = [NSMutableDictionary dictionary];
                self.authorImageData = [NSMutableDictionary dictionary];
            }
            _loadedCount = [_ids count];
            [self getPostData];
            [self.tableView reloadData];
            [ref endRefreshing];
        }];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView setSeparatorColor:SEPARATORCOLOR];
    self.tableView.backgroundColor = BACKGROUNDCOLOR;
    self.tableView.allowsSelection = NO;
    UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
    [refresh addTarget:self
                action:@selector(refresh:)
      forControlEvents:UIControlEventValueChanged];
    refresh.tintColor = REFCOLOR;
    self.refreshControl = refresh;
}
-(void)viewWillAppear:(BOOL)animated
{
    [self.navigationController.navigationBar setTitleTextAttributes:TITLEATTRIBUTES];
    [super viewDidAppear:animated];
    [self getPostData];
    [self refresh:[UIRefreshControl alloc]];
    self.title = _titleString;
}
- (PFObject *)postForIndex:(NSInteger)index
{
    NSString *objectId = self.ids[index];
    if (!self.preLoadData[objectId]) {
        [self refresh:nil];
        PFQuery *query = [PFQuery queryWithClassName:@"Post"];
        query.cachePolicy = kPFCachePolicyNetworkElseCache;
        self.preLoadData[objectId] = [query getObjectWithId:objectId];
    }
    return self.preLoadData[objectId];
}

- (void)makePost:(id)sender
{
    FBUPostViewController *textEditor;
    if (!self.group) {
        textEditor= [[FBUPostViewController alloc] init];
    } else {
        textEditor = [[FBUPostViewController alloc] initWithNibName:nil bundle:nil groupId:self.group.objectId];
    }
    textEditor.hidesBottomBarWhenPushed = YES;
    UINavigationController *navController = [[UINavigationController alloc]initWithRootViewController:textEditor];
    [self presentViewController:navController animated:YES completion:nil];
}

-(void)showOptions:(id)sender
{
    FBUGroupSettingsViewController *groupSettings = [[FBUGroupSettingsViewController alloc] initWithEdit:YES group:self.group];
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:groupSettings];
    
    [self presentViewController:navigation animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([_titles count] != [_ids count]) {
        return 0;
    }
    if([_titles count] == 0) //No posts, show placeholder
    {
        return 1;
    }
    if ([_ids count] < _loadedCount) {
        return [_ids count];
    }
    return _loadedCount;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    if([_titles count] == 0 || [_ids count] == 0) //No posts
    {
        return 100;
    }
    
    if (self.imageData[self.ids[indexPath.row]])
    {
        return 500;
    }
    return 260;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([_titles count] == 0 || [_ids count] == 0)
    {
        UITableViewCell *placeHolder = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Placeholder"];
        placeHolder.textLabel.text = @"No articles yet!";
        placeHolder.textLabel.font = [UIFont fontWithName:@"AppleSDGothicNeo-Light" size:22.0];
        placeHolder.textLabel.textColor = DARKBLUE;
        placeHolder.textLabel.textAlignment = NSTextAlignmentCenter;
        placeHolder.backgroundColor = GREY;
        return placeHolder;
    }
    if (indexPath.row >= [_ids count]) {
        FBUNewsNoImageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NoImageNewsFeedCell"];
        if (!cell) {
            [tableView registerNib:[UINib nibWithNibName:@"FBUNewsNoImageTableViewCell" bundle:nil] forCellReuseIdentifier:@"NoImageNewsFeedCell"];
            cell = [tableView dequeueReusableCellWithIdentifier:@"NoImageNewsFeedCell"];
        }
        
        cell.contView.layer.cornerRadius = 5;
        cell.contView.layer.masksToBounds = YES;
        return cell;
        [self.tableView reloadData];
    }
    if (self.imageData[self.ids[indexPath.row]]) { //Has pictures
        FBUNewsFeedTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NewsFeedCell"];
        if (!cell) {
            [tableView registerNib:[UINib nibWithNibName:@"NewsFeedViewControllerCell" bundle:nil] forCellReuseIdentifier:@"NewsFeedCell"];
            cell = [tableView dequeueReusableCellWithIdentifier:@"NewsFeedCell"];
        }
        cell.contView.layer.cornerRadius = 5;
        cell.contView.layer.masksToBounds = YES;
        
        //Votes count
        NSNumber *votes = self.votes[self.ids[indexPath.row]];
        cell.voteLabel.text = [NSString stringWithFormat:@"%d", votes.intValue];
        
        cell.postAuthor.text = [self.authorData[self.ids[indexPath.row]] uppercaseString];
        [cell.postTitle setTitle:self.titles[indexPath.row] forState:UIControlStateNormal];
        long len = cell.postTitle.titleLabel.text.length;
        if (len < 17) {
            cell.postTitle.titleLabel.font = NEWSTITLEFONT1;
        } else if (len < 19){
            cell.postTitle.titleLabel.font = NEWSTITLEFONT2;
        } else if (len < 21) {
            cell.postTitle.titleLabel.font = NEWSTITLEFONT3;
        } else {
            cell.postTitle.titleLabel.font = NEWSTITLEFONT4;
        }
        //Star post
        
        cell.star.imageView.image = self.voterImages[self.ids[indexPath.row]];
        
        [cell.star addTarget:self action:@selector(starPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        //Click to go to post
        [cell.postClicked addTarget: self action: @selector(userPressed:) forControlEvents: UIControlEventTouchUpInside];
        [cell.click addTarget: self action: @selector(userPressed:) forControlEvents: UIControlEventTouchUpInside];
        
        cell.postText.text = self.descriptionData[self.ids[indexPath.row]];
        cell.postText.textAlignment = NSTextAlignmentLeft;
        cell.postText.editable = NO;
        
        cell.postImage.contentMode = UIViewContentModeScaleAspectFill;
        cell.postImage.image = self.imageData[self.ids[indexPath.row]];
        
        cell.groupIndicator.backgroundColor = self.groupColors[self.groupData[self.ids[indexPath.row]]];
        cell.groupName.text = [self.groupData[self.ids[indexPath.row]] uppercaseString];
        
        cell.profileImage.contentMode = UIViewContentModeScaleAspectFit;
        cell.profileImage.image = ((UIImageView *)self.authorImageData[self.ids[indexPath.row]]).image;
        cell.profileImage.layer.cornerRadius = 5;
        cell.profileImage.layer.masksToBounds = YES;
        
        
        //See if author is an admin of the group
        if ([_adminGroups[_authorId[self.ids[indexPath.row]]] containsObject:_groupId[self.ids[indexPath.row]]])
        {
            _admin[self.ids[indexPath.row]] = [NSNumber numberWithBool:YES];
        } else {
            _admin[self.ids[indexPath.row]] = [NSNumber numberWithBool:NO];
        }
        
        //Is user an admin? If so, put admin tag next to name.
        if (_admin[self.ids[indexPath.row]] == [NSNumber numberWithBool:YES])
        {
            cell.userTag.image = [UIImage imageNamed:@"adminTag.png"];
        }
        
        cell.dateLabel.text = self.timeData[self.ids[indexPath.row]];
        return cell;
        
        cell.dateLabel.text = self.timeData[self.ids[indexPath.row]];
        return cell;
    } else { //No pictures
        FBUNewsNoImageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NoImageNewsFeedCell"];
        if (!cell) {
            [tableView registerNib:[UINib nibWithNibName:@"FBUNewsNoImageTableViewCell" bundle:nil] forCellReuseIdentifier:@"NoImageNewsFeedCell"];
            cell = [tableView dequeueReusableCellWithIdentifier:@"NoImageNewsFeedCell"];
        }
        
        cell.contView.layer.cornerRadius = 5;
        cell.contView.layer.masksToBounds = YES;
        
        //Votes count
        NSNumber *votes = self.votes[self.ids[indexPath.row]];
        cell.voteLabel.text = [NSString stringWithFormat:@"%d", votes.intValue];
        
        //Star button
        cell.starButton.imageView.image =self.voterImages[self.ids[indexPath.row]];
        
        [cell.starButton addTarget:self action:@selector(starPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        cell.postAuthor.text = [self.authorData[self.ids[indexPath.row]] uppercaseString];
        [cell.postTitle setTitle:self.titles[indexPath.row] forState:UIControlStateNormal];
        long len = cell.postTitle.titleLabel.text.length;
        if (len < 17) {
            cell.postTitle.titleLabel.font = NEWSTITLEFONT1;
        } else if (len < 19){
            cell.postTitle.titleLabel.font = NEWSTITLEFONT2;
        } else if (len < 21) {
            cell.postTitle.titleLabel.font = NEWSTITLEFONT3;
        } else {
            cell.postTitle.titleLabel.font = NEWSTITLEFONT4;
        }
        [cell.postClicked addTarget: self action: @selector(userPressed:) forControlEvents: UIControlEventTouchUpInside];
        [cell.click addTarget: self action: @selector(userPressed:) forControlEvents: UIControlEventTouchUpInside];
        
        cell.postText.text = (NSString *)self.descriptionData[self.ids[indexPath.row]];
        cell.postText.text = self.descriptionData[self.ids[indexPath.row]];
        cell.postText.editable = NO;
        cell.postText.textAlignment = NSTextAlignmentLeft;
        
        cell.profileImage.contentMode = UIViewContentModeScaleAspectFit;
        cell.profileImage.image = ((UIImageView *)self.authorImageData[self.ids[indexPath.row]]).image;
        cell.profileImage.layer.cornerRadius = 10;
        cell.profileImage.layer.masksToBounds = YES;
        
        cell.groupIndicator.backgroundColor = self.groupColors[self.groupData[self.ids[indexPath.row]]];
        cell.groupName.text = [self.groupData[self.ids[indexPath.row]] uppercaseString];
        
        
        //See if author is an admin of the group
        if ([_adminGroups[_authorId[self.ids[indexPath.row]]] containsObject:_groupId[self.ids[indexPath.row]]])
        {
            _admin[self.ids[indexPath.row]] = [NSNumber numberWithBool:YES];
        } else {
            _admin[self.ids[indexPath.row]] = [NSNumber numberWithBool:NO];
        }
        
        //Is user an admin? If so, put admin tag next to name.
        NSLog(@"admin status: %@", _admin[self.ids[indexPath.row]]);
        if (_admin[self.ids[indexPath.row]] == [NSNumber numberWithBool:YES])
        {
            cell.userTag.image = [UIImage imageNamed:@"adminTag.png"];
        }
        
        cell.dateLabel.text = self.timeData[self.ids[indexPath.row]];
        return cell;
    }
}

- (void)getPostData
{
    __block int countUp = 0;
    for (int i = 0; i < [self.ids count]; i++ )
    {
        //While we still have posts to display
        if([self.ids count] && i < [self.ids count]) {
            PFQuery *query = [PFQuery queryWithClassName:@"Post"];
            query.cachePolicy = kPFCachePolicyNetworkElseCache;
            [query getObjectInBackgroundWithId:self.ids[i] block:^(PFObject *postObject, NSError *error) {
                if (!error) {
                    if (postObject[@"authorName"]) {
                        self.authorData[self.ids[i]] = postObject[@"authorName"];
                        self.authorId[self.ids[i]] = postObject[@"author"];
                    }
                    
                    if (postObject[@"voters"]) {
                        self.voters[self.ids[i]] = postObject[@"voters"];
                        if (![self.voters[self.ids[i]] containsObject:[PFUser currentUser].objectId]) {
                            self.voterImages[self.ids[i]] = [UIImage imageNamed:@"greyStar.png"];
                        } else {
                            self.voterImages[self.ids[i]] = [UIImage imageNamed:@"blueStar.png"];
                        }
                    }
                    
                    if(postObject[@"description"]) {
                        self.descriptionData[self.ids[i]] = postObject[@"description"];
                    } else {
                        if ([postObject[@"text"] length] >= 80) {
                            self.descriptionData[self.ids[i]] = [[(NSString *) postObject[@"text"] substringToIndex:80] stringByAppendingString:@"..."];
                        } else {
                            self.descriptionData[self.ids[i]] = postObject[@"text"];
                        }
                    }
                    
                    if (postObject[@"votes"])
                    {
                        self.votes[self.ids[i]] = postObject[@"votes"];
                    }
                    
                    if (postObject.createdAt) {
                        NSString *age;
                        NSDate *updateTime = postObject.createdAt;
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
                        self.timeData[self.ids[i]] = age;
                    }
                    
                    if (postObject[@"groupId"]){
                        self.groupId[self.ids[i]] = postObject[@"groupId"];
                    }
                    
                    //Keep track of group as well, and group color
                    if (postObject[@"group"]){
                        self.groupData[self.ids[i]] = postObject[@"group"];
                        //NSLog(@"%@", postObject[@"group"]);
                        if (!self.groupColors[postObject[@"group"]])
                        {
                            CGFloat hue = ( arc4random() % 256 / 256.0 ); // 0.0 to 1.0
                            CGFloat saturation = ( arc4random() % 128 / 256.0 ); // 0.5 to 1.0, away from white
                            CGFloat brightness = ( arc4random() % 128 / 256.0 ) + 0.5; // 0.5 to 1.0, away from black
                            UIColor *color = [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
                            self.groupColors[postObject[@"group"]] = color;
                        }
                    }
                    
                    
                    if (postObject[@"author"]){
                        NSString *authorId = postObject[@"author"];
                        NSString *postId = self.ids[i];
                        
                        if (!self.postsWithAuthor[authorId] || ![self.postsWithAuthor[authorId] count]) {
                            self.postsWithAuthor[authorId] = [NSMutableArray array];
                            [self.postsWithAuthor[authorId] addObject:postId];
                            PFQuery *secondQuery = [PFUser query];
                            secondQuery.cachePolicy = kPFCachePolicyNetworkElseCache;
                            [secondQuery getObjectInBackgroundWithId:authorId block:^(PFObject *object, NSError *error) {
                                if (!error) {
                                    //Get the adminGroups of the author
                                    if ([object[@"adminGroups"] count]) {
                                        _adminGroups[authorId] = object[@"adminGroups"];
                                    } else {
                                        _adminGroups[authorId] = [NSMutableDictionary dictionary];
                                    }
                                    [self.tableView reloadData];
                                    
                                    //Grab profile picture asynchronously
                                    if ([object objectForKey:@"profile"][@"pictureURL"]) {
                                        NSURL *pictureURL = [NSURL URLWithString:[object objectForKey:@"profile"][@"pictureURL"]];
                                        NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:pictureURL
                                                                                                  cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                                                              timeoutInterval:2.0f];
                                        self.urlData[authorId] = urlRequest;
                                        // Run network request asynchronously
                                        if ([self.urlData count] == 1) {
                                            [self downloadData];
                                        }
                                    }
                                }
                                else {
                                    NSLog(@"Couldn't get profile image");
                                }
                                
                            }];
                            
                        } else {
                            NSMutableArray *posts = self.postsWithAuthor[postObject[@"author"]];
                            if (![posts containsObject:postId]) {
                                [posts addObject:postId];
                            }
                            if (((UIImageView *)self.authorImageData[posts[0]]).image) {
                                [((UIImageView *)self.authorImageData[postId]) setImage:((UIImageView *)self.authorImageData[posts[0]]).image];
                            }
                            
                        }
                    }
                    
                    
                    //If has gallery set hasImages and imageData for that index
                    if (postObject[@"gallery"]) {
                        //NSLog(@"hasImages in loading: %@", _hasImages);
                        _hasImages[i] = [NSNumber numberWithBool:YES];
                        //Query for gallery
                        PFQuery *galleryQuery = [PFQuery queryWithClassName:@"Gallery"];
                        galleryQuery.cachePolicy = kPFCachePolicyCacheElseNetwork;
                        [galleryQuery getObjectInBackgroundWithId:postObject[@"gallery"] block:^(PFObject *galleryObject, NSError *galleryError) {
                            if(!galleryError) {
                                PFQuery *imageQuery = [PFQuery queryWithClassName:@"Image"];
                                imageQuery.cachePolicy = kPFCachePolicyCacheElseNetwork;
                                [imageQuery getObjectInBackgroundWithId:galleryObject[@"photoIds"][0] block:^(PFObject *imageObject, NSError *imageError) {
                                    if (!imageError) {
                                        PFFile * parseImage = (PFFile *) imageObject[@"imageFile"];
                                        [parseImage getDataInBackgroundWithBlock:^(NSData *parseImageData, NSError *imageDataError) {
                                            if (!imageDataError) {
                                                self.imageData[self.ids[i]] = [[UIImage imageWithData:parseImageData] scaledToWidth:320];
                                                countUp += 1;
                                                //On the last load
                                                if (countUp == [self.ids count])
                                                {
                                                    self.loadedCount = countUp;
                                                    [self.tableView reloadData];
                                                }
                                                
                                            } else {
                                            }
                                            
                                        }];
                                    } else {
                                    }
                                    
                                }];
                                
                            } else {
                            }
                        }];
                        
                    } else { //Doesn't have images
                        _hasImages[i]= [NSNumber numberWithBool:NO];
                        countUp += 1;
                        
                        if (countUp == [self.ids count])
                        {
                            self.loadedCount = countUp;
                            [self.tableView reloadData];
                        }
                    }
                    
                    
                    
                } else {
                    NSLog(@"ERROR");
                }
                
            }]; //End Query
            
        } else {
            PFObject *post = self.preLoadData[self.ids[i]];
            [post refreshInBackgroundWithBlock:^(PFObject *postObject, NSError *error) {
                if (postObject[@"votes"])
                {
                    self.votes[self.ids[i]] = postObject[@"votes"];
                }
                
                if (postObject.createdAt) {
                    NSString *age;
                    NSDate *updateTime = postObject.createdAt;
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
                    self.timeData[self.ids[i]] = age;
                }
            }];
        }
    }
    
    //NSLog(@"Successfully got post data");
    
}


-(void)downloadData
{
    if ([self.urlData count] < 1) {
        return;
    } else {
        self.currentAuthor = [[self.urlData allKeys] objectAtIndex:0];
        self.authorImageData[self.currentAuthor] = [[NSMutableData alloc] init];
        NSURLConnection *urlConnection = [[NSURLConnection alloc] initWithRequest:self.urlData[self.currentAuthor] delegate:self];
        if (!urlConnection) {
            NSLog(@"Failed to download picture");
        }
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.authorImageData[self.currentAuthor] appendData:data];
    
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSArray *postNames = self.postsWithAuthor[self.currentAuthor];
    unsigned long numberOfPosts = [postNames count];
    for (NSString *postId in postNames) {
        UIImage *image = [UIImage imageWithData:(self.authorImageData[self.currentAuthor])];
        image = [image scaledToWidth:200];
        image = [image imageByCroppingImageToSize:200.0f];
        //image = [image imageByRoundMaskToSize:200];
        self.authorImageData[postId] = [[UIImageView alloc]init];
        
        ((UIImageView*) self.authorImageData[postId]).image = image;
        numberOfPosts -= 1;
        if (numberOfPosts == 0)
        {
            [self.tableView reloadData];
            NSLog(@"reloaded data");
        }
    }
    [self.urlData removeObjectForKey:self.currentAuthor];
    [self.tableView reloadData];
    [self downloadData];
}



- (IBAction)userPressed:(id)sender {
    self.max = [self.ids count] - 1;
    UIAlertView *loadingAlert;
    
    //Get button position
    CGPoint buttonPosition = [sender convertPoint:CGPointZero
                                           toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    if (indexPath)
    {
        loadingAlert = [[UIAlertView alloc] initWithTitle:@"Loading" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
        if (ALERT) {
            [loadingAlert show];
        }
    } else {
        return;
    }
    
    //Load post into postViewController and display
    NSString *objectId = self.ids[indexPath.row];
    if (self.preLoadData[objectId]) {
        //Already have the post loaded before in this session
        [loadingAlert dismissWithClickedButtonIndex:-1 animated:NO];
        
        NewsArticleController *postViewController;
        if ([self.hasImages[indexPath.row] boolValue])
        {
            NSLog(@"this has images");
            postViewController = [[NewsArticleController alloc] initWithGallery:YES post:self.preLoadData[objectId]];
        } else {
            postViewController = [[NewsArticleController alloc] initWithGallery:NO post:self.preLoadData[objectId]];
        }
        postViewController.owner = self;
        [self.navigationController pushViewController:postViewController animated:YES];
        
    } else {
        //Query for the post
        PFQuery *query = [PFQuery queryWithClassName:@"Post"];
        query.cachePolicy = kPFCachePolicyCacheElseNetwork;
        [query getObjectInBackgroundWithId:objectId block:^(PFObject *postObject, NSError *error) {
            if (!error) {
                if (loadingAlert) {
                    [loadingAlert dismissWithClickedButtonIndex:-1 animated:NO];
                }
                self.preLoadData[objectId] = postObject;
                
                NewsArticleController *postViewController;
                if ([self.hasImages[indexPath.row] boolValue])
                {
                    postViewController = [[NewsArticleController alloc] initWithGallery:YES post:self.preLoadData[objectId]];
                    postViewController.owner = self;
                    [self.navigationController pushViewController:postViewController animated:YES];
                } else {
                    postViewController = [[NewsArticleController alloc] initWithGallery:NO post:self.preLoadData[objectId]];
                    postViewController.owner = self;
                    [self.navigationController pushViewController:postViewController animated:YES];
                }
                
            } else {
                if (loadingAlert) {
                    [loadingAlert dismissWithClickedButtonIndex:-1 animated:YES];
                }
                [PXAlertView showAlertWithTitle:@"Could not load post" message:@"Try again later" cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
            }
        }];
    }
    
}

- (IBAction)starPressed:(id)sender
{
    CGPoint buttonPosition = [sender convertPoint:CGPointZero
                                           toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    
    //Change color of star
    NSString *objectId = self.ids[indexPath.row];
    self.voterImages[objectId] = [UIImage imageNamed:@"blueStar.png"];
    
    //Increment the number of stars this object has
    if (self.preLoadData[objectId]) {
        PFObject *post = self.preLoadData[objectId];
        if(!([post[@"voters"] containsObject:([PFUser currentUser].objectId)]))
        {
            //Add voter to posts array of voters
            [post incrementKey:@"votes"];
            [post addObject:[PFUser currentUser].objectId forKey:@"voters"];
            self.preLoadData[objectId] = post;
            [post saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (!error) {
                    self.votes[objectId] = post[@"votes"];
                    self.voters[objectId] = post[@"voters"];
                    [self.tableView reloadData];
                    NSString *userId = post[@"author"];
                    NSString *groupId = post[@"groupId"];
                    NSDictionary *params = @{@"userId" : userId, @"groupId" : groupId};
                    NSDictionary *param = @{@"userId" : userId};
                    [PFCloud callFunctionInBackground:@"fixUser" withParameters:param block:nil];
                    [PFCloud callFunctionInBackground:@"updateUser" withParameters:params block:nil];
                    [post refreshInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                        self.votes[objectId] = object[@"votes"];
                        self.voters[objectId] = object[@"voters"];
                        [self.tableView reloadData];
                    }];
                } else {
                    [PXAlertView showAlertWithTitle:@"Could not star post" message:@"Try again later" cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
                    self.voterImages[objectId] = [UIImage imageNamed:@"greyStar.png"];
                }
            }];
            
        } else{
            [PXAlertView showAlertWithTitle:@"Post already starred" message:@"Unstar post?" cancelTitle:@"Cancel" otherTitle:@"Yes" completion:^(BOOL cancelled, NSInteger buttonIndex) {
                if (!cancelled) {
                    self.voterImages[objectId] = [UIImage imageNamed:@"greyStar.png"];
                    [post incrementKey:@"votes" byAmount:@-1];
                    [post removeObject:[PFUser currentUser].objectId forKey:@"voters"];
                    self.preLoadData[objectId] = post;
                    [post saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                        if (!error) {
                            self.votes[objectId] = post[@"votes"];
                            self.voters[objectId] = post[@"voters"];
                            [self.tableView reloadData];
                            NSString *userId = post[@"author"];
                            NSString *groupId = post[@"groupId"];
                            NSDictionary *params = @{@"userId" : userId, @"groupId" : groupId};
                            NSDictionary *param = @{@"userId" : userId};
                            [PFCloud callFunctionInBackground:@"fixUser" withParameters:param block:nil];
                            [PFCloud callFunctionInBackground:@"updateUser" withParameters:params block:nil];
                            [post refreshInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                                self.votes[objectId] = object[@"votes"];
                                self.voters[objectId] = object[@"voters"];
                                [self.tableView reloadData];
                            }];
                        } else {
                            [PXAlertView showAlertWithTitle:@"Could not unstar post" message:@"Try again later" cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
                            self.voterImages[objectId] = [UIImage imageNamed:@"blueStar.png"];
                            
                        }
                    }];
                }
            }];
        }
    } else {
        NSLog(@"getting query");
        PFQuery *query = [PFQuery queryWithClassName:@"Post"];
        query.cachePolicy = kPFCachePolicyNetworkElseCache;
        [query getObjectInBackgroundWithId:objectId block:^(PFObject *postObject, NSError *error) {
            if (!error) {
                PFObject *post =  postObject;
                if(!([postObject[@"voters"]
                      containsObject:[[PFUser currentUser] objectId]]))
                {
                    //Add voter to posts array of voters
                    [post incrementKey:@"votes"];
                    [post addObject:[PFUser currentUser].objectId forKey:@"voters"];
                    self.preLoadData[objectId] = post;
                    [post saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                        if (!error) {
                            self.votes[objectId] = post[@"votes"];
                            self.voters[objectId] = post[@"voters"];
                            [self.tableView reloadData];
                            NSString *userId = post[@"author"];
                            NSString *groupId = post[@"groupId"];
                            NSDictionary *params = @{@"userId" : userId, @"groupId" : groupId};
                            NSDictionary *param = @{@"userId" : userId};
                            [PFCloud callFunctionInBackground:@"fixUser" withParameters:param block:nil];
                            [PFCloud callFunctionInBackground:@"updateUser" withParameters:params block:nil];
                            [post refreshInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                                self.votes[objectId] = object[@"votes"];
                                self.voters[objectId] = object[@"voters"];
                                [self.tableView reloadData];
                            }];
                        } else {
                            [PXAlertView showAlertWithTitle:@"Could not star post" message:@"Try again later" cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
                            self.voterImages[objectId] = [UIImage imageNamed:@"greyStar.png"];
                            
                        }
                    }];
                    
                } else{
                    [PXAlertView showAlertWithTitle:@"Post already starred" message:@"Unstar post?" cancelTitle:@"Cancel" otherTitle:@"Yes" completion:^(BOOL cancelled, NSInteger buttonIndex) {
                        if (!cancelled) {
                            self.voterImages[objectId] = [UIImage imageNamed:@"greyStar.png"];
                            
                            [post incrementKey:@"votes" byAmount:@-1];
                            [post removeObject:[PFUser currentUser].objectId forKey:@"voters"];
                            self.preLoadData[objectId] = post;
                            [post saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                                if (!error) {
                                    self.votes[objectId] = post[@"votes"];
                                    self.voters[objectId] = post[@"voters"];
                                    [self.tableView reloadData];
                                    NSString *userId = post[@"author"];
                                    NSString *groupId = post[@"groupId"];
                                    NSDictionary *params = @{@"userId" : userId, @"groupId" : groupId};
                                    NSDictionary *param = @{@"userId" : userId};
                                    [PFCloud callFunctionInBackground:@"fixUser" withParameters:param block:^(id object, NSError *error) {
                                        [PFCloud callFunctionInBackground:@"updateUser" withParameters:params block:nil];
                                    }];
                                    [post refreshInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                                        self.votes[objectId] = object[@"votes"];
                                        self.voters[objectId] = object[@"voters"];
                                        [self.tableView reloadData];
                                    }];
                                } else {
                                    [PXAlertView showAlertWithTitle:@"Could not unstar post" message:@"Try again later" cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
                                    self.voterImages[objectId] = [UIImage imageNamed:@"blueStar.png"];
                                    
                                }
                            }];
                        }
                    }];
                }
            } else {
                [PXAlertView showAlertWithTitle:@"Could not star post" message:@"Try again later" cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
                self.voterImages[objectId] = [UIImage imageNamed:@"greyStar.png"];
            }
        }];
    }
    
}

@end

//
//  FBUGroupSettingsViewController.m
//  NewsPaper
//
//  Created by Lillian Choung on 7/17/14.
//  Copyright (c) 2014 Facebook. All rights reserved.
//

#import "FBUGroupSettingsViewController.h"
#import <Parse/Parse.h>
#import "DesignConstants.h"
#import "PXAlertView+Customization.h"
#import "FBUBackgroundLayer.h"

@interface FBUGroupSettingsViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *groupName;
@property (weak, nonatomic) IBOutlet UITextView *groupDescription;
@property (weak, nonatomic) IBOutlet UITextField *tagField;
@property (nonatomic) PFObject *group;
@property (strong, nonatomic) NSMutableCharacterSet *delimiters;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *tagsLabel;
@property (assign, nonatomic) BOOL blocking;
@property (weak, nonatomic) IBOutlet UISlider *pointSlider;
@property (weak, nonatomic) IBOutlet UILabel *pointsLabel;

@end

@implementation FBUGroupSettingsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}

- (id)initWithEdit:(BOOL)editMode group:(PFObject *)group
{
    self = [super initWithNibName:nil bundle:nil];
    if (editMode) {
        if (self) { //In editing mode
            _group = group;
            UIBarButtonItem *edit = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(submitChanges:)];
            UIBarButtonItem *cancel = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
            self.navigationItem.rightBarButtonItem = edit;
            self.navigationItem.leftBarButtonItem = cancel;
        }
    }
    else{ //Not in editing mode
        UIBarButtonItem *done = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(makeGroup:)];
        UIBarButtonItem *cancel = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
        self.navigationItem.rightBarButtonItem = done;
        self.navigationItem.leftBarButtonItem = cancel;
    }
    return self;
}

- (void)makeGroup:(id)sender
{
    if (self.blocking) {
        return;
    }
    self.blocking = true;
    //Create group object on Parse
    PFObject *group = [PFObject objectWithClassName: @"Group"];
    //Check for name
    if (self.groupName.text.length < 1)
    {
        [PXAlertView showAlertWithTitle:@"Missing name" message:@"Please enter in a publication name" cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {
            self.blocking = false;
        }];
        return;
    } else if (self.groupName.text.length > 75)
    {
        [PXAlertView showAlertWithTitle:@"Name too long" message:@"Please enter in a publication title with less than 75 characters" cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {
            self.blocking = false;
        }];
        return;
    }
    group[@"name"] = self.groupName.text;
    if(self.groupDescription.text.length < 1){
        group[@"description"] = @"None";
    } else {
        group[@"description"] = self.groupDescription.text;
    }
    group[@"tags"] = [[NSMutableArray alloc] init];
    for(NSString *tag in [[self.tagField.text lowercaseString] componentsSeparatedByCharactersInSet:self.delimiters]) {
        if(tag.length) {
            [group[@"tags"] addObject:tag];
        }
    }
    //Add creator to member list and instantiate group newsfeed
    PFUser *currUser = [PFUser currentUser];
    group[@"memberIds"] = [[NSMutableArray alloc] initWithObjects: currUser.objectId, nil];
    [currUser[@"groups"] addObject: group[@"name"]];
    group[@"members"] = [[NSMutableArray alloc] initWithObjects: currUser[@"name"], nil];
    group[@"newsfeed"] = [[NSMutableArray alloc] initWithObjects:nil];
    group[@"approvedPosts"] = [[NSMutableArray alloc] initWithObjects:nil];
    group[@"pendingPosts"] = [[NSMutableArray alloc] initWithObjects:nil];
    group[@"postIds"] = [[NSMutableArray alloc] initWithObjects:nil];
    //Give the creator credits
    group[@"minCred"] = @((int)self.pointSlider.value);
    group[@"cred"] = [[NSMutableDictionary alloc] init];
    group[@"cred"][currUser.objectId] = @((int)self.pointSlider.value);
    group[@"creator"] = currUser.objectId;
    PFQuery *query = [PFQuery queryWithClassName:@"Group"];
    [query whereKey:@"name" equalTo:group[@"name"]];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            if ([objects count]) {
                [PXAlertView showAlertWithTitle:@"Error" message:@"Publication already exists. Try joining it." cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {
                    self.blocking = false;
                }];
            } else {
                [group saveInBackgroundWithBlock:^(BOOL succeeded, NSError *errorSaving) {
                    if (!errorSaving) {
                        [currUser[@"groupIds"] addObject: [group objectId]];
                        [currUser[@"adminGroups"] addObject: [group objectId]];
                        [currUser addUniqueObject:[@"g"stringByAppendingString:group.objectId] forKey:@"channels"];
                        PFInstallation *currentInstallation = [PFInstallation currentInstallation];
                        [currUser addUniqueObject:[@"u"stringByAppendingString:[PFUser currentUser].objectId] forKey:@"channels"];
                        currentInstallation[@"channels"] = currUser[@"channels"];
                        [currentInstallation saveInBackground];
                        [currUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                            [PXAlertView showAlertWithTitle:@"Publication Created" message:@"Your publication has been created!" cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {
                                self.blocking = false;
                            }];
                            NSLog(@"%@", currUser);
                            [self viewWillAppear:YES];
                            [self dismissViewControllerAnimated:TRUE completion:nil];
                        }];
                    } else {
                        [PXAlertView showAlertWithTitle:@"Error" message:@"Could not make publication. Try again later" cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {
                            self.blocking = false;
                        }];
                    }
                }];
            }
        } else {
            [PXAlertView showAlertWithTitle:@"Error" message:@"Could not make publication. Try again later" cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {
                self.blocking = false;
            }];
        }
    }];
}
- (IBAction)sliderValueChanged:(id)sender {
    self.pointsLabel.text = [NSString stringWithFormat:@"%d", (int)self.pointSlider.value];
}

- (void)submitChanges:(id)sender
{
    //Name has changed?
    if (!([_group[@"name"] isEqualToString:self.groupName.text]))
    {
        _group[@"name"] = self.groupName.text;
    }
    //Description has changed?
    if (!([_group[@"description"] isEqualToString:self.groupDescription.text]))
    {
        _group[@"description"] = self.groupDescription.text;
    }
    [_group saveInBackground];
    [self viewWillAppear:YES];
    [self dismissViewControllerAnimated:TRUE completion:nil];
}

- (void)cancel:(id)sender
{
    [self dismissViewControllerAnimated:TRUE completion:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.blocking = false;
    if (_group) //If we are editing an existing group
    {
        [self setLabels];
    }
    self.delimiters = [[NSMutableCharacterSet alloc] init];
    [self.delimiters formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [self.delimiters formUnionWithCharacterSet:[NSCharacterSet punctuationCharacterSet]];
    [self.delimiters formUnionWithCharacterSet:[NSCharacterSet punctuationCharacterSet]];
    
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.groupName) {
        [self.groupName resignFirstResponder];
        [self.tagField becomeFirstResponder];
        return NO;
    } else if(textField == self.tagField) {
        [self.tagField resignFirstResponder];
        [self.groupDescription becomeFirstResponder];
        return NO;
    }
    return YES;
}
- (void)setLabels
{
    //Set the text of text fields
    self.groupName.text = _group[@"name"];
    self.groupDescription.text = _group[@"description"];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.groupDescription.keyboardAppearance = KEYBOARD;
    self.groupName.keyboardAppearance = KEYBOARD;
    self.tagField.keyboardAppearance = KEYBOARD;
    self.groupDescription.tintColor = BARTEXTCOLOR;
    self.groupDescription.layer.cornerRadius = 5;
    self.groupDescription.clipsToBounds = YES;
    self.groupName.tintColor = BARTEXTCOLOR;
    self.groupName.textColor = BARTEXTCOLOR;
    self.tagField.tintColor = BARTEXTCOLOR;
    self.view.backgroundColor = BACKGROUNDCOLOR;
    self.groupDescription.backgroundColor = TEXTFIELDBACKGROUND;
    self.groupName.backgroundColor = TEXTFIELDBACKGROUND;
    self.tagField.backgroundColor = TEXTFIELDBACKGROUND;
    self.descriptionLabel.textColor = BARTEXTCOLOR;
    self.descriptionLabel.font = TEXTFONT;
    self.tagsLabel.textColor = BARTEXTCOLOR;
    self.tagsLabel.font = TEXTFONT;
    self.groupName.font = TEXTFONT;
    self.tagField.font = TEXTFONT;
    self.groupDescription.font = TEXTFONT;
    self.groupName.returnKeyType = UIReturnKeyNext;
    self.groupName.enablesReturnKeyAutomatically = YES;
    self.tagField.returnKeyType = UIReturnKeyNext;
    self.tagField.enablesReturnKeyAutomatically = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void)dismissKeyboard
{
    [self.groupName resignFirstResponder];
    [self.groupDescription resignFirstResponder];
    [self.tagField resignFirstResponder];
}
@end

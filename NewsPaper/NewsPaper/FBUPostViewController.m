//
//  FBUPostViewController.m
//  NewsPaper
//
//  Created by Lillian Choung on 7/11/14.
//  Copyright (c) 2014 Facebook. All rights reserved.
//

#import "FBUPostViewController.h"
#import <Parse/Parse.h>
#import "MWPhotoBrowser.h"
#import <CommonCrypto/CommonDigest.h>
#import "DesignConstants.h"
#import "NewsFeedViewController.h"
#import "FBUAppDelegate.h"
#import "GroupViewController.h"
#import "FBUManageViewController.h"
#import "PXAlertView+Customization.h"
#import "FBUBackgroundLayer.h"

@interface FBUPostViewController () <UITextFieldDelegate, MWPhotoBrowserDelegate, UIPickerViewDataSource, UIPickerViewDelegate>
@property (strong, nonatomic) IBOutlet UIView *view;
@property (weak, nonatomic) IBOutlet UIView *selectorView;
@property (weak, nonatomic) IBOutlet UITextView *inputViewField;
@property (weak, nonatomic) IBOutlet UITextField *inputTitle;
@property (weak, nonatomic) IBOutlet UIPickerView *picker;
@property (weak, nonatomic) IBOutlet UITextField *inputDescription;
@property (weak, nonatomic) IBOutlet UIButton *groupButton;
@property (weak, nonatomic) IBOutlet UIButton *doneGroup;

@property (nonatomic) UIButton *doneButton;
@property (nonatomic) NSLayoutConstraint *keyboardHeight;
@property(nonatomic) UIButton *dismiss;

//Assets library
@property (nonatomic) ALAssetsLibrary *library;

//Asset collection
@property (nonatomic) NSMutableArray *assets;
@property (nonatomic) NSMutableArray *selectedAssets;

//MW Photo Arrays
@property (nonatomic) NSMutableArray *photos;
@property (nonatomic) NSMutableArray *selectedPhotos;
@property (nonatomic) NSMutableArray *systemPhotos;

//Boolean Arrays
@property (nonatomic) NSMutableArray *selections;
@property (nonatomic) NSMutableArray *selectedBool;
@property (nonatomic) NSMutableArray *systemBool; //Should always be NO?

//Groups
@property (nonatomic, strong) NSMutableArray *groups;
@property (nonatomic, strong) NSMutableArray *ids;
@property (nonatomic, strong) NSString *groupId;
@property (nonatomic, strong) NSMutableString *currentGroupName;
@property (nonatomic) NSInteger groupPickerNumber;
@property (nonatomic) BOOL hasBeenNotified;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *v1;

@end


/* Note: _photos, _assets, and _selections are used to help the
 grid view know what to display and what to save to the server.
 To get PFObject pictures, you should use _gallery */

@implementation FBUPostViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [self initWithNibName:nibNameOrNil bundle:nibBundleOrNil groupId:nil];
}
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil groupId:(NSString *)groupId
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        _hasBeenNotified = NO;
        _groups = [PFUser currentUser][@"groups"];
        _currentGroupName = [NSMutableString string];
        _ids = [PFUser currentUser][@"groupIds"];
        if ([_ids count]) {
            _groupId = _ids[0];
            _currentGroupName = _groups[0];
            if (groupId) {
                _groupPickerNumber = [_ids indexOfObject:groupId];
                _groupId = _ids[_groupPickerNumber];
                _currentGroupName = _groups[_groupPickerNumber];
                [self.groupButton setTitle:[self.currentGroupName uppercaseString] forState:UIControlStateNormal];
                [self.groupButton setTitle:[self.currentGroupName uppercaseString] forState:UIControlStateHighlighted];
                [_picker reloadAllComponents];
                if (_currentGroupName.length < 1) {
                    [self.groupButton setTitle:[@"No groups to post to" uppercaseString] forState:UIControlStateNormal];
                    [self.groupButton setTitle:[@"No groups to post to" uppercaseString] forState:UIControlStateHighlighted];
                }
            }
        }
        [[PFUser currentUser] refreshInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            if (!error) {
                _groups = [PFUser currentUser][@"groups"];
                _ids = [PFUser currentUser][@"groupIds"];
                if ([_ids count]) {
                    _groupId = _ids[0];
                    _currentGroupName = _groups[0];
                    if (groupId) {
                        _groupPickerNumber = [_ids indexOfObject:groupId];
                        _groupId = _ids[_groupPickerNumber];
                        _currentGroupName = _groups[_groupPickerNumber];
                        [self.groupButton setTitle:[self.currentGroupName uppercaseString] forState:UIControlStateNormal];
                        [self.groupButton setTitle:[self.currentGroupName uppercaseString] forState:UIControlStateHighlighted];
                        [_picker reloadAllComponents];
                        if (_currentGroupName.length < 1) {
                            [self.groupButton setTitle:[@"No groups to post to" uppercaseString] forState:UIControlStateNormal];
                            [self.groupButton setTitle:[@"No groups to post to" uppercaseString] forState:UIControlStateHighlighted];
                        }
                    }
                }
            } else {
                NSLog(@"%@", error);
            }
            
        }];
        //Create BACK button on navigation bar
        UIBarButtonItem *back = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(done:)];
        self.navigationItem.leftBarButtonItem = back;
        
        UIBarButtonItem *publish = [[UIBarButtonItem alloc] initWithTitle:@"Publish" style:UIBarButtonItemStylePlain target:self action:@selector(post:)];
        self.navigationItem.rightBarButtonItem = publish;
        
        //Create toolbar and items
        UIBarButtonItem *gallery;
        gallery = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"photos.png"] style:UIBarButtonItemStylePlain target:self action:@selector(showSelected:)];
        UIBarButtonItem *label = [[UIBarButtonItem alloc] initWithTitle:@"Gallery" style:UIBarButtonItemStylePlain target:self action:@selector(showSelected:)];
        UIToolbar *toolbar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, [[UIScreen mainScreen] bounds].size.height - 44, [[UIScreen mainScreen] bounds].size.width, 44.0f)];
        [self setToolbarItems:@[gallery, label]];
        gallery.tintColor = ACCENTCOLOR;
        [self.view addSubview:toolbar];
        
        _dismiss = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        _dismiss.frame = CGRectMake(220, 310, 100, 50);
        [_dismiss setTitle:@"Dismiss" forState:UIControlStateNormal];
        [_dismiss addTarget:self action:@selector(dismissKeyboard) forControlEvents:UIControlEventTouchUpInside];
        _dismiss.hidden =  YES;
        [self.view addSubview:_dismiss];
        _dismiss.tintColor = TEXTCOLOR;
        _dismiss.titleLabel.textColor = TEXTCOLOR;
        _dismiss.titleLabel.font = TEXTFONT;
        _selectedPhotos = [[NSMutableArray alloc] init];
        _systemPhotos = [[NSMutableArray alloc] init];
        _selections = [[NSMutableArray alloc] init];
        _selectedBool = [[NSMutableArray alloc] init];
        _systemBool = [[NSMutableArray alloc] init];
        
        _assets = [[NSMutableArray alloc] init];
        _selectedAssets = [[NSMutableArray alloc] init];
        
    }
    return self;
}

- (void)showAnimate:(UIView *)view
{
    view.transform = CGAffineTransformMakeScale(1.3, 1.3);
    view.alpha = 0;
    [UIView animateWithDuration:.25 animations:^{
        view.alpha = 1;
        view.transform = CGAffineTransformMakeScale(1, 1);
    }];
}

- (void)removeAnimate:(UIView *)view
{
    [UIView animateWithDuration:.25 animations:^{
        view.transform = CGAffineTransformMakeScale(1.3, 1.3);
        view.alpha = 0.0;
    }];
}

- (IBAction)showGroupPicker:(id)sender {
    [self dismissKeyboard];
    //Without this line, bugs due to the placement of the view will occur
    [self.view bringSubviewToFront:_selectorView];
    [self showAnimate:_selectorView];
    if ([_groups count]) {
        [self.picker selectRow:_groupPickerNumber inComponent:0 animated:NO];
        _currentGroupName = _groups[_groupPickerNumber];
        [self.groupButton setTitle:[self.currentGroupName uppercaseString] forState:UIControlStateNormal];
        [self.groupButton setTitle:[self.currentGroupName uppercaseString] forState:UIControlStateHighlighted];
    }
    if (_currentGroupName.length < 1) {
        [self.groupButton setTitle:[@"No groups to post to" uppercaseString] forState:UIControlStateNormal];
        [self.groupButton setTitle:[@"No groups to post to" uppercaseString] forState:UIControlStateHighlighted];
    }
    [self showAnimate:_selectorView];
    [self.view bringSubviewToFront:_selectorView];
}

- (IBAction)hideGroupPicker:(id)sender {
    [self removeAnimate:_selectorView];
    //Without this line, bugs due to the placement of the view will occur
    [self.view sendSubviewToBack:_selectorView];
    if ([_groups count]) {
        [self.picker selectRow:_groupPickerNumber inComponent:0 animated:NO];
        _currentGroupName = _groups[_groupPickerNumber];
        [self.groupButton setTitle:[self.currentGroupName uppercaseString] forState:UIControlStateNormal];
        [self.groupButton setTitle:[self.currentGroupName uppercaseString] forState:UIControlStateHighlighted];
    }
    if (_currentGroupName.length < 1) {
        [self.groupButton setTitle:[@"No groups to post to" uppercaseString] forState:UIControlStateNormal];
        [self.groupButton setTitle:[@"No groups to post to" uppercaseString] forState:UIControlStateHighlighted];
    }
    [self removeAnimate:_selectorView];
    [self.view sendSubviewToBack:_selectorView];
}

- (void)showSystemPhotos
{
    //Create a photo browser
    MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    
    //Set options
    NSLog(@"Setting options!");
    browser.displayActionButton = NO; // Show action button to allow sharing, copying, etc (defaults to YES)
    browser.displayNavArrows = NO; // Whether to display left and right nav arrows on toolbar (defaults to NO)
    browser.navigationItem.title = @"";
    browser.displaySelectionButtons = YES;
    UIBarButtonItem *toggleEdit = [[UIBarButtonItem alloc]initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(donePicking:)];
    toggleEdit.tintColor = [UIColor whiteColor];
    browser.navigationItem.rightBarButtonItems = @[toggleEdit];
    browser.zoomPhotosToFill = YES; // Images that almost fill the screen will be initially zoomed to fill (defaults to YES)
    browser.alwaysShowControls = NO; // Allows to control whether the bars and controls are always visible or whether they fade away to show the photo full (defaults to NO)
    browser.enableGrid = YES; // Whether to allow the viewing of all the photo thumbnails on a grid (defaults to YES)
    browser.startOnGrid = YES; // Whether to start on the grid of thumbnails instead of the first photo (defaults to NO)
    
    [self.navigationController pushViewController:browser animated:YES];
}

- (void)showSelected: (id)sender
{
    MWPhotoBrowser *browser;
    //Create a photo browser
    if ([_selectedPhotos count] > 0)
    {
        browser = [[MWPhotoBrowser alloc] initWithDelegate:self hasPosts:YES];
    } else {
        browser = [[MWPhotoBrowser alloc] initWithDelegate:self hasPosts:NO];
    }
    _photos = _selectedPhotos;
    _selections = _selectedBool;
    
    
    //Set options
    NSLog(@"Setting options!");
    browser.displayActionButton = NO; // Show action button to allow sharing, copying, etc (defaults to YES)
    browser.displayNavArrows = NO; // Whether to display left and right nav arrows on toolbar (defaults to NO)
    browser.navigationItem.title = @"";
    browser.displaySelectionButtons = YES;
    UIBarButtonItem *delete = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(deletePhotos:)];
    UIBarButtonItem *toggleEdit = [[UIBarButtonItem alloc]initWithTitle:@"Add" style:UIBarButtonItemStylePlain target:self action:@selector(addPhotos:)];
    toggleEdit.tintColor = [UIColor whiteColor];
    browser.navigationItem.rightBarButtonItems = @[toggleEdit, delete];
    browser.zoomPhotosToFill = YES; // Images that almost fill the screen will be initially zoomed to fill (defaults to YES)
    browser.alwaysShowControls = NO; // Allows to control whether the bars and controls are always visible or whether they fade away to show the photo full (defaults to NO)
    browser.enableGrid = YES; // Whether to allow the viewing of all the photo thumbnails on a grid (defaults to YES)
    browser.startOnGrid = YES; // Whether to start on the grid of thumbnails instead of the first photo (defaults to NO)
    
    [self.navigationController pushViewController:browser animated:YES];
}

- (void)getPhotosFromSelected
{
    _photos = _selectedPhotos;
    _selections = _selectedBool;
    NSLog(@"Selected bool: %@", _selectedBool);
}

- (void)getPhotosFromSystem
{
    if ([_systemPhotos count] > 0)
    {
        _photos = _systemPhotos;
        _selections = _systemBool;
        [self showSystemPhotos];
        return;
    }
    _library = [[ALAssetsLibrary alloc]init];
    [_library enumerateGroupsWithTypes:ALAssetsGroupAll
                            usingBlock: ^(ALAssetsGroup *group, BOOL *stop)
     {
         if (group){
             [group enumerateAssetsUsingBlock:^(ALAsset *asset, NSUInteger index, BOOL *stop)
              {
                  if (asset)
                  {
                      [_assets addObject:asset];
                      [_systemBool addObject:[NSNumber numberWithBool:NO]];
                      [_systemPhotos addObject: [MWPhoto photoWithImage:[UIImage imageWithCGImage:[asset thumbnail]]]];
                      NSLog(@"%@", _systemPhotos);
                  }
                  else
                  {
                      NSLog(@"%ld", [_systemPhotos count]);
                  }
              }];
         }
         else {
             _photos = _systemPhotos;
             NSLog(@"Photos: %@", _photos);
             _selections = _systemBool;
             [self showSystemPhotos];
         }
     } failureBlock:nil];
}

- (void)addPhotos: (id)sender
{
    [self getPhotosFromSystem];
}

- (void)deletePhotos: (id)sender
{
    NSMutableIndexSet *deleteIndices = [[NSMutableIndexSet alloc] init];
    for (int i = 0; i < [_selections count]; i++)
    {
        if(_selections[i] == [NSNumber numberWithBool:NO])
        {
            [deleteIndices addIndex:i];
        }
    }
    [_selectedBool removeObjectsAtIndexes:deleteIndices];
    [_selectedAssets removeObjectsAtIndexes:deleteIndices];
    [_selectedPhotos removeObjectsAtIndexes:deleteIndices];
    
    [self.navigationController popToViewController:self animated:YES];
}

- (void)donePicking: (id)sender{
    
    for (int i = 0; i < [_selections count]; i++)
    {
        if (_selections[i] == [NSNumber numberWithBool:YES])
        {
            if(!([_selectedPhotos containsObject:_systemPhotos[i]]))
            {
                [_selectedPhotos addObject: _systemPhotos[i]];
                [_selectedAssets addObject: _assets[i]];
                [_selectedBool addObject: [NSNumber numberWithBool:YES]];
            }
        }
    }
    [self.navigationController popToViewController:self animated:YES];
    [PXAlertView showAlertWithTitle:@"Gallery Saved" message:@"" cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
}

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return self.photos.count;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < self.photos.count)
    return [self.photos objectAtIndex:index];
    return nil;
}

//For grid view
- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser thumbPhotoAtIndex:(NSUInteger)index
{
    if (index < self.photos.count)
    return [self.photos objectAtIndex:index];
    return nil;
}

//For selecting photos
- (BOOL)photoBrowser:(MWPhotoBrowser *)photoBrowser isPhotoSelectedAtIndex:(NSUInteger)index {
    if ([self.photos count] > 0){
        NSLog(@"%@", _selections);
        return [[_selections objectAtIndex:index] boolValue];
    }
    return NO;
}

//Toggle selection array
- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index selectedChanged:(BOOL)selected {
    [_selections replaceObjectAtIndex:index withObject:[NSNumber numberWithBool:selected]];
    NSLog(@"Selections are %@", _selections);
}

//This class function scales images down nicely
+(UIImage*)imageWithImage: (UIImage*) sourceImage scaledToWidth: (float) i_width
{
    float oldWidth = sourceImage.size.width;
    float scaleFactor = i_width / oldWidth;
    
    float newHeight = sourceImage.size.height * scaleFactor;
    float newWidth = oldWidth * scaleFactor;
    
    UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight));
    [sourceImage drawInRect:CGRectMake(0, 0, newWidth, newHeight)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (NSData *)assetToData:(ALAsset *)asset
{
    ALAssetRepresentation* representation = [asset defaultRepresentation];
    
    //Retrieve image orientation
    UIImageOrientation orientation = UIImageOrientationUp;
    NSNumber* orientationValue = [asset valueForProperty:@"ALAssetPropertyOrientation"];
    if (orientationValue != nil) {
        orientation = [orientationValue intValue];
    }
    UIImage *largeImage = [UIImage imageWithCGImage:[representation fullResolutionImage]
                                              scale:1
                                        orientation:orientation];
    UIImage *currImage = [FBUPostViewController imageWithImage:largeImage scaledToWidth: 640.0];
    NSData *currData = UIImageJPEGRepresentation(currImage, 0.7);
    return currData;
}

- (NSString *)dataToHash:(NSData *)data
{
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5([data bytes], [data length], result);
    NSString *imageHash = [NSString stringWithFormat:
                           @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
                           result[0], result[1], result[2], result[3],
                           result[4], result[5], result[6], result[7],
                           result[8], result[9], result[10], result[11],
                           result[12], result[13], result[14], result[15]
                           ];
    
    return imageHash;
}

- (void)done:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

//KEYBOARD STUFF

- (void)observeKeyboard
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.inputTitle) {
        [textField resignFirstResponder];
        [self.inputDescription becomeFirstResponder];
        return NO;
    } else if (textField == self.inputDescription) {
        [textField resignFirstResponder];
        [self.inputViewField becomeFirstResponder];
        return NO;
    }
    return YES;
}

// The callback for frame-changing of keyboard
- (void)keyboardWillShow:(NSNotification *)notification
{
    [self hideGroupPicker:nil];
    NSDictionary *info = [notification userInfo];
    NSValue *kbFrame = [info objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardFrame = [kbFrame CGRectValue];
    
    CGFloat height = keyboardFrame.size.height;
    self.keyboardHeight.constant += height;
    [self.inputViewField updateConstraints];
    
    //Show dismiss button with transition
    [UIView transitionWithView:_dismiss
                      duration:0.4
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:NULL
                    completion:NULL];
    _dismiss.hidden = NO;
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    self.keyboardHeight.constant = 10;
    [self.inputViewField updateConstraints];
    [self.inputViewField setContentOffset:CGPointZero animated:NO];
    
    //Hide dismiss button with transition
    [UIView transitionWithView:_dismiss
                      duration:0.3
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:NULL
                    completion:NULL];
    
    _dismiss.hidden = YES;
}

- (void)viewDidLoad
{
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;
    if (screenHeight + screenWidth < 810) {
        self.v1.constant = 250;
    }
    //Dismiss keyboard on tapping outside of the textView.
    [super viewDidLoad];
    [self observeKeyboard];
    [self.picker selectRow:_groupPickerNumber inComponent:0 animated:NO];
    NSLog(@"%d", _groupPickerNumber);
    self.title = @"Post";
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
    self.inputDescription.keyboardAppearance = KEYBOARD;
    self.inputTitle.keyboardAppearance = KEYBOARD;
    self.inputViewField.keyboardAppearance = KEYBOARD;
    self.inputTitle.returnKeyType = UIReturnKeyNext;
    self.inputTitle.enablesReturnKeyAutomatically = YES;
    self.inputDescription.returnKeyType = UIReturnKeyNext;
    self.view.backgroundColor = [UIColor whiteColor];
    self.picker.backgroundColor = [UIColor clearColor];
    self.selectorView.backgroundColor = BACKGROUNDCOLOR;
    self.selectorView.alpha = 0;
    self.selectorView.layer.cornerRadius = 5;
    self.selectorView.layer.masksToBounds = YES;
    _doneGroup.tintColor = TEXTCOLOR;
    _doneGroup.titleLabel.textColor = TEXTCOLOR;
    _doneGroup.titleLabel.font = TEXTFONT;
    _dismiss.tintColor = TEXTCOLOR;
    _dismiss.titleLabel.textColor = TEXTCOLOR;
    _dismiss.titleLabel.font = TEXTFONT;
    [self.groupButton setTitle:[self.currentGroupName uppercaseString] forState:UIControlStateNormal];
    [self.groupButton setTitle:[self.currentGroupName uppercaseString] forState:UIControlStateHighlighted];
    if (_currentGroupName.length < 1) {
        [self.groupButton setTitle:[@"No groups to post to" uppercaseString] forState:UIControlStateNormal];
        [self.groupButton setTitle:[@"No groups to post to" uppercaseString] forState:UIControlStateHighlighted];
    }
    
}
- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view{
    UILabel* tView = (UILabel*)view;
    if (!tView){
        tView = [[UILabel alloc] initWithFrame:CGRectMake(10, 0.0, [pickerView rowSizeForComponent:component].width - 20, [pickerView rowSizeForComponent:component].height)];
        tView.backgroundColor = [UIColor clearColor];
        [tView setFont:TEXTFONT];
        [tView setTextColor:TEXTCOLOR];
        [tView setTextAlignment:NSTextAlignmentCenter];
    }
    [tView setText:[self.groups objectAtIndex:row]];
    // Fill the label text here
    return tView;
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.toolbarItems[1] setTitle:[NSString stringWithFormat:@"(%lu added)", (unsigned long)[_selectedPhotos count]]];
    [self.navigationController setToolbarHidden:NO animated:YES];
    self.navigationController.toolbar.barTintColor = BARCOLOR;
    self.navigationController.toolbar.tintColor = ACCENTCOLOR;
    [self.groupButton setTitle:[self.currentGroupName uppercaseString] forState:UIControlStateNormal];
    [self.groupButton setTitle:[self.currentGroupName uppercaseString] forState:UIControlStateHighlighted];
    if (_currentGroupName.length < 1) {
        [self.groupButton setTitle:[@"No groups to post to" uppercaseString] forState:UIControlStateNormal];
        [self.groupButton setTitle:[@"No groups to post to" uppercaseString] forState:UIControlStateHighlighted];
    }
    NSLog(@"%@", _groupButton.titleLabel.text);
}

- (void)viewWillDisappear:(BOOL)animated
{
    /* No longer listen for keyboard */
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    
    [super viewWillDisappear:animated];
    [self.navigationController setToolbarHidden:YES animated:YES];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)post:(id)sender
{
    //Check for content before posting
    if(self.inputTitle.text.length < 1) {
        [PXAlertView showAlertWithTitle:@"Missing title" message:@"Please enter in a title. " cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
        return;
    }
    if(self.inputTitle.text.length > 25) {
        [PXAlertView showAlertWithTitle:@"Title too long" message:@"Please enter in a title less than 25 characters. " cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
        return;
    }
    if(self.inputDescription.text.length > 75) {
        [PXAlertView showAlertWithTitle:@"Description too long" message:@"Please enter in a description less than 75 characters" cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
        return;
    }
    if(self.inputViewField.text.length < 1) {
        [PXAlertView showAlertWithTitle:@"Missing post" message:@"Please enter in a post. " cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
        return;
    }
    if([self.groups count] < 1) {
        [PXAlertView showAlertWithTitle:@"Missing group" message:@"Please select a group. " cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
        return;
    }
    
    //Create post and hook it up to the gallery
    PFObject *post = [PFObject objectWithClassName: @"Post"];
    post[@"votes"] = @0;
    post[@"text"] = self.inputViewField.text;
    post[@"title"] = self.inputTitle.text;
    
    
    //Will it be a draft?
    if([[PFUser currentUser][@"adminGroups"] containsObject:_groupId])
    {
        post[@"approved"] = @YES;
        post[@"draft"] = @NO;
    } else {
        post[@"approved"] = @NO;
        post[@"draft"] = @YES;
    }
    
    post[@"group"] = self.currentGroupName;
    post[@"voters"] = [[NSMutableArray alloc]init];
    post[@"groupId"] = self.groupId;
    if(self.inputDescription.text.length > 0) {
        post[@"description"] = self.inputDescription.text;
    }
    
    //Save the post
    [post saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            if ([PFUser currentUser]) {
                post[@"author"] = [[PFUser currentUser] objectId];
                NSDictionary* userProfile = [PFUser currentUser][@"profile"];
                post[@"authorName"] = userProfile[@"name"];
            }
            
            PFObject *gallery = [PFObject objectWithClassName:@"Gallery"];
            gallery[@"photoIds"] = [[NSMutableArray alloc]init];
            gallery[@"hash"] = [[NSMutableArray alloc]init];
            
            __block int count = [_selectedPhotos count];
            
            
            if ([_selectedBool count] == 0)
            {
                [gallery saveInBackground];
                [post saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if(!error) {
                        NSDictionary *params = @{@"groupId" : self.groupId, @"postId" : post.objectId, @"postTitle" : post[@"title"]};
                        [PFCloud callFunctionInBackground:@"addPostToGroup" withParameters:params block:^(id object, NSError *error) {
                            if (!error) {
                                //Clear input fields when done
                                self.inputTitle.text = @"";
                                self.inputViewField.text = @"";
                                self.inputDescription.text = @"";
                                //Dismiss keyboard when done
                                [self.inputViewField resignFirstResponder];
                                [self.inputTitle resignFirstResponder];
                                [self.inputDescription resignFirstResponder];
                                
                                if ([[PFUser currentUser][@"adminGroups"] containsObject:_groupId])
                                {
                                    //Call cloud code to push the newest post to everyone
                                    NSDictionary *params = @{@"postId" : [post objectId], @"postTitle" : post[@"title"]};
                                    [PFCloud callFunctionInBackground:@"approvePost" withParameters:params block:^(id object, NSError *error) {
                                        if (!error) {
                                            [PXAlertView showAlertWithTitle:@"Post Submitted" message:@"Post has been published" cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
                                        } else {
                                            PFPush *push = [[PFPush alloc] init];
                                            [push setChannel:[@"g"stringByAppendingString:post[@"groupId"]]];
                                            [push setMessage:[NSString stringWithFormat:@"%@ has submitted a post for review", post[@"authorName"]]];
                                            [push sendPushInBackground];
                                            [PXAlertView showAlertWithTitle:@"Post Submitted" message:@"Post has been submitted for review" cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
                                        }
                                    }];
                                } else {
                                    PFPush *push = [[PFPush alloc] init];
                                    [push setChannel:[@"g"stringByAppendingString:post[@"groupId"]]];
                                    [push setMessage:[NSString stringWithFormat:@"%@ has submitted a post for review", post[@"authorName"]]];
                                    [push sendPushInBackground];
                                    [PXAlertView showAlertWithTitle:@"Post Submitted" message:@"Post has been submitted for review" cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
                                }
                            } else {
                                [PXAlertView showAlertWithTitle:@"Error" message:@"Unable to save changes. Try again later" cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
                            }
                        }];
                        
                        
                    }
                }];
            }
            
            for (int i = 0; i < [_selectedBool count]; i++)
            {
                //Match up assets with selection BOOL values
                if (_selectedBool[i] == [NSNumber numberWithBool:YES])
                {
                    ALAsset *currAsset = _selectedAssets[i];
                    NSData *currData = [self assetToData:currAsset];
                    
                    //Create a hash for the image
                    NSString *imageHash = [self dataToHash:currData];
                    
                    //Create a Parse object
                    PFObject *photo = [PFObject objectWithClassName:@"Image"];
                    photo[@"imageFile"] = [PFFile fileWithName:@"Image.jpg" data:currData];
                    photo[@"hash"] = imageHash;
                    photo[@"post"] = [post objectId];
                    
                    [photo saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
                     {
                         if(!error){
                             //Save the photo's ID to the gallery object after photo saves
                             [gallery[@"photoIds"] addObject:[photo objectId]];
                             [gallery[@"hash"] addObject:imageHash];
                             count -= 1;
                             NSLog(@"COUNT: %d", count);
                             if (count == 0)
                             {
                                 //Save the gallery object and then save the post
                                 [gallery saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
                                  {
                                      if (!error) {
                                          post[@"gallery"] = [gallery objectId];
                                          [post saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                                              if(!error) {
                                                  NSDictionary *params = @{@"groupId" : self.groupId, @"postId" : post.objectId, @"postTitle" : post[@"title"]};
                                                  [PFCloud callFunctionInBackground:@"addPostToGroup" withParameters:params block:^(id object, NSError *error) {
                                                      if (!error) {
                                                          
                                                          if ([[PFUser currentUser][@"adminGroups"] containsObject:_groupId])
                                                          {
                                                              //Call cloud code to push the newest post to everyone
                                                              NSDictionary *params = @{@"postId" : [post objectId], @"postTitle" : post[@"title"]};
                                                              [PFCloud callFunctionInBackground:@"approvePost" withParameters:params block:^(id object, NSError *error) {
                                                                  if (!error) {
                                                                      [PXAlertView showAlertWithTitle:@"Post Submitted" message:@"Post has been published" cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
                                                                  } else {
                                                                      PFPush *push = [[PFPush alloc] init];
                                                                      [push setChannel:[@"g"stringByAppendingString:post[@"groupId"]]];
                                                                      [push setMessage:[NSString stringWithFormat:@"%@ has submitted a post for review", post[@"authorName"]]];
                                                                      [push sendPushInBackground];
                                                                      [PXAlertView showAlertWithTitle:@"Post Submitted" message:@"Post has been submitted for review" cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
                                                                  }
                                                              }];
                                                          } else {
                                                              PFPush *push = [[PFPush alloc] init];
                                                              [push setChannel:[@"g"stringByAppendingString:post[@"groupId"]]];
                                                              [push setMessage:[NSString stringWithFormat:@"%@ has submitted a post for review", post[@"authorName"]]];
                                                              [push sendPushInBackground];
                                                              [PXAlertView showAlertWithTitle:@"Post Submitted" message:@"Post has been submitted for review" cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
                                                          }
                                                          
                                                          //Clear input fields when done
                                                          self.inputTitle.text = @"";
                                                          self.inputViewField.text = @"";
                                                          self.inputDescription.text = @"";
                                                          //Dismiss keyboard when done
                                                          [self.inputViewField resignFirstResponder];
                                                          [self.inputTitle resignFirstResponder];
                                                          [self.inputDescription resignFirstResponder];
                                                      } else {
                                                          [PXAlertView showAlertWithTitle:@"Error" message:@"Unable to save changes. Try again later" cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
                                                          NSLog(@"%@", error);
                                                      }
                                                  }];
                                              } else {
                                                  [PXAlertView showAlertWithTitle:@"Error" message:@"Unable to save changes. Try again later" cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
                                                  NSLog(@"%@", error);
                                              }
                                          }];
                                      } else {
                                          [PXAlertView showAlertWithTitle:@"Error" message:@"Unable to save changes. Try again later" cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
                                          NSLog(@"%@", error);
                                      }
                                  }];
                             }
                             
                         } else {
                             [PXAlertView showAlertWithTitle:@"Error" message:@"Unable to save changes. Try again later" cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
                             NSLog(@"%@", error);
                         }
                     }];
                }
            }
        } else {
            [PXAlertView showAlertWithTitle:@"Error" message:@"Unable to save changes. Try again later" cancelTitle:@"OK" completion:^(BOOL cancelled, NSInteger buttonIndex) {}];
            NSLog(@"%@", error);
        }
    }];
    
    //Clear input fields when done
    self.inputTitle.text = @"";
    self.inputViewField.text = @"";
    self.inputDescription.text = @"";
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

//Keyboard Management
-(void)dismissKeyboard
{
    [self.inputViewField resignFirstResponder];
    [self.inputTitle resignFirstResponder];
    [self.inputDescription resignFirstResponder];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

// returns the # of rows in each component..
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent: (NSInteger)component
{
    if (![self.ids count] && !self.hasBeenNotified) {
        self.hasBeenNotified = YES;
        [PXAlertView showAlertWithTitle:@"You do not have any publications to post to" message:@"Join a publication?" cancelTitle:@"No" otherTitles: @[@"Yes"] completion:^(BOOL cancelled, NSInteger buttonIndex) {
            if (!cancelled) {
                [self switchView];
            }
        }];
        return 0;
    }
    return [self.groups count];
}
-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    
    return [self.groups objectAtIndex:row];
}
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    
    NSLog(@"Selected Row %d", row);
    if (![self.ids count]) {
        [PXAlertView showAlertWithTitle:@"You do not have any publications to post to" message:@"Join a publication?" cancelTitle:@"No" otherTitles: @[@"Yes"] completion:^(BOOL cancelled, NSInteger buttonIndex) {
            if (!cancelled) {
                [self switchView];
            }
        }];
        return;
    }
    self.groupPickerNumber = row;
    self.groupId = self.ids[row];
    self.currentGroupName = self.groups[row];
    [self.groupButton setTitle:[self.currentGroupName uppercaseString] forState:UIControlStateNormal];
    [self.groupButton setTitle:[self.currentGroupName uppercaseString] forState:UIControlStateHighlighted];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField == self.inputTitle) {
        NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
        if (newString.length > 25) {
            textField.layer.cornerRadius=8.0f;
            textField.layer.masksToBounds=YES;
            textField.layer.borderColor=[[UIColor redColor] CGColor];
            textField.layer.borderWidth= 1.0f;
            return NO;
        }
        if (newString.length <= 25) {
            textField.layer.borderColor = [[UIColor clearColor] CGColor];
            return YES;
        }
    } else if (textField == self.inputDescription){
        NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
        if (newString.length > 75) {
            textField.layer.cornerRadius=8.0f;
            textField.layer.masksToBounds=YES;
            textField.layer.borderColor=[[UIColor redColor] CGColor];
            textField.layer.borderWidth= 1.0f;
            return NO;
        }
        if (newString.length <= 75) {
            textField.layer.borderColor = [[UIColor clearColor] CGColor];
            return YES;
        }
    }
    return YES;
}

- (void)switchView
{
    FBUAppDelegate *appDelegate = (FBUAppDelegate *)[[UIApplication sharedApplication] delegate];
    // Override point for customization after application launch.
    //Create a tab bar and initialize view controllers
    UITabBarController *tabBarController  = [[UITabBarController alloc] init];
    NewsFeedViewController *newsFeed = [[NewsFeedViewController alloc] initWithStyle:UITableViewStylePlain];
    UINavigationController *newsFeedNav = [[UINavigationController alloc] initWithRootViewController:newsFeed];
    FBUManageViewController *manage = [[FBUManageViewController alloc] init];
    UINavigationController *manageNav = [[UINavigationController alloc] initWithRootViewController:manage];
    GroupViewController *groups = [[GroupViewController alloc] initWithStyle:UITableViewStylePlain];
    UINavigationController *groupsNav = [[UINavigationController alloc]initWithRootViewController:groups];
    //Set the titles on the tab bar
    [manage setTitle:@"Manage"];
    [newsFeed setTitle:@"News Feed"];
    [groups setTitle:@"Publications"];
    //Assign the controllers to the tab bar
    NSArray *controllers = [NSArray arrayWithObjects:newsFeedNav, manageNav, groupsNav, nil];
    [tabBarController setViewControllers:controllers];
    [UITabBarItem.appearance setTitleTextAttributes:
     @{NSForegroundColorAttributeName : BARTEXTCOLOR}
                                           forState:UIControlStateNormal];
    [UITabBarItem.appearance setTitleTextAttributes:
     @{NSForegroundColorAttributeName : ACCENTCOLOR}
                                           forState:UIControlStateSelected];
    UITabBar *tabBar = (UITabBar *)tabBarController.tabBar;
    UITabBarItem *item1 = [tabBar.items objectAtIndex:0];
    item1.image = [[UIImage imageNamed:@"activity_feed.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    item1.selectedImage = [UIImage imageNamed:@"activity_feed.png"];
    UITabBarItem *item2 = [tabBar.items objectAtIndex:1];
    item2.image = [[UIImage imageNamed:@"edit_user.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    item2.selectedImage = [UIImage imageNamed:@"edit_user.png"];
    UITabBarItem *item3 = [tabBar.items objectAtIndex:2];
    item3.image = [[UIImage imageNamed:@"magazine.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    item3.selectedImage = [UIImage imageNamed:@"magazine.png"];
    [tabBarController setSelectedIndex:2];
    appDelegate.window.rootViewController = tabBarController;
}
@end

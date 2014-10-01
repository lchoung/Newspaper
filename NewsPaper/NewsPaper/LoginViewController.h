//
//  Copyright (c) 2013 Parse. All rights reserved.

#import <UIKit/UIKit.h>
#import <FacebookSDK/FBLoginView.h>

@interface LoginViewController : UIViewController

@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;

- (IBAction)loginButtonTouchHandler:(id)sender;
@property (strong, nonatomic) IBOutlet UIView *view;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet FBLoginView *loginView;

@end

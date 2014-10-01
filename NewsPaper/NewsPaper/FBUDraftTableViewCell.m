//
//  FBUDraftTableViewCell.m
//  NewsPaper
//
//  Created by Lillian Choung on 7/14/14.
//  Copyright (c) 2014 Facebook. All rights reserved.
//

#import "FBUDraftTableViewCell.h"

@implementation FBUDraftTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (IBAction)editPost:(id)sender {
    //Send notification for the FBUDraftTableViewController
    [[NSNotificationCenter defaultCenter] postNotificationName:@"editPost" object:self];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

@end

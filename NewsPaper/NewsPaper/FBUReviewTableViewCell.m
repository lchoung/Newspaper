//
//  FBUReviewTableViewCell.m
//  NewsPaper
//
//  Created by Lillian Choung on 7/13/14.
//  Copyright (c) 2014 Facebook. All rights reserved.
//

#import "FBUReviewTableViewCell.h"

@implementation FBUReviewTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

- (NSString *)reuseIdentifier{
    return @"reviewCell";
}

@end

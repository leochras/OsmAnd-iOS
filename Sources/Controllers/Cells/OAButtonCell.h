//
//  OAButtonCell.h
//  OsmAnd
//
//  Created by Paul on 26/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OAButtonCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIButton *button;
@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *buttonLeadingToIcon;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *buttonLeadingNoIcon;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *buttonHeight;
-(void)showImage:(BOOL)show;

@end

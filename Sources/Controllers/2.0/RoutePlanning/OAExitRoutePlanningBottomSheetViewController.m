//
//  OAExitRoutePlanningBottomSheetViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 19.01.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAExitRoutePlanningBottomSheetViewController.h"

#import "Localization.h"
#import "OAColors.h"
#import "OATextLineViewCell.h"
#import "OAButtonMenuCell.h"

#define kOABottomSheetWidth 320.
#define kOABottomSheetWidthIPad (DeviceScreenWidth / 2)
#define kLabelVerticalMargin 16.
#define kButtonHeight 42.
#define kButtonsVerticalMargin 32.
#define kHorizontalMargin 20.
#define kLabelCell @"OATextLineViewCell"
#define kButtonCell @"OAButtonMenuCell"

@interface OAExitRoutePlanningBottomSheetViewController () <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) IBOutlet UILabel *messageView;
@property (strong, nonatomic) IBOutlet UIButton *exitButton;
@property (strong, nonatomic) IBOutlet UIButton *saveButton;
@property (strong, nonatomic) IBOutlet UIButton *cancelButton;

@end

@implementation OAExitRoutePlanningBottomSheetViewController
{
    NSMutableArray<NSDictionary *> *_data;
}


- (instancetype) init
{
    self = [super initWithNibName:@"OABaseBottomSheetViewController" bundle:nil];

    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.contentInset = UIEdgeInsetsZero;
    self.tableView.separatorInset = UIEdgeInsetsZero;
    self.buttonsSectionDividerView.backgroundColor = UIColor.clearColor;;

    [self.rightButton removeFromSuperview];
    [self.leftIconView setImage:[UIImage imageNamed:@"ic_custom_routes"]];
    
    self.exitButton.layer.cornerRadius = 9.;
    self.saveButton.layer.cornerRadius = 9.;
    self.cancelButton.layer.cornerRadius = 9.;
    
    self.isFullScreenAvailable = NO;
    self.isDraggingUpAvailable = NO;
}

- (void) applyLocalization
{
    self.titleView.text = OALocalizedString(@"osm_editing_lost_changes_title");
    [self.exitButton setTitle:OALocalizedString(@"shared_string_exit") forState:UIControlStateNormal];
    [self.saveButton setTitle:OALocalizedString(@"shared_string_save") forState:UIControlStateNormal];
    [self.cancelButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
}

- (CGFloat) initialHeight
{
    CGFloat width;
    if ([OAUtilities isLandscape])
        width = OAUtilities.isIPad ? kOABottomSheetWidthIPad : kOABottomSheetWidth;
    else
        width = DeviceScreenWidth;
    width -= 2 * kHorizontalMargin;
    
    CGFloat headerHeight = self.headerView.frame.size.height;
    CGFloat textHeight = [OAUtilities calculateTextBounds:OALocalizedString(@"plan_route_exit_message") width:width font:[UIFont systemFontOfSize:15.]].height + kLabelVerticalMargin * 2;
    CGFloat contentHeight = textHeight + 2 * kButtonHeight + 2 * kButtonsVerticalMargin;
    CGFloat buttonsHeight = [self buttonsViewHeight];
    return headerHeight + contentHeight + buttonsHeight;
}

- (void) generateData
{
    _data = [NSMutableArray new];
    
    [_data addObject: @{
        @"type" : kLabelCell,
        @"title" : OALocalizedString(@"plan_route_exit_message"),
    }];
    
    [_data addObject: @{
        @"type" : kButtonCell,
        @"title" : OALocalizedString(@"shared_string_exit"),
        @"buttonColor" : UIColorFromRGB(color_route_button_inactive),
        @"textColor" : UIColorFromRGB(color_primary_purple),
        @"action": @"exitButtonPressed"
    }];

    [_data addObject: @{
        @"type" : kButtonCell,
        @"title" : OALocalizedString(@"shared_string_save"),
        @"buttonColor" : UIColorFromRGB(color_primary_purple),
        @"textColor" : UIColor.whiteColor,
        @"action": @"saveButtonPressed"
    }];
}

#pragma mark - Actions

- (void) exitButtonPressed
{
    [self dismissViewControllerAnimated:NO completion:nil];
    if (_delegate)
        [_delegate onExitRoutePlanningPressed];
}

- (void) saveButtonPressed
{
    [self dismissViewControllerAnimated:NO completion:nil];
    if (_delegate)
        [_delegate onSaveResultPressed];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section];
    NSString *type = item[@"type"];
    
    if ([type isEqualToString:kLabelCell])
    {
        OATextLineViewCell* cell;
        cell = (OATextLineViewCell *)[tableView dequeueReusableCellWithIdentifier:@"OATextLineViewCell"];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OATextLineViewCell" owner:self options:nil];
            cell = (OATextLineViewCell *)[nib objectAtIndex:0];
        }
        if (cell)
        {
            cell.backgroundColor = UIColor.clearColor;
            [cell.textView setTextColor:[UIColor blackColor]];
            [cell.textView setText:item[@"title"]];
        }
        return cell;
    }
    else if ([type isEqualToString:kButtonCell])
    {
        OAButtonMenuCell* cell = nil;
        cell = [self.tableView dequeueReusableCellWithIdentifier:kButtonCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kButtonCell owner:self options:nil];
            cell = (OAButtonMenuCell *)[nib objectAtIndex:0];
        }
        if (cell)
        {
            cell.backgroundColor = UIColor.clearColor;
            [cell.button setBackgroundColor:item[@"buttonColor"]];
            [cell.button setTitleColor:item[@"textColor"] forState:UIControlStateNormal];
            [cell.button setTitle:item[@"title"] forState:UIControlStateNormal];
            [cell.button addTarget:self action:NSSelectorFromString(item[@"action"]) forControlEvents:UIControlEventTouchDown];
            cell.button.layer.cornerRadius = 9.;
        }
        return cell;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.01;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (section == 1)
        return kButtonsVerticalMargin;
    else
        return kLabelVerticalMargin;
}

@end

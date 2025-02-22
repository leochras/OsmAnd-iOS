//
//  OAEditDescriptionViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 03/06/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAEditDescriptionViewController.h"
#import "Localization.h"
#import "OAColors.h"
#import "OATextViewSimpleCell.h"
#import "OAWebViewCell.h"
#import "OAIconTitleValueCell.h"

@interface OAEditDescriptionViewController () <UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, WKNavigationDelegate>

@end

@implementation OAEditDescriptionViewController
{
    CGFloat _keyboardHeight;
    BOOL _isNew;
    BOOL _readOnly;
    BOOL _isEditing;
    NSArray<NSDictionary<NSString *, NSString *> *> *_cellsData;
    NSString *_textViewContent;
    CGFloat _webViewHeight;
    int _webViewReloadingsCount;
}

-(id)initWithDescription:(NSString *)desc isNew:(BOOL)isNew isEditing:(BOOL)isEditing readOnly:(BOOL)readOnly
{
    self = [super init];
    if (self)
    {
        self.desc = desc ? desc : @"";
        _isNew = isNew;
        _readOnly = readOnly;
        _keyboardHeight = 0.0;
        _isEditing = isEditing || ((desc.length == 0) && !readOnly);
    }
    return self;
}

- (BOOL)isHtml:(NSString *)text
{
    BOOL res = NO;
    res = res || [text containsString:@"<html>"];
    res = res || [text containsString:@"<body>"];
    res = res || [text containsString:@"<div>"];
    res = res || [text containsString:@"<a>"];
    res = res || [text containsString:@"<p>"];
    res = res || [text containsString:@"<html "];
    res = res || [text containsString:@"<body "];
    res = res || [text containsString:@"<div "];
    res = res || [text containsString:@"<a "];
    res = res || [text containsString:@"<p "];
    res = res || [text containsString:@"<img "];
    return res;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [[UIView alloc] init];
    self.tableView.backgroundColor = UIColorFromRGB(color_bottom_sheet_background);
    
    [self setupView];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self registerForKeyboardNotifications];
    [self applySafeAreaMargins];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self unregisterKeyboardNotifications];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        if(!_isEditing)
        {
            _webViewHeight = 0.0;
            _webViewReloadingsCount = 0;
            [self generateData];
            [_tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        
    } completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(UIView *) getTopView
{
    return _toolbarView;
}

-(UIView *) getMiddleView
{
    return _tableView;
}

-(void)setupView
{
    [self generateData];
    if (_isEditing)
    {
        _titleView.text = OALocalizedString(@"context_menu_edit_descr");
        _saveButton.hidden = NO;
        _editButton.hidden = YES;
        _toolbarView.backgroundColor = UIColorFromRGB(color_bottom_sheet_background);
        _titleView.textColor = UIColor.blackColor;
        _saveButton.tintColor = UIColorFromRGB(color_primary_purple);
        _backButton.tintColor = UIColorFromRGB(color_primary_purple);
        [_backButton setTitle:@"" forState:UIControlStateNormal];
        [_backButton setImage:[UIImage templateImageNamed:@"ic_navbar_close"] forState:UIControlStateNormal];
    }
    else
    {
        _titleView.text = OALocalizedString(@"description");
        _editButton.hidden = _readOnly;
        _saveButton.hidden = YES;
        _toolbarView.backgroundColor = UIColorFromRGB(color_chart_orange);
        _titleView.textColor = UIColor.whiteColor;
        _editButton.tintColor = UIColor.whiteColor;
        [_editButton setImage:[UIImage templateImageNamed:@"ic_navbar_pencil"] forState:UIControlStateNormal];
        _backButton.tintColor = UIColor.whiteColor;
        [_backButton setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];
        [_backButton setImage:[UIImage templateImageNamed:@"ic_navbar_chevron"] forState:UIControlStateNormal];
        if ([self.view isDirectionRTL])
            _backButton.imageView.image = _backButton.imageView.image.imageFlippedForRightToLeftLayoutDirection;
    }
}

- (void) generateData
{
    if (_isEditing)
    {
        _cellsData = @[
            @{
                @"type" : [OATextViewSimpleCell getCellIdentifier],
                @"title" : self.desc,
                @"separatorInset" : @0
            }
        ];
    }
    else
    {
        NSString *textHtml = self.desc;
        if (![self isHtml:textHtml])
        {
            textHtml = [textHtml stringByReplacingOccurrencesOfString:@"\n" withString:@"<br/>"];
        }
        if (![textHtml containsString:@"<header"])
        {
            NSString *head = @"<header><meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no'><style> body { font-family: -apple-system; font-size: 17px; color:#000009} b {font-family: -apple-system; font-weight: bolder; font-size: 17px; color:#000000 }</style></header><head></head><div class=\"main\">%@</div>";
            textHtml = [NSString stringWithFormat:head, textHtml];
        }
        
        _cellsData = @[
            @{
                @"type" : [OAWebViewCell getCellIdentifier],
                @"title" : textHtml,
                @"separatorInset" : @(16 + OAUtilities.getLeftMargin)
            },
            @{
                @"type" : [OAIconTitleValueCell getCellIdentifier],
                @"title" : OALocalizedString(@"context_menu_edit_descr"),
                @"separatorInset" : @0
            }
        ];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return _isEditing ? UIStatusBarStyleBlackOpaque : UIStatusBarStyleLightContent;
}

// keyboard notifications register+process
- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillChangeFrame:)
                                                 name:UIKeyboardWillChangeFrameNotification object:nil];
    
}

- (void)unregisterKeyboardNotifications
{
    //unregister the keyboard notifications while not visible
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWillShow:(NSNotification*)aNotification
{
     CGRect keyboardFrame = [[[aNotification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
     CGRect convertedFrame = [self.view convertRect:keyboardFrame fromView:self.view.window];

    _keyboardHeight = convertedFrame.size.height;
    [self forceUpdateLayout];
}

- (void)keyboardWillChangeFrame:(NSNotification*)aNotification
{
    CGRect keyboardFrame = [[[aNotification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    CGRect convertedFrame = [self.view convertRect:keyboardFrame fromView:self.view.window];
    
    _keyboardHeight = convertedFrame.size.height;
    [self forceUpdateLayout];
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    [self forceUpdateLayout];
}

- (void)forceUpdateLayout
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:.3 animations:^{
            [self.view setNeedsLayout];
        }];
    });
}

#pragma mark - Actions

- (IBAction)saveClicked:(id)sender
{
    self.desc = _textViewContent;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(descriptionChanged)])
        [self.delegate descriptionChanged];
    
    [self backButtonClicked:self];
}

- (IBAction)editClicked:(id)sender
{
    _isEditing = YES;
    [self setupView];
    [_tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _cellsData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _cellsData[indexPath.row];
    
    if ([item[@"type"] isEqualToString:[OATextViewSimpleCell getCellIdentifier]])
    {
        OATextViewSimpleCell *cell = [tableView dequeueReusableCellWithIdentifier:[OATextViewSimpleCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATextViewSimpleCell getCellIdentifier] owner:self options:nil];
            cell = (OATextViewSimpleCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            NSNumber *inset = item[@"separatorInset"];
            cell.separatorInset = UIEdgeInsetsMake(0, inset.floatValue, 0, 0);
            cell.textView.delegate = self;
            cell.textView.text = item[@"title"];
            cell.textView.font = [UIFont systemFontOfSize:16];
            [cell.textView sizeToFit];
            cell.textView.editable = YES;
            [cell.textView becomeFirstResponder];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OAWebViewCell getCellIdentifier]])
    {
        OAWebViewCell* cell;
        cell = (OAWebViewCell *)[tableView dequeueReusableCellWithIdentifier:[OAWebViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAWebViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAWebViewCell *)[nib objectAtIndex:0];
        }
        if (cell)
        {
            NSNumber *inset = item[@"separatorInset"];
            cell.separatorInset = UIEdgeInsetsMake(0, inset.floatValue, 0, 0);
            cell.iconView.hidden = YES;
            cell.arrowIconView.hidden = YES;
            cell.webViewLeftConstraint.constant = 0;
            cell.webViewRightConstraint.constant = 0;
            cell.backgroundColor = UIColor.whiteColor;
            cell.webView.navigationDelegate = self;
            [cell.webView loadHTMLString:item[@"title"]  baseURL:nil];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OAIconTitleValueCell getCellIdentifier]])
    {
        OAIconTitleValueCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAIconTitleValueCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTitleValueCell getCellIdentifier] owner:self options:nil];
            cell = (OAIconTitleValueCell *) nib[0];
            [cell showLeftIcon:NO];
            [cell showRightIcon:NO];
        }
        if (cell)
        {
            NSNumber *inset = item[@"separatorInset"];
            cell.separatorInset = UIEdgeInsetsMake(0, inset.floatValue, 0, 0);
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            cell.textView.font = [UIFont systemFontOfSize:17. weight:UIFontWeightMedium];
            cell.textView.textColor = UIColorFromRGB(color_primary_purple);
            cell.textView.text = item[@"title"];
            cell.descriptionView.hidden = YES;
        }
        return cell;
    }

    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _cellsData[indexPath.row];
    if ([item[@"type"] isEqualToString:[OAWebViewCell getCellIdentifier]])
        return _webViewHeight;
    return UITableViewAutomaticDimension;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _cellsData[indexPath.row];
    if ([item[@"type"] isEqualToString:[OAIconTitleValueCell getCellIdentifier]])
        [self editClicked:nil];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView
{
    _textViewContent = textView.text;
    [_tableView beginUpdates];
    [_tableView endUpdates];
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    BOOL shouldSkipFirstLoadingWithIncorrectData = _webViewReloadingsCount == 0;
    BOOL isEmptyResponce = webView.scrollView.contentSize.height == 0 && webView.scrollView.contentSize.width;
    BOOL isLayoutReady = webView.scrollView.contentSize.width == (self.tableView.frame.size.width - 2*OAUtilities.getLeftMargin);
    BOOL isValuesStopChanging = _webViewHeight == webView.scrollView.contentSize.height;
    
    _webViewReloadingsCount++;
    if (shouldSkipFirstLoadingWithIncorrectData || isEmptyResponce || !isLayoutReady || !isValuesStopChanging)
    {
        _webViewHeight = webView.scrollView.contentSize.height;
        [_tableView reloadData];
    }
    else
    {
        //correct value. don't reload again
    }
}

@end

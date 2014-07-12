//
//  OAManageFavoritesViewController.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/10/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAManageFavoritesViewController.h"

#import <QuickDialog.h>
#import <QEmptyListElement.h>
#import <UIAlertView+Blocks.h>

#import "OsmAndApp.h"
#import "OAEditFavoriteViewController.h"
#import "OAQuickDialogTableDelegate.h"
#import "QuickDialogTableView+ElementByIndexAccessor.h"
#include "Localization.h"

#include <OsmAndCore.h>
#include <OsmAndCore/IFavoriteLocation.h>
#include <OsmAndCore/Utilities.h>

#define _(name) OAManageFavoritesViewController__##name

#define GroupItemData _(GroupItemData)
@interface GroupItemData : NSObject
@property NSString* groupName;
@property QList< std::shared_ptr<OsmAnd::IFavoriteLocation> > favorites;
@end
@implementation GroupItemData
@end

#define FavoriteItemData _(FavoriteItemData)
@interface FavoriteItemData : NSObject
@property std::shared_ptr<OsmAnd::IFavoriteLocation> favorite;
@end
@implementation FavoriteItemData
@end

@interface OAManageFavoritesViewController () <UIDocumentInteractionControllerDelegate>
@end

@implementation OAManageFavoritesViewController
{
    OsmAndAppInstance _app;

    NSArray* _editToolbarItems;
    UIDocumentInteractionController* _exportController;
}

- (instancetype)init
{
    OsmAndAppInstance app = [OsmAndApp instance];

    const auto allFavorites = app.favoritesCollection->getFavoriteLocations();
    QHash< QString, QList< std::shared_ptr<OsmAnd::IFavoriteLocation> > > groupedFavorites;
    QList< std::shared_ptr<OsmAnd::IFavoriteLocation> > ungroupedFavorites;
    QSet<QString> groupNames;
    for(const auto& favorite : allFavorites)
    {
        const auto& groupName = favorite->getGroup();
        if (groupName.isEmpty())
            ungroupedFavorites.push_back(favorite);
        else
        {
            groupNames.insert(groupName);
            groupedFavorites[groupName].push_back(favorite);
        }
    }

    QRootElement* rootElement = [[QRootElement alloc] init];
    rootElement.title = OALocalizedString(@"My favorites");
    rootElement.grouped = YES;
    rootElement.appearance.entryAlignment = NSTextAlignmentRight;

    if (!groupNames.isEmpty())
    {
        QSection* groupsSection = [[QSection alloc] initWithTitle:OALocalizedString(@"Groups")];
        [rootElement addSection:groupsSection];

        for (const auto& groupName : groupNames)
        {
            GroupItemData* itemData = [[GroupItemData alloc] init];
            itemData.groupName = groupName.toNSString();
            itemData.favorites = groupedFavorites[groupName];

            QLabelElement* groupElement = [[QLabelElement alloc] initWithTitle:itemData.groupName
                                                                         Value:nil];
            groupElement.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            groupElement.keepSelected = NO;
            groupElement.controllerAction = NSStringFromSelector(@selector(onManageGroup:));
            groupElement.object = itemData;
            [groupsSection addElement:groupElement];
        }

        // Sort by title
        [groupsSection.elements sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            QLabelElement* element1 = (QLabelElement*)obj1;
            QLabelElement* element2 = (QLabelElement*)obj2;

            return [element1.title localizedCaseInsensitiveCompare:element2.title];
        }];
    }

    if (!ungroupedFavorites.isEmpty())
    {
        QSection* ungroupedFavoritesSection = [[QSection alloc] initWithTitle:OALocalizedString(@"Favorites")];
        ungroupedFavoritesSection.canDeleteRows = YES;
        [rootElement addSection:ungroupedFavoritesSection];

        for (const auto& favorite : ungroupedFavorites)
        {
            FavoriteItemData* itemData = [[FavoriteItemData alloc] init];
            itemData.favorite = favorite;

            QLabelElement* favoriteElement = [[QLabelElement alloc] initWithTitle:favorite->getTitle().toNSString()
                                                                            Value:nil];
            favoriteElement.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            favoriteElement.controllerAction = NSStringFromSelector(@selector(onEditFavorite:));
            favoriteElement.object = itemData;
            [ungroupedFavoritesSection addElement:favoriteElement];
        }

        // Sort by title
        [ungroupedFavoritesSection.elements sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            QLabelElement* element1 = (QLabelElement*)obj1;
            QLabelElement* element2 = (QLabelElement*)obj2;

            return [element1.title localizedCaseInsensitiveCompare:element2.title];
        }];
    }

    if ([rootElement.sections count] == 0)
    {
        QSection* fakeSection = [[QSection alloc] init];
        [rootElement addSection:fakeSection];

        QEmptyListElement* emptyListElement = [[QEmptyListElement alloc] initWithTitle:OALocalizedString(@"You haven't saved any favorites yet")
                                                                                 Value:nil];
        [fakeSection addElement:emptyListElement];
    }

    self = [super initWithRoot:rootElement];
    if (self) {
        _app = app;

        [self inflateEditToolbarItems];
    }
    return self;
}

- (instancetype)initWithGroupTitle:(NSString*)groupTitle andFavorites:(const QList< std::shared_ptr<OsmAnd::IFavoriteLocation> >&)favorites
{
    OsmAndAppInstance app = [OsmAndApp instance];

    QRootElement* rootElement = [[QRootElement alloc] init];
    rootElement.title = groupTitle;
    rootElement.grouped = YES;
    rootElement.appearance.entryAlignment = NSTextAlignmentRight;

    QSection* favoritesSection = [[QSection alloc] initWithTitle:OALocalizedString(@"Favorites")];
    favoritesSection.canDeleteRows = YES;
    [rootElement addSection:favoritesSection];

    for (const auto& favorite : favorites)
    {
        FavoriteItemData* itemData = [[FavoriteItemData alloc] init];
        itemData.favorite = favorite;

        QLabelElement* favoriteElement = [[QLabelElement alloc] initWithTitle:favorite->getTitle().toNSString()
                                                                        Value:nil];
        favoriteElement.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        favoriteElement.controllerAction = NSStringFromSelector(@selector(onEditFavorite:));
        favoriteElement.object = itemData;
        [favoritesSection addElement:favoriteElement];
    }

    // Sort by title
    [favoritesSection.elements sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        QLabelElement* element1 = (QLabelElement*)obj1;
        QLabelElement* element2 = (QLabelElement*)obj2;

        return [element1.title localizedCaseInsensitiveCompare:element2.title];
    }];

    self = [super initWithRoot:rootElement];
    if (self) {
        _app = app;

        [self inflateEditToolbarItems];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Create own deletage
    self.quickDialogTableView.quickDialogTableDelegate = [[OAQuickDialogTableDelegate alloc] initForTableView:self.quickDialogTableView];
    self.quickDialogTableView.delegate = self.quickDialogTableView.quickDialogTableDelegate;

    // Configure
    self.quickDialogTableView.allowsSelectionDuringEditing = YES;

    // Initially disable edit mode
    [self setEditing:NO
            animated:NO];
}

- (void)inflateEditToolbarItems
{
    _editToolbarItems = @[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                        target:nil
                                                                        action:nil],
                          [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                        target:self
                                                                        action:@selector(onShareSelected)],
                          [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                        target:nil
                                                                        action:nil],
                          [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
                                                                        target:self
                                                                        action:@selector(onDeleteSelected)],
                          [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                        target:nil
                                                                        action:nil]];
}

- (void)updateMode
{
    if (!self.quickDialogTableView.isEditing)
    {
        // Add navbar item to select multiple elements
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:OALocalizedString(@"Select")
                                                                                  style:UIBarButtonItemStylePlain
                                                                                 target:self
                                                                                 action:@selector(onEnterMultipleSelectionMode)];
    }
    else
    {
        // Add navbar item to cancel selectino mode
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                 target:self
                                                                                 action:@selector(onExitMultipleSelectionMode)];

    }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing
             animated:animated];

    self.toolbarItems = editing ? _editToolbarItems : nil;
    [self.navigationController setToolbarHidden:!editing
                                       animated:animated];

    [self updateMode];
}

- (void)onEnterMultipleSelectionMode
{
    [self setEditing:YES
            animated:YES];
}

- (void)onExitMultipleSelectionMode
{
    [self setEditing:NO
            animated:YES];
}

- (void)onShareSelected
{
    NSArray* selectedCells = [self.quickDialogTableView indexPathsForSelectedRows];
    if ([selectedCells count] == 0)
        return;

    NSArray* selectedElements = [self.quickDialogTableView elementsForIndexPaths:selectedCells];
    if ([selectedElements count] == 0)
        return;

    std::shared_ptr<OsmAnd::FavoriteLocationsGpxCollection> exportCollection(new OsmAnd::FavoriteLocationsGpxCollection());
    for (QElement* element in selectedElements)
    {
        if ([element.object isKindOfClass:[FavoriteItemData class]])
        {
            FavoriteItemData* favoriteItemData = (FavoriteItemData*)element.object;

            exportCollection->copyFavoriteLocation(favoriteItemData.favorite);
        }
        else if ([element.object isKindOfClass:[GroupItemData class]])
        {
            GroupItemData* groupItemData = (GroupItemData*)element.object;

            exportCollection->mergeFrom(groupItemData.favorites);
        }
    }
    if (exportCollection->getFavoriteLocationsCount() == 0)
        return;

    NSString* tempFilename = [NSTemporaryDirectory() stringByAppendingString:@"exported_favorites.gpx"];
    if (!exportCollection->saveTo(QString::fromNSString(tempFilename)))
        return;

    NSURL* favoritesUrl = [NSURL fileURLWithPath:tempFilename];
    _exportController = [UIDocumentInteractionController interactionControllerWithURL:favoritesUrl];
    _exportController.UTI = @"net.osmand.gpx";
    _exportController.delegate = self;
    _exportController.name = OALocalizedString(@"Exported favorites.gpx");
    [_exportController presentOptionsMenuFromRect:CGRectZero
                                           inView:self.view
                                         animated:YES];
}

- (void)onDeleteSelected
{
    NSArray* selectedCells = [self.quickDialogTableView indexPathsForSelectedRows];
    if ([selectedCells count] == 0)
        return;

    NSArray* selectedElements = [self.quickDialogTableView elementsForIndexPaths:selectedCells];
    if ([selectedElements count] == 0)
        return;

    QList< std::shared_ptr<OsmAnd::IFavoriteLocation> > toBeRemoved;
    for (QElement* element in selectedElements)
    {
        if ([element.object isKindOfClass:[FavoriteItemData class]])
        {
            FavoriteItemData* favoriteItemData = (FavoriteItemData*)element.object;

            toBeRemoved.push_back(favoriteItemData.favorite);
        }
        else if ([element.object isKindOfClass:[GroupItemData class]])
        {
            GroupItemData* groupItemData = (GroupItemData*)element.object;

            toBeRemoved.append(groupItemData.favorites);
        }
    }
    if (toBeRemoved.isEmpty())
        return;

    [[[UIAlertView alloc] initWithTitle:OALocalizedString(@"Confirmation")
                                message:OALocalizedString(@"Do you want to delete selected favorites?")
                       cancelButtonItem:[RIButtonItem itemWithLabel:OALocalizedString(@"No")
                                                             action:^{
                                                             }]
                       otherButtonItems:[RIButtonItem itemWithLabel:OALocalizedString(@"Yes")
                                                             action:^{
                                                                 _app.favoritesCollection->removeFavoriteLocations(toBeRemoved);
                                                                 [_app saveFavoritesToPermamentStorage];
                                                             }], nil] show];
}

- (void)onManageGroup:(QElement*)sender
{
    if (self.quickDialogTableView.isEditing)
        return;

    GroupItemData* itemData = (GroupItemData*)sender.object;

    UIViewController* manageGroupVC = [[OAManageFavoritesViewController alloc] initWithGroupTitle:itemData.groupName
                                                                                     andFavorites:itemData.favorites];
    [self.navigationController pushViewController:manageGroupVC
                                         animated:YES];
}

- (void)onEditFavorite:(QElement*)sender
{
    if (self.quickDialogTableView.isEditing)
        return;

    FavoriteItemData* itemData = (FavoriteItemData*)sender.object;

    [self.navigationController pushViewController:[[OAEditFavoriteViewController alloc] initWithFavorite:itemData.favorite]
                                         animated:YES];
}

#pragma mark - UIDocumentInteractionControllerDelegate

- (void)documentInteractionControllerDidDismissOptionsMenu:(UIDocumentInteractionController *)controller
{
    if (controller == _exportController)
        _exportController = nil;
}

- (void)documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *)controller
{
    if (controller == _exportController)
        _exportController = nil;
}

#pragma mark -

@end

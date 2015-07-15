//
//  OAGPXRouteDocument.m
//  OsmAnd
//
//  Created by Alexey Kulish on 02/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAGPXRouteDocument.h"
#import "OAGpxRoutePoint.h"
#import "OAGpxRouteWptItem.h"
#import "OsmAndApp.h"

#include <OsmAndCore/GeoInfoDocument.h>
#include <OsmAndCore/GpxDocument.h>
#include <OsmAndCore/Utilities.h>

@implementation OAGPXRouteDocument
{
    std::shared_ptr<OsmAnd::GpxDocument> document;
}

- (BOOL) loadFrom:(NSString *)filename
{
    _syncObj = [[NSObject alloc] init];
    
    document = OsmAnd::GpxDocument::loadFrom(QString::fromNSString(filename));
    return [self fetch:document];
}

- (const std::shared_ptr<OsmAnd::GpxDocument>&) getDocument
{
    return document;
}

-(BOOL)fetch:(std::shared_ptr<OsmAnd::GpxDocument>)gpxDocument
{
    BOOL res = [super fetch:gpxDocument];
    
    if (res)
        [self loadData];
    
    return res;
}

+ (OAGpxWpt *)fetchWpt:(const std::shared_ptr<const OsmAnd::GpxDocument::GpxWpt>)mark
{
    OAGpxWpt* wpt = [super fetchWpt:mark];
    std::shared_ptr<OsmAnd::GpxDocument::GpxWpt> m = std::const_pointer_cast<OsmAnd::GpxDocument::GpxWpt>(mark);
    wpt.wpt = m;
    
    OAGpxRoutePoint *rp = [[OAGpxRoutePoint alloc] initWithWpt:wpt];
    
    return rp;
}

- (BOOL) saveTo:(NSString *)filename
{
    for (OAGpxRoutePoint *rp in self.locationMarks)
        [rp applyRouteInfo];
    
    return document->saveTo(QString::fromNSString(filename));
}

- (BOOL) clearAndSaveTo:(NSString *)filename
{
    [self clearRouteTrack];
    
    for (OAGpxRoutePoint *rp in self.locationMarks)
        [rp clearRouteInfo];

    return document->saveTo(QString::fromNSString(filename));
}

- (void)buildRouteTrack
{
    NSMutableArray *tracks = (NSMutableArray *)self.tracks;
    if (!tracks)
    {
        tracks = [NSMutableArray array];
        self.tracks = tracks;
    }
    
    OAGpxTrk *track;
    for (OAGpxTrk *t in tracks)
    {
        if ([t.name isEqualToString:@"routeHelperTrack"])
        {
            track = t;
            break;
        }
    }
    
    if (!track)
    {
        track = [[OAGpxTrk alloc] init];
        track.name = @"routeHelperTrack";
        [tracks addObject:track];
    }
    
    NSArray *rps = [self.locationMarks sortedArrayUsingComparator:^NSComparisonResult(OAGpxRoutePoint *rp1, OAGpxRoutePoint *rp2)
    {
        if (rp2.index > rp1.index)
            return NSOrderedAscending;
        else if (rp2.index < rp1.index)
            return NSOrderedDescending;
        else
            return NSOrderedSame;
    }];
    
    
    OAGpxTrkSeg *seg = [[OAGpxTrkSeg alloc] init];
    NSMutableArray *points = [NSMutableArray array];
    for (OAGpxRoutePoint *rp in rps)
    {
        if (rp.disabled || rp.visited)
            continue;
        
        OAGpxTrkPt *p = [[OAGpxTrkPt alloc] init];
        p.position = rp.position;
        [points addObject:p];
    }
    seg.points = points;
    track.segments = @[seg];
    
    std::shared_ptr<OsmAnd::GpxDocument::GpxTrk> trk;
    trk.reset(new OsmAnd::GpxDocument::GpxTrk());
    [self.class fillTrack:trk usingTrack:track];
    track.trk = trk;
    
    for (auto& t : document->tracks)
    {
        if (t->name == QString("routeHelperTrack"))
        {
            t = trk;
            document->tracks.removeOne(t);
            break;
        }
    }
    
    document->tracks.append(trk);
}

- (void)clearRouteTrack
{
    NSMutableArray *tracks = (NSMutableArray *)self.tracks;
    
    for (OAGpxTrk *t in tracks)
    {
        if ([t.name isEqualToString:@"routeHelperTrack"])
        {
            [tracks removeObject:t];
            break;
        }
    }
    
    for (auto& t : document->tracks)
    {
        if (t->name == QString("routeHelperTrack"))
        {
            document->tracks.removeOne(t);
            break;
        }
    }
}

- (void)loadData
{
    self.groups = [self readGroups];
    
    NSMutableArray *arr = [NSMutableArray array];
    for (OAGpxRoutePoint *p in self.locationMarks) {
        OAGpxRouteWptItem *item = [[OAGpxRouteWptItem alloc] init];
        item.point = p;
        [arr addObject:item];
    }
    
    self.locationPoints = [NSMutableArray arrayWithArray:
                           [arr sortedArrayUsingComparator:^NSComparisonResult(OAGpxRouteWptItem *item1, OAGpxRouteWptItem *item2)
                            {
                                if (item2.point.index > item1.point.index)
                                    return NSOrderedAscending;
                                else if (item2.point.index < item1.point.index)
                                    return NSOrderedDescending;
                                else
                                    return NSOrderedSame;
                            }]];
    
    [self buildActiveInactive];
    
    [self updateDistances];
}

- (void)buildActiveInactive
{
    @synchronized(self.syncObj)
    {
        self.activePoints = [NSMutableArray array];
        self.inactivePoints = [NSMutableArray array];
        
        for (OAGpxRouteWptItem* item in self.locationPoints)
        {
            if (item.point.disabled || item.point.visited)
                [self.inactivePoints addObject:item];
            else
                [self.activePoints addObject:item];
        }
    }
}

- (NSArray *)readGroups
{
    NSMutableSet *groups = [NSMutableSet set];
    for (OAGpxRoutePoint *item in self.locationMarks)
    {
        if (item.type.length > 0)
            [groups addObject:item.type];
    }

    return [[groups allObjects] sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        return [obj1 localizedCompare:obj2];
    }];
}

- (void)updateDistances
{
    @synchronized(self.syncObj)
    {
        double tDistance = 0.0;
        
        OAGpxRouteWptItem* prevItemData;
        for (OAGpxRouteWptItem* itemData in self.activePoints)
        {
            if (prevItemData)
            {
                const auto distance = OsmAnd::Utilities::distance(itemData.point.position.longitude,
                                                                  itemData.point.position.latitude,
                                                                  prevItemData.point.position.longitude, prevItemData.point.position.latitude);
                
                itemData.distance = [[OsmAndApp instance] getFormattedDistance:distance];
                itemData.distanceMeters = distance;
                itemData.direction = 0.0;
                
                tDistance += distance;
            }
            prevItemData = itemData;
        }
        
        _totalDistance = tDistance;
    }
}

- (void)updateDirections:(CLLocationDirection)newDirection myLocation:(CLLocationCoordinate2D)myLocation
{
    @synchronized(self.syncObj)
    {
        [self.locationPoints enumerateObjectsUsingBlock:^(OAGpxRouteWptItem* itemData, NSUInteger idx, BOOL *stop)
         {
             if (![self.activePoints containsObject:itemData] || (self.activePoints.count > 0 && self.activePoints[0] == itemData))
             {
                 OsmAnd::LatLon latLon(itemData.point.position.latitude, itemData.point.position.longitude);
                 const auto& wptPosition31 = OsmAnd::Utilities::convertLatLonTo31(latLon);
                 const auto wptLon = OsmAnd::Utilities::get31LongitudeX(wptPosition31.x);
                 const auto wptLat = OsmAnd::Utilities::get31LatitudeY(wptPosition31.y);
                 
                 const auto distance = OsmAnd::Utilities::distance(myLocation.longitude,
                                                                   myLocation.latitude,
                                                                   wptLon, wptLat);
                 
                 itemData.distance = [[OsmAndApp instance] getFormattedDistance:distance];
                 itemData.distanceMeters = distance;
                 CGFloat itemDirection = [[OsmAndApp instance].locationServices radiusFromBearingToLocation:[[CLLocation alloc] initWithLatitude:wptLat longitude:wptLon]];
                 itemData.direction = OsmAnd::Utilities::normalizedAngleDegrees(itemDirection - newDirection) * (M_PI / 180);
             }
             
         }];
    }
}

- (NSArray *)getWaypointsByGroup:(NSString *)groupName activeOnly:(BOOL)activeOnly
{
    @synchronized(self.syncObj)
    {
        NSMutableArray *res = [NSMutableArray array];
        
        NSArray *source;
        if (activeOnly)
            source = self.activePoints;
        else
            source = self.locationPoints;
        
        for (OAGpxRouteWptItem* item in source)
        {
            if ([item.point.type isEqualToString:groupName])
                [res addObject:item];
        }
        
        return [NSArray arrayWithArray:res];
    }
}

- (void)includeGroupToRouting:(NSString *)groupName
{
    @synchronized(self.syncObj)
    {
        for (OAGpxRouteWptItem* item in self.locationPoints)
        {
            if ([item.point.type isEqualToString:groupName])
            {
                item.point.disabled = NO;
                item.point.visited = NO;
            }
        }
    }
    
    [self buildActiveInactive];
}

- (void)excludeGroupFromRouting:(NSString *)groupName
{
    @synchronized(self.syncObj)
    {
        for (OAGpxRouteWptItem* item in self.locationPoints)
        {
            if ([item.point.type isEqualToString:groupName])
            {
                item.point.disabled = YES;
            }
        }
    }

    [self buildActiveInactive];
}

@end

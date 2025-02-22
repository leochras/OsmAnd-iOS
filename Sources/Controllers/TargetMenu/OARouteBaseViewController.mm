//
//  OARouteBaseViewController.m
//  OsmAnd
//
//  Created by Paul on 28.01.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OARouteBaseViewController.h"
#import "Localization.h"
#import "OARootViewController.h"
#import "OAColors.h"
#import "OARoutingHelper.h"
#import "OAGPXTrackAnalysis.h"
#import "OANativeUtilities.h"
#import "OAGPXDocument.h"
#import "OAGPXUIHelper.h"
#import "OAMapLayers.h"
#import "OARouteStatisticsHelper.h"
#import "OAMapRendererView.h"
#import "OARouteStatisticsModeCell.h"
#import "OATransportRoutingHelper.h"
#import "OAOsmAndFormatter.h"
#import "OAGPXDatabase.h"

#import "OsmAnd_Maps-Swift.h"
#import <Charts/Charts-Swift.h>

@implementation OARouteLineChartHelper
{
    OAGPXDocument *_gpxDoc;
    OARouteLineChartCenterMapOnBBox _centerMapOnBBox;
    OARouteLineChartAdjustViewPort _adjustViewPort;
}

- (instancetype)initWithGpxDoc:(OAGPXDocument *)gpxDoc
               centerMapOnBBox:(OARouteLineChartCenterMapOnBBox)centerMapOnBBox
                adjustViewPort:(OARouteLineChartAdjustViewPort)adjustViewPort
{
    self = [super init];
    if (self)
    {
        _gpxDoc = gpxDoc;
        _centerMapOnBBox = centerMapOnBBox;
        _adjustViewPort = adjustViewPort;
    }
    return self;
}

- (void)changeChartMode:(EOARouteStatisticsMode)mode
                  chart:(LineChartView *)chart
               analysis:(OAGPXTrackAnalysis *)analysis
               modeCell:(OARouteStatisticsModeCell *)statsModeCell
{
    ChartYAxisCombinedRenderer *renderer = (ChartYAxisCombinedRenderer *) chart.rightYAxisRenderer;
    switch (mode)
    {
        case EOARouteStatisticsModeAltitudeSlope:
        {
            if (statsModeCell)
            {
                [statsModeCell.modeButton setTitle:[NSString stringWithFormat:@"%@/%@",
                                        OALocalizedString(@"map_widget_altitude"),
                                        OALocalizedString(@"gpx_slope")]
                                          forState:UIControlStateNormal];
            }
            [GpxUIHelper refreshLineChartWithChartView:chart
                                              analysis:analysis
                                   useGesturesAndScale:YES
                                             firstType:GPXDataSetTypeALTITUDE
                                            secondType:GPXDataSetTypeSLOPE];
            renderer.renderingMode = YAxisCombinedRenderingModeBothValues;
            break;
        }
        case EOARouteStatisticsModeAltitudeSpeed:
        {
            if (analysis.isSpeedSpecified)
            {
                if (statsModeCell)
                {
                    [statsModeCell.modeButton setTitle:[NSString stringWithFormat:@"%@/%@",
                                            OALocalizedString(@"map_widget_altitude"),
                                            OALocalizedString(@"gpx_speed")]
                                              forState:UIControlStateNormal];
                }
                [GpxUIHelper refreshLineChartWithChartView:chart
                                                  analysis:analysis
                                       useGesturesAndScale:YES
                                                 firstType:GPXDataSetTypeALTITUDE
                                                secondType:GPXDataSetTypeSPEED];
                renderer.renderingMode = YAxisCombinedRenderingModeBothValues;
            }
            else
            {
                [self changeChartMode:EOARouteStatisticsModeAltitude
                                chart:chart
                             analysis:analysis
                             modeCell:statsModeCell];
            }
            break;
        }
        case EOARouteStatisticsModeAltitude:
        {
            if (statsModeCell)
                [statsModeCell.modeButton setTitle:OALocalizedString(@"map_widget_altitude") forState:UIControlStateNormal];
            [GpxUIHelper refreshLineChartWithChartView:chart
                                              analysis:analysis
                                   useGesturesAndScale:YES
                                             firstType:GPXDataSetTypeALTITUDE
                                          useRightAxis:YES];
            renderer.renderingMode = YAxisCombinedRenderingModeSecondaryValueOnly;
            break;
        }
        case EOARouteStatisticsModeSlope:
        {
            if (statsModeCell)
                [statsModeCell.modeButton setTitle:OALocalizedString(@"gpx_slope") forState:UIControlStateNormal];
            [GpxUIHelper refreshLineChartWithChartView:chart
                                              analysis:analysis
                                   useGesturesAndScale:YES
                                             firstType:GPXDataSetTypeSLOPE
                                          useRightAxis:YES];
            renderer.renderingMode = YAxisCombinedRenderingModePrimaryValueOnly;
            break;
        }
        case EOARouteStatisticsModeSpeed:
        {
            if (statsModeCell)
                [statsModeCell.modeButton setTitle:OALocalizedString(@"gpx_speed") forState:UIControlStateNormal];
            [GpxUIHelper refreshLineChartWithChartView:chart
                                              analysis:analysis
                                   useGesturesAndScale:YES
                                             firstType:GPXDataSetTypeSPEED
                                          useRightAxis:YES];
            renderer.renderingMode = YAxisCombinedRenderingModePrimaryValueOnly;
            break;
        }
        default:
            break;
    }
    [chart notifyDataSetChanged];
}

- (void)refreshHighlightOnMap:(BOOL)forceFit
                lineChartView:(LineChartView *)lineChartView
             trackChartPoints:(OATrackChartPoints *)trackChartPoints
                     analysis:(OAGPXTrackAnalysis *)analysis
{
    OATrkSegment *segment = [self getTrackSegment:lineChartView analysis:analysis];
    [self refreshHighlightOnMap:forceFit
                  lineChartView:lineChartView
               trackChartPoints:trackChartPoints
                        segment:segment];
}

- (void)refreshHighlightOnMap:(BOOL)forceFit
                lineChartView:(LineChartView *)lineChartView
             trackChartPoints:(OATrackChartPoints *)trackChartPoints
                      segment:(OATrkSegment *)segment
{
    if (!_gpxDoc)
        return;

    NSArray<ChartHighlight *> *highlights = lineChartView.highlighted;
    CLLocationCoordinate2D location = kCLLocationCoordinate2DInvalid;
    OAMapViewController *mapViewController = [OARootViewController instance].mapPanel.mapViewController;
    [mapViewController.mapLayers.routeMapLayer showCurrentStatisticsLocation:trackChartPoints];

    double minimumVisibleXValue = lineChartView.lowestVisibleX;
    double maximumVisibleXValue = lineChartView.highestVisibleX;

    double highlightPosition = -1;

    if (highlights.count > 0)
    {
        ChartHighlight *highlight = highlights.firstObject;
        if (minimumVisibleXValue != 0 && maximumVisibleXValue != 0)
        {
            if (highlight.x < minimumVisibleXValue && highlight.x != lineChartView.chartXMin)
            {
                double difference = (maximumVisibleXValue - minimumVisibleXValue) * 0.1;
                highlightPosition = minimumVisibleXValue + difference;
            }
            else if (highlight.x > maximumVisibleXValue)
            {
                double difference = (maximumVisibleXValue - minimumVisibleXValue) * 0.1;
                highlightPosition = maximumVisibleXValue - difference;
            }
            else
            {
                highlightPosition = highlight.x;
            }
        }
        else
        {
            highlightPosition = highlight.x;
        }
        location = [self getLocationAtPos:highlightPosition
                            lineChartView:lineChartView
                                  segment:segment];
        if (CLLocationCoordinate2DIsValid(location))
            trackChartPoints.highlightedPoint = location;
    }

    trackChartPoints.axisPointsInvalidated = forceFit;
    trackChartPoints.xAxisPoints = [self getXAxisPoints:trackChartPoints lineChartView:lineChartView segment:segment];

    [mapViewController.mapLayers.routeMapLayer showCurrentStatisticsLocation:trackChartPoints];
    [self fitTrackOnMap:location
               forceFit:forceFit
          lineChartView:lineChartView
                segment:segment];
}

- (OATrackChartPoints *)generateTrackChartPoints:(LineChartView *)lineChartView
                                        analysis:(OAGPXTrackAnalysis *)analysis
{
    OATrkSegment *segment = [self getTrackSegment:lineChartView analysis:analysis];
    return [self generateTrackChartPoints:lineChartView startPoint:kCLLocationCoordinate2DInvalid segment:segment];
}

- (OATrackChartPoints *)generateTrackChartPoints:(LineChartView *)lineChartView
                                      startPoint:(CLLocationCoordinate2D)startPoint
                                        segment:(OATrkSegment *)segment
{
    OATrackChartPoints *trackChartPoints = [[OATrackChartPoints alloc] init];
    trackChartPoints.segmentColor = -1;
    trackChartPoints.gpx = _gpxDoc;
    trackChartPoints.axisPointsInvalidated = YES;
    trackChartPoints.xAxisPoints = [self getXAxisPoints:trackChartPoints lineChartView:lineChartView segment:segment];
    if (CLLocationCoordinate2DIsValid(startPoint))
        trackChartPoints.highlightedPoint = startPoint;

    return trackChartPoints;
}

- (NSArray<CLLocation *> *)getXAxisPoints:(OATrackChartPoints *)points
                            lineChartView:(LineChartView *)lineChartView
                                  segment:(OATrkSegment *)segment
{
    if (!points.axisPointsInvalidated)
        return points.xAxisPoints;

    NSMutableArray<CLLocation *> *result = [NSMutableArray new];
    NSArray<NSNumber *> *entries = lineChartView.xAxis.entries;
    LineChartData *lineData = lineChartView.lineData;
    double maxXValue = lineData ? lineData.xMax : -1;
    if (entries.count >= 2 && lineData)
    {
        double interval = entries[1].doubleValue - entries[0].doubleValue;
        if (interval > 0)
        {
            double currentPointEntry = interval;
            while (currentPointEntry < maxXValue)
            {
                CLLocationCoordinate2D location = [self getLocationAtPos:currentPointEntry
                                                           lineChartView:lineChartView
                                                                 segment:segment];
                if (CLLocationCoordinate2DIsValid(location))
                    [result addObject:[[CLLocation alloc] initWithLatitude:location.latitude longitude:location.longitude]];

                currentPointEntry += interval;
            }
        }
    }
    return result;
}

+ (OATrkSegment *)getSegmentForAnalysis:(OAGPXDocument *)gpxDoc analysis:(OAGPXTrackAnalysis *)analysis
{
    for (OATrack *track in gpxDoc.tracks)
    {
        for (OATrkSegment *segment in track.segments)
        {
            NSInteger size = segment.points.count;
            if (size > 0 && [segment.points.firstObject isEqual:analysis.locationStart]
                    && [segment.points[size - 1] isEqual:analysis.locationEnd])
                return segment;
        }
    }
    return nil;
}

- (OATrkSegment *)getTrackSegment:(LineChartView *)chart analysis:(OAGPXTrackAnalysis *)analysis
{
    OATrkSegment *segment;
    LineChartData *lineData = chart.lineData;
    NSArray<id <IChartDataSet>> *ds = lineData ? lineData.dataSets : [NSArray array];

    if (ds && ds.count > 0)
        segment = [self.class getSegmentForAnalysis:_gpxDoc analysis:analysis];

    return segment;
}

- (CLLocationCoordinate2D)getLocationAtPos:(double)position
                             lineChartView:(LineChartView *)lineChartView
                                   segment:(OATrkSegment *)segment
{
    LineChartData *data = lineChartView.lineData;
    NSArray<id<IChartDataSet>> *dataSets = data ? data.dataSets : nil;

    if (dataSets && dataSets.count > 0 && segment && _gpxDoc)
    {
        OAGPX *gpx = [[OAGPXDatabase sharedDb] getGPXItem:[OAUtilities getGpxShortPath:_gpxDoc.path]];
        BOOL joinSegments = gpx.joinSegments;
        id<IChartDataSet> dataSet = dataSets.firstObject;
        if ([GpxUIHelper getDataSetAxisTypeWithDataSet:dataSet] == GPXDataSetAxisTypeTIME)
        {
            double time = position * 1000;
            return [OAGPXUIHelper getSegmentPointByTime:segment
                                                gpxFile:_gpxDoc
                                                   time:time
                                        preciseLocation:NO
                                           joinSegments:joinSegments];
        }
        else
        {
            double distance = [dataSet getDivX] * position;
            return [OAGPXUIHelper getSegmentPointByDistance:segment
                                                    gpxFile:_gpxDoc
                                            distanceToPoint:distance
                                            preciseLocation:NO
                                               joinSegments:joinSegments];
        }
    }
    return kCLLocationCoordinate2DInvalid;
}

- (void)fitTrackOnMap:(CLLocationCoordinate2D)location
             forceFit:(BOOL)forceFit
        lineChartView:(LineChartView *)lineChartView
              segment:(OATrkSegment *)segment
{
    OABBox rect = [self getRect:lineChartView segment:segment];
    OAMapViewController *mapViewController = [OARootViewController instance].mapPanel.mapViewController;
    if (rect.left != 0 && rect.right != 0)
    {
        auto point = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(location.latitude, location.longitude));
        CGPoint mapPoint;
        [mapViewController.mapView convert:&point toScreen:&mapPoint checkOffScreen:YES];

        if (forceFit && _centerMapOnBBox)
        {
            _centerMapOnBBox(rect);
        }
        else if (CLLocationCoordinate2DIsValid(location) && !CGRectContainsPoint(_screenBBox, mapPoint))
        {
            if (!_isLandscape && _adjustViewPort)
                _adjustViewPort();

            Point31 pos = [OANativeUtilities convertFromPointI:point];
            [mapViewController goToPosition:pos animated:YES];
        }
    }
}

- (OABBox)getRect:(LineChartView *)lineChartView
          segment:(OATrkSegment *)segment
{
    OABBox bbox;

    double startPos = lineChartView.lowestVisibleX;
    double endPos = lineChartView.highestVisibleX;
    double left = 0, right = 0;
    double top = 0, bottom = 0;
    LineChartData *data = lineChartView.lineData;
    NSArray<id<IChartDataSet>> *dataSets = data ? data.dataSets : [NSArray new];
    if (dataSets.count > 0 && segment && _gpxDoc)
    {
        id <IChartDataSet> dataSet = dataSets.firstObject;

        GPXDataSetAxisType axisType = [GpxUIHelper getDataSetAxisTypeWithDataSet:dataSet];
        if (axisType == GPXDataSetAxisTypeTIME || axisType == GPXDataSetAxisTypeTIMEOFDAY)
        {
            float startTime = startPos * 1000;
            float endTime = endPos * 1000;
            OAGPXTrackAnalysis *analysis = [OAGPXTrackAnalysis segment:0 seg:segment];
            for (OAWptPt *p in segment.points)
            {
                if (p.time - analysis.startTime >= startTime && p.time - analysis.startTime <= endTime)
                {
                    if (left == 0 && right == 0)
                    {
                        left = p.position.longitude;
                        right = p.position.longitude;
                        top = p.position.latitude;
                        bottom = p.position.latitude;
                    }
                    else
                    {
                        left = MIN(left, p.position.longitude);
                        right = MAX(right, p.position.longitude);
                        top = MAX(top, p.position.latitude);
                        bottom = MIN(bottom, p.position.latitude);
                    }
                }
            }
        }
        else
        {
            double startDistance = startPos * [dataSet getDivX];
            double endDistance = endPos * [dataSet getDivX];
            double previousSplitDistance = 0;
            for (NSInteger i = 0; i < segment.points.count; i++)
            {
                OAWptPt *currentPoint = segment.points[i];
                if (i != 0)
                {
                    OAWptPt *previousPoint = segment.points[i - 1];
                    if (currentPoint.distance < previousPoint.distance)
                        previousSplitDistance += previousPoint.distance;
                }
                if (previousSplitDistance + currentPoint.distance >= startDistance
                        && previousSplitDistance + currentPoint.distance <= endDistance)
                {
                    if (left == 0 && right == 0)
                    {
                        left = currentPoint.getLongitude;
                        right = currentPoint.getLongitude;
                        top = currentPoint.getLatitude;
                        bottom = currentPoint.getLatitude;
                    }
                    else
                    {
                        left = min(left, currentPoint.getLongitude);
                        right = max(right, currentPoint.getLongitude);
                        top = max(top, currentPoint.getLatitude);
                        bottom = min(bottom, currentPoint.getLatitude);
                    }
                }
            }
        }
    }

    bbox.top = top;
    bbox.bottom = bottom;
    bbox.left = left;
    bbox.right = right;

    return bbox;
}

@end

@interface OARouteBaseViewController () <OARouteInformationListener>

@end

@implementation OARouteBaseViewController

- (instancetype) initWithGpxData:(NSDictionary *)data
{
    self = [super init];
    
    if (self) {
        if (data)
        {
            _gpx = data[@"gpx"];
            _analysis = data[@"analysis"];
        }
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _routingHelper = [OARoutingHelper sharedInstance];
    [_routingHelper addListener:self];
    _routeLineChartHelper = [[OARouteLineChartHelper alloc] initWithGpxDoc:_gpx
                                                           centerMapOnBBox:^(OABBox rect) {
                                                                    [self centerMapOnBBox:rect];
                                                           }
                                                            adjustViewPort:^() {
                                                                    [self adjustViewPort:[self isLandscapeIPadAware]];
                                                            }];
    _routeLineChartHelper.isLandscape = [self isLandscapeIPadAware];
    _routeLineChartHelper.screenBBox = [self getScreenBBox];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {

    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        _routeLineChartHelper.isLandscape = [self isLandscapeIPadAware];
        _routeLineChartHelper.screenBBox = [self getScreenBBox];
    }];
}

- (CGRect)getScreenBBox
{
    BOOL landscape = [self isLandscapeIPadAware];
    CGFloat bottomInset = !landscape && self.delegate ? self.delegate.getVisibleHeight : 0;
    CGFloat topInset = !landscape && !self.navBar.isHidden ? self.navBar.frame.size.height : 0;
    CGFloat leftInset = landscape ? self.contentView.frame.size.width + kMapMargin : 0;
    return CGRectMake(leftInset + kMapMargin, topInset, DeviceScreenWidth - leftInset - kMapMargin * 2, DeviceScreenHeight - topInset - bottomInset);
}

- (void)onMenuShown
{
    [self centerMapOnRoute];
}

- (BOOL) needsAdditionalBottomMargin
{
    return NO;
}

- (NSAttributedString *) getFormattedDistTimeString
{
    OsmAndAppInstance app = [OsmAndApp instance];
    
    NSDictionary *numericAttributes = @{NSFontAttributeName: [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold], NSForegroundColorAttributeName : UIColor.blackColor};
    NSDictionary *alphabeticAttributes = @{NSFontAttributeName: [UIFont systemFontOfSize:20], NSForegroundColorAttributeName : UIColorFromRGB(color_text_footer)};
    NSString *dist = [OAOsmAndFormatter getFormattedDistance:[_routingHelper getLeftDistance]];
    NSAttributedString *distance = [self formatDistance:dist numericAttributes:numericAttributes alphabeticAttributes:alphabeticAttributes];
    NSAttributedString *time = [self getFormattedTimeInterval:[_routingHelper getLeftTime] numericAttributes:numericAttributes alphabeticAttributes:alphabeticAttributes];

    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] init];
    NSAttributedString *space = [[NSAttributedString alloc] initWithString:@" "];
    NSAttributedString *bullet = [[NSAttributedString alloc] initWithString:@"•" attributes:alphabeticAttributes];
    [str appendAttributedString:distance];
    [str appendAttributedString:space];
    [str appendAttributedString:bullet];
    [str appendAttributedString:space];
    [str appendAttributedString:time];

    return str;
}

- (NSAttributedString *) formatDistance:(NSString *)dist numericAttributes:(NSDictionary *) numericAttributes alphabeticAttributes:(NSDictionary *)alphabeticAttributes
{
    NSMutableAttributedString *res = [[NSMutableAttributedString alloc] init];
    if (dist.length > 0)
    {
        NSArray<NSString *> *components = [[dist trim] componentsSeparatedByString:@" "];
        NSAttributedString *space = [[NSAttributedString alloc] initWithString:@" "];
        for (NSInteger i = 0; i < components.count; i++)
        {
            NSAttributedString *str = [[NSAttributedString alloc] initWithString:components[i] attributes:i % 2 == 0 ? numericAttributes : alphabeticAttributes];
            [res appendAttributedString:str];
            if (i != components.count - 1)
                [res appendAttributedString:space];
        }
    }
    return res;
}

- (NSAttributedString *) getFormattedTimeInterval:(NSTimeInterval)timeInterval numericAttributes:(NSDictionary *) numericAttributes alphabeticAttributes:(NSDictionary *)alphabeticAttributes
{
    int hours, minutes, seconds;
    [OAUtilities getHMS:timeInterval hours:&hours minutes:&minutes seconds:&seconds];
    
    NSMutableAttributedString *time = [[NSMutableAttributedString alloc] init];
    NSAttributedString *space = [[NSAttributedString alloc] initWithString:@" "];
    
    if (hours > 0)
    {
        NSAttributedString *val = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d", hours] attributes:numericAttributes];
        NSAttributedString *units = [[NSAttributedString alloc] initWithString:OALocalizedString(@"units_hour") attributes:alphabeticAttributes];
        [time appendAttributedString:val];
        [time appendAttributedString:space];
        [time appendAttributedString:units];
    }
    if (minutes > 0)
    {
        if (time.length > 0)
            [time appendAttributedString:space];
        NSAttributedString *val = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d", minutes] attributes:numericAttributes];
        NSAttributedString *units = [[NSAttributedString alloc] initWithString:OALocalizedString(@"units_min_short") attributes:alphabeticAttributes];
        [time appendAttributedString:val];
        [time appendAttributedString:space];
        [time appendAttributedString:units];
    }
    if (minutes == 0 && hours == 0)
    {
        if (time.length > 0)
            [time appendAttributedString:space];
        NSAttributedString *val = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d", seconds] attributes:numericAttributes];
        NSAttributedString *units = [[NSAttributedString alloc] initWithString:OALocalizedString(@"units_sec_short") attributes:alphabeticAttributes];
        [time appendAttributedString:val];
        [time appendAttributedString:space];
        [time appendAttributedString:units];
    }
    
    NSString *eta = [NSString stringWithFormat:@" (%@)", [self getTimeAfter:timeInterval]];
    [time appendAttributedString:[[NSAttributedString alloc] initWithString:eta attributes:alphabeticAttributes]];
    
    return [[NSAttributedString alloc] initWithAttributedString:time];
}

- (NSString *)getTimeAfter:(NSTimeInterval)timeInterval
{
    int hours, minutes, seconds;
    [OAUtilities getHMS:timeInterval hours:&hours minutes:&minutes seconds:&seconds];
    
    NSDate *date = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:date];
    NSInteger nowHours = [components hour];
    NSInteger nowMinutes = [components minute];
    nowHours = nowMinutes + minutes >= 60 ? nowHours + 1 : nowHours;
    return [NSString stringWithFormat:@"%02ld:%02ld", (nowHours + hours) % 24, (nowMinutes + minutes) % 60];
}

- (double) getRoundedDouble:(double)toRound
{
    return floorf(toRound * 100 + 0.5) / 100;
}

- (void)setupRouteInfo
{
    // override
}

- (void) adjustViewPort:(BOOL)landscape
{
    // override
}

- (void) centerMapOnRoute
{
    NSString *error = [_routingHelper getLastRouteCalcError];
    OABBox routeBBox;
    routeBBox.top = DBL_MAX;
    routeBBox.bottom = DBL_MAX;
    routeBBox.left = DBL_MAX;
    routeBBox.right = DBL_MAX;
    if ([_routingHelper isRouteCalculated] && !error && !_routingHelper.isPublicTransportMode)
    {
        routeBBox = [_routingHelper getBBox];
        if ([_routingHelper isRoutePlanningMode] && routeBBox.left != DBL_MAX)
        {
            [self centerMapOnBBox:routeBBox];
        }
    }
    else if (_routingHelper.isPublicTransportMode)
    {
        OATransportRoutingHelper *transportHelper = OATransportRoutingHelper.sharedInstance;
        if (!transportHelper.isRouteBeingCalculated && transportHelper.getRoutes.size() > 0 && transportHelper.currentRoute != -1)
        {
            [self centerMapOnBBox:transportHelper.getBBox];
        }
    }
}

- (void)centerMapOnBBox:(const OABBox)routeBBox
{
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    BOOL landscape = [self isLandscapeIPadAware];
    [mapPanel displayAreaOnMap:CLLocationCoordinate2DMake(routeBBox.top, routeBBox.left)
                   bottomRight:CLLocationCoordinate2DMake(routeBBox.bottom, routeBBox.right)
                          zoom:0
                   bottomInset:!landscape && self.delegate ? self.delegate.getVisibleHeight + kMapMargin : 0
                     leftInset:landscape ? self.contentView.frame.size.width + kMapMargin : 0
                      animated:YES];
}

- (BOOL) isLandscapeIPadAware
{
    return (OAUtilities.isLandscape || OAUtilities.isIPad) && !OAUtilities.isWindowed;
}

#pragma mark - OARouteInformationListener

- (void) newRouteIsCalculated:(BOOL)newRoute
{
    [self setupRouteInfo];
}

- (void) routeWasUpdated
{
    [self setupRouteInfo];
}

- (void) routeWasCancelled
{
    [self setupRouteInfo];
}

- (void) routeWasFinished
{
    [self setupRouteInfo];
}

@end

//
//  OAAppData.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 3/25/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAAppData.h"
#import "OAHistoryHelper.h"
#import "OAPointDescription.h"
#import "OAAutoObserverProxy.h"
#import "OrderedDictionary.h"
#import "OAPOIFiltersHelper.h"
#import "OAWikipediaPlugin.h"
#import "OAWeatherBand.h"

#define kLastMapSourceKey @"lastMapSource"
#define kOverlaySourceKey @"overlayMapSource"
#define kUnderlaySourceKey @"underlayMapSource"
#define kLastOverlayKey @"lastOverlayMapSource"
#define kLastUnderlayKey @"lastUnderlayMapSource"
#define kOverlayAlphaKey @"overlayAlpha"
#define kUnderlayAlphaKey @"underlayAlpha"
#define kContoursAlphaKey @"contoursAlpha"
#define kMapLayersConfigurationKey @"mapLayersConfiguration"

#define kTerrainTypeKey @"terrainType"
#define kLastTerrainTypeKey @"lastTerrainType"
#define kHillshadeAlphaKey @"hillshadeAlpha"
#define kSlopeAlphaKey @"slopeAlpha"
#define kHillshadeMinZoomKey @"hillshadeMinZoom"
#define kHillshadeMaxZoomKey @"hillshadeMaxZoom"
#define kSlopeMinZoomKey @"slopeMinZoom"
#define kSlopeMaxZoomKey @"slopeMaxZoom"
#define kMapillaryKey @"mapillary"
#define kWikipediaLanguagesKey @"wikipediaLanguages"
#define kWikipediaGlobalKey @"wikipediaGlobal"

#define kWeatherKey @"weather"
#define kWeatherTempKey @"weatherTemp"
#define kWeatherTempUnitKey @"weatherTempUnit"
#define kWeatherTempUnitAutoKey @"weatherTempUnitAuto"
#define kWeatherTempAlphaKey @"weatherTempAlpha"
#define kWeatherPressureKey @"weatherPressure"
#define kWeatherPressureUnitKey @"weatherPressureUnit"
#define kWeatherPressureUnitAutoKey @"weatherPressureUnitAuto"
#define kWeatherPressureAlphaKey @"weatherPressureAlpha"
#define kWeatherWindKey @"weatherWind"
#define kWeatherWindUnitKey @"weatherWindUnit"
#define kWeatherWindUnitAutoKey @"weatherWindUnitAuto"
#define kWeatherWindAlphaKey @"weatherWindAlpha"
#define kWeatherCloudKey @"weatherCloud"
#define kWeatherCloudUnitKey @"weatherCloudUnit"
#define kWeatherCloudUnitAutoKey @"weatherCloudUnitAuto"
#define kWeatherCloudAlphaKey @"weatherCloudAlpha"
#define kWeatherPrecipKey @"weatherPrecip"
#define kWeatherPrecipUnitKey @"weatherPrecipUnit"
#define kWeatherPrecipUnitAutoKey @"weatherPrecipUnitAuto"
#define kWeatherPrecipAlphaKey @"weatherPrecipAlpha"

@implementation OAAppData
{
    NSObject* _lock;
    NSMutableDictionary* _lastMapSources;
    
    OAAutoObserverProxy *_applicationModeChangedObserver;
    
    NSMutableArray<OARTargetPoint *> *_intermediates;
    
    OACommonMapSource *_lastMapSourceProfile;
    OACommonMapSource *_overlayMapSourceProfile;
    OACommonMapSource *_lastOverlayMapSourceProfile;
    OACommonMapSource *_underlayMapSourceProfile;
    OACommonMapSource  *_lastUnderlayMapSourceProfile;
    OACommonDouble *_overlayAlphaProfile;
    OACommonDouble *_underlayAlphaProfile;
    OACommonTerrain *_terrainTypeProfile;
    OACommonTerrain *_lastTerrainTypeProfile;
    OACommonDouble *_hillshadeAlphaProfile;
    OACommonInteger *_hillshadeMinZoomProfile;
    OACommonInteger *_hillshadeMaxZoomProfile;
    OACommonDouble *_slopeAlphaProfile;
    OACommonInteger *_slopeMinZoomProfile;
    OACommonInteger *_slopeMaxZoomProfile;
    OACommonBoolean *_mapillaryProfile;
    OACommonBoolean *_wikipediaGlobalProfile;
    OACommonStringList *_wikipediaLanguagesProfile;

    OACommonBoolean *_weatherProfile;
    OACommonBoolean *_weatherTempProfile;
    OACommonUnit *_weatherTempUnitProfile;
    OACommonBoolean *_weatherTempUnitAutoProfile;
    OACommonDouble *_weatherTempAlphaProfile;
    OACommonBoolean *_weatherPressureProfile;
    OACommonUnit *_weatherPressureUnitProfile;
    OACommonBoolean *_weatherPressureUnitAutoProfile;
    OACommonDouble *_weatherPressureAlphaProfile;
    OACommonBoolean *_weatherWindProfile;
    OACommonUnit *_weatherWindUnitProfile;
    OACommonBoolean *_weatherWindUnitAutoProfile;
    OACommonDouble *_weatherWindAlphaProfile;
    OACommonBoolean *_weatherCloudProfile;
    OACommonUnit *_weatherCloudUnitProfile;
    OACommonBoolean *_weatherCloudUnitAutoProfile;
    OACommonDouble *_weatherCloudAlphaProfile;
    OACommonBoolean *_weatherPrecipProfile;
    OACommonUnit *_weatherPrecipUnitProfile;
    OACommonBoolean *_weatherPrecipUnitAutoProfile;
    OACommonDouble *_weatherPrecipAlphaProfile;
    
    OACommonDouble *_contoursAlphaProfile;

    NSMapTable<NSString *, OACommonPreference *> *_registeredPreferences;
}

@synthesize applicationModeChangedObservable = _applicationModeChangedObservable, mapLayersConfiguration = _mapLayersConfiguration;

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        [self commonInit];
        [self safeInit];
    }
    return self;
}

- (void) setSettingValue:(NSString *)value forKey:(NSString *)key mode:(OAApplicationMode *)mode
{
    @synchronized (_lock)
    {
        if ([key isEqualToString:@"terrain_mode"])
        {
            [_lastTerrainTypeProfile setValueFromString:value appMode:mode];
        }
        else if ([key isEqualToString:@"hillshade_min_zoom"])
        {
            [_hillshadeMinZoomProfile setValueFromString:value appMode:mode];
        }
        else if ([key isEqualToString:@"hillshade_max_zoom"])
        {
            [_hillshadeMaxZoomProfile setValueFromString:value appMode:mode];
        }
        else if ([key isEqualToString:@"hillshade_transparency"])
        {
            double alpha = [value doubleValue] / 100;
            [_hillshadeAlphaProfile set:alpha mode:mode];
        }
        else if ([key isEqualToString:@"slope_transparency"])
        {
            double alpha = [value doubleValue] / 100;
            [_slopeAlphaProfile set:alpha mode:mode];
        }
        else if ([key isEqualToString:@"slope_min_zoom"])
        {
            [_slopeMinZoomProfile setValueFromString:value appMode:mode];
        }
        else if ([key isEqualToString:@"slope_max_zoom"])
        {
            [_slopeMaxZoomProfile setValueFromString:value appMode:mode];
        }
        else if ([key isEqualToString:@"show_mapillary"])
        {
            [_mapillaryProfile setValueFromString:value appMode:mode];
        }
        else if ([key isEqualToString:@"global_wikipedia_poi_enabled"])
        {
            [_wikipediaGlobalProfile setValueFromString:value appMode:mode];
        }
        else if ([key isEqualToString:@"wikipedia_poi_enabled_languages"])
        {
            [_wikipediaLanguagesProfile setValueFromString:value appMode:mode];
        }
    }
}

- (void) addPreferenceValuesToDictionary:(MutableOrderedDictionary *)prefs mode:(OAApplicationMode *)mode
{
    @synchronized (_lock)
    {
        prefs[@"terrain_mode"] = [_lastTerrainTypeProfile toStringValue:mode];
        prefs[@"hillshade_min_zoom"] = [_hillshadeMinZoomProfile toStringValue:mode];
        prefs[@"hillshade_max_zoom"] = [_hillshadeMaxZoomProfile toStringValue:mode];
        prefs[@"hillshade_transparency"] = [NSString stringWithFormat:@"%d", (int) ([_hillshadeAlphaProfile get:mode] * 100)];
        prefs[@"slope_transparency"] = [NSString stringWithFormat:@"%d", (int) ([_slopeAlphaProfile get:mode] * 100)];
        prefs[@"slope_min_zoom"] = [_slopeMinZoomProfile toStringValue:mode];
        prefs[@"slope_max_zoom"] = [_slopeMaxZoomProfile toStringValue:mode];
        prefs[@"show_mapillary"] = [_mapillaryProfile toStringValue:mode];
        prefs[@"global_wikipedia_poi_enabled"] = [_wikipediaGlobalProfile toStringValue:mode];
        prefs[@"wikipedia_poi_enabled_languages"] = [_wikipediaLanguagesProfile toStringValue:mode];
    }
}

- (void) commonInit
{
    _lock = [[NSObject alloc] init];
    _lastMapSourceChangeObservable = [[OAObservable alloc] init];

    _overlayMapSourceChangeObservable = [[OAObservable alloc] init];
    _overlayAlphaChangeObservable = [[OAObservable alloc] init];
    _underlayMapSourceChangeObservable = [[OAObservable alloc] init];
    _underlayAlphaChangeObservable = [[OAObservable alloc] init];
    _contoursAlphaChangeObservable = [[OAObservable alloc] init];
    _terrainChangeObservable = [[OAObservable alloc] init];
    _terrainResourcesChangeObservable = [[OAObservable alloc] init];
    _terrainAlphaChangeObservable = [[OAObservable alloc] init];
    _mapLayerChangeObservable = [[OAObservable alloc] init];
    _mapillaryChangeObservable = [[OAObservable alloc] init];

    _destinationsChangeObservable = [[OAObservable alloc] init];
    _destinationAddObservable = [[OAObservable alloc] init];
    _destinationRemoveObservable = [[OAObservable alloc] init];
    _destinationShowObservable = [[OAObservable alloc] init];
    _destinationHideObservable = [[OAObservable alloc] init];
    _mapLayersConfigurationChangeObservable = [[OAObservable alloc] init];

    _wikipediaChangeObservable = [[OAObservable alloc] init];

    _applicationModeChangedObservable = [[OAObservable alloc] init];
    _applicationModeChangedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                           withHandler:@selector(onAppModeChanged)
                                                            andObserve:_applicationModeChangedObservable];
    _mapLayersConfiguration = [[OAMapLayersConfiguration alloc] init];
    // Profile settings
    _lastMapSourceProfile = [OACommonMapSource withKey:kLastMapSourceKey defValue:[[OAMapSource alloc] initWithResource:@"default.render.xml"
                                                                                                             andVariant:@"type_default"]];
    _overlayMapSourceProfile = [OACommonMapSource withKey:kOverlaySourceKey defValue:nil];
    _underlayMapSourceProfile = [OACommonMapSource withKey:kUnderlaySourceKey defValue:nil];
    _lastOverlayMapSourceProfile = [OACommonMapSource withKey:kLastOverlayKey defValue:nil];
    _lastUnderlayMapSourceProfile = [OACommonMapSource withKey:kLastUnderlayKey defValue:nil];
    _overlayAlphaProfile = [OACommonDouble withKey:kOverlayAlphaKey defValue:0.5];
    _underlayAlphaProfile = [OACommonDouble withKey:kUnderlayAlphaKey defValue:0.5];
    _contoursAlphaProfile = [OACommonDouble withKey:kContoursAlphaKey defValue:1.];
    _terrainTypeProfile = [OACommonTerrain withKey:kTerrainTypeKey defValue:EOATerrainTypeDisabled];
    _lastTerrainTypeProfile = [OACommonTerrain withKey:kLastTerrainTypeKey defValue:EOATerrainTypeHillshade];
    _hillshadeAlphaProfile = [OACommonDouble withKey:kHillshadeAlphaKey defValue:0.45];
    _slopeAlphaProfile = [OACommonDouble withKey:kSlopeAlphaKey defValue:0.35];
    _hillshadeMinZoomProfile = [OACommonInteger withKey:kHillshadeMinZoomKey defValue:3];
    _hillshadeMaxZoomProfile = [OACommonInteger withKey:kHillshadeMaxZoomKey defValue:16];
    _slopeMinZoomProfile = [OACommonInteger withKey:kSlopeMinZoomKey defValue:3];
    _slopeMaxZoomProfile = [OACommonInteger withKey:kSlopeMaxZoomKey defValue:16];
    _mapillaryProfile = [OACommonBoolean withKey:kMapillaryKey defValue:NO];
    _wikipediaGlobalProfile = [OACommonBoolean withKey:kWikipediaGlobalKey defValue:NO];
    _wikipediaLanguagesProfile = [OACommonStringList withKey:kWikipediaLanguagesKey defValue:@[]];

    _weatherProfile = [OACommonBoolean withKey:kWeatherKey defValue:NO];
    _weatherTempProfile = [OACommonBoolean withKey:kWeatherTempKey defValue:NO];
    _weatherTempUnitProfile = [OACommonUnit withKey:kWeatherTempUnitKey defValue:[OAWeatherBand getDefaultBandUnit:WEATHER_BAND_TEMPERATURE]];
    _weatherTempUnitAutoProfile = [OACommonBoolean withKey:kWeatherTempUnitAutoKey defValue:YES];
    _weatherTempAlphaProfile = [OACommonDouble withKey:kWeatherTempAlphaKey defValue:0.5];
    _weatherPressureProfile = [OACommonBoolean withKey:kWeatherPressureKey defValue:NO];
    _weatherPressureUnitProfile = [OACommonUnit withKey:kWeatherPressureUnitKey defValue:[OAWeatherBand getDefaultBandUnit:WEATHER_BAND_PRESSURE]];
    _weatherPressureUnitAutoProfile = [OACommonBoolean withKey:kWeatherPressureUnitAutoKey defValue:YES];
    _weatherPressureAlphaProfile = [OACommonDouble withKey:kWeatherPressureAlphaKey defValue:0.6];
    _weatherWindProfile = [OACommonBoolean withKey:kWeatherWindKey defValue:NO];
    _weatherWindUnitProfile = [OACommonUnit withKey:kWeatherWindUnitKey defValue:[OAWeatherBand getDefaultBandUnit:WEATHER_BAND_WIND_SPEED]];
    _weatherWindUnitAutoProfile = [OACommonBoolean withKey:kWeatherWindUnitAutoKey defValue:YES];
    _weatherWindAlphaProfile = [OACommonDouble withKey:kWeatherWindAlphaKey defValue:0.6];
    _weatherCloudProfile = [OACommonBoolean withKey:kWeatherCloudKey defValue:NO];
    _weatherCloudUnitProfile = [OACommonUnit withKey:kWeatherCloudUnitKey defValue:[OAWeatherBand getDefaultBandUnit:WEATHER_BAND_CLOUD]];
    _weatherCloudUnitAutoProfile = [OACommonBoolean withKey:kWeatherCloudUnitAutoKey defValue:YES];
    _weatherCloudAlphaProfile = [OACommonDouble withKey:kWeatherCloudAlphaKey defValue:0.5];
    _weatherPrecipProfile = [OACommonBoolean withKey:kWeatherPrecipKey defValue:NO];
    _weatherPrecipUnitProfile = [OACommonUnit withKey:kWeatherPrecipUnitKey defValue:[OAWeatherBand getDefaultBandUnit:WEATHER_BAND_PRECIPITATION]];
    _weatherPrecipUnitAutoProfile = [OACommonBoolean withKey:kWeatherPrecipUnitAutoKey defValue:YES];
    _weatherPrecipAlphaProfile = [OACommonDouble withKey:kWeatherPrecipAlphaKey defValue:0.7];

    _weatherChangeObservable = [[OAObservable alloc] init];
    _weatherTempChangeObservable = [[OAObservable alloc] init];
    _weatherTempUnitChangeObservable = [[OAObservable alloc] init];
    _weatherPressureChangeObservable = [[OAObservable alloc] init];
    _weatherPressureUnitChangeObservable = [[OAObservable alloc] init];
    _weatherWindChangeObservable = [[OAObservable alloc] init];
    _weatherWindUnitChangeObservable = [[OAObservable alloc] init];
    _weatherCloudChangeObservable = [[OAObservable alloc] init];
    _weatherCloudUnitChangeObservable = [[OAObservable alloc] init];
    _weatherPrecipChangeObservable = [[OAObservable alloc] init];
    _weatherPrecipUnitChangeObservable = [[OAObservable alloc] init];
    _weatherTempAlphaChangeObservable = [[OAObservable alloc] init];
    _weatherPressureAlphaChangeObservable = [[OAObservable alloc] init];
    _weatherWindAlphaChangeObservable = [[OAObservable alloc] init];
    _weatherCloudAlphaChangeObservable = [[OAObservable alloc] init];
    _weatherPrecipAlphaChangeObservable = [[OAObservable alloc] init];
    
    _registeredPreferences = [NSMapTable strongToStrongObjectsMapTable];
    [_registeredPreferences setObject:_overlayMapSourceProfile forKey:@"map_overlay_previous"];
    [_registeredPreferences setObject:_underlayMapSourceProfile forKey:@"map_underlay_previous"];
    [_registeredPreferences setObject:_overlayAlphaProfile forKey:@"overlay_transparency"];
    [_registeredPreferences setObject:_underlayAlphaProfile forKey:@"map_transparency"];
    [_registeredPreferences setObject:_contoursAlphaProfile forKey:@"contours_alpha"];
    [_registeredPreferences setObject:_lastTerrainTypeProfile forKey:@"terrain_mode"];
    [_registeredPreferences setObject:_hillshadeAlphaProfile forKey:@"hillshade_transparency"];
    [_registeredPreferences setObject:_slopeAlphaProfile forKey:@"slope_transparency"];
    [_registeredPreferences setObject:_hillshadeMinZoomProfile forKey:@"hillshade_min_zoom"];
    [_registeredPreferences setObject:_hillshadeMaxZoomProfile forKey:@"hillshade_max_zoom"];
    [_registeredPreferences setObject:_slopeMinZoomProfile forKey:@"slope_min_zoom"];
    [_registeredPreferences setObject:_slopeMaxZoomProfile forKey:@"slope_max_zoom"];
    [_registeredPreferences setObject:_mapillaryProfile forKey:@"show_mapillary"];
    [_registeredPreferences setObject:_terrainTypeProfile forKey:@"terrain_mode"];
    [_registeredPreferences setObject:_wikipediaGlobalProfile forKey:@"global_wikipedia_poi_enabled"];
    [_registeredPreferences setObject:_wikipediaLanguagesProfile forKey:@"wikipedia_poi_enabled_languages"];

    [_registeredPreferences setObject:_weatherProfile forKey:@"show_weather"];
    [_registeredPreferences setObject:_weatherTempProfile forKey:@"show_weather_temp"];
    [_registeredPreferences setObject:_weatherTempUnitProfile forKey:@"show_weather_temp_unit"];
    [_registeredPreferences setObject:_weatherTempUnitAutoProfile forKey:@"show_weather_temp_unit_auto"];
    [_registeredPreferences setObject:_weatherTempAlphaProfile forKey:@"weather_temp_transparency"];
    [_registeredPreferences setObject:_weatherPressureProfile forKey:@"show_weather_pressure"];
    [_registeredPreferences setObject:_weatherPressureUnitProfile forKey:@"show_weather_pressure_unit"];
    [_registeredPreferences setObject:_weatherPressureUnitAutoProfile forKey:@"show_weather_pressure_unit_auto"];
    [_registeredPreferences setObject:_weatherPressureAlphaProfile forKey:@"weather_pressure_transparency"];
    [_registeredPreferences setObject:_weatherWindProfile forKey:@"show_weather_wind"];
    [_registeredPreferences setObject:_weatherWindUnitProfile forKey:@"show_weather_wind_unit"];
    [_registeredPreferences setObject:_weatherWindUnitAutoProfile forKey:@"show_weather_wind_unit_auto"];
    [_registeredPreferences setObject:_weatherWindAlphaProfile forKey:@"weather_wind_transparency"];
    [_registeredPreferences setObject:_weatherCloudProfile forKey:@"show_weather_cloud"];
    [_registeredPreferences setObject:_weatherCloudUnitProfile forKey:@"show_weather_cloud_unit"];
    [_registeredPreferences setObject:_weatherCloudUnitAutoProfile forKey:@"show_weather_cloud_unit_auto"];
    [_registeredPreferences setObject:_weatherCloudAlphaProfile forKey:@"weather_cloud_transparency"];
    [_registeredPreferences setObject:_weatherPrecipProfile forKey:@"show_weather_precip"];
    [_registeredPreferences setObject:_weatherPrecipUnitProfile forKey:@"show_weather_precip_unit"];
    [_registeredPreferences setObject:_weatherPrecipUnitAutoProfile forKey:@"show_weather_precip_unit_auto"];
    [_registeredPreferences setObject:_weatherPrecipAlphaProfile forKey:@"weather_precip_transparency"];
}

- (void) dealloc
{
    if (_applicationModeChangedObserver)
    {
        [_applicationModeChangedObserver detach];
        _applicationModeChangedObserver = nil;
    }
}

- (void) onAppModeChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_mapLayersConfiguration resetConfigutation];
        [_overlayAlphaChangeObservable notifyEventWithKey:self andValue:@(self.overlayAlpha)];
        [_underlayAlphaChangeObservable notifyEventWithKey:self andValue:@(self.underlayAlpha)];
        [_contoursAlphaChangeObservable notifyEventWithKey:self andValue:@(self.contoursAlpha)];
        [_terrainChangeObservable notifyEventWithKey:self andValue:@YES];
        if (self.terrainType != EOATerrainTypeDisabled)
            [_terrainAlphaChangeObservable notifyEventWithKey:self andValue:self.terrainType == EOATerrainTypeHillshade ? @(self.hillshadeAlpha) : @(self.slopeAlpha)];
        [_lastMapSourceChangeObservable notifyEventWithKey:self andValue:self.lastMapSource];
        [_wikipediaChangeObservable notifyEventWithKey:self andValue:@(self.wikipedia)];
        [self setLastMapSourceVariant:[OAAppSettings sharedManager].applicationMode.get.variantKey];
    });
}

- (void) safeInit
{
    if (_lastMapSources == nil)
        _lastMapSources = [[NSMutableDictionary alloc] init];
    if (_mapLastViewedState == nil)
        _mapLastViewedState = [[OAMapViewState alloc] init];
    if (_destinations == nil)
        _destinations = [NSMutableArray array];
    if (_intermediates == nil)
        _intermediates = [NSMutableArray array];
    
    if (isnan(_mapLastViewedState.zoom) || _mapLastViewedState.zoom < 1.0f || _mapLastViewedState.zoom > 23.0f)
        _mapLastViewedState.zoom = 3.0f;
    
    if (_mapLastViewedState.target31.x < 0 || _mapLastViewedState.target31.y < 0)
    {
        Point31 p;
        p.x = 1073741824;
        p.y = 1073741824;
        _mapLastViewedState.target31 = p;
        _mapLastViewedState.zoom = 3.0f;
    }
    
}

- (OAMapSource*) lastMapSource
{
    @synchronized(_lock)
    {
        return [_lastMapSourceProfile get];
    }
}

- (OAMapSource *) getLastMapSource:(OAApplicationMode *)mode
{
    @synchronized (_lock)
    {
        return [_lastMapSourceProfile get:mode];
    }
}

- (void) setLastMapSource:(OAMapSource *)lastMapSource mode:(OAApplicationMode *)mode
{
    @synchronized(_lock)
    {
        if (![lastMapSource isEqual:[_lastMapSourceProfile get:mode]])
        {
            OAMapSource *savedSource = [_lastMapSourceProfile get:mode];
            // Store previous, if such exists
            if (savedSource != nil)
            {
                [_lastMapSources setObject:savedSource.variant != nil ? savedSource.variant : [NSNull null]
                                    forKey:savedSource.resourceId];
            }
            [_lastMapSourceProfile set:[lastMapSource copy] mode:mode];
        }
		[_lastMapSourceChangeObservable notifyEventWithKey:self andValue:[_lastMapSourceProfile get:mode]];
    }
}

- (void) setLastMapSource:(OAMapSource*)lastMapSource
{
    @synchronized(_lock)
    {
        if (![lastMapSource isEqual:self.lastMapSource])
        {
            OAMapSource *savedSource = [_lastMapSourceProfile get];
            // Store previous, if such exists
            if (savedSource != nil)
            {
                [_lastMapSources setObject:savedSource.variant != nil ? savedSource.variant : [NSNull null]
                                    forKey:savedSource.resourceId];
            }
            
            // Save new one
            [_lastMapSourceProfile set:[lastMapSource copy]];
            [_lastMapSourceChangeObservable notifyEventWithKey:self andValue:self.lastMapSource];
        }
    }
}

- (void) setLastMapSourceVariant:(NSString *)variant
{
    OAMapSource *lastSource = self.lastMapSource;
    if ([lastSource.resourceId isEqualToString:@"online_tiles"])
        return;
    
    OAMapSource *mapSource = [[OAMapSource alloc] initWithResource:lastSource.resourceId andVariant:variant name:lastSource.name];
    [_lastMapSourceProfile set:mapSource];
}

@synthesize lastMapSourceChangeObservable = _lastMapSourceChangeObservable;

- (OAMapSource*) lastMapSourceByResourceId:(NSString*)resourceId
{
    @synchronized(_lock)
    {
        OAMapSource *lastMapSource = self.lastMapSource;
        if (lastMapSource != nil && [lastMapSource.resourceId isEqualToString:resourceId])
            return lastMapSource;

        NSNull* variant = [_lastMapSources objectForKey:resourceId];
        if (variant == nil || variant == [NSNull null])
            return nil;

        return [[OAMapSource alloc] initWithResource:resourceId
                                          andVariant:(NSString*)variant];
    }
}

@synthesize overlayMapSourceChangeObservable = _overlayMapSourceChangeObservable;
@synthesize overlayAlphaChangeObservable = _overlayAlphaChangeObservable;
@synthesize underlayMapSourceChangeObservable = _underlayMapSourceChangeObservable;
@synthesize underlayAlphaChangeObservable = _underlayAlphaChangeObservable;
@synthesize contoursAlphaChangeObservable = _contoursAlphaChangeObservable;
@synthesize destinationsChangeObservable = _destinationsChangeObservable;
@synthesize destinationAddObservable = _destinationAddObservable;
@synthesize destinationRemoveObservable = _destinationRemoveObservable;
@synthesize terrainChangeObservable = _terrainChangeObservable;
@synthesize terrainResourcesChangeObservable = _terrainResourcesChangeObservable;
@synthesize terrainAlphaChangeObservable = _terrainAlphaChangeObservable;
@synthesize mapLayerChangeObservable = _mapLayerChangeObservable;
@synthesize mapillaryChangeObservable = _mapillaryChangeObservable;
@synthesize wikipediaChangeObservable = _wikipediaChangeObservable;

@synthesize weatherChangeObservable = _weatherChangeObservable;
@synthesize weatherTempChangeObservable = _weatherTempChangeObservable;
@synthesize weatherTempUnitChangeObservable = _weatherTempUnitChangeObservable;
@synthesize weatherTempAlphaChangeObservable = _weatherTempAlphaChangeObservable;
@synthesize weatherPressureChangeObservable = _weatherPressureChangeObservable;
@synthesize weatherPressureUnitChangeObservable = _weatherPressureUnitChangeObservable;
@synthesize weatherPressureAlphaChangeObservable = _weatherPressureAlphaChangeObservable;
@synthesize weatherWindChangeObservable = _weatherWindChangeObservable;
@synthesize weatherWindUnitChangeObservable = _weatherWindUnitChangeObservable;
@synthesize weatherWindAlphaChangeObservable = _weatherWindAlphaChangeObservable;
@synthesize weatherCloudChangeObservable = _weatherCloudChangeObservable;
@synthesize weatherCloudUnitChangeObservable = _weatherCloudUnitChangeObservable;
@synthesize weatherCloudAlphaChangeObservable = _weatherCloudAlphaChangeObservable;
@synthesize weatherPrecipChangeObservable = _weatherPrecipChangeObservable;
@synthesize weatherPrecipUnitChangeObservable = _weatherPrecipUnitChangeObservable;
@synthesize weatherPrecipAlphaChangeObservable = _weatherPrecipAlphaChangeObservable;

- (BOOL) weather
{
    @synchronized(_lock)
    {
        return [_weatherProfile get];
    }
}

- (void) setWeather:(BOOL)weather
{
    @synchronized(_lock)
    {
        [_weatherProfile set:weather];
        [_weatherChangeObservable notifyEventWithKey:self andValue:@(self.weather)];
    }
}

- (BOOL) weatherTemp
{
    @synchronized(_lock)
    {
        return [_weatherTempProfile get];
    }
}

- (void) setWeatherTemp:(BOOL)weatherTemp
{
    @synchronized(_lock)
    {
        [_weatherTempProfile set:weatherTemp];
        [_weatherTempChangeObservable notifyEventWithKey:@(WEATHER_BAND_TEMPERATURE) andValue:@(self.weatherTemp)];
    }
}

- (NSUnitTemperature *) weatherTempUnit
{
    @synchronized(_lock)
    {
        NSUnitTemperature *unit = (NSUnitTemperature *) [_weatherTempUnitProfile get];
        if (self.weatherTempUnitAuto)
        {
            NSUnitTemperature *current = [NSUnitTemperature current];
            if (![unit.symbol isEqualToString:current.symbol])
            {
                unit = current;
                [self setWeatherTempUnit:unit];
            }
        }
        return unit;
    }
}

- (void) setWeatherTempUnit:(NSUnitTemperature *)weatherTempUnit
{
    @synchronized(_lock)
    {
        [_weatherTempUnitProfile set:weatherTempUnit];
        [_weatherTempUnitChangeObservable notifyEventWithKey:@(WEATHER_BAND_TEMPERATURE) andValue:self.weatherTempUnit];
    }
}

- (BOOL) weatherTempUnitAuto
{
    @synchronized(_lock)
    {
        return [_weatherTempUnitAutoProfile get];
    }
}

- (void) setWeatherTempUnitAuto:(BOOL)weatherTempUnitAuto
{
    @synchronized(_lock)
    {
        [_weatherTempUnitAutoProfile set:weatherTempUnitAuto];
        if (weatherTempUnitAuto)
        {
            NSUnitTemperature *current = [NSUnitTemperature current];
            if ([_weatherTempUnitProfile get] != current)
                [self setWeatherTempUnit:current];
        }
    }
}

- (double) weatherTempAlpha
{
    @synchronized (_lock)
    {
        return [_weatherTempAlphaProfile get];
    }
}

- (void) setWeatherTempAlpha:(double)weatherTempAlpha
{
    @synchronized(_lock)
    {
        [_weatherTempAlphaProfile set:weatherTempAlpha];
        [_weatherTempAlphaChangeObservable notifyEventWithKey:@(WEATHER_BAND_TEMPERATURE) andValue:@(self.weatherTempAlpha)];
    }
}

- (BOOL) weatherPressure
{
    @synchronized(_lock)
    {
        return [_weatherPressureProfile get];
    }
}

- (void) setWeatherPressure:(BOOL)weatherPressure
{
    @synchronized(_lock)
    {
        [_weatherPressureProfile set:weatherPressure];
        [_weatherPressureChangeObservable notifyEventWithKey:@(WEATHER_BAND_PRESSURE) andValue:@(self.weatherPressure)];
    }
}

- (NSUnitPressure *) weatherPressureUnit
{
    @synchronized(_lock)
    {
        NSUnitPressure *unit = (NSUnitPressure *) [_weatherPressureUnitProfile get];
        if (self.weatherPressureUnitAuto)
        {
            NSUnitPressure *current = [NSUnitPressure current];
            if (![unit.symbol isEqualToString:current.symbol])
            {
                unit = current;
                [self setWeatherPressureUnit:unit];
            }
        }
        return unit;
    }
}

- (void) setWeatherPressureUnit:(NSUnitPressure *)weatherPressureUnit
{
    @synchronized(_lock)
    {
        [_weatherPressureUnitProfile set:weatherPressureUnit];
        [_weatherPressureUnitChangeObservable notifyEventWithKey:@(WEATHER_BAND_PRESSURE) andValue:self.weatherPressureUnit];
    }
}

- (BOOL) weatherPressureUnitAuto
{
    @synchronized(_lock)
    {
        return [_weatherPressureUnitAutoProfile get];
    }
}

- (void) setWeatherPressureUnitAuto:(BOOL)weatherPressureUnitAuto
{
    @synchronized(_lock)
    {
        [_weatherPressureUnitAutoProfile set:weatherPressureUnitAuto];
        if (weatherPressureUnitAuto)
        {
            NSUnitPressure *current = [NSUnitPressure current];
            if ([_weatherPressureUnitProfile get] != current)
                [self setWeatherPressureUnit:current];
        }
    }
}

- (double) weatherPressureAlpha
{
    @synchronized (_lock)
    {
        return [_weatherPressureAlphaProfile get];
    }
}

- (void) setWeatherPressureAlpha:(double)weatherPressureAlpha
{
    @synchronized(_lock)
    {
        [_weatherPressureAlphaProfile set:weatherPressureAlpha];
        [_weatherPressureAlphaChangeObservable notifyEventWithKey:@(WEATHER_BAND_PRESSURE) andValue:@(self.weatherPressureAlpha)];
    }
}

- (BOOL) weatherWind
{
    @synchronized(_lock)
    {
        return [_weatherWindProfile get];
    }
}

- (void) setWeatherWind:(BOOL)weatherWind
{
    @synchronized(_lock)
    {
        [_weatherWindProfile set:weatherWind];
        [_weatherWindChangeObservable notifyEventWithKey:@(WEATHER_BAND_WIND_SPEED) andValue:@(self.weatherWind)];
    }
}

- (NSUnitSpeed *) weatherWindUnit
{
    @synchronized(_lock)
    {
        NSUnitSpeed *unit = (NSUnitSpeed *) [_weatherWindUnitProfile get];
        if (self.weatherWindUnitAuto)
        {
            NSUnitSpeed *current = [NSUnitSpeed current];
            if (![unit.symbol isEqualToString:current.symbol])
            {
                unit = current;
                [self setWeatherWindUnit:unit];
            }
        }
        return unit;
    }
}

- (void) setWeatherWindUnit:(NSUnitSpeed *)weatherWindUnit
{
    @synchronized(_lock)
    {
        [_weatherWindUnitProfile set:weatherWindUnit];
        [_weatherWindUnitChangeObservable notifyEventWithKey:@(WEATHER_BAND_WIND_SPEED) andValue:self.weatherWindUnit];
    }
}

- (BOOL) weatherWindUnitAuto
{
    @synchronized(_lock)
    {
        return [_weatherWindUnitAutoProfile get];
    }
}

- (void) setWeatherWindUnitAuto:(BOOL)weatherWindUnitAuto
{
    @synchronized(_lock)
    {
        [_weatherWindUnitAutoProfile set:weatherWindUnitAuto];
        if (weatherWindUnitAuto)
        {
            NSUnitSpeed *current = [NSUnitSpeed current];
            if ([_weatherWindUnitProfile get] != current)
                [self setWeatherWindUnit:current];
        }
    }
}

- (double) weatherWindAlpha
{
    @synchronized (_lock)
    {
        return [_weatherWindAlphaProfile get];
    }
}

- (void) setWeatherWindAlpha:(double)weatherWindAlpha
{
    @synchronized(_lock)
    {
        [_weatherWindAlphaProfile set:weatherWindAlpha];
        [_weatherWindAlphaChangeObservable notifyEventWithKey:@(WEATHER_BAND_WIND_SPEED) andValue:@(self.weatherWindAlpha)];
    }
}

- (BOOL) weatherCloud
{
    @synchronized(_lock)
    {
        return [_weatherCloudProfile get];
    }
}

- (void) setWeatherCloud:(BOOL)weatherCloud
{
    @synchronized(_lock)
    {
        [_weatherCloudProfile set:weatherCloud];
        [_weatherCloudChangeObservable notifyEventWithKey:@(WEATHER_BAND_CLOUD) andValue:@(self.weatherCloud)];
    }
}

- (NSUnitCloud *) weatherCloudUnit
{
    @synchronized(_lock)
    {
        NSUnitCloud *unit = (NSUnitCloud *) [_weatherCloudUnitProfile get];
        if (self.weatherCloudUnitAuto)
        {
            NSUnitCloud *current = [NSUnitCloud current];
            if (![unit.symbol isEqualToString:current.symbol])
            {
                unit = current;
                [self setWeatherCloudUnit:unit];
            }
        }
        return unit;
    }
}

- (void) setWeatherCloudUnit:(NSUnitCloud *)weatherCloudUnit
{
    @synchronized(_lock)
    {
        [_weatherCloudUnitProfile set:weatherCloudUnit];
        [_weatherCloudUnitChangeObservable notifyEventWithKey:@(WEATHER_BAND_CLOUD) andValue:self.weatherCloudUnit];
    }
}

- (BOOL) weatherCloudUnitAuto
{
    @synchronized(_lock)
    {
        return [_weatherCloudUnitAutoProfile get];
    }
}

- (void) setWeatherCloudUnitAuto:(BOOL)weatherCloudUnitAuto
{
    @synchronized(_lock)
    {
        [_weatherCloudUnitAutoProfile set:weatherCloudUnitAuto];
        if (weatherCloudUnitAuto)
        {
            NSUnitCloud *current = [NSUnitCloud current];
            if ([_weatherCloudUnitProfile get] != current)
                [self setWeatherCloudUnit:current];
        }
    }
}

- (double) weatherCloudAlpha
{
    @synchronized (_lock)
    {
        return [_weatherCloudAlphaProfile get];
    }
}

- (void) setWeatherCloudAlpha:(double)weatherCloudAlpha
{
    @synchronized(_lock)
    {
        [_weatherCloudAlphaProfile set:weatherCloudAlpha];
        [_weatherCloudAlphaChangeObservable notifyEventWithKey:@(WEATHER_BAND_CLOUD) andValue:@(self.weatherCloudAlpha)];
    }
}

- (BOOL) weatherPrecip
{
    @synchronized(_lock)
    {
        return [_weatherPrecipProfile get];
    }
}

- (void) setWeatherPrecip:(BOOL)weatherPrecip
{
    @synchronized(_lock)
    {
        [_weatherPrecipProfile set:weatherPrecip];
        [_weatherPrecipChangeObservable notifyEventWithKey:@(WEATHER_BAND_PRECIPITATION) andValue:@(self.weatherPrecip)];
    }
}

- (NSUnitLength *) weatherPrecipUnit
{
    @synchronized(_lock)
    {
        NSUnitLength *unit = (NSUnitLength *) [_weatherPrecipUnitProfile get];
        if (self.weatherPrecipUnitAuto)
        {
            NSUnitLength *current = [NSUnitLength current];
            if (![unit.symbol isEqualToString:current.symbol])
            {
                unit = current;
                [self setWeatherPrecipUnit:unit];
            }
        }
        return unit;
    }
}

- (void) setWeatherPrecipUnit:(NSUnitLength *)weatherPrecipUnit
{
    @synchronized(_lock)
    {
        [_weatherPrecipUnitProfile set:weatherPrecipUnit];
        [_weatherPrecipUnitChangeObservable notifyEventWithKey:@(WEATHER_BAND_PRECIPITATION) andValue:self.weatherPrecipUnit];
    }
}

- (BOOL) weatherPrecipUnitAuto
{
    @synchronized(_lock)
    {
        return [_weatherPrecipUnitAutoProfile get];
    }
}

- (void) setWeatherPrecipUnitAuto:(BOOL)weatherPrecipUnitAuto
{
    @synchronized(_lock)
    {
        [_weatherPrecipUnitAutoProfile set:weatherPrecipUnitAuto];
        if (weatherPrecipUnitAuto)
        {
            NSUnitLength *current = [NSUnitLength current];
            if ([_weatherPrecipUnitProfile get] != current)
                [self setWeatherPrecipUnit:current];
        }
    }
}

- (double) weatherPrecipAlpha
{
    @synchronized (_lock)
    {
        return [_weatherPrecipAlphaProfile get];
    }
}

- (void) setWeatherPrecipAlpha:(double)weatherPrecipAlpha
{
    @synchronized(_lock)
    {
        [_weatherPrecipAlphaProfile set:weatherPrecipAlpha];
        [_weatherPrecipAlphaChangeObservable notifyEventWithKey:@(WEATHER_BAND_PRECIPITATION) andValue:@(self.weatherPrecipAlpha)];
    }
}

- (OAMapSource*) overlayMapSource
{
    @synchronized(_lock)
    {
        return [_overlayMapSourceProfile get];
    }
}

- (void) setOverlayMapSource:(OAMapSource*)overlayMapSource
{
    @synchronized(_lock)
    {
        [_overlayMapSourceProfile set:[overlayMapSource copy]];
        [_overlayMapSourceChangeObservable notifyEventWithKey:self andValue:self.overlayMapSource];
    }
}

- (OAMapSource*) lastOverlayMapSource
{
    @synchronized(_lock)
    {
        return [_lastOverlayMapSourceProfile get];
    }
}

- (void) setLastOverlayMapSource:(OAMapSource*)lastOverlayMapSource
{
    @synchronized(_lock)
    {
        [_lastOverlayMapSourceProfile set:[lastOverlayMapSource copy]];
    }
}

- (OAMapSource*) underlayMapSource
{
    @synchronized(_lock)
    {
        return [_underlayMapSourceProfile get];
    }
}

- (void) setUnderlayMapSource:(OAMapSource*)underlayMapSource
{
    @synchronized(_lock)
    {
        [_underlayMapSourceProfile set:[underlayMapSource copy]];
        [_underlayMapSourceChangeObservable notifyEventWithKey:self andValue:self.underlayMapSource];
    }
}

- (OAMapSource*) lastUnderlayMapSource
{
    @synchronized(_lock)
    {
        return [_lastUnderlayMapSourceProfile get];
    }
}

- (void) setLastUnderlayMapSource:(OAMapSource*)lastUnderlayMapSource
{
    @synchronized(_lock)
    {
        [_lastUnderlayMapSourceProfile set:[lastUnderlayMapSource copy]];
    }
}

- (double) overlayAlpha
{
    @synchronized (_lock)
    {
        return [_overlayAlphaProfile get];
    }
}

- (void) setOverlayAlpha:(double)overlayAlpha
{
    @synchronized(_lock)
    {
        [_overlayAlphaProfile set:overlayAlpha];
        [_overlayAlphaChangeObservable notifyEventWithKey:self andValue:@(self.overlayAlpha)];
    }
}

- (double) underlayAlpha
{
    @synchronized (_lock)
    {
        return [_underlayAlphaProfile get];
    }
}

- (void) setUnderlayAlpha:(double)underlayAlpha
{
    @synchronized(_lock)
    {
        [_underlayAlphaProfile set:underlayAlpha];
        [_underlayAlphaChangeObservable notifyEventWithKey:self andValue:@(self.underlayAlpha)];
    }
}

- (OAMapLayersConfiguration *)mapLayersConfiguration
{
    @synchronized (_lock)
    {
        return _mapLayersConfiguration;
    }
}

- (double) contoursAlpha
{
    @synchronized (_lock)
    {
        return [_contoursAlphaProfile get];
    }
}

- (void) setContoursAlpha:(double)contoursAlpha
{
    @synchronized(_lock)
    {
        [_contoursAlphaProfile set:contoursAlpha];
        [_contoursAlphaChangeObservable notifyEventWithKey:self andValue:@(self.overlayAlpha)];
    }
}

- (NSInteger) hillshadeMinZoom
{
    @synchronized(_lock)
    {
        return [_hillshadeMinZoomProfile get];
    }
}

- (void) setHillshadeMinZoom:(NSInteger)hillshadeMinZoom
{
    @synchronized(_lock)
    {
        [_hillshadeMinZoomProfile set:(int)hillshadeMinZoom];
        [_terrainChangeObservable notifyEventWithKey:self andValue:@(YES)];
    }
}

- (NSInteger) hillshadeMaxZoom
{
    @synchronized(_lock)
    {
        return [_hillshadeMaxZoomProfile get];
    }
}

- (void) setHillshadeMaxZoom:(NSInteger)hillshadeMaxZoom
{
    @synchronized(_lock)
    {
        [_hillshadeMaxZoomProfile set:(int)hillshadeMaxZoom];
        [_terrainChangeObservable notifyEventWithKey:self andValue:@(YES)];
    }
}

- (NSInteger) slopeMinZoom
{
    @synchronized(_lock)
    {
        return [_slopeMinZoomProfile get];
    }
}

- (void) setSlopeMinZoom:(NSInteger)slopeMinZoom
{
    @synchronized(_lock)
    {
        [_slopeMinZoomProfile set:(int)slopeMinZoom];
        [_terrainChangeObservable notifyEventWithKey:self andValue:@(YES)];
    }
}

- (NSInteger) slopeMaxZoom
{
    @synchronized(_lock)
    {
        return [_slopeMaxZoomProfile get];
    }
}

- (void) setSlopeMaxZoom:(NSInteger)slopeMaxZoom
{
    @synchronized(_lock)
    {
        [_slopeMaxZoomProfile set:(int)slopeMaxZoom];
        [_terrainChangeObservable notifyEventWithKey:self andValue:@(YES)];
    }
}

- (EOATerrainType) terrainType
{
    @synchronized(_lock)
    {
        return [_terrainTypeProfile get];
    }
}

- (void) setTerrainType:(EOATerrainType)terrainType
{
    @synchronized(_lock)
    {
        [_terrainTypeProfile set:terrainType];
        if (terrainType == EOATerrainTypeHillshade || terrainType == EOATerrainTypeSlope)
            [_terrainChangeObservable notifyEventWithKey:self andValue:@(YES)];
        else
            [_terrainChangeObservable notifyEventWithKey:self andValue:@(NO)];
    }
}

- (EOATerrainType) getTerrainType:(OAApplicationMode *)mode
{
    @synchronized (_lock)
    {
        return [_terrainTypeProfile get:mode];
    }
}

- (void) setTerrainType:(EOATerrainType)terrainType mode:(OAApplicationMode *)mode
{
    @synchronized (_lock)
    {
        [_terrainTypeProfile set:terrainType mode:mode];
    }
}

- (EOATerrainType) getLastTerrainType:(OAApplicationMode *)mode
{
    @synchronized (_lock)
    {
        return [_lastTerrainTypeProfile get:mode];
    }
}

- (void) setLastTerrainType:(EOATerrainType)terrainType mode:(OAApplicationMode *)mode
{
    @synchronized (_lock)
    {
        [_lastTerrainTypeProfile set:terrainType mode:mode];
    }
}

- (EOATerrainType) lastTerrainType
{
    @synchronized(_lock)
    {
        return [_lastTerrainTypeProfile get];
    }
}

- (void) setLastTerrainType:(EOATerrainType)lastTerrainType
{
    @synchronized(_lock)
    {
        [_lastTerrainTypeProfile set:lastTerrainType];
    }
}


- (double)hillshadeAlpha
{
    @synchronized (_lock)
    {
        return [_hillshadeAlphaProfile get];
    }
}

- (void) setHillshadeAlpha:(double)hillshadeAlpha
{
    @synchronized(_lock)
    {
        [_hillshadeAlphaProfile set:hillshadeAlpha];
        [_terrainAlphaChangeObservable notifyEventWithKey:self andValue:[NSNumber numberWithDouble:self.hillshadeAlpha]];
    }
}

- (double)slopeAlpha
{
    @synchronized (_lock)
    {
        return [_slopeAlphaProfile get];
    }
}

- (void) setSlopeAlpha:(double)slopeAlpha
{
    @synchronized(_lock)
    {
        [_slopeAlphaProfile set:slopeAlpha];
        [_terrainAlphaChangeObservable notifyEventWithKey:self andValue:[NSNumber numberWithDouble:self.slopeAlpha]];
    }
}

- (BOOL) mapillary
{
    @synchronized (_lock)
    {
        return [_mapillaryProfile get];
    }
}

- (void) setMapillary:(BOOL)mapillary
{
    @synchronized (_lock)
    {
        [_mapillaryProfile set:mapillary];
        [_mapillaryChangeObservable notifyEventWithKey:self andValue:[NSNumber numberWithBool:self.mapillary]];
    }
}

- (BOOL)wikipedia
{
    @synchronized (_lock)
    {
        return [[OAPOIFiltersHelper sharedInstance] isPoiFilterSelectedByFilterId:[OAPOIFiltersHelper getTopWikiPoiFilterId]];
    }
}

- (void)setWikipedia:(BOOL)wikipedia
{
    @synchronized (_lock)
    {
        OAWikipediaPlugin *plugin = (OAWikipediaPlugin *) [OAPlugin getPlugin:OAWikipediaPlugin.class];
        [plugin setEnabled:wikipedia];
        [plugin toggleWikipediaPoi:wikipedia];
        [_wikipediaChangeObservable notifyEventWithKey:self andValue:@(wikipedia)];
    }
}

- (BOOL)getWikipediaAllLanguages
{
    @synchronized (_lock)
    {
        return _wikipediaGlobalProfile.get;
    }
}

- (BOOL)getWikipediaAllLanguages:(OAApplicationMode *)mode
{
    @synchronized (_lock)
    {
        return [_wikipediaGlobalProfile get:mode];
    }
}

- (void)setWikipediaAllLanguages:(BOOL)allLanguages
{
    @synchronized (_lock)
    {
        [_wikipediaGlobalProfile set:allLanguages];
    }
}

- (void)setWikipediaAllLanguages:(BOOL)allLanguages mode:(OAApplicationMode *)mode
{
    @synchronized (_lock)
    {
        [_wikipediaGlobalProfile set:allLanguages mode:mode];
    }
}

- (NSArray<NSString *> *)getWikipediaLanguages
{
    @synchronized (_lock)
    {
        return _wikipediaLanguagesProfile.get;
    }
}

- (NSArray<NSString *> *)getWikipediaLanguages:(OAApplicationMode *)mode
{
    @synchronized (_lock)
    {
        return [_wikipediaLanguagesProfile get:mode];
    }
}

- (void)setWikipediaLanguages:(NSArray<NSString *> *)languages
{
    @synchronized (_lock)
    {
        [_wikipediaLanguagesProfile set:languages];
    }
}

- (void)setWikipediaLanguages:(NSArray<NSString *> *)languages mode:(OAApplicationMode *)mode
{
    @synchronized (_lock)
    {
        [_wikipediaLanguagesProfile set:languages mode:mode];
    }
}

@synthesize mapLastViewedState = _mapLastViewedState;

- (void) backupTargetPoints
{
    @synchronized (_lock)
    {
        _pointToNavigateBackup = _pointToNavigate;
        _pointToStartBackup = _pointToStart;
        _intermediatePointsBackup = [NSMutableArray arrayWithArray:_intermediates];
    }
}

- (void) restoreTargetPoints
{
    _pointToNavigate = _pointToNavigateBackup;
    _pointToStart = _pointToStartBackup;
    _intermediates = [NSMutableArray arrayWithArray:_intermediatePointsBackup];
}

- (BOOL) restorePointToStart
{
    return (_pointToStartBackup != nil);
}

- (void) setPointToStart:(OARTargetPoint *)pointToStart
{
    _pointToStart = pointToStart;
    [self backupTargetPoints];
}

- (void) setPointToNavigate:(OARTargetPoint *)pointToNavigate
{
    _pointToNavigate = pointToNavigate;
    if (pointToNavigate && pointToNavigate.pointDescription)
    {
        OAHistoryItem *h = [[OAHistoryItem alloc] init];
        h.name = pointToNavigate.pointDescription.name;
        h.latitude = [pointToNavigate getLatitude];
        h.longitude = [pointToNavigate getLongitude];
        h.date = [NSDate date];
        h.hType = [[OAHistoryItem alloc] initWithPointDescription:pointToNavigate.pointDescription].hType;
        
        [[OAHistoryHelper sharedInstance] addPoint:h];
    }
    
    [self backupTargetPoints];
}

- (NSArray<OARTargetPoint *> *) intermediatePoints
{
    return [NSArray arrayWithArray:_intermediates];
}

- (void) setIntermediatePoints:(NSArray<OARTargetPoint *> *)intermediatePoints
{
    _intermediates = [NSMutableArray arrayWithArray:intermediatePoints];
    [self backupTargetPoints];
}

- (void) addIntermediatePoint:(OARTargetPoint *)point
{
    [_intermediates addObject:point];
    [self backupTargetPoints];
}

- (void) insertIntermediatePoint:(OARTargetPoint *)point index:(int)index
{
    [_intermediates insertObject:point atIndex:index];
    [self backupTargetPoints];
}

- (void) deleteIntermediatePoint:(int)index
{
    [_intermediates removeObjectAtIndex:index];
    [self backupTargetPoints];
}

- (void) clearPointToStart
{
    _pointToStart = nil;
}

- (void) clearPointToNavigate
{
    _pointToNavigate = nil;
}

- (void) clearIntermediatePoints
{
    [_intermediates removeAllObjects];
}

#pragma mark - defaults

+ (OAAppData*) defaults
{
    OAAppData* defaults = [[OAAppData alloc] init];
    
    // Imagine that last viewed location was center of the world
    Point31 centerOfWorld;
    centerOfWorld.x = centerOfWorld.y = INT32_MAX>>1;
    defaults.mapLastViewedState.target31 = centerOfWorld;
    defaults.mapLastViewedState.zoom = 1.0f;
    defaults.mapLastViewedState.azimuth = 0.0f;
    defaults.mapLastViewedState.elevationAngle = 90.0f;

    return defaults;
}

+ (OAMapSource *) defaultMapSource
{
    return [[OAMapSource alloc] initWithResource:@"default.render.xml"
                                      andVariant:@"type_default"];
}

#pragma mark - NSCoding

#define kLastMapSources @"last_map_sources"
#define kMapLastViewedState @"map_last_viewed_state"
#define kDestinations @"destinations"

#define kPointToStart @"pointToStart"
#define kPointToNavigate @"pointToNavigate"
#define kIntermediatePoints @"intermediatePoints"

#define kPointToStartBackup @"pointToStartBackup"
#define kPointToNavigateBackup @"pointToNavigateBackup"
#define kIntermediatePointsBackup @"intermediatePointsBackup"

#define kMyLocationToStart @"myLocationToStart"

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_lastMapSources forKey:kLastMapSources];
    [aCoder encodeObject:_mapLastViewedState forKey:kMapLastViewedState];
    [aCoder encodeObject:_destinations forKey:kDestinations];
    
    [aCoder encodeObject:_pointToStart forKey:kPointToStart];
    [aCoder encodeObject:_pointToNavigate forKey:kPointToNavigate];
    [aCoder encodeObject:_intermediates forKey:kIntermediatePoints];
    [aCoder encodeObject:_pointToStartBackup forKey:kPointToStartBackup];
    [aCoder encodeObject:_pointToNavigateBackup forKey:kPointToNavigateBackup];
    [aCoder encodeObject:_intermediatePointsBackup forKey:kIntermediatePointsBackup];
    [aCoder encodeObject:_myLocationToStart forKey:kMyLocationToStart];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        [self commonInit];
        _lastMapSources = [aDecoder decodeObjectForKey:kLastMapSources];
        _mapLastViewedState = [aDecoder decodeObjectForKey:kMapLastViewedState];
        _destinations = [aDecoder decodeObjectForKey:kDestinations];

        _pointToStart = [aDecoder decodeObjectForKey:kPointToStart];
        _pointToNavigate = [aDecoder decodeObjectForKey:kPointToNavigate];
        _intermediates = [aDecoder decodeObjectForKey:kIntermediatePoints];
        _pointToStartBackup = [aDecoder decodeObjectForKey:kPointToStartBackup];
        _pointToNavigateBackup = [aDecoder decodeObjectForKey:kPointToNavigateBackup];
        _intermediatePointsBackup = [aDecoder decodeObjectForKey:kIntermediatePointsBackup];
        _myLocationToStart = [aDecoder decodeObjectForKey:kMyLocationToStart];
        
        [self safeInit];
    }
    return self;
}

- (void) resetProfileSettingsForMode:(OAApplicationMode *)mode
{
    for (OACommonPreference *value in [_registeredPreferences objectEnumerator].allObjects)
    {
        [value resetModeToDefault:mode];
    }
}

#pragma mark - Copying profiles

- (void) copyAppDataFrom:(OAApplicationMode *)sourceMode toMode:(OAApplicationMode *)targetMode
{
    [_mapLayersConfiguration resetConfigutation];
    [_lastMapSourceProfile set:[_lastMapSourceProfile get:sourceMode] mode:targetMode];
    [_overlayMapSourceProfile set:[_overlayMapSourceProfile get:sourceMode] mode:targetMode];
    [_underlayMapSourceProfile set:[_underlayMapSourceProfile get:sourceMode] mode:targetMode];
    [_lastOverlayMapSourceProfile set:[_lastOverlayMapSourceProfile get:sourceMode] mode:targetMode];
    [_lastUnderlayMapSourceProfile set:[_lastUnderlayMapSourceProfile get:sourceMode] mode:targetMode];
    [_overlayAlphaProfile set:[_overlayAlphaProfile get:sourceMode] mode:targetMode];
    [_underlayAlphaProfile set:[_underlayAlphaProfile get:sourceMode] mode:targetMode];
    [_contoursAlphaProfile set:[_contoursAlphaProfile get:sourceMode] mode:targetMode];
    [_terrainTypeProfile set:[_terrainTypeProfile get:sourceMode] mode:targetMode];
    [_lastTerrainTypeProfile set:[_lastTerrainTypeProfile get:sourceMode] mode:targetMode];
    [_hillshadeAlphaProfile set:[_hillshadeAlphaProfile get:sourceMode] mode:targetMode];
    [_slopeAlphaProfile set:[_slopeAlphaProfile get:sourceMode] mode:targetMode];
    [_hillshadeMinZoomProfile set:[_hillshadeMinZoomProfile get:sourceMode] mode:targetMode];
    [_hillshadeMaxZoomProfile set:[_hillshadeMaxZoomProfile get:sourceMode] mode:targetMode];
    [_slopeMinZoomProfile set:[_slopeMinZoomProfile get:sourceMode] mode:targetMode];
    [_slopeMaxZoomProfile set:[_slopeMaxZoomProfile get:sourceMode] mode:targetMode];
    [_mapillaryProfile set:[_mapillaryProfile get:sourceMode] mode:targetMode];
    [_wikipediaGlobalProfile set:[_wikipediaGlobalProfile get:sourceMode] mode:targetMode];
    [_wikipediaLanguagesProfile set:[_wikipediaLanguagesProfile get:sourceMode] mode:targetMode];

    [_weatherProfile set:[_weatherProfile get:sourceMode] mode:targetMode];
    [_weatherTempProfile set:[_weatherTempProfile get:sourceMode] mode:targetMode];
    [_weatherTempUnitProfile set:[_weatherTempUnitProfile get:sourceMode] mode:targetMode];
    [_weatherTempUnitAutoProfile set:[_weatherTempUnitAutoProfile get:sourceMode] mode:targetMode];
    [_weatherTempAlphaProfile set:[_weatherTempAlphaProfile get:sourceMode] mode:targetMode];
    [_weatherPressureProfile set:[_weatherPressureProfile get:sourceMode] mode:targetMode];
    [_weatherPressureUnitProfile set:[_weatherPressureUnitProfile get:sourceMode] mode:targetMode];
    [_weatherPressureUnitAutoProfile set:[_weatherPressureUnitAutoProfile get:sourceMode] mode:targetMode];
    [_weatherPressureAlphaProfile set:[_weatherPressureAlphaProfile get:sourceMode] mode:targetMode];
    [_weatherWindProfile set:[_weatherWindProfile get:sourceMode] mode:targetMode];
    [_weatherWindUnitProfile set:[_weatherWindUnitProfile get:sourceMode] mode:targetMode];
    [_weatherWindUnitAutoProfile set:[_weatherWindUnitAutoProfile get:sourceMode] mode:targetMode];
    [_weatherWindAlphaProfile set:[_weatherWindAlphaProfile get:sourceMode] mode:targetMode];
    [_weatherCloudProfile set:[_weatherCloudProfile get:sourceMode] mode:targetMode];
    [_weatherCloudUnitProfile set:[_weatherCloudUnitProfile get:sourceMode] mode:targetMode];
    [_weatherCloudUnitAutoProfile set:[_weatherCloudUnitAutoProfile get:sourceMode] mode:targetMode];
    [_weatherCloudAlphaProfile set:[_weatherCloudAlphaProfile get:sourceMode] mode:targetMode];
    [_weatherPrecipProfile set:[_weatherPrecipProfile get:sourceMode] mode:targetMode];
    [_weatherPrecipUnitProfile set:[_weatherPrecipUnitProfile get:sourceMode] mode:targetMode];
    [_weatherPrecipUnitAutoProfile set:[_weatherPrecipUnitAutoProfile get:sourceMode] mode:targetMode];
    [_weatherPrecipAlphaProfile set:[_weatherPrecipAlphaProfile get:sourceMode] mode:targetMode];
}

@end

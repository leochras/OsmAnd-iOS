//
//  OAAppVersionDependentConstants.h
//  OsmAnd
//
//  Created by nnngrach on 28.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kLatestChangesUrl @"https://osmand.net/blog/osmand-ios-4-1-released"

@interface OAAppVersionDependentConstants : NSObject

+ (NSString *) getShortAppVersion;
+ (NSString *) getShortAppVersionWithSeparator:(NSString *)separator;
+ (NSString *)getAppVersionWithBundle;

@end

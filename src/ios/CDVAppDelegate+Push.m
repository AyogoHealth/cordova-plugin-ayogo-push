/*! Copyright 2018 Ayogo Health Inc. */

#import "CDVAppDelegate+Push.h"

@implementation CDVAppDelegate (push)

- (void) application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken: (NSData *) deviceToken {
    NSString* token = [[[[deviceToken description]
        stringByReplacingOccurrencesOfString:@"<" withString:@""]
        stringByReplacingOccurrencesOfString:@">" withString:@""]
        stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    [NSNotificationCenter.defaultCenter postNotificationName: @"CordovaDidRegisterForRemoteNotificationsWithDeviceToken" object: token];
}

- (void) application:(UIApplication *) application didFailToRegisterForRemoteNotificationsWithError: (NSError *) error {
    [NSNotificationCenter.defaultCenter postNotificationName: @"CordovaDidFailToRegisterForRemoteNotificationsWithError" object: error];
}

- (void) application:(UIApplication *) application didReceiveRemoteNotification: (NSDictionary *) userInfo fetchCompletionHandler: (void (^)(UIBackgroundFetchResult result)) completionHandler {
    if ([userInfo objectForKey:@"url"] != nil) {
        NSURL * url = [NSURL URLWithString: [userInfo objectForKey:@"url"]];
        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:CDVPluginHandleOpenURLNotification object:url]];
    }

    completionHandler(UIBackgroundFetchResultNewData);
}

@end

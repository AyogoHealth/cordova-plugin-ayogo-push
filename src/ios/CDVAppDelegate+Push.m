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

- (void) userNotificationCenter: (UNUserNotificationCenter *) center willPresentNotification: (UNNotification *) notification withCompletionHandler: (void (^)(UNNotificationPresentationOptions options)) completionHandler {
    completionHandler(UNNotificationPresentationOptionAlert | UNNotificationPresentationOptionSound);
}

@end

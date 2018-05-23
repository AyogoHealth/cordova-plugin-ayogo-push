/*! Copyright 2018 Ayogo Health Inc. */

#import "Cordova/CDVAppDelegate.h"

@interface CDVAppDelegate (push)

- (void) application:(UIApplication *) application didRegisterForRemoteNotificationsWithDeviceToken: (NSData *) deviceToken;
- (void) application:(UIApplication *) application didFailToRegisterForRemoteNotificationsWithError: (NSError *) error;
- (void) application:(UIApplication *) application didReceiveRemoteNotification: (NSDictionary *) userInfo fetchCompletionHandler: (void (^)(UIBackgroundFetchResult result)) completionHandler;

@end

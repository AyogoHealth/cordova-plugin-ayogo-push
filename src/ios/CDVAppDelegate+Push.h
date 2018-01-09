/*! Copyright 2018 Ayogo Health Inc. */

#import "Cordova/CDVAppDelegate.h"

@interface CDVAppDelegate (appScope)

- (void) application:(UIApplication *) application didRegisterForRemoteNotificationsWithDeviceToken: (NSData *) deviceToken;
- (void) application:(UIApplication *) application didFailToRegisterForRemoteNotificationsWithError: (NSError *) error;
- (void) userNotificationCenter: (UNUserNotificationCenter *) center willPresentNotification: (UNNotification *) notification withCompletionHandler: (void (^)(UNNotificationPresentationOptions options)) completionHandler;

@end

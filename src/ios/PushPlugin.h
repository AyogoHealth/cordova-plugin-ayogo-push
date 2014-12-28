// Copyright 2014 Ayogo Health Inc.

#import <Cordova/CDVPlugin.h>

@interface PushPlugin : CDVPlugin

- (void) register:(CDVInvokedUrlCommand*)command;
- (void) unregister:(CDVInvokedUrlCommand*)command;
- (void) getRegistration:(CDVInvokedUrlCommand*)command;
- (void) hasPermission:(CDVInvokedUrlCommand*)command;


- (void) didRegisterForRemoteNotificationsWithDeviceToken:(NSNotification*)notification;
- (void) didFailToRegisterForRemoteNotificationsWithError:(NSNotification*)notification;

@end

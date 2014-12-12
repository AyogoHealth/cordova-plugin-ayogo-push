// Copyright 2014 Ayogo Health Inc.

#import "PushPlugin.h"

@interface PushPlugin ()

@property (nonatomic, strong) NSString* registrationCallbackId;
@property (nonatomic, strong) NSDictionary* pushRegistration;

@end


@implementation PushPlugin

- (void) pluginInitialize
{
    self.registrationCallbackId = nil;
    self.pushRegistration = nil;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRegisterForRemoteNotificationsWithDeviceToken:) name:CDVRemoteNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFailToRegisterForRemoteNotificationsWithError:) name:CDVRemoteNotificationError object:nil];
}


- (void) register:(CDVInvokedUrlCommand*)command
{
    self.registrationCallbackId = command.callbackId;

    UIRemoteNotificationType notificationTypes = UIRemoteNotificationTypeNone;

    notificationTypes |= UIRemoteNotificationTypeAlert;
    notificationTypes |= UIRemoteNotificationTypeSound;
    notificationTypes |= UIRemoteNotificationTypeBadge;
    notificationTypes |= UIRemoteNotificationTypeNewsstandContentAvailability;

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    UIUserNotificationType userNotificationTypes = UIUserNotificationTypeNone;

    userNotificationTypes |= UIUserNotificationTypeAlert;
    userNotificationTypes |= UIUserNotificationTypeSound;
    userNotificationTypes |= UIUserNotificationTypeBadge;
    userNotificationTypes |= UIUserNotificationActivationModeBackground;
#endif

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    if ([[UIApplication sharedApplication]respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationSettings* settings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    } else {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:notificationTypes];
    }
#else
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:notificationTypes];
#endif
}


- (void) getRegistration:(CDVInvokedUrlCommand*)command
{
    NSString* callbackId = command.callbackId;
    CDVPluginResult* result = nil;

    if (self.pushRegistration == nil)
    {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"AbortError"];
    }
    else
    {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:self.pushRegistration];
    }

    [self.commandDelegate sendPluginResult:result callbackId:callbackId];
}


- (void) hasPermission:(CDVInvokedUrlCommand*)command
{
    NSString* callbackId = command.callbackId;
    NSString* permission = @"default";

    UIApplication* application = [UIApplication sharedApplication];

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
        if ([application isRegisteredForRemoteNotifications])
        {
            permission = @"granted";
        }
        else
        {
            permission = @"denied";
        }
#else
        UIRemoteNotificationType types = [application enabledRemoteNotificationTypes];
        if (types & UIRemoteNotificationTypeAlert)
        {
            permission = @"granted";
        }
        else
        {
            permission = @"denied";
        }
#endif

    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:permission];
    [self.commandDelegate sendPluginResult:result callbackId:callbackId];
}



- (void) didRegisterForRemoteNotificationsWithDeviceToken:(NSNotification*)notification
{
    NSString* token = [notification object];

    NSLog(@"REGISTERED WITH DEVICE TOKEN: %@", token);

    self.pushRegistration = @{
        @"endpoint"         : @"ios",
        @"registrationId"   : token
    };

    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:self.pushRegistration];
    [self.commandDelegate sendPluginResult:result callbackId:self.registrationCallbackId];

    self.registrationCallbackId = nil;
}


- (void) didFailToRegisterForRemoteNotificationsWithError:(NSNotification*)notification
{
    NSError* error = [notification object];

    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"AbortError"];
    [self.commandDelegate sendPluginResult:result callbackId:self.registrationCallbackId];

    self.registrationCallbackId = nil;
}

@end

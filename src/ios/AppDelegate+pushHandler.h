// Copyright 2014 Ayogo Health Inc.

#import "AppDelegate.h"

@interface AppDelegate (pushHandler)

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo;
- (void)applicationDidBecomeActive:(UIApplication*)application;

@property (nonatomic, strong) NSDictionary* pushParameters;

@end

// Copyright 2014 Ayogo Health Inc.

#import "AppDelegate+pushHandler.h"

#import <objc/runtime.h>

@implementation AppDelegate (pushHandler)

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    NSLog(@"didReceiveNotification");

    self.pushParameters = userInfo;
}


- (void)applicationDidBecomeActive:(UIApplication*)application
{
    application.applicationIconBadgeNumber = 0;

    if (self.pushParameters && [self.pushParameters objectForKey:@"url"] != nil)
    {
        NSString* urlLink = [self.pushParameters objectForKey:@"url"];
        NSURL *url = [NSURL URLWithString:urlLink];

        if (![[UIApplication sharedApplication] openURL:url]) {
            NSLog(@"Failed to open url:%@", [url description]);
        }
    }

    self.pushParameters = nil;
}



- (NSDictionary*)pushParameters
{
    return objc_getAssociatedObject(self, @selector(pushParameters));
}

- (void)setPushParameters:(NSDictionary*)params
{
    objc_setAssociatedObject(self, @selector(pushParameters), params, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)dealloc
{
    self.pushParameters = nil; // clear the association and release the object
}

@end

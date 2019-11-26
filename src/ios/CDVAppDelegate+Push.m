/**
 * Copyright 2018 Ayogo Health Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "CDVAppDelegate+Push.h"

@implementation CDVAppDelegate (push)

- (void) application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken: (NSData *) deviceToken {
    const unsigned char *dataBuffer = (const unsigned char *)[deviceToken bytes];

    NSUInteger          dataLength  = [deviceToken length];
    NSMutableString     *hexString  = [NSMutableString stringWithCapacity:(dataLength * 2)];

    for (int i = 0; i < dataLength; ++i)
        [hexString appendString:[NSString stringWithFormat:@"%02lx", (unsigned long)dataBuffer[i]]];

     NSString* token = [NSString stringWithString:hexString];

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

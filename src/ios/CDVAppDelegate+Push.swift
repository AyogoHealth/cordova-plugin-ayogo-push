/*! Copyright 2016 Ayogo Health Inc. */

#if swift(>=2.3)
import UserNotifications;
#endif

// NSUserDefaults key names
let CDV_PushPreference      = "CordovaPushPreference";
let CDV_PushRegistration    = "CordovaPushRegistration";

// Notification Center hooks
let CordovaDidRegisterForRemoteNotificationsWithDeviceToken = "CordovaDidRegisterForRemoteNotificationsWithDeviceToken";
let CordovaDidFailToRegisterForRemoteNotificationsWithError = "CordovaDidFailToRegisterForRemoteNotificationsWithError";

extension CDVAppDelegate {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let description  = deviceToken.description;
        let token = description.replacingOccurrences(of: "<", with:"").replacingOccurrences(of: ">", with: "").replacingOccurrences(of: " ", with :"");
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: CordovaDidRegisterForRemoteNotificationsWithDeviceToken), object: token);
    }


    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: CordovaDidFailToRegisterForRemoteNotificationsWithError), object: error);
    }
}

#if swift(>=2.3)
@available(iOS 10.0, *)
extension CDVAppDelegate : UNUserNotificationCenterDelegate {
    public func userNotificationCenter(center: UNUserNotificationCenter, willPresentNotification notification: UNNotification, withCompletionHandler completionHandler: (UNNotificationPresentationOptions) -> Void) {
        // Show the notification while in the foreground
        completionHandler([.alert, .sound]);
    }
}
#endif

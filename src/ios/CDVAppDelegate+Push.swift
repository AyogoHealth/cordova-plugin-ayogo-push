/*! Copyright 2016 Ayogo Health Inc. */

#if swift(>=2.3)
import UserNotifications;
#endif

// NSUserDefaults key names
let CDV_PushPreference      = "CordovaPushPreference";
let CDV_PushRegistration    = "CordovaPushRegistration";

// Notification Center hooks
let CordovaDidRegisterUserNotificationSettings = "CordovaDidRegisterUserNotificationSettings";
let CordovaDidRegisterForRemoteNotificationsWithDeviceToken = "CordovaDidRegisterForRemoteNotificationsWithDeviceToken";
let CordovaDidFailToRegisterForRemoteNotificationsWithError = "CordovaDidFailToRegisterForRemoteNotificationsWithError";


// Keep track of swizzled methods
private var _CDV_didRegisterUserNotificationSettings        = false;
private var _CDV_didRegisterForRemoteNotifications          = false;
private var _CDV_didFailToRegisterForRemoteNotifications    = false;
private var _CDV_willFinishLaunchingWithOptions             = false;



func _swizzleMethod(klass : AnyClass, original : Selector, replacement : Selector) -> Bool {
    let originalMethod = class_getInstanceMethod(klass, original);
    let swizzledMethod = class_getInstanceMethod(klass, replacement);

    if class_addMethod(klass, original, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod)) {
        class_replaceMethod(klass, replacement, method_getImplementation(originalMethod), method_getTypeEncoding(swizzledMethod));
        return false;
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
        return true;
    }
}



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

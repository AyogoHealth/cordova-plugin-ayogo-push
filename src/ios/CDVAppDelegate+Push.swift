/*! Copyright 2016 Ayogo Health Inc. */

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

    public override static func initialize() {
        struct Static {
            static var token : dispatch_once_t = 0;
        }

        if self !== CDVAppDelegate.self {
            return;
        }


        dispatch_once(&Static.token) {
            _CDV_didRegisterUserNotificationSettings = _swizzleMethod(self,
                original: #selector(UIApplicationDelegate.application(_:didRegisterUserNotificationSettings:)),
                replacement: #selector(CDVAppDelegate.CordovaApplication(_:didRegisterUserNotificationSettings:)));

            _CDV_didRegisterForRemoteNotifications = _swizzleMethod(self,
                original: #selector(UIApplicationDelegate.application(_:didRegisterForRemoteNotificationsWithDeviceToken:)),
                replacement: #selector(CDVAppDelegate.CordovaApplication(_:didRegisterForRemoteNotificationsWithDeviceToken:)));

            _CDV_didFailToRegisterForRemoteNotifications = _swizzleMethod(self,
                original: #selector(UIApplicationDelegate.application(_:didFailToRegisterForRemoteNotificationsWithError:)),
                replacement: #selector(CDVAppDelegate.CordovaApplication(_:didFailToRegisterForRemoteNotificationsWithError:)));
        }
    }



    func CordovaApplication(application : UIApplication, didRegisterUserNotificationSettings notificationSettings : UIUserNotificationSettings) {
        NSNotificationCenter.defaultCenter().postNotificationName(CordovaDidRegisterUserNotificationSettings, object: notificationSettings);

        if _CDV_didRegisterUserNotificationSettings {
            // Call the original implementation (if any)
            return self.CordovaApplication(application, didRegisterUserNotificationSettings:notificationSettings);
        }
    }


    func CordovaApplication(application : UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken : NSData) {
        let description  = deviceToken.description;
        let token = description.stringByReplacingOccurrencesOfString("<", withString:"").stringByReplacingOccurrencesOfString(">", withString:"").stringByReplacingOccurrencesOfString(" ", withString:"");

        NSNotificationCenter.defaultCenter().postNotificationName(CordovaDidRegisterForRemoteNotificationsWithDeviceToken, object: token);

        if _CDV_didRegisterForRemoteNotifications {
            // Call the original implementation (if any)
            return self.CordovaApplication(application, didRegisterForRemoteNotificationsWithDeviceToken:deviceToken);
        }
    }


    func CordovaApplication(application : UIApplication, didFailToRegisterForRemoteNotificationsWithError error : NSError) {
        NSNotificationCenter.defaultCenter().postNotificationName(CordovaDidFailToRegisterForRemoteNotificationsWithError, object: error);

        if _CDV_didFailToRegisterForRemoteNotifications {
            // Call the original implementation (if any)
            return self.CordovaApplication(application, didFailToRegisterForRemoteNotificationsWithError:error);
        }
    }
}

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

    open static func loadPush() {

        if self !== CDVAppDelegate.self {
            return;
        }

        struct Inner {
            static let i: () = {
                _CDV_didRegisterUserNotificationSettings = _swizzleMethod(klass: CDVAppDelegate.self,
                                                                          original: #selector(UIApplicationDelegate.application(_:didRegister:)),
                                                                          replacement: #selector(CDVAppDelegate.CordovaApplication(_:didRegister:)));

                _CDV_willFinishLaunchingWithOptions = _swizzleMethod(klass: CDVAppDelegate.self,
                                                                     original: #selector(UIApplicationDelegate.application(_:willFinishLaunchingWithOptions:)),
                                                                     replacement: #selector(CDVAppDelegate.CordovaApplication(_:willFinishLaunchingWithOptions:)));

            }()
        }
        let _ = Inner.i

    }



    @objc func CordovaApplication(_ application : UIApplication, didRegister notificationSettings : UIUserNotificationSettings) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: CordovaDidRegisterUserNotificationSettings), object: notificationSettings);

        if _CDV_didRegisterUserNotificationSettings {
            // Call the original implementation (if any)
            return self.CordovaApplication(application, didRegister: notificationSettings);
        }
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let description  = deviceToken.description;
        let token = description.replacingOccurrences(of: "<", with:"").replacingOccurrences(of: ">", with: "").replacingOccurrences(of: " ", with :"");
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: CordovaDidRegisterForRemoteNotificationsWithDeviceToken), object: token);
    }


    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: CordovaDidFailToRegisterForRemoteNotificationsWithError), object: error);
    }


    @objc func CordovaApplication(_ application : UIApplication, willFinishLaunchingWithOptions launchOptions: NSDictionary) {
        #if swift(>=2.3)
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self;
        }
        #endif

        if _CDV_willFinishLaunchingWithOptions {
            return self.CordovaApplication(application, willFinishLaunchingWithOptions:launchOptions);
        }
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

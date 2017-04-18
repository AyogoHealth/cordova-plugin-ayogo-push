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

    open override static func initialize() {

        if self !== CDVAppDelegate.self {
            return;
        }

        struct Inner {
            static let i: () = {
                _CDV_didRegisterUserNotificationSettings = _swizzleMethod(klass: CDVAppDelegate.self,
                                                                          original: #selector(UIApplicationDelegate.application(_:didRegister:)),
                                                                          replacement: #selector(CDVAppDelegate.CordovaApplication(_:didRegister:)));

                _CDV_didRegisterForRemoteNotifications = _swizzleMethod(klass: CDVAppDelegate.self,
                                                                        original: #selector(UIApplicationDelegate.application(_:didRegisterForRemoteNotificationsWithDeviceToken:)),
                                                                        replacement: #selector(CDVAppDelegate.CordovaApplication(_:didRegisterForRemoteNotificationsWithDeviceToken:)));

                _CDV_didFailToRegisterForRemoteNotifications = _swizzleMethod(klass: CDVAppDelegate.self,
                                                                              original: #selector(UIApplicationDelegate.application(_:didFailToRegisterForRemoteNotificationsWithError:)),
                                                                              replacement: #selector(CDVAppDelegate.CordovaApplication(_:didFailToRegisterForRemoteNotificationsWithError:)));

                _CDV_willFinishLaunchingWithOptions = _swizzleMethod(klass: CDVAppDelegate.self,
                                                                     original: #selector(UIApplicationDelegate.application(_:willFinishLaunchingWithOptions:)),
                                                                     replacement: #selector(CDVAppDelegate.CordovaApplication(_:willFinishLaunchingWithOptions:)));

            }()
        }
        let _ = Inner.i

    }



    func CordovaApplication(_ application : UIApplication, didRegister notificationSettings : UIUserNotificationSettings) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: CordovaDidRegisterUserNotificationSettings), object: notificationSettings);

        if _CDV_didRegisterUserNotificationSettings {
            // Call the original implementation (if any)
            return self.CordovaApplication(application, didRegister: notificationSettings);
        }
    }


    func CordovaApplication(_ application : UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken : NSData) {
        let description  = deviceToken.description;
        let token = description.replacingOccurrences(of: "<", with:"").replacingOccurrences(of: ">", with: "").replacingOccurrences(of: " ", with :"");

        NotificationCenter.default.post(name: NSNotification.Name(rawValue: CordovaDidRegisterForRemoteNotificationsWithDeviceToken), object: token);

        if _CDV_didRegisterForRemoteNotifications {
            // Call the original implementation (if any)
            return self.CordovaApplication(application, didRegisterForRemoteNotificationsWithDeviceToken:deviceToken);
        }
    }


    func CordovaApplication(_ application : UIApplication, didFailToRegisterForRemoteNotificationsWithError error : NSError) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: CordovaDidFailToRegisterForRemoteNotificationsWithError), object: error);

        if _CDV_didFailToRegisterForRemoteNotifications {
            // Call the original implementation (if any)
            return self.CordovaApplication(application, didFailToRegisterForRemoteNotificationsWithError:error);
        }
    }


    func CordovaApplication(_ application : UIApplication, willFinishLaunchingWithOptions launchOptions: NSDictionary) {
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

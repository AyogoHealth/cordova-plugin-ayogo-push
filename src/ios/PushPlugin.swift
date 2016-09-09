/*! Copyright 2016 Ayogo Health Inc. */

#if swift(>=2.3)
import UserNotifications
#endif

@objc(CDVPushPlugin) class PushPlugin : CDVPlugin {
    private var registrationCallback : String? = nil;


    override func pluginInitialize() {
        NSNotificationCenter.defaultCenter().addObserver(self,
                selector: #selector(PushPlugin._didRegisterUserNotificationSettings(_:)),
                name: CordovaDidRegisterUserNotificationSettings,
                object: nil);

        NSNotificationCenter.defaultCenter().addObserver(self,
                selector: #selector(PushPlugin._didRegisterForRemoteNotifications(_:)),
                name: CordovaDidRegisterForRemoteNotificationsWithDeviceToken,
                object: nil);

        NSNotificationCenter.defaultCenter().addObserver(self,
                selector: #selector(PushPlugin._didFailToRegisterForRemoteNotifications(_:)),
                name: CordovaDidFailToRegisterForRemoteNotificationsWithError,
                object: nil);

        NSNotificationCenter.defaultCenter().addObserver(self,
                selector: #selector(PushPlugin._didFinishLaunchingWithOptions(_:)),
                name: UIApplicationDidFinishLaunchingNotification,
                object: nil);


        // Re-register for notifications if we think we're registered
        let permission = NSUserDefaults.standardUserDefaults().stringForKey(CDV_PushPreference);
        if permission == "granted" {
            self._doRegister();
        }

        let registration = NSUserDefaults.standardUserDefaults().objectForKey(CDV_PushRegistration);
        if registration != nil {
            UIApplication.sharedApplication().registerForRemoteNotifications();
        }
    }



    /* Notification Permission ***********************************************/

    func hasPermission(command : CDVInvokedUrlCommand) {
        var permission = NSUserDefaults.standardUserDefaults().stringForKey(CDV_PushPreference);

        if permission == nil {
            permission = "default";
        }

        // Ensure that it matches the current notification settings
        let settings = UIApplication.sharedApplication().currentUserNotificationSettings();
        if settings != nil && settings!.types == UIUserNotificationType.None && permission != "default" {
            permission = "denied";
        }

        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAsString: permission);
        self.commandDelegate.sendPluginResult(result, callbackId: command.callbackId);
    }


    internal func _doRegister() {
        #if swift(>=2.3)
        if #available(iOS 10.0, *) {
            let options: UNAuthorizationOptions = [.Badge, .Alert, .Sound];

            UNUserNotificationCenter.currentNotificationCenter().requestAuthorizationWithOptions(options) { (granted, error) in
                if granted {
                    NSUserDefaults.standardUserDefaults().setObject("granted", forKey:CDV_PushPreference);
                } else {
                    NSUserDefaults.standardUserDefaults().setObject("denied", forKey:CDV_PushPreference);
                }
            }
        } else
        #endif

        // Note that this falls into the `else` block from above on iOS 10
        UIApplication.sharedApplication().registerUserNotificationSettings(UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil));
    }


    internal func _didRegisterUserNotificationSettings(notification : NSNotification) {
        let settings = notification.object as! UIUserNotificationSettings;

        if settings.types == UIUserNotificationType.None {
            NSUserDefaults.standardUserDefaults().setObject("denied", forKey:CDV_PushPreference);
        } else {
            NSUserDefaults.standardUserDefaults().setObject("granted", forKey:CDV_PushPreference);
        }
    }



    /* Push Notification Registrations ***************************************/

    func registerPush(command : CDVInvokedUrlCommand) {
        self.registrationCallback = command.callbackId;

        let permission = NSUserDefaults.standardUserDefaults().stringForKey(CDV_PushPreference);

        if permission != "denied" {
            self._doRegister();
            UIApplication.sharedApplication().registerForRemoteNotifications();
        } else {
            let result = CDVPluginResult(status:CDVCommandStatus_ERROR, messageAsString:"AbortError");
            self.commandDelegate.sendPluginResult(result, callbackId: self.registrationCallback);

            self.registrationCallback = nil;
        }
    }


    func unregisterPush(command : CDVInvokedUrlCommand) {
        UIApplication.sharedApplication().unregisterForRemoteNotifications();

        let registration = NSUserDefaults.standardUserDefaults().objectForKey(CDV_PushRegistration);

        if registration == nil {
            let result = CDVPluginResult(status:CDVCommandStatus_ERROR, messageAsString:"AbortError");
            self.commandDelegate.sendPluginResult(result, callbackId: command.callbackId);
            return;
        }

        NSUserDefaults.standardUserDefaults().removeObjectForKey(CDV_PushRegistration);

        let result = CDVPluginResult(status:CDVCommandStatus_OK, messageAsDictionary:registration as! [String:String]);
        self.commandDelegate.sendPluginResult(result, callbackId: command.callbackId);
    }


    func getPushRegistration(command : CDVInvokedUrlCommand) {
        // Fail immediately if notifications aren't registered
        if !UIApplication.sharedApplication().isRegisteredForRemoteNotifications() {
            let result = CDVPluginResult(status:CDVCommandStatus_ERROR, messageAsString:"AbortError");
            self.commandDelegate.sendPluginResult(result, callbackId: command.callbackId);
            return;
        }

        let registration = NSUserDefaults.standardUserDefaults().objectForKey(CDV_PushRegistration);

        if registration == nil {
            let result = CDVPluginResult(status:CDVCommandStatus_ERROR, messageAsString:"AbortError");
            self.commandDelegate.sendPluginResult(result, callbackId: command.callbackId);
        } else {
            let result = CDVPluginResult(status:CDVCommandStatus_OK, messageAsDictionary:registration as! [String:String]);
            self.commandDelegate.sendPluginResult(result, callbackId: command.callbackId);
        }
    }


    internal func _didRegisterForRemoteNotifications(notification : NSNotification) {
        let token = notification.object as! String;

        NSLog("REGISTERED WITH DEVICE TOKEN: \(token)");

        let registration = ["endpoint": "ios", "registrationId": token];

        NSUserDefaults.standardUserDefaults().setObject(registration, forKey:CDV_PushRegistration);

        let result = CDVPluginResult(status:CDVCommandStatus_OK, messageAsDictionary:registration);
        self.commandDelegate.sendPluginResult(result, callbackId: self.registrationCallback);

        self.registrationCallback = nil;
    }


    internal func _didFailToRegisterForRemoteNotifications(notification : NSNotification) {
        let result = CDVPluginResult(status:CDVCommandStatus_ERROR, messageAsString:"AbortError");
        self.commandDelegate.sendPluginResult(result, callbackId: self.registrationCallback);

        self.registrationCallback = nil;
    }



    /* Local Notification Scheduling *****************************************/

    func showNotification(command : CDVInvokedUrlCommand) {
        let title   = command.argumentAtIndex(0) as! String;
        var options = command.argumentAtIndex(1) as? NSDictionary;


        #if swift(>=2.3)
        if #available(iOS 10.0, *) {
            let content = UNMutableNotificationContent();

            if let body = options?.objectForKey("body") as? String {
                content.title = title;
                content.body = body;
            } else {
                content.body = title;
            }

            content.threadIdentifier = options?.objectForKey("tag") as? String;
            content.sound = UNNotificationSound.default();
            content.userInfo = options?.objectForKey("data") as? NSDictionary;

            /*
            if let delay = options?.objectForKey("at") as? Double {
                let 
            }
            */
        }
        #endif
    }


    func closeNotification(command : CDVInvokedUrlCommand) {
    }

    func getNotifications(command : CDVInvokedUrlCommand) {
    }





    /* Notification Launch URL handling **************************************/

    internal func _didFinishLaunchingWithOptions(notification : NSNotification) {
        UIApplication.sharedApplication().applicationIconBadgeNumber = 0;

        let options = notification.userInfo;
        if options == nil {
            return;
        }


        if let remoteNotification = options?[UIApplicationLaunchOptionsRemoteNotificationKey] as! NSDictionary! {
            if let url = remoteNotification["url"] as! String! {
                let data = NSURL(string: url);

                NSNotificationCenter.defaultCenter().postNotificationName(CDVPluginHandleOpenURLNotification, object: data);
            }
        }
    }
}

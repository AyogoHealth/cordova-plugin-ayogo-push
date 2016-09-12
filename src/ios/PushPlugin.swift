/*! Copyright 2016 Ayogo Health Inc. */

#if swift(>=2.3)
import UserNotifications;
#endif

@objc(CDVPushPlugin)
class PushPlugin : CDVPlugin {
    private var registrationCallback : String? = nil;
    private var permissionCallback : String? = nil;


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
                let permission = granted ? "granted" : "denied";

                NSUserDefaults.standardUserDefaults().setObject(permission, forKey:CDV_PushPreference);

                if let callback = self.permissionCallback {
                    let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAsString: permission);
                    self.commandDelegate.sendPluginResult(result, callbackId: callback);

                    self.permissionCallback = nil;
                }
            }

            return;
        }
        #endif

        // Note that this falls into the `else` block from above on iOS 10
        UIApplication.sharedApplication().registerUserNotificationSettings(UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil));
    }


    internal func _didRegisterUserNotificationSettings(notification : NSNotification) {
        let settings = notification.object as! UIUserNotificationSettings;
        let permission = (settings.types == UIUserNotificationType.None) ? "denied" : "granted";

        NSUserDefaults.standardUserDefaults().setObject(permission, forKey:CDV_PushPreference);

        if let callback = self.permissionCallback {
            let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAsString: permission);
            self.commandDelegate.sendPluginResult(result, callbackId: callback);

            self.permissionCallback = nil;
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
            let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString:"AbortError");
            self.commandDelegate.sendPluginResult(result, callbackId: self.registrationCallback);

            self.registrationCallback = nil;
        }
    }


    func unregisterPush(command : CDVInvokedUrlCommand) {
        UIApplication.sharedApplication().unregisterForRemoteNotifications();

        let registration = NSUserDefaults.standardUserDefaults().objectForKey(CDV_PushRegistration);

        if registration == nil {
            let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString:"AbortError");
            self.commandDelegate.sendPluginResult(result, callbackId: command.callbackId);
            return;
        }

        NSUserDefaults.standardUserDefaults().removeObjectForKey(CDV_PushRegistration);

        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAsDictionary:registration as! [String:String]);
        self.commandDelegate.sendPluginResult(result, callbackId: command.callbackId);
    }


    func getPushRegistration(command : CDVInvokedUrlCommand) {
        // Fail immediately if notifications aren't registered
        if !UIApplication.sharedApplication().isRegisteredForRemoteNotifications() {
            let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString:"AbortError");
            self.commandDelegate.sendPluginResult(result, callbackId: command.callbackId);
            return;
        }

        let registration = NSUserDefaults.standardUserDefaults().objectForKey(CDV_PushRegistration);

        if registration == nil {
            let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString:"AbortError");
            self.commandDelegate.sendPluginResult(result, callbackId: command.callbackId);
        } else {
            let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAsDictionary:registration as! [String:String]);
            self.commandDelegate.sendPluginResult(result, callbackId: command.callbackId);
        }
    }


    internal func _didRegisterForRemoteNotifications(notification : NSNotification) {
        let token = notification.object as! String;

        NSLog("REGISTERED WITH DEVICE TOKEN: \(token)");

        let registration = ["endpoint": "ios", "registrationId": token];

        NSUserDefaults.standardUserDefaults().setObject(registration, forKey:CDV_PushRegistration);

        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAsDictionary:registration);
        self.commandDelegate.sendPluginResult(result, callbackId: self.registrationCallback);

        self.registrationCallback = nil;
    }


    internal func _didFailToRegisterForRemoteNotifications(notification : NSNotification) {
        let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString:"AbortError");
        self.commandDelegate.sendPluginResult(result, callbackId: self.registrationCallback);

        self.registrationCallback = nil;
    }



    /* Local Notification Scheduling *****************************************/

    func requestPermission(command : CDVInvokedUrlCommand) {
        let permission = NSUserDefaults.standardUserDefaults().stringForKey(CDV_PushPreference);

        if permission == nil {
            self.permissionCallback = command.callbackId;
            self._doRegister();
        } else {
            let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAsString:permission);
            self.commandDelegate.sendPluginResult(result, callbackId: command.callbackId);
        }
    }


    func showNotification(command : CDVInvokedUrlCommand) {
        guard let title = command.argumentAtIndex(0) as? String else {
            self.commandDelegate.sendPluginResult(CDVPluginResult(status: CDVCommandStatus_ERROR), callbackId: command.callbackId);
            return;
        }

        let options = command.argumentAtIndex(1) as? NSDictionary;


        let permission = NSUserDefaults.standardUserDefaults().stringForKey(CDV_PushPreference);
        if permission != "granted" {
            let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString:"TypeError");
            self.commandDelegate.sendPluginResult(result, callbackId: command.callbackId);
            return;
        }


        let id : String = options?.objectForKey("tag") as? String ?? command.callbackId;

        #if swift(>=2.3)
        if #available(iOS 10.0, *) {
            let content = UNMutableNotificationContent();

            content.title = title;
            //content.sound = UNNotificationSound.`default`();

            if let body = options?.objectForKey("body") as? String {
                content.body = body;
            }

            if let data = options?.objectForKey("data") as? [NSObject : AnyObject] {
                content.userInfo = data;
            }

            var trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: 1, repeats: false);

            if let at = options?.objectForKey("at")?.doubleValue {
                let scheduleDate = NSDate(timeIntervalSince1970: at/1000.0);
                trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: scheduleDate.timeIntervalSinceDate(NSDate()), repeats: false);
            }

            let request = UNNotificationRequest.init(identifier: id, content: content, trigger: trigger);

            UNUserNotificationCenter.currentNotificationCenter().addNotificationRequest(request) { (error) in
                if error != nil{
                    let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString: "TypeError");
                    self.commandDelegate.sendPluginResult(result, callbackId: command.callbackId);
                    return;
                }

                self.commandDelegate.sendPluginResult(CDVPluginResult(status: CDVCommandStatus_OK), callbackId: command.callbackId);
            }

            return;
        }
        #endif

        let notification = UILocalNotification()
        notification.soundName = UILocalNotificationDefaultSoundName;

        if #available(iOS 8.2, *) {
            notification.alertTitle = title;

            if let body = options?.objectForKey("body") as? String {
                notification.alertBody = body;
            }
        } else {
            notification.alertBody = title;
        }

        if let data = options?.objectForKey("data") as? [NSObject : AnyObject] {
            notification.userInfo = data;
            notification.userInfo!["__CDV_id__"] = id;
        } else {
            notification.userInfo = [ "__CDV_id__": id ];
        }

        if let at = options?.objectForKey("at")?.doubleValue {
            notification.fireDate = NSDate(timeIntervalSince1970: at/1000.0);
        }

        UIApplication.sharedApplication().scheduleLocalNotification(notification);

        self.commandDelegate.sendPluginResult(CDVPluginResult(status: CDVCommandStatus_OK), callbackId: command.callbackId);
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

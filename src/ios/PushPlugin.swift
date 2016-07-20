/*! Copyright 2016 Ayogo Health Inc. */

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
            UIApplication.sharedApplication().registerUserNotificationSettings(UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil));
        }

        let registration = NSUserDefaults.standardUserDefaults().objectForKey(CDV_PushRegistration);
        if registration != nil {
            UIApplication.sharedApplication().registerForRemoteNotifications();
        }
    }



    func register(command : CDVInvokedUrlCommand) {
        self.registrationCallback = command.callbackId;

        let permission = NSUserDefaults.standardUserDefaults().stringForKey(CDV_PushPreference);

        if permission != "denied" {
            UIApplication.sharedApplication().registerUserNotificationSettings(UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil));
            UIApplication.sharedApplication().registerForRemoteNotifications();
        } else {
            let result = CDVPluginResult(status:CDVCommandStatus_ERROR, messageAsString:"AbortError");
            self.commandDelegate.sendPluginResult(result, callbackId: self.registrationCallback);

            self.registrationCallback = nil;
        }
    }


    func unregister(command : CDVInvokedUrlCommand) {
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


    func getRegistration(command : CDVInvokedUrlCommand) {
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




    internal func _didRegisterUserNotificationSettings(notification : NSNotification) {
        let settings = notification.object as! UIUserNotificationSettings;

        if settings.types == UIUserNotificationType.None {
            NSUserDefaults.standardUserDefaults().setObject("denied", forKey:CDV_PushPreference);
        } else {
            NSUserDefaults.standardUserDefaults().setObject("granted", forKey:CDV_PushPreference);
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

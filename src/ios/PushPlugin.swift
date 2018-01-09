/*! Copyright 2018 Ayogo Health Inc. */

import UserNotifications;

let CDV_PushPreference      = "CordovaPushPreference";
let CDV_PushRegistration    = "CordovaPushRegistration";

@objc(CDVPushPlugin)
class PushPlugin : CDVPlugin {
    private var registrationCallback : String? = nil;
    private var permissionCallback : String? = nil;


    override func pluginInitialize() {
        NotificationCenter.default.addObserver(self,
                selector: #selector(PushPlugin._didRegisterForRemoteNotifications(_:)),
                name: NSNotification.Name(rawValue: "CordovaDidRegisterForRemoteNotificationsWithDeviceToken"),
                object: nil);

        NotificationCenter.default.addObserver(self,
                selector: #selector(PushPlugin._didFailToRegisterForRemoteNotifications(_:)),
                name: NSNotification.Name(rawValue: "CordovaDidFailToRegisterForRemoteNotificationsWithError"),
                object: nil);

        NotificationCenter.default.addObserver(self,
                selector: #selector(PushPlugin._didFinishLaunchingWithOptions(_:)),
                name: NSNotification.Name.UIApplicationDidFinishLaunching,
                object: nil);


        // Re-register for notifications if we think we're registered
        let permission = UserDefaults.standard.string(forKey: CDV_PushPreference);
        if permission == "granted" {
            self._doRegister();
        }

        let registration = UserDefaults.standard.object(forKey: CDV_PushRegistration);
        if registration != nil {
            UIApplication.shared.registerForRemoteNotifications();
        }
    }



    /* Notification Permission ***********************************************/

    func hasPermission(_ command : CDVInvokedUrlCommand) {
        var permission = UserDefaults.standard.string(forKey: CDV_PushPreference);

        if permission == nil {
            permission = "default";
        }

        // Ensure that it matches the current notification settings
        let settings = UIApplication.shared.currentUserNotificationSettings;
        if settings != nil && settings!.types == [] && permission != "default" {
            permission = "denied";
        }

        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: permission);
        self.commandDelegate.send(result, callbackId: command.callbackId);
    }


    internal func _doRegister() {
        let options: UNAuthorizationOptions = [.badge, .alert, .sound];

        UNUserNotificationCenter.current().requestAuthorization(options: options) { (granted, error) in
            let permission = granted ? "granted" : "denied";

            UserDefaults.standard.set(permission, forKey:CDV_PushPreference);

            if let callback = self.permissionCallback {
                let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: permission);
                self.commandDelegate.send(result, callbackId: callback);

                self.permissionCallback = nil;
            }
        }
    }


    /* Push Notification Registrations ***************************************/

    @objc func registerPush(_ command : CDVInvokedUrlCommand) {
        self.registrationCallback = command.callbackId;

        let permission = UserDefaults.standard.string(forKey: CDV_PushPreference);

        if permission != "denied" {
            self._doRegister();
            UIApplication.shared.registerForRemoteNotifications();
        } else {
            let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs:"AbortError");
            self.commandDelegate.send(result, callbackId: self.registrationCallback);

            self.registrationCallback = nil;
        }
    }


    @objc func unregisterPush(_ command : CDVInvokedUrlCommand) {
        UIApplication.shared.unregisterForRemoteNotifications();

        let registration = UserDefaults.standard.object(forKey: CDV_PushRegistration);

        if registration == nil {
            let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs:"AbortError");
            self.commandDelegate.send(result, callbackId: command.callbackId);
            return;
        }

        UserDefaults.standard.removeObject(forKey: CDV_PushRegistration);

        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs:registration as! [String:String]);
        self.commandDelegate.send(result, callbackId: command.callbackId);
    }


    func getPushRegistration(_ command : CDVInvokedUrlCommand) {
        // Fail immediately if notifications aren't registered
        if !UIApplication.shared.isRegisteredForRemoteNotifications {
            let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs:"AbortError");
            self.commandDelegate.send(result, callbackId: command.callbackId);
            return;
        }

        let registration = UserDefaults.standard.object(forKey: CDV_PushRegistration);

        if registration == nil {
            let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs:"AbortError");
            self.commandDelegate.send(result, callbackId: command.callbackId);
        } else {
            let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs:registration as! [String:String]);
            self.commandDelegate.send(result, callbackId: command.callbackId);
        }
    }


    @objc internal func _didRegisterForRemoteNotifications(_ notification : NSNotification) {
        let token = notification.object as! String;

        NSLog("REGISTERED WITH DEVICE TOKEN: \(token)");

        let registration = ["endpoint": "ios", "registrationId": token];

        UserDefaults.standard.set(registration, forKey:CDV_PushRegistration);

        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs:registration);
        self.commandDelegate.send(result, callbackId: self.registrationCallback);

        self.registrationCallback = nil;
    }


    @objc internal func _didFailToRegisterForRemoteNotifications(_ notification : NSNotification) {
        let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs:"AbortError");
        self.commandDelegate.send(result, callbackId: self.registrationCallback);

        self.registrationCallback = nil;
    }



    /* Local Notification Scheduling *****************************************/

    func requestPermission(_ command : CDVInvokedUrlCommand) {
        let permission = UserDefaults.standard.string(forKey: CDV_PushPreference);

        if permission == nil {
            self.permissionCallback = command.callbackId;
            self._doRegister();
        } else {
            let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs:permission);
            self.commandDelegate.send(result, callbackId: command.callbackId);
        }
    }


    func showNotification(_ command : CDVInvokedUrlCommand) {
        guard let title = command.argument(at: 0) as? String else {
            self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_ERROR), callbackId: command.callbackId);
            return;
        }

        let options = command.argument(at: 1) as? NSDictionary;


        let permission = UserDefaults.standard.string(forKey: CDV_PushPreference);
        if permission != "granted" {
            let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs:"TypeError");
            self.commandDelegate.send(result, callbackId: command.callbackId);
            return;
        }


        let id : String = options?.object(forKey: "tag") as? String ?? command.callbackId;

        let content = UNMutableNotificationContent();
        //content.sound = UNNotificationSound.`default`();

        if let body = options?.object(forKey: "body") as? String {
            content.body = body;
            content.title = title;
        } else {
            content.body = title;
        }

        if let data = options?.object(forKey: "data") as? [NSObject : AnyObject] {
            content.userInfo = data;
        }

        var trigger : UNNotificationTrigger? = nil;

        if let at = (options?.object(forKey: "at") as AnyObject).doubleValue {
            let scheduleDate = NSDate(timeIntervalSince1970: at/1000.0);
            trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: scheduleDate.timeIntervalSince(NSDate() as Date), repeats: false);
        }

        let request = UNNotificationRequest.init(identifier: id, content: content, trigger: trigger);

        UNUserNotificationCenter.current().add(request) { (error) in
            if error != nil{
                let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "TypeError");
                self.commandDelegate.send(result, callbackId: command.callbackId);
                return;
            }

            self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_OK), callbackId: command.callbackId);
        }
    }


    func closeNotification(_ command : CDVInvokedUrlCommand) {
        guard let id = command.argument(at: 0) as? String else {
            self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_ERROR), callbackId: command.callbackId);
            return;
        }

        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id]);
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [id]);

        self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_OK), callbackId: command.callbackId);
    }


    func getNotifications(_ command : CDVInvokedUrlCommand) {
        UNUserNotificationCenter.current().getPendingNotificationRequests() { (requests) in
            let notifications : [[String : Any]]? = requests.map() { (req) in
                var ret = [String : Any]();

                ret["tag"] = req.identifier;
                ret["title"] = req.content.title;
                ret["body"] = req.content.body;
                ret["userInfo"] = req.content.userInfo;

                let formatter = DateFormatter()
                formatter.calendar = Calendar(identifier: .iso8601)
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXX"

                if let trigger = req.trigger as? UNTimeIntervalNotificationTrigger, trigger.nextTriggerDate() != nil {
                  ret["at"] = formatter.string(from: trigger.nextTriggerDate()!);
                }

                if let trigger = req.trigger as? UNCalendarNotificationTrigger, trigger.nextTriggerDate() != nil {
                  ret["at"] = formatter.string(from: trigger.nextTriggerDate()!);
                }

                return ret;
            };

            self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_OK, messageAs:notifications), callbackId: command.callbackId);
        };
    }





    /* Notification Launch URL handling **************************************/

    @objc internal func _didFinishLaunchingWithOptions(_ notification : NSNotification) {
        UIApplication.shared.applicationIconBadgeNumber = 0;

        let options = notification.userInfo;
        if options == nil {
            return;
        }


        if let remoteNotification = options?[UIApplicationLaunchOptionsKey.remoteNotification] as! NSDictionary! {
            if let url = remoteNotification["url"] as! String! {
                let data = NSURL(string: url);

                NotificationCenter.default.post(name: NSNotification.Name.CDVPluginHandleOpenURL, object: data);
            }
        }
        
        UNUserNotificationCenter.current().delegate = self.appDelegate() as? UNUserNotificationCenterDelegate;
    }
}

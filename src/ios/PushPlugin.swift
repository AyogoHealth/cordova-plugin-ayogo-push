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

import UserNotifications;

let CDV_PushPreference      = "CordovaPushPreference";
let CDV_PushRegistration    = "CordovaPushRegistration";

@objc(CDVPushPlugin)
class PushPlugin : CDVPlugin, UNUserNotificationCenterDelegate {
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
                name: UIApplication.didFinishLaunchingNotification,
                object: nil);


        // Re-register for notifications if we think we're registered
        _getPermission() { (permission) -> () in
            if permission == "granted" {
                self._doRegister();
            }

            let registration = UserDefaults.standard.object(forKey: CDV_PushRegistration);
            if registration != nil {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications();
                }
            }
        };
    }



    /* Notification Permission ***********************************************/

    @objc func hasPermission(_ command : CDVInvokedUrlCommand) {
        _getPermission() { (permission) -> () in
            let result = CDVPluginResult(status: .ok, messageAs: permission);
            self.commandDelegate.send(result, callbackId: command.callbackId);
        }
    }

    func _getPermission(completion: @escaping (_ result: String?) -> ()) {
        var permission = UserDefaults.standard.string(forKey: CDV_PushPreference);
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().getNotificationSettings { (settings) in
                switch settings.authorizationStatus {
                    case .denied:
                        permission = "denied";
                    case .authorized:
                        permission = "granted";
                    default:
                        permission = permission ?? "prompt";
                }
                completion(permission!);
            }
        } else {
            if permission == nil {
                permission = "prompt";
            }

            // Ensure that it matches the current notification settings
            if let settings = UIApplication.shared.currentUserNotificationSettings, settings.types == [] && permission != "prompt" {
                permission = "denied";
            }
            completion(permission!);
        }
    }


    internal func _doRegister() {
        let options: UNAuthorizationOptions = [.badge, .alert, .sound];

        UNUserNotificationCenter.current().requestAuthorization(options: options) { (granted, error) in
            let permission = granted ? "granted" : "denied";

            UserDefaults.standard.set(permission, forKey:CDV_PushPreference);

            if let callback = self.permissionCallback {
                let result = CDVPluginResult(status: .ok, messageAs: permission);
                self.commandDelegate.send(result, callbackId: callback);

                self.permissionCallback = nil;
            }

            if let callback = self.registrationCallback {
                if granted {
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications();
                    }
                } else {
                    let result = CDVPluginResult(status: .ok, messageAs: permission);
                    self.commandDelegate.send(result, callbackId: callback);

                    self.registrationCallback = nil;
                }
            }
        }
    }


    /* Push Notification Registrations ***************************************/

    @objc func registerPush(_ command : CDVInvokedUrlCommand) {
        self.registrationCallback = command.callbackId;
        _getPermission() { (permission) -> () in
            if permission != "denied" {
                self._doRegister();
            } else {
                let result = CDVPluginResult(status: .error, messageAs:"AbortError");
                self.commandDelegate.send(result, callbackId: self.registrationCallback);

                self.registrationCallback = nil;
            }
        };

    }


    @objc func unregisterPush(_ command : CDVInvokedUrlCommand) {
        UIApplication.shared.unregisterForRemoteNotifications();

        let registration = UserDefaults.standard.object(forKey: CDV_PushRegistration);

        if registration == nil {
            let result = CDVPluginResult(status: .error, messageAs:"AbortError");
            self.commandDelegate.send(result, callbackId: command.callbackId);
            return;
        }

        UserDefaults.standard.removeObject(forKey: CDV_PushRegistration);

        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs:registration as! [String:String]);
        self.commandDelegate.send(result, callbackId: command.callbackId);
    }


    @objc func getPushRegistration(_ command : CDVInvokedUrlCommand) {
        // Fail immediately if notifications aren't registered
        if !UIApplication.shared.isRegisteredForRemoteNotifications {
            let result = CDVPluginResult(status: .error, messageAs:"AbortError");
            self.commandDelegate.send(result, callbackId: command.callbackId);
            return;
        }

        let registration = UserDefaults.standard.object(forKey: CDV_PushRegistration);

        if registration == nil {
            let result = CDVPluginResult(status: .error, messageAs:"AbortError");
            self.commandDelegate.send(result, callbackId: command.callbackId);
        } else {
            let result = CDVPluginResult(status: .ok, messageAs:registration as! [String:String]);
            self.commandDelegate.send(result, callbackId: command.callbackId);
        }
    }


    @objc internal func _didRegisterForRemoteNotifications(_ notification : NSNotification) {
        let token = notification.object as! String;

        NSLog("REGISTERED WITH DEVICE TOKEN: \(token)");

        let registration = ["endpoint": "ios", "registrationId": token];

        UserDefaults.standard.set(registration, forKey:CDV_PushRegistration);

        if self.registrationCallback != nil {
            let result = CDVPluginResult(status: .ok, messageAs:registration);
            self.commandDelegate.send(result, callbackId: self.registrationCallback);

            self.registrationCallback = nil;
        }
    }


    @objc internal func _didFailToRegisterForRemoteNotifications(_ notification : NSNotification) {
        if self.registrationCallback != nil {
            let result = CDVPluginResult(status: .error, messageAs:"AbortError");
            self.commandDelegate.send(result, callbackId: self.registrationCallback);

            self.registrationCallback = nil;
        }
    }



    /* Local Notification Scheduling *****************************************/

    @objc func requestPermission(_ command : CDVInvokedUrlCommand) {
        _getPermission() { (permission) -> () in
            if permission == nil {
                self.permissionCallback = command.callbackId;
                self._doRegister();
            } else {
                let result = CDVPluginResult(status: .ok, messageAs:permission);
                self.commandDelegate.send(result, callbackId: command.callbackId);
            }
        }
    }


    @objc func showNotification(_ command : CDVInvokedUrlCommand) {
        guard let title = command.argument(at: 0) as? String else {
            self.commandDelegate.send(CDVPluginResult(status: .error), callbackId: command.callbackId);
            return;
        }

        let options = command.argument(at: 1) as? NSDictionary;



        _getPermission() { (permission) -> () in
            if permission != "granted" {
                let result = CDVPluginResult(status: .error, messageAs:"TypeError");
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
                    let result = CDVPluginResult(status: .error, messageAs: "TypeError");
                    self.commandDelegate.send(result, callbackId: command.callbackId);
                    return;
                }

                self.commandDelegate.send(CDVPluginResult(status: .ok), callbackId: command.callbackId);
            }
        };
    }


    @objc func closeNotification(_ command : CDVInvokedUrlCommand) {
        guard let id = command.argument(at: 0) as? String else {
            self.commandDelegate.send(CDVPluginResult(status: .error), callbackId: command.callbackId);
            return;
        }

        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id]);
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [id]);

        self.commandDelegate.send(CDVPluginResult(status: .ok), callbackId: command.callbackId);
    }


    @objc func getNotifications(_ command : CDVInvokedUrlCommand) {
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

            self.commandDelegate.send(CDVPluginResult(status: .ok, messageAs:notifications), callbackId: command.callbackId);
        };
    }





    /* Notification Launch URL handling **************************************/

    @objc internal func _didFinishLaunchingWithOptions(_ notification : NSNotification) {
        UIApplication.shared.applicationIconBadgeNumber = 0;
        UNUserNotificationCenter.current().delegate = self;

        let options = notification.userInfo;
        if options == nil {
            return;
        }


        if let remoteNotification = options?[UIApplication.LaunchOptionsKey.remoteNotification] as? NSDictionary {
            if let url = remoteNotification["url"] as? String {
                let data = NSURL(string: url);

                NotificationCenter.default.post(name: NSNotification.Name.CDVPluginHandleOpenURL, object: data);
            }
        }
    }

    @objc internal func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
       completionHandler([.alert, .sound, .badge]);
    }
}

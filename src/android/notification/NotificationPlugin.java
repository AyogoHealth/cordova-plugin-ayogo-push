// Copyright 2014 Ayogo Health Inc.

package com.ayogo.notification;

import android.app.Activity;
import android.content.Context;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.LOG;
import org.apache.cordova.PluginResult;

import org.json.JSONException;
import org.json.JSONArray;
import org.json.JSONObject;

public class NotificationPlugin extends CordovaPlugin
{
    public static final String TAG = "NotificationPlugin";

    // Manager to handle our scheduled notifications.
    private ScheduledNotificationManager mgr;

    @Override
    protected void pluginInitialize() {
        LOG.v(TAG, "Initializing");

        this.mgr = new ScheduledNotificationManager(cordova.getActivity().getApplicationContext());
    }


    @Override
    public boolean execute(String action, final JSONArray args, final CallbackContext callback)
    {


        if (action.equals("requestPermission")) {
            callback.sendPluginResult(new PluginResult(PluginResult.Status.OK, "granted"));
            return true;
        }


        if (action.equals("showNotification")) {
            cordova.getThreadPool().execute(new Runnable() {
                public void run() {
                    try {
                        String title = args.getString(0);
                        JSONObject options = args.getJSONObject(1);

                        if(options.optString("tag", null) == null) {
                            options.put("tag", callback.getCallbackId());
                        }

                        LOG.v(TAG, "Schedule Notification: " + title);

                        mgr.scheduleNotification(title, options);

                        callback.sendPluginResult(new PluginResult(PluginResult.Status.OK));
                    } catch (JSONException ex) {
                        callback.sendPluginResult(new PluginResult(PluginResult.Status.ERROR, "Missing or invalid title or options"));
                    }
                }
            });
            return true;
        }

        if (action.equals("closeNotification")) {
            cordova.getThreadPool().execute(new Runnable() {
                public void run() {
                    try {
                        String tag = args.getString(0);

                        LOG.v(TAG, "cancel Notification: " + tag);

                        mgr.cancelNotification(tag);

                        callback.sendPluginResult(new PluginResult(PluginResult.Status.OK));
                    } catch (JSONException ex) {
                        callback.sendPluginResult(new PluginResult(PluginResult.Status.ERROR, "Missing or invalid title or options"));
                    }
                }
            });
            return true;
        }


        if (action.equals("getNotifications")) {
            cordova.getThreadPool().execute(new Runnable() {
                public void run() {
                    LOG.v(TAG, "Get Notifications");

                    JSONArray notifications = mgr.getNotifications();

                    // Android doesn't require permission to send push notifications
                    callback.sendPluginResult(new PluginResult(PluginResult.Status.OK, notifications));
                }
            });
            return true;
        }

        LOG.i(TAG, "Tried to call " + action + " with " + args.toString());

        callback.sendPluginResult(new PluginResult(PluginResult.Status.INVALID_ACTION));
        return false;
    }
}

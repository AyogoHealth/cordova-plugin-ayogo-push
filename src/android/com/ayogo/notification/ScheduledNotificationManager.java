// Copyright 2016 Ayogo Health Inc.

package com.ayogo.notification;

import android.app.AlarmManager;
import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.pm.PackageManager;
import android.content.pm.PackageManager.NameNotFoundException;
import android.content.pm.ApplicationInfo;
import android.content.res.AssetManager;
import android.content.res.Resources;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.content.Intent;
import android.content.SharedPreferences;

import android.support.v4.app.NotificationCompat;
import android.support.v4.app.TaskStackBuilder;

import org.json.JSONException;
import org.json.JSONArray;
import org.json.JSONObject;

import java.util.Map;
import java.util.Set;

import java.io.IOException;
import java.io.InputStream;

import org.apache.cordova.LOG;

public class ScheduledNotificationManager {

    private Context context;

    private static final String PREF_KEY = "LocalNotification";
    private static final String INTENT_CATEGORY = "android.intent.category.DEFAULT";
    private static final int INTENT_REQUEST_CODE = 0;

    private static Class<?> receiver = TriggerReceiver.class;

    public ScheduledNotificationManager(Context ctx) {
        this.context = ctx;
    }

    public ScheduledNotification scheduleNotification(String title, JSONObject options) {
        LOG.e(NotificationPlugin.TAG, "scheduleNotification: "+title);

        AlarmManager alarmManager = (AlarmManager) context.getSystemService(Context.ALARM_SERVICE);

        ScheduledNotification notification = new ScheduledNotification(title, options);

        saveNotification(notification);

        LOG.e(NotificationPlugin.TAG, "create Intent: "+notification.tag);

        Intent intent = new Intent(context, receiver);
        intent.setAction(notification.tag);

        PendingIntent pi = PendingIntent.getBroadcast(context, INTENT_REQUEST_CODE, intent, PendingIntent.FLAG_CANCEL_CURRENT);

        long alarmTime = notification.at;

        LOG.e(NotificationPlugin.TAG, "schedule alarm for: "+alarmTime);

        alarmManager.setExact(AlarmManager.RTC_WAKEUP, alarmTime, pi);

        return notification;
    }

    public void rescheduleNotifications() {
        LOG.e(NotificationPlugin.TAG, "rescheduleNotifications");

        JSONArray notifications = getNotifications();
        long now = System.currentTimeMillis();

        for(int i = 0; i < notifications.length(); i++) {
            try {
                JSONObject opts = notifications.getJSONObject(i);
                long at = opts.optLong("at", 0);

                if (at > now) {
                    LOG.e(NotificationPlugin.TAG, "notification is in the future");
                    //Reschedule the notification
                    scheduleNotification(opts.optString("title", null), opts);
                } else {
                    LOG.e(NotificationPlugin.TAG, "notification is in the past");
                    cancelNotification(opts.getString("tag"));
                }
            } catch(JSONException e) {}
        }
    }

    public JSONArray getNotifications() {
        LOG.e(NotificationPlugin.TAG, "getNotifications");

        SharedPreferences prefs = getPrefs();
        Map<String, ?> notes = prefs.getAll();

        JSONArray notifications = new JSONArray();

        for(String key : notes.keySet()) {
            try {
                JSONObject value = new JSONObject(notes.get(key).toString());
                notifications.put(value);
            } catch(JSONException e) {}
        }

        LOG.e(NotificationPlugin.TAG, notifications.toString());

        return notifications;
    }

    public ScheduledNotification getNotification(String tag) {
        LOG.e(NotificationPlugin.TAG, "getNotification: "+ tag);

        JSONArray notifications = getNotifications();

        for(int i = 0; i < notifications.length(); i++) {
            try {
                JSONObject opts = notifications.getJSONObject(i);
                if (tag.equals(opts.optString("tag", null))) {
                    LOG.e(NotificationPlugin.TAG, "found Notification: "+ opts.toString());
                    return new ScheduledNotification(opts.optString("title", null), opts);
                }
            } catch(JSONException e) {}
        }
        LOG.e(NotificationPlugin.TAG, "no notification found");
        return null;
    }

    public ScheduledNotification cancelNotification(String tag) {
        LOG.e(NotificationPlugin.TAG, "cancelNotification: "+tag);
        SharedPreferences prefs = getPrefs();
        SharedPreferences.Editor editor = prefs.edit();

        Map<String, ?> notifications = prefs.getAll();
        ScheduledNotification notification = null;

        for(String key : notifications.keySet()) {
            try {
                JSONObject value = new JSONObject(notifications.get(key).toString());
                String ntag = value.optString("tag");
                LOG.e(NotificationPlugin.TAG, "checking Notification: "+ value.toString());
                if (ntag != null && ntag.equals(tag)) {
                    LOG.e(NotificationPlugin.TAG, "found Notification: "+ value.toString());
                    notification = new ScheduledNotification(value.optString("title", null), value);

                    editor.remove(key);


                    LOG.e(NotificationPlugin.TAG, "unscheduling Notification: ");
                    //unschedule the alarm
                    Intent intent = new Intent(context, receiver);
                    intent.setAction(ntag);

                    PendingIntent pi = PendingIntent.
                            getBroadcast(context, INTENT_REQUEST_CODE, intent, PendingIntent.FLAG_CANCEL_CURRENT);

                    AlarmManager alarmManager = (AlarmManager) context.getSystemService(Context.ALARM_SERVICE);
                    alarmManager.cancel(pi);
                }
            } catch(JSONException e) {}
        }

        editor.commit();

        if (notification != null) {
            LOG.e(NotificationPlugin.TAG, "returning Notification "+ notification.toString());
        } else {
            LOG.e(NotificationPlugin.TAG, "could not find Notification "+ tag);
        }

        return notification;
    }

    public void showNotification(ScheduledNotification scheduledNotification) {
        LOG.e(NotificationPlugin.TAG, "showNotification: "+ scheduledNotification.toString());

        NotificationManager nManager = (NotificationManager) context
            .getSystemService(Context.NOTIFICATION_SERVICE);

        NotificationCompat.Builder builder = new NotificationCompat.Builder(context);

        // Build the notification options
        builder
            .setDefaults(Notification.DEFAULT_ALL)
            .setContentTitle(scheduledNotification.title)
            .setContentText(scheduledNotification.body)
            .setTicker(scheduledNotification.body)
            .setAutoCancel(true);

        // TODO: add sound support
        // if (scheduledNotification.sound != null) {
        //     builder.setSound(sound);
        // }

        if (scheduledNotification.badge != null) {
            LOG.e(NotificationPlugin.TAG, "showNotification: has a badge!");
            builder.setSmallIcon(getResIdForDrawable(scheduledNotification.badge));
        } else {
            LOG.e(NotificationPlugin.TAG, "showNotification: has no badge, use app icon!");
            try {
                PackageManager pm = context.getPackageManager();
                ApplicationInfo applicationInfo = pm.getApplicationInfo(context.getPackageName(), PackageManager.GET_META_DATA);
                Resources resources = pm.getResourcesForApplication(applicationInfo);
                builder.setSmallIcon(applicationInfo.icon);
            } catch(NameNotFoundException e) {
                LOG.e(NotificationPlugin.TAG, "Failed to set icon for notification!");
                return;
            }
        }

        if (scheduledNotification.icon != null) {
            LOG.e(NotificationPlugin.TAG, "showNotification: has an icon!");
            builder.setLargeIcon(getIconFromUri(scheduledNotification.icon));
        }


        Notification notification = builder.build();

        NotificationManager notificationManager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
        LOG.e(NotificationPlugin.TAG, "notify!");
        notificationManager.notify(scheduledNotification.tag.hashCode(), notification);
    }

    private void saveNotification(ScheduledNotification notification) {
        LOG.e(NotificationPlugin.TAG, "saveNotification"+notification.toString());
        SharedPreferences prefs = getPrefs();
        SharedPreferences.Editor editor = prefs.edit();

        editor.putString(notification.tag, notification.toString());
        editor.commit();
    }

    /**
     * Shared private preferences for the application.
     */
    private SharedPreferences getPrefs () {
        return context.getSharedPreferences(PREF_KEY, Context.MODE_PRIVATE);
    }

    private int getResIdForDrawable(String resPath) {
        int resId = getResIdForDrawable(context.getPackageName(), resPath);

        if (resId == 0) {
            resId = getResIdForDrawable("android", resPath);
        }

        return resId;
    }

    private int getResIdForDrawable(String clsName, String drawable) {
        int resId = 0;

        try {
            Class<?> cls  = Class.forName(clsName + ".R$drawable");

            resId = (Integer) cls.getDeclaredField(drawable).get(Integer.class);
        } catch (Exception ignore) {}

        return resId;
    }

    private Bitmap getIconFromUri(String path) {
        try {
            AssetManager amgr = context.getAssets();
            String tmp_uri = "www/" + path;
            InputStream input = amgr.open(tmp_uri);

            return BitmapFactory.decodeStream(input);
        } catch(IOException e) {
            LOG.e(NotificationPlugin.TAG, "cant load icon from "+"www/"+path);
            LOG.e(NotificationPlugin.TAG, e.getMessage());
            return null;
        }
    }
}

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
import android.support.v4.app.NotificationCompat.BigTextStyle;
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

    public ScheduledNotificationManager(Context ctx) {
        this.context = ctx;
    }

    public ScheduledNotification scheduleNotification(String title, JSONObject options) {
        LOG.v(NotificationPlugin.TAG, "scheduleNotification: "+title);

        AlarmManager alarmManager = (AlarmManager) context.getSystemService(Context.ALARM_SERVICE);

        ScheduledNotification notification = new ScheduledNotification(title, options);

        long alarmTime = notification.at;

        if (alarmTime != 0) { //0 = uninitialized.

            saveNotification(notification);

            LOG.v(NotificationPlugin.TAG, "create Intent: "+notification.tag);

            Intent intent = new Intent(context, TriggerReceiver.class);
            intent.setAction(notification.tag);

            PendingIntent pi = PendingIntent.getBroadcast(context, INTENT_REQUEST_CODE, intent, PendingIntent.FLAG_CANCEL_CURRENT);

            LOG.v(NotificationPlugin.TAG, "schedule alarm for: "+alarmTime);

            alarmManager.setExact(AlarmManager.RTC_WAKEUP, alarmTime, pi);
        } else {
            // No "at", trigger the notification right now.
            showNotification(notification);
        }

        return notification;
    }

    public void rescheduleNotifications() {
        LOG.v(NotificationPlugin.TAG, "rescheduleNotifications");

        JSONArray notifications = getNotifications();
        long now = System.currentTimeMillis();

        for(int i = 0; i < notifications.length(); i++) {
            try {
                JSONObject opts = notifications.getJSONObject(i);
                long at = opts.optLong("at", 0);

                if (at > now) {
                    LOG.v(NotificationPlugin.TAG, "notification is in the future");
                    //Reschedule the notification
                    scheduleNotification(opts.optString("title", null), opts);
                } else {
                    LOG.v(NotificationPlugin.TAG, "notification is in the past");
                    cancelNotification(opts.getString("tag"));
                }
            } catch(JSONException e) {}
        }
    }

    public JSONArray getNotifications() {
        LOG.v(NotificationPlugin.TAG, "getNotifications");

        SharedPreferences prefs = getPrefs();
        Map<String, ?> notes = prefs.getAll();

        JSONArray notifications = new JSONArray();

        for(String key : notes.keySet()) {
            try {
                JSONObject value = new JSONObject(notes.get(key).toString());
                notifications.put(value);
            } catch(JSONException e) {}
        }

        LOG.v(NotificationPlugin.TAG, notifications.toString());

        return notifications;
    }

    public ScheduledNotification getNotification(String tag) {
        LOG.v(NotificationPlugin.TAG, "getNotification: "+ tag);

        JSONArray notifications = getNotifications();

        for(int i = 0; i < notifications.length(); i++) {
            try {
                JSONObject opts = notifications.getJSONObject(i);
                if (tag.equals(opts.optString("tag", null))) {
                    LOG.v(NotificationPlugin.TAG, "found Notification: "+ opts.toString());
                    return new ScheduledNotification(opts.optString("title", null), opts);
                }
            } catch(JSONException e) {}
        }
        LOG.v(NotificationPlugin.TAG, "no notification found");
        return null;
    }

    public ScheduledNotification cancelNotification(String tag) {
        LOG.v(NotificationPlugin.TAG, "cancelNotification: "+tag);
        SharedPreferences prefs = getPrefs();
        SharedPreferences.Editor editor = prefs.edit();

        Map<String, ?> notifications = prefs.getAll();
        ScheduledNotification notification = null;

        for(String key : notifications.keySet()) {
            try {
                JSONObject value = new JSONObject(notifications.get(key).toString());
                String ntag = value.optString("tag");
                LOG.v(NotificationPlugin.TAG, "checking Notification: "+ value.toString());
                if (ntag != null && ntag.equals(tag)) {
                    LOG.v(NotificationPlugin.TAG, "found Notification: "+ value.toString());
                    notification = new ScheduledNotification(value.optString("title", null), value);

                    editor.remove(key);


                    LOG.v(NotificationPlugin.TAG, "unscheduling Notification: ");
                    //unschedule the alarm
                    Intent intent = new Intent(context, TriggerReceiver.class);
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
            LOG.v(NotificationPlugin.TAG, "returning Notification "+ notification.toString());
        } else {
            LOG.v(NotificationPlugin.TAG, "could not find Notification "+ tag);
        }

        return notification;
    }

    public void showNotification(ScheduledNotification scheduledNotification) {
        LOG.v(NotificationPlugin.TAG, "showNotification: "+ scheduledNotification.toString());

        NotificationManager nManager = (NotificationManager) context
            .getSystemService(Context.NOTIFICATION_SERVICE);

        NotificationCompat.Builder builder = new NotificationCompat.Builder(context);

        // Build the notification options
        builder
            .setDefaults(Notification.DEFAULT_ALL)
            .setTicker(scheduledNotification.body)
            .setPriority(Notification.PRIORITY_HIGH)
            .setAutoCancel(true);

        // TODO: add sound support
        // if (scheduledNotification.sound != null) {
        //     builder.setSound(sound);
        // }

        if (scheduledNotification.body != null) {
            builder.setContentTitle(scheduledNotification.title);
            builder.setContentText(scheduledNotification.body);
            builder.setStyle(new NotificationCompat.BigTextStyle().bigText(scheduledNotification.body));
        } else {
            //Default the title to the app name
            try {
                PackageManager pm = context.getPackageManager();
                ApplicationInfo applicationInfo = pm.getApplicationInfo(context.getPackageName(), PackageManager.GET_META_DATA);

                String appName = applicationInfo.loadLabel(pm).toString();

                builder.setContentTitle(appName);
                builder.setContentText(scheduledNotification.title);
                builder.setStyle(new NotificationCompat.BigTextStyle().bigText(scheduledNotification.title));
            } catch(NameNotFoundException e) {
                LOG.v(NotificationPlugin.TAG, "Failed to set title for notification!");
                return;
            }
        }

        if (scheduledNotification.badge != null) {
            LOG.v(NotificationPlugin.TAG, "showNotification: has a badge!");
            builder.setSmallIcon(getResIdForDrawable(scheduledNotification.badge));
        } else {
            LOG.v(NotificationPlugin.TAG, "showNotification: has no badge, use app icon!");
            try {
                PackageManager pm = context.getPackageManager();
                ApplicationInfo applicationInfo = pm.getApplicationInfo(context.getPackageName(), PackageManager.GET_META_DATA);
                Resources resources = pm.getResourcesForApplication(applicationInfo);
                builder.setSmallIcon(applicationInfo.icon);
            } catch(NameNotFoundException e) {
                LOG.v(NotificationPlugin.TAG, "Failed to set badge for notification!");
                return;
            }
        }

        if (scheduledNotification.icon != null) {
            LOG.v(NotificationPlugin.TAG, "showNotification: has an icon!");
            builder.setLargeIcon(getIconFromUri(scheduledNotification.icon));
        } else {
            LOG.v(NotificationPlugin.TAG, "showNotification: has no icon, use app icon!");
            try {
                PackageManager pm = context.getPackageManager();
                ApplicationInfo applicationInfo = pm.getApplicationInfo(context.getPackageName(), PackageManager.GET_META_DATA);
                Resources resources = pm.getResourcesForApplication(applicationInfo);
                Bitmap appIconBitmap = BitmapFactory.decodeResource(resources, applicationInfo.icon);
                builder.setLargeIcon(appIconBitmap);
            } catch(NameNotFoundException e) {
                LOG.v(NotificationPlugin.TAG, "Failed to set icon for notification!");
                return;
            }
        }



        Intent launchIntent = context.getPackageManager().getLaunchIntentForPackage(context.getPackageName());
        launchIntent.setFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_SINGLE_TOP);
        launchIntent.setAction("notification");

        PendingIntent contentIntent = PendingIntent.getActivity(context, 0, launchIntent, PendingIntent.FLAG_UPDATE_CURRENT);
        builder.setContentIntent(contentIntent);

        Notification notification = builder.build();

        NotificationManager notificationManager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
        LOG.v(NotificationPlugin.TAG, "notify!");
        notificationManager.notify(scheduledNotification.tag.hashCode(), notification);
    }

    private void saveNotification(ScheduledNotification notification) {
        LOG.v(NotificationPlugin.TAG, "saveNotification"+notification.toString());
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

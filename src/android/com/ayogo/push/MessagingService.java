// Copyright 2018 Ayogo Health Inc.

package com.ayogo.push;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.content.res.Resources;
import android.os.Build;
import android.util.Log;

import com.google.firebase.messaging.FirebaseMessagingService;
import com.google.firebase.messaging.RemoteMessage;

import java.util.Map;
import java.util.Set;

public class MessagingService extends FirebaseMessagingService {

    private static final String TAG = "MessagingService";

    @Override
    public void onMessageReceived(RemoteMessage remoteMessage) {
        // Check if message contains a data payload.
        if (remoteMessage.getData().size() > 0) {
            sendNotification(remoteMessage);
        }
    }

    private void sendNotification(RemoteMessage remoteMessage) {
        PackageManager pm = getApplicationContext().getPackageManager();
        Intent launchIntent = pm.getLaunchIntentForPackage(getApplicationContext().getPackageName());
        String activityClassName = launchIntent != null ? launchIntent.getComponent().getClassName() : null;

        if (activityClassName == null) {
            Log.e(TAG, "Could not find activity class name");
            return;
        }

        Intent intent = new Intent();
        intent.setAction("push"); // This is important for the AppScope
        intent.setClassName(getApplicationContext(), activityClassName);
        intent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP);

        PendingIntent pendingIntent = PendingIntent.getActivity(getApplicationContext(), 0, intent, PendingIntent.FLAG_ONE_SHOT);

        ApplicationInfo applicationInfo = null;
        Resources resources = null;

        try {
            applicationInfo = pm.getApplicationInfo(getApplicationContext().getPackageName(), PackageManager.GET_META_DATA);
            resources = pm.getResourcesForApplication(applicationInfo);
        } catch (PackageManager.NameNotFoundException e) {
            Log.e(TAG, "Could not find application info or resources: " + e.getMessage());
        }

        if (resources == null) {
            return;
        }

        String channelId = applicationInfo.metaData.getString("com.google.firebase.messaging.default_notification_channel_id");
        int iconId = resources.getIdentifier("notification", "drawable", getApplicationContext().getPackageName());

        if (iconId == 0) {
            Log.w(TAG, "Could not find the notification icon.");
        }

        if (channelId == null) {
            channelId = getApplicationContext().getPackageName();
        }

        /* This will configure a heads-up notification. We need to set the priority as max and also enable the vibration. */
        Notification.Builder notificationBuilder = new Notification.Builder(this)
                .setSmallIcon(iconId)
                .setContentTitle(remoteMessage.getNotification().getTitle())
                .setContentText(remoteMessage.getNotification().getBody())
                .setPriority(Notification.PRIORITY_MAX)
                .setAutoCancel(true)
                .setVibrate(new long[]{0, Notification.DEFAULT_VIBRATE})
                .setContentIntent(pendingIntent);

        Map<String, String> data = remoteMessage.getData();

        if (data != null) {
            Set<String> keys = data.keySet();

            for (String key : keys) {
                intent.putExtra(key, data.get(key));
            }
        }

        NotificationManager notificationManager = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);

        /* Since android Oreo notification channel is needed. */
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            notificationBuilder.setChannelId(channelId);

            int appNameId = applicationInfo.labelRes;

            String appName = appNameId == 0 ? applicationInfo.nonLocalizedLabel.toString() : getApplicationContext().getString(appNameId);

            NotificationChannel channel = new NotificationChannel(channelId, appName, NotificationManager.IMPORTANCE_HIGH);

            channel.enableVibration(true);
            channel.setVibrationPattern(new long[]{0, Notification.DEFAULT_VIBRATE});

            notificationManager.createNotificationChannel(channel);
        }

        notificationManager.notify(0, notificationBuilder.build());
    }
}

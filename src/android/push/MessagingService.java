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

package com.ayogo.cordova.push;

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

import android.support.v4.app.NotificationCompat;
import android.support.v4.app.NotificationCompat.BigTextStyle;

import com.google.firebase.messaging.FirebaseMessagingService;
import com.google.firebase.messaging.RemoteMessage;

import java.util.Map;
import java.util.Set;

public class MessagingService extends FirebaseMessagingService {

    private static final String TAG = "MessagingService";

    @Override
    public void onMessageReceived(RemoteMessage remoteMessage) {
        super.onMessageReceived(remoteMessage);

        // Check if message contains a data payload.
        if (remoteMessage.getData().size() > 0) {
            sendNotification(remoteMessage);
        }
    }

    private void sendNotification(RemoteMessage remoteMessage) {
        PackageManager pm = getApplicationContext().getPackageManager();

        Intent launchIntent = pm.getLaunchIntentForPackage(getApplicationContext().getPackageName());
        launchIntent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_SINGLE_TOP);
        launchIntent.setAction("push"); // This is important for the AppScope

        Map<String, String> data = remoteMessage.getData();
        if (data != null) {
            Set<String> keys = data.keySet();

            for (String key : keys) {
                launchIntent.putExtra(key, data.get(key));
            }
        }

        PendingIntent pendingIntent = PendingIntent.getActivity(getApplicationContext(), 0, launchIntent, PendingIntent.FLAG_UPDATE_CURRENT);

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

        int iconId = resources.getIdentifier("notification", "drawable", getApplicationContext().getPackageName());

        if (iconId == 0) {
            Log.w(TAG, "Could not find the notification icon.");
        }

        /* This will configure a heads-up notification */
        NotificationCompat.Builder builder = new NotificationCompat.Builder(this);

        builder
            .setDefaults(Notification.DEFAULT_ALL)
            .setTicker(remoteMessage.getNotification().getBody())
            .setContentIntent(pendingIntent)
            .setContentTitle(remoteMessage.getNotification().getTitle())
            .setContentText(remoteMessage.getNotification().getBody())
            .setStyle(new NotificationCompat.BigTextStyle().bigText(remoteMessage.getNotification().getBody()))
            .setPriority(Notification.PRIORITY_HIGH)
            .setSmallIcon(iconId)
            .setAutoCancel(true);

        NotificationManager notificationManager = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);

        /* Since android Oreo notification channel is needed. */
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            String channelId = applicationInfo.metaData.getString("com.google.firebase.messaging.default_notification_channel_id");

            if (channelId == null) {
                channelId = getApplicationContext().getPackageName();
            }

            builder.setChannelId(channelId);

            int appNameId = applicationInfo.labelRes;

            String appName = appNameId == 0 ? applicationInfo.nonLocalizedLabel.toString() : getApplicationContext().getString(appNameId);

            NotificationChannel channel = new NotificationChannel(channelId, appName, NotificationManager.IMPORTANCE_HIGH);

            channel.enableVibration(true);
            channel.setVibrationPattern(new long[]{0, Notification.DEFAULT_VIBRATE});

            notificationManager.createNotificationChannel(channel);
        }

        notificationManager.notify(0, builder.build());
    }
}

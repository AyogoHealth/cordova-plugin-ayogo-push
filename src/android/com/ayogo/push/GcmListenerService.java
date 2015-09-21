// Copyright 2015 Ayogo Health Inc.

package com.ayogo.push;

import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.support.v4.app.NotificationCompat;
import android.util.Log;

public class GcmListenerService extends com.google.android.gms.gcm.GcmListenerService {

    private static final String TAG = "GcmListenerService";
    private static final String NOTIFICATION_COUNT = "notification_count";

    /**
     * Called when message is received.
     *
     * @param from SenderID of the sender.
     * @param data Data bundle containing message data as key/value pairs.
     *             For Set of keys use data.keySet().
     */
    @Override
    public void onMessageReceived(String from, Bundle data) {

        String title = data.getString("title");
        String message = data.getString("message");

        Log.d(TAG, "title: " + title);
        Log.d(TAG, "message: " + message);

        if(title == null || message == null){
            Log.w(TAG, "Could not find title or message. Ignoring notification...");
            return;
        }

        String packageName = getApplicationContext().getPackageName();

        int iconRes = -1;

        try{
            iconRes = getResources().getIdentifier("icon", "drawable", packageName);
        }catch (Exception e){
            Log.w(TAG, "Could not find icon resource");
        }

        NotificationCompat.Builder builder = new NotificationCompat.Builder(this)
                                                .setContentTitle(title)
                                                .setContentText(message);
        if(iconRes > -1){
            builder.setSmallIcon(iconRes);
        }

        SharedPreferences prefs = this.getSharedPreferences(TAG, Context.MODE_PRIVATE);

        int notificationId = prefs.getInt(NOTIFICATION_COUNT, 0) + 1;
        notificationId = notificationId > Integer.MAX_VALUE ? 0 : notificationId; // quite impossible

        SharedPreferences.Editor editor = prefs.edit();
        editor.putInt(NOTIFICATION_COUNT, notificationId);
        editor.commit();

        Intent launchIntent = getApplicationContext().getPackageManager().getLaunchIntentForPackage(packageName);
        launchIntent.setFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_SINGLE_TOP);

        PendingIntent contentIntent = PendingIntent.getActivity(this, 0, launchIntent, PendingIntent.FLAG_UPDATE_CURRENT);
        builder.setContentIntent(contentIntent);

        NotificationManager manager = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
        manager.notify(notificationId, builder.build());
    }
}

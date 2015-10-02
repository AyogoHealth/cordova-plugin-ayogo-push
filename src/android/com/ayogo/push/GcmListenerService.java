// Copyright 2015 Ayogo Health Inc.

package com.ayogo.push;

import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.Bundle;
import android.support.v4.app.NotificationCompat;
import android.util.Log;

import org.json.JSONObject;

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
        String url = null;

        try {
            JSONObject customData = new JSONObject(data.getString("custom_data"));
            url = customData.getString("url");
        } catch (Exception e) {
            Log.e(TAG, "Could not find url from customData");
        }

        if(title == null || message == null) {
            Log.w(TAG, "Could not find title or message. Ignoring notification...");
            return;
        }

        String packageName = getApplicationContext().getPackageName();

        boolean lollipopOrHigher = android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.LOLLIPOP;

        NotificationCompat.Builder builder = new NotificationCompat.Builder(this)
                                                .setContentTitle(title)
                                                .setContentText(message)
                                                .setAutoCancel(true);

        try {
            String smallIconName = lollipopOrHigher ? "notification" : "icon";
            int smallIconRes = getResources().getIdentifier(smallIconName, "drawable", packageName);
            if(smallIconRes > 0) {
                builder.setSmallIcon(smallIconRes);
            }
        } catch (Exception e) {
            Log.w(TAG, "Could not find small icon resource");
        }

        try {
            int largeIconRes = getResources().getIdentifier("icon", "drawable", packageName);
            if(largeIconRes > 0) {
                Bitmap largetIcon = BitmapFactory.decodeResource(getResources(), largeIconRes);
                builder.setLargeIcon(largetIcon);
            }
        }catch (Exception e) {
            Log.w(TAG, "Could not find large icon resource");
        }

        SharedPreferences prefs = this.getSharedPreferences(TAG, Context.MODE_PRIVATE);

        int notificationId = prefs.getInt(NOTIFICATION_COUNT, 0) + 1;
        notificationId = notificationId > Integer.MAX_VALUE ? 0 : notificationId; // quite impossible

        SharedPreferences.Editor editor = prefs.edit();
        editor.putInt(NOTIFICATION_COUNT, notificationId);
        editor.commit();

        Intent launchIntent = getApplicationContext().getPackageManager().getLaunchIntentForPackage(packageName);
        launchIntent.setFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_SINGLE_TOP);
        launchIntent.setAction("push");
        if(url != null) {
            Bundle bundle = new Bundle();
            bundle.putString("url", url);
            launchIntent.putExtras(bundle);
        }

        PendingIntent contentIntent = PendingIntent.getActivity(this, 0, launchIntent, PendingIntent.FLAG_UPDATE_CURRENT);
        builder.setContentIntent(contentIntent);

        NotificationManager manager = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
        manager.notify(notificationId, builder.build());
    }
}

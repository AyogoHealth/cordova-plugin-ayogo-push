// Copyright 2016 Ayogo Health Inc.

package com.ayogo.notification;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

import org.apache.cordova.LOG;

public class RestoreReceiver extends BroadcastReceiver {

    @Override
    public void onReceive (Context context, Intent intent) {
        LOG.v(NotificationPlugin.TAG, "Restore Reciever Triggered!");
        ScheduledNotificationManager mgr   = new ScheduledNotificationManager(context);
        mgr.rescheduleNotifications();
    }

}

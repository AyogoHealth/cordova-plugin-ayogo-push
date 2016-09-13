// Copyright 2016 Ayogo Health Inc.

package com.ayogo.notification;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

import org.apache.cordova.LOG;

public class TriggerReceiver extends BroadcastReceiver {

    @Override
    public void onReceive(Context context, Intent intent) {
        LOG.e(NotificationPlugin.TAG, "Trigger Reciever Triggered!");

        String tag = intent.getAction();

        LOG.e(NotificationPlugin.TAG, "Trigger Tag: " + tag );

        ScheduledNotificationManager mgr   = new ScheduledNotificationManager(context);

        // Cancel and Remove the notification from the list of scheduled notifications
        ScheduledNotification notification = mgr.cancelNotification(tag);

        if (notification != null) {
            //Build and show the notification.
            mgr.showNotification(notification);
        } else {
            LOG.e(NotificationPlugin.TAG, "Notification "+tag+" is null! " );
        }
    }
}

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

package com.ayogo.cordova.notification;

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

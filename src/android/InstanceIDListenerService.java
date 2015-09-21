// Copyright 2015 Ayogo Health Inc.

package com.ayogo.push;

import android.content.Intent;
import android.support.v4.content.LocalBroadcastManager;
import android.util.Log;

public class InstanceIDListenerService extends com.google.android.gms.iid.InstanceIDListenerService {

    private final String TAG = "InstanceIDListService";

    @Override
    public void onTokenRefresh() {
        Log.d(TAG, "onTokenRefresh");
        LocalBroadcastManager.getInstance(this).sendBroadcast(new Intent("token_refreshed"));
    }
}

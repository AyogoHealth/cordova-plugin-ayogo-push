// Copyright 2014 Ayogo Health Inc.

package com.ayogo.push;

import android.app.Activity;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.SharedPreferences;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager.NameNotFoundException;
import android.support.v4.content.LocalBroadcastManager;
import android.util.Log;

import com.google.android.gms.common.ConnectionResult;
import com.google.android.gms.common.GooglePlayServicesUtil;
import com.google.android.gms.gcm.GoogleCloudMessaging;
import com.google.android.gms.iid.InstanceID;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONObject;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

public class PushPlugin extends CordovaPlugin
{
    private final String TAG = "PushPlugin";

    private final static int PLAY_SERVICES_RESOLUTION_REQUEST = 9000;
    private static final String EXTRA_MESSAGE = "message";
    private static final String PROPERTY_REG_ID = "registration_id";
    private static final String PROPERTY_APP_VERSION = "appVersion";

    /** The Sender ID for GCM. */
    protected String mSenderID = null;

    private BroadcastReceiver mRegistrationBroadcastReceiver;

    @Override
    protected void pluginInitialize() {
        Log.v(TAG, "Initializing");

        // Check device for Play Services APK.
        if (!checkPlayServices()) {
            Log.w(TAG, "No valid Google Play Services APK found.");
            return;
        }

        mSenderID = this.preferences.getString("gcm_sender_id", null);
        mRegistrationBroadcastReceiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                Log.d(TAG, "Token has changed");
                /*
                TODO: we should notify the client app to update the token on server
                This will work as soon as the user open the app again though
                */
                storeRegistrationId(getApplicationContext(),null);
            }
        };

        LocalBroadcastManager.getInstance(getApplicationContext()).registerReceiver(mRegistrationBroadcastReceiver, new IntentFilter("token_refreshed"));

        onNewIntent(cordova.getActivity().getIntent());
    }

    @Override
    public void onDestroy() {
        LocalBroadcastManager.getInstance(getApplicationContext()).unregisterReceiver(mRegistrationBroadcastReceiver);
        super.onDestroy();
    }

    @Override
    public boolean execute(String action, JSONArray args, final CallbackContext callback)
    {
        if (action.equals("register")) {
            String regId = getRegistration(getApplicationContext());

            if (regId == null) {
                cordova.getThreadPool().execute(new Runnable() {
                    public void run() {
                        try {
                            InstanceID instanceID = InstanceID.getInstance(getApplicationContext());
                            String new_regId = instanceID.getToken(mSenderID, GoogleCloudMessaging.INSTANCE_ID_SCOPE, null);

                            storeRegistrationId(getApplicationContext(), new_regId);

                            callback.sendPluginResult(new PluginResult(PluginResult.Status.OK, parseRegistrationData(new_regId)));
                        } catch (IOException ex) {
                            callback.sendPluginResult(new PluginResult(PluginResult.Status.ERROR, "AbortError"));
                        }
                    }
                });
            } else {
                callback.sendPluginResult(new PluginResult(PluginResult.Status.OK, parseRegistrationData(regId)));
            }

            return true;
        }


        if (action.equals("unregister")) {
            final String regId = getRegistration(getApplicationContext());

            if (regId != null) {
                cordova.getThreadPool().execute(new Runnable() {
                    public void run() {
                        try {
                            InstanceID instanceID = InstanceID.getInstance(getApplicationContext());
                            instanceID.deleteToken(mSenderID, GoogleCloudMessaging.INSTANCE_ID_SCOPE);

                            storeRegistrationId(getApplicationContext(), null);

                            callback.sendPluginResult(new PluginResult(PluginResult.Status.OK, regId));
                        } catch (IOException ex) {
                            callback.sendPluginResult(new PluginResult(PluginResult.Status.ERROR, "AbortError"));
                        }
                    }
                });
            } else {
                callback.sendPluginResult(new PluginResult(PluginResult.Status.ERROR, "AbortError"));
            }
            return true;
        }


        if (action.equals("getRegistration")) {
            String regId = getRegistration(getApplicationContext());

            if (regId != null) {
                callback.sendPluginResult(new PluginResult(PluginResult.Status.OK, parseRegistrationData(regId)));
            } else {
                callback.sendPluginResult(new PluginResult(PluginResult.Status.ERROR, "AbortError"));
            }

            return true;
        }


        if (action.equals("hasPermission")) {
            // Android doesn't require permission to send push notifications
            callback.sendPluginResult(new PluginResult(PluginResult.Status.OK, "granted"));
            return true;
        }

        Log.d(TAG, "Tried to call " + action + " with " + args.toString());

        callback.sendPluginResult(new PluginResult(PluginResult.Status.INVALID_ACTION));
        return false;
    }

    private JSONObject parseRegistrationData(String registrationId){
        Map<String,String> regData = new HashMap<String,String>();
        regData.put("endpoint", "android");
        regData.put("registrationId", registrationId);
        return new JSONObject(regData);
    }

    public void onNewIntent(Intent intent) {
        if(intent == null){
            return;
        }

        if(intent.getAction() != null && intent.getAction().equalsIgnoreCase("push")) {
            handlePushIntent(intent);
        }
    }

    private void handlePushIntent(Intent intent) {
        if(intent.getExtras() != null && intent.getExtras().getString("url") != null) {
            final String url = intent.getExtras().getString("url");
            cordova.getActivity().runOnUiThread(new Runnable() {
                public void run() {
                    webView.loadUrl("javascript:window.handleOpenURL('" + url + "')");
                }
            });
        }
    }

    /**
     * Gets the application context from cordova's main activity.
     *
     * @return the application context
     */
    private Context getApplicationContext() {
        return this.cordova.getActivity().getApplicationContext();
    }


    /**
     * Stores the registration ID and the app versionCode in the application's
     * {@code SharedPreferences}.
     *
     * @param context application's context.
     * @param regId registration ID
     */
    private void storeRegistrationId(Context context, String regId) {
        final SharedPreferences prefs = getGcmPreferences(context);
        int appVersion = getAppVersion(context);

        SharedPreferences.Editor editor = prefs.edit();
        editor.putString(PROPERTY_REG_ID, regId);
        editor.putInt(PROPERTY_APP_VERSION, appVersion);
        editor.commit();
    }


    /**
     * @return Application's version code from the {@code PackageManager}.
     */
    private static int getAppVersion(Context context) {
        try {
            PackageInfo packageInfo = context.getPackageManager().getPackageInfo(context.getPackageName(), 0);
            return packageInfo.versionCode;
        } catch (NameNotFoundException e) {
            // should never happen
            throw new RuntimeException("Could not get package name: " + e);
        }
    }

    private SharedPreferences getGcmPreferences(Context context) {
        return context.getSharedPreferences(TAG, Context.MODE_PRIVATE);
    }


    /**
     * Check the device to make sure it has the Google Play Services APK.
     *
     * If it doesn't, display a dialog that allows users to download the APK
     * from the Google Play Store or enable it in the device's system settings.
     */
    private boolean checkPlayServices() {
        Activity act = this.cordova.getActivity();

        int resultCode = GooglePlayServicesUtil.isGooglePlayServicesAvailable(act.getApplicationContext());

        if (resultCode != ConnectionResult.SUCCESS) {
            if (GooglePlayServicesUtil.isUserRecoverableError(resultCode)) {
                GooglePlayServicesUtil.getErrorDialog(resultCode, act, PLAY_SERVICES_RESOLUTION_REQUEST).show();
            } else {
                Log.i(TAG, "This device is not supported.");
            }
            return false;
        }
        return true;
    }


    /**
     * Gets the current registration ID for application on GCM service.
     *
     * If result is empty, the app needs to register.
     *
     * @return registration ID, or null if there is no existing registration.
     */
    private String getRegistration(Context context) {
        final SharedPreferences prefs = getGcmPreferences(context);
        String registrationId = prefs.getString(PROPERTY_REG_ID, "");

        if (registrationId.isEmpty()) {
            Log.i(TAG, "Registration not found.");
            return null;
        }

        // Check if app was updated; if so, it must clear the registration ID
        // since the existing regID is not guaranteed to work with the new
        // app version.
        int registeredVersion = prefs.getInt(PROPERTY_APP_VERSION, Integer.MIN_VALUE);
        int currentVersion = getAppVersion(context);

        if (registeredVersion != currentVersion) {
            Log.i(TAG, "App version changed.");
            return null;
        }

        return registrationId;
    }
}

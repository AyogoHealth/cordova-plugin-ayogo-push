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

import org.json.JSONObject;
import org.json.JSONException;

public class ScheduledNotification {

    public String title;
    public String tag;
    public String body;
    public long at;
    public String icon;
    public String badge;
    public JSONObject data;
    private JSONObject options;

    /**
     * Notification as per https://notifications.spec.whatwg.org/#persistent-notification
     * NOTE: missing some options that are not implemented yet.
     *
     * @param  {string} title
     * @param  {string} options.tag       - unique identifier for the notification
     * @param  {string} options.title     - same as the string param
     * @param  {string} options.body      - body text
     * @param  {string} options.icon      - notification icon url
     * @param  {string} options.badge     - notification badge url
     * @param  {object} options.data      - any extra data associated with the notification
     *
     */
    public ScheduledNotification(String title, JSONObject options) {
        this.title     = options.optString("title", title);

        // Save the title into the options.
        try {
            options.put("title", this.title);
        } catch(JSONException e) {}

        this.tag       = options.optString("tag", null);
        this.body      = options.optString("body", null);
        this.at        = options.optLong("at", 0);
        this.icon      = options.optString("icon", null);
        this.badge     = options.optString("badge", null);
        this.data      = options.optJSONObject("data");

        // Store the orig options for use in toString();
        this.options   = options;
    }

    public String toString() {
        return options.toString();
    }

    public JSONObject getOptions() {
        return options;
    }
}

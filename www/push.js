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

var exec = require('cordova/exec');

function PushRegistrationManager() { }

PushRegistrationManager.prototype.register = function() {
  return new Promise(function(res, rej) {
    exec(res, rej, 'Push', 'registerPush', []);
  });
};

PushRegistrationManager.prototype.unregister = function() {
  return new Promise(function(res, rej) {
    exec(res, rej, 'Push', 'unregisterPush', []);
  });
};

PushRegistrationManager.prototype.getRegistration = function() {
  return new Promise(function(res, rej) {
    exec(res, rej, 'Push', 'getPushRegistration', []);
  });
};

PushRegistrationManager.prototype.hasPermission = function() {
  return new Promise(function(res, rej) {
    exec(res, rej, 'Push', 'hasPermission', []);
  });
};

module.exports = new PushRegistrationManager();

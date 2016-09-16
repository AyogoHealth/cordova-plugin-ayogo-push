// Copyright 2014 Ayogo Health Inc.

var exec = require('cordova/exec');

/**
 * Notification as per https://notifications.spec.whatwg.org/#persistent-notification
 * NOTE: missing some options that are not implemented yet.
 *
 * @param  {string} title
 * @param  {string} options.tag       - unique identifier for the notification
 * @param  {string} options.title     - same as the string param
 * @param  {string} options.body      - body text
 * @param  {number} options.at        - unix timestamp set to when the notification should trigger
 * @param  {string} options.icon      - notification icon url
 * @param  {string} options.badge     - notification badge url
 * @param  {object} options.data      - any extra data associated with the notification
 *
 */
function Notification(title, options) {
  this.title     = title;
  this.title     = this.title || options.title;
  this.tag       = options.tag;
  this.body      = options.body;
  this.at        = options.at;
  this.icon      = options.icon;
  this.badge     = options.badge;
  this.data      = options.data;
}

var noop = function() { };

Notification.prototype.close = function() {
  exec(noop, noop, 'LocalNotification', 'closeNotification', [this.tag]);
};

function NotificationManager() { }

NotificationManager.prototype.requestPermission = function(cb) {
  if (cb) {
      exec(cb, noop, 'LocalNotification', 'requestPermission', []);
  } else {
    return new Promise(function(res, rej) {
      exec(res, rej, 'LocalNotification', 'requestPermission', []);
    });
  }
};

NotificationManager.prototype.showNotification = function(title, options) {
  return new Promise(function(res, rej) {
    exec(res, rej, 'LocalNotification', 'showNotification', [title, options]);
  });
};

NotificationManager.prototype.getNotifications = function() {
  return new Promise(function(res, rej) {
    function onsuccess(notes) {
      res(notes.map(function(options) { return new Notification(options.title, options); }));
    }

    exec(onsuccess, rej, 'LocalNotification', 'getNotifications', []);
  });
};

module.exports = new NotificationManager();

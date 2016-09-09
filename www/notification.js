// Copyright 2014 Ayogo Health Inc.

var exec = require('cordova/exec');


function NotificationInstance(data) {
  this.data = data;
}

NotificationInstance.prototype.close = function() {
  exec(res, rej, 'Notification', 'closeNotification', [this.data]);
};

function NotificationManager() { }

NotificationManager.prototype.showNotification = function(title, options) {
  return new Promise(function(res, rej) {
    exec(res, rej, 'Notification', 'showNotification', [title, options]);
  });
};

NotificationManager.prototype.getNotifications = function() {
  return new Promise(function(res, rej) {
    function onsuccess(notes) {
      res(notes.map(function(note) { return new NotificationInstance(note); }));
    }

    exec(onsuccess, rej, 'Notification', 'getNotifications', []);
  });
};

module.exports = new NotificationManager();

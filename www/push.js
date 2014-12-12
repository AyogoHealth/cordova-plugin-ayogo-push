// Copyright 2014 Ayogo Health Inc.

var exec = require('cordova/exec');

function PushRegistrationManager() { }

PushRegistrationManager.prototype.register = function() {
  return new Promise(function(res, rej) {
    exec(res, rej, 'Push', 'register', []);
  });
};

PushRegistrationManager.prototype.getRegistration = function() {
  return new Promise(function(res, rej) {
    exec(res, rej, 'Push', 'getRegistration', []);
  });
};

PushRegistrationManager.prototype.hasPermission = function() {
  return new Promise(function(res, rej) {
    exec(res, rej, 'Push', 'hasPermission', []);
  });
};

module.exports = new PushRegistrationManager();

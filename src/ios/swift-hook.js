"use strict";

const fs = require('fs');

module.exports = function(context) {
    const encoding = 'utf-8';
    const filepath = 'platforms/ios/cordova/build-release.xcconfig';
    const filepathDebug = 'platforms/ios/cordova/build-debug.xcconfig';

    var xcconfig = fs.readFileSync(filepath, encoding);
    var xcconfigDebug = fs.readFileSync(filepathDebug, encoding);

    const content = '\nEMBEDDED_CONTENT_CONTAINS_SWIFT = "YES"\nLD_RUNPATH_SEARCH_PATHS = "@executable_path/Frameworks"';

    xcconfig += content;
    fs.writeFileSync(filepath, xcconfig, encoding);

    xcconfigDebug += content;
    fs.writeFileSync(filepathDebug, xcconfigDebug, encoding);
};

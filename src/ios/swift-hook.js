"use strict";

const fs = require('fs');

module.exports = function(context) {
    if (context.opts.platforms.indexOf('ios') >= 0) {
        console.warn('UPDATING the Xcode Project files');

        const encoding = 'utf-8';
        const filepath = 'platforms/ios/cordova/build.xcconfig';

        var xcconfig = fs.readFileSync(filepath, encoding);

        if (!xcconfig.match(/SWIFT_VERSION/)) {
          const content = '\nEMBEDDED_CONTENT_CONTAINS_SWIFT = YES\nSWIFT_VERSION=4.0\nALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES=NO';

          xcconfig += content;
          fs.writeFileSync(filepath, xcconfig, encoding);
        }
    }
};

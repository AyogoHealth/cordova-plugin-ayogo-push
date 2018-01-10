"use strict";

const fs = require('fs');

module.exports = function(context) {
    if (context.opts.cordova.platforms.indexOf('ios') >= 0) {
        console.warn('UPDATING the Xcode Project files');

        const encoding = 'utf-8';
        const filepath = 'platforms/ios/cordova/build.xcconfig';

        var xcconfig = fs.readFileSync(filepath, encoding);

        const content = ['EMBEDDED_CONTENT_CONTAINS_SWIFT = YES','SWIFT_VERSION=4.0','ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES=NO'].filter(s => xcconfig.indexOf(s) === 1);

        xcconfig += `\n${content.join('\n')}\n`;
        fs.writeFileSync(filepath, xcconfig, encoding);
    }
};

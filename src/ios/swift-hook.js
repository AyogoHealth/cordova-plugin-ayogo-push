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
"use strict";

const fs = require('fs');

module.exports = function(context) {
    if (context.opts.platforms.indexOf('ios') >= 0) {
        console.warn('UPDATING the Xcode Project files');

        const encoding = 'utf-8';
        const filepath = 'platforms/ios/cordova/build.xcconfig';

        var xcconfig = fs.readFileSync(filepath, encoding);

        const content = ['EMBEDDED_CONTENT_CONTAINS_SWIFT = YES','SWIFT_VERSION=4.0','ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES=NO'].filter(s => xcconfig.indexOf(s) === -1);

        if (content.length > 0) {
          xcconfig += `\n${content.join('\n')}\n`;
          fs.writeFileSync(filepath, xcconfig, encoding);
        }
    }
};

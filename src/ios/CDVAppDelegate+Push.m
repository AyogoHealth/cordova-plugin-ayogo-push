#import "Cordova/CDVAppDelegate.h"

@implementation CDVAppDelegate(Push)
  + (void) load {
      [self performSelector:@selector(loadPush)];
  }
@end

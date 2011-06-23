//
//  AppDelegate.m
//  O-course
//
//  Created by Erik Aderstedt on 2011-06-23.
//  Copyright 2011 Aderstedt Software AB. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void)awakeFromNib {
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_6
    [NSApp setPresentationOptions:NSApplicationPresentationAutoHideDock | 
     NSApplicationPresentationDefault |
     NSApplicationPresentationFullScreen];
#endif
}
    
@end

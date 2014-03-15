//
//  VDAppDelegate.h
//  VK Audio Disk
//
//  Created by Ibadinov Marat on 11/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface VDAppDelegate : NSObject <NSApplicationDelegate> {
    __strong id fileSystem;
    __strong id fileSystemDelegate;
    __strong id accessToken;
    __unsafe_unretained id _window;
    __unsafe_unretained id webView;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet WebView *webView;

@end

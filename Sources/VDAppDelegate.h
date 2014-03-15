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
    id fileSystem;
    id fileSystemDelegate;
    id accessToken;
    id _window;
    id webView;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet WebView *webView;

@end

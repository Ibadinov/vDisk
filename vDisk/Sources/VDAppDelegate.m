//
//  VDAppDelegate.m
//  VK Audio Disk
//
//  Created by Ibadinov Marat on 11/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VDAppDelegate.h"
#import "VDFilesystemDelegate.h"
#import <OSXFUSE/OSXFUSE.h>
#import <OAuth2Client/NXOAuth2.h>

static NSString *VDClientID = nil;
static NSString *VDSecret = nil;


@implementation VDAppDelegate

@synthesize window = _window;
@synthesize webView;


- (void)mountFilesystem
{
    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(mountFailed:)
                   name:kGMUserFileSystemMountFailed object:nil];
    [center addObserver:self selector:@selector(didMount:)
                   name:kGMUserFileSystemDidMount object:nil];
    [center addObserver:self selector:@selector(didUnmount:)
                   name:kGMUserFileSystemDidUnmount object:nil];
    
    NSString* mountPath = @"/Volumes/VKAudioDisk";
    fileSystemDelegate = [[VDFilesystemDelegate alloc] init];
    fileSystem = [[GMUserFileSystem alloc] initWithDelegate:fileSystemDelegate 
                                               isThreadSafe:YES];
    
    NSMutableArray* options = [NSMutableArray array];
    NSString* volArg = [NSString stringWithFormat:@"volicon=%@",
                        [[NSBundle mainBundle] pathForResource:@"vDisk" ofType:@"icns"]];
    [options addObject:volArg];
    [options addObject:@"volname=VK Audio Disk"];
    [options addObject:@"rdonly"];
    [fileSystem mountAtPath:mountPath withOptions:options];
}

- (void)authorize
{
    [[NXOAuth2AccountStore sharedStore] setClientID:VDClientID
                                             secret:VDSecret
                                   authorizationURL:[NSURL URLWithString:@"http://api.vk.com/oauth/authorize?scope=audio&display=popup"]
                                           tokenURL:[NSURL URLWithString:@"https://api.vk.com/oauth/access_token"]
                                        redirectURL:[NSURL URLWithString:@"http://api.vk.com/blank.html"]
                                     forAccountType:VDAccountType];
    [[NXOAuth2AccountStore sharedStore] requestAccessToAccountWithType:VDAccountType
                                   withPreparedAuthorizationURLHandler:^(NSURL *preparedURL) {
                                       [[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:preparedURL]];
                                   }];
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
    NSString *pageURLString = [[[[[sender mainFrame] dataSource] request] URL] absoluteString];
    if ([pageURLString rangeOfString:@"http://api.vk.com/blank.html"].location == NSNotFound) {
        return;
    }
    pageURLString = [pageURLString stringByReplacingOccurrencesOfString:@"#" withString:@"?"];
    BOOL handled = [[NXOAuth2AccountStore sharedStore] handleRedirectURL:[NSURL URLWithString:pageURLString]];
    if (!handled) {
        NSLog(@"Counld not handle URI: %@", pageURLString);
    }
    [_window close];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(accountsDidChange:) 
                                                 name:NXOAuth2AccountStoreAccountsDidChangeNotification 
                                               object:[NXOAuth2AccountStore sharedStore]];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(authorizationFailed:) 
                                                 name:NXOAuth2AccountStoreDidFailToRequestAccessNotification 
                                               object:[NXOAuth2AccountStore sharedStore]];
    [self authorize];
}

- (void)accountsDidChange:(NSNotification *)aNotification
{
    [self mountFilesystem];
    NSLog(@"mounting filesystem");
}

- (void)authorizationFailed:(NSNotification *)aNotification
{
    NSError *error = [aNotification.userInfo objectForKey:NXOAuth2AccountStoreErrorKey];
    NSLog(@"Authorization failed, error: %@", [error description]);
}

- (void)mountFailed:(NSNotification *)notification 
{
    NSDictionary* userInfo = [notification userInfo];
    NSError* error = [userInfo objectForKey:kGMUserFileSystemErrorKey];
    NSLog(@"kGMUserFileSystem Error: %@, userInfo=%@", error, [error userInfo]);
    NSRunAlertPanel(@"Mount Failed", @"%@", nil, nil, nil, [error localizedDescription]);
    [[NSApplication sharedApplication] terminate:nil];
}

- (void)didMount:(NSNotification *)notification {
    NSDictionary* userInfo = [notification userInfo];
    NSString* mountPath = [userInfo objectForKey:kGMUserFileSystemMountPathKey];
    NSString* parentPath = [mountPath stringByDeletingLastPathComponent];
    [[NSWorkspace sharedWorkspace] selectFile:mountPath
                     inFileViewerRootedAtPath:parentPath];
}

- (void)didUnmount:(NSNotification*)notification 
{
    [[NSApplication sharedApplication] terminate:nil];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [fileSystem unmount];
    return NSTerminateNow;
}

@end
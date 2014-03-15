/*
 * vDisk
 *
 * Copyright (c) 2012-2014 Marat Ibadinov <ibadinov@me.com>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import "VDFilesystemDelegate.h"

#import <OAuth2Client/NXOAuth2.h>
#import <OSXFUSE/OSXFUSE.h>
#import <sys/xattr.h>
#import <sys/stat.h>

#import "NSData+MD5.h"
#import "NSError+POSIX.h"
#import "VDAudioTrack.h"


NSString *const VDAccountType = @"VDAccountType";


/*
 * The core set of file system operations. This class will serve as the delegate
 * for GMUserFileSystemFilesystem. For more details, see the section on
 * GMUserFileSystemOperations found in the documentation at:
 * http://macfuse.googlecode.com/svn/trunk/core/sdk-objc/Documentation/index.html
 */
@implementation VDFilesystemDelegate

@synthesize tracks;

- (id)init
{
    if (self = [super init]) {
        tracks = nil;
        checksum = nil;
    }
    return self;
}

- (NXOAuth2Account*)account {
    return [[[NXOAuth2AccountStore sharedStore] accountsWithAccountType:VDAccountType] lastObject];
}

- (NSData *) performMethod:(NSString *)method
           usingParameters:(NSDictionary *)parameters
                     error:(NSError **)error
{
    NSString *uri = [NSString stringWithFormat:@"https://api.vk.com/method/%@.xml", method];
    
    NSMutableDictionary *allParams;
    if (parameters) {
        allParams = [NSMutableDictionary dictionaryWithDictionary:parameters];
    } else {
        allParams = [NSMutableDictionary dictionary];
    }   
    NXOAuth2Account *account = [self account];    
    [allParams setValue:account.accessToken.accessToken forKey:@"access_token"];
    
    NXOAuth2Request *request = [[NXOAuth2Request alloc] initWithResource:[NSURL URLWithString:uri] method:@"GET" parameters:allParams];
    [request setAccount:account];
    
    NSURLRequest *signedRequest = [request signedURLRequest];
    
    return [NSURLConnection sendSynchronousRequest:signedRequest returningResponse:nil error:error];
}

#pragma mark Directory Contents

static inline NSArray *
VDFileList(NSDictionary *tracks)
{
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[tracks count]];
    NSEnumerator *enumerator = [tracks objectEnumerator];
    VDAudioTrack *track;
    while ((track = [enumerator nextObject]) != nil) {
        [result addObject:[track filename]];
    }
    return result;
}

- (void)updateTracks
{
    NSError *error = nil;
    NSData *data = [self performMethod:@"audio.get" usingParameters:nil error:&error];
    if (!data) {
        return NSLog(@"Failed to retrive list of tracks, error: %@", error);
    }
    @synchronized(self) {
        NSString *dataChecksum = [data md5];
        if ([checksum isEqualToString:dataChecksum]) {
            return;
        }
        NSXMLDocument *document = [[NSXMLDocument alloc] initWithData:data options:0 error:nil];
        NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:[[document rootElement] childCount]];

        NSUInteger updatedCount = 0;
        for (NSXMLElement *audio in [[document rootElement] children]) {
            VDAudioTrack *track = [[VDAudioTrack alloc] initWithXMLElement:audio];
            NSString *path = [@"/" stringByAppendingPathComponent:[track filename]];
            VDAudioTrack *old = [tracks objectForKey:path];
            /* prefer old objects with downloaded attributes over the new ones */
            [result setObject:([track isEqual:old] ? old : track) forKey:path];
            updatedCount += ![track isEqual:old];
        }
        NSLog(@"Updated tracks, found %tu new", updatedCount);
        tracks = result;
        checksum = dataChecksum;
    }
}

- (NSArray *)contentsOfDirectoryAtPath:(NSString *)path error:(NSError **)error
{
    [self updateTracks];
    return VDFileList([self tracks]);
}

#pragma mark Getting Attributes

- (NSDictionary *)attributesOfItemAtPath:(NSString *)path
                                userData:(id)userData
                                   error:(NSError **)error
{
    __strong VDAudioTrack *track;
    @synchronized(self) {
        track = [tracks objectForKey:path];
    }
    if (!track) {
        NSLog(@"No entry at path: %@", path);
        *error = [NSError errorWithPOSIXCode:ENOENT];
        return nil;
    }
    
    if (![track size]) {
        NSLog(@"Requesting attributes of file at path: %@\nURI: %@", path, [track uri]);
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[track uri]]];
        [request setHTTPMethod:@"HEAD"];
        
        NSHTTPURLResponse *response = nil;
        [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:error];
        
        if (!response) {
            NSLog(@"Failed to retrieve attribtes, error: %@", *error);
            return nil;
        }
        
        [track setSize:(NSInteger)[response expectedContentLength]];
        
        NSString *lastModified = [[response allHeaderFields] objectForKey:@"Last-Modified"];
        NSDate *date = [NSDate dateWithNaturalLanguageString:lastModified];
        [track setModificationDate:(date ? date : [NSDate date])];
    }
    
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys: 
                                [track modificationDate], NSFileCreationDate,
                                [track modificationDate], NSFileModificationDate, 
                                [NSNumber numberWithInteger:[track size]], NSFileSize,
                                [NSNumber numberWithLong:0444], NSFilePosixPermissions, 
                                NSFileTypeRegular, NSFileType, 
                                nil];
    return attributes;
}

- (NSDictionary *)attributesOfFileSystemForPath:(NSString *)path
                                          error:(NSError **)error {
  return [NSDictionary dictionary];  // Default file system attributes.
}

#pragma mark File Contents

// TODO: There are two ways to support reading of file data. With the contentsAtPath
// method you must return the full contents of the file with each invocation. For
// a more complex (or efficient) file system, consider supporting the openFileAtPath:,
// releaseFileAtPath:, and readFileAtPath: delegate methods.
#if VDFS_SIMPLE_FILE_CONTENTS

- (NSData *)contentsAtPath:(NSString *)path {
    __strong VDAudioTrack *track;
    @synchronized(self) {
        track = [tracks objectForKey:path];
    }
    if (!track) {
        return nil;  // Equivalent to ENOENT
    }
    NSLog(@"Requesting contents of file at path: %@", path);
    NSLog(@"Using URI: %@", [track uri]);
    NSURL *url = [NSURL URLWithString:[track uri]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    return [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
}

#else /* VDFS_SIMPLE_FILE_CONTENTS */

- (BOOL)openFileAtPath:(NSString *)path
                  mode:(int)mode
              userData:(const void **)userData
                 error:(NSError **)error
{
    NSLog(@"Opening file: %@", path);
    @synchronized(self) {
        *userData = CFBridgingRetain([tracks objectForKey:path]);
    }
    if (!*userData) {
        *error = [NSError errorWithPOSIXCode:ENOENT];
        return NO;
    } else
        return YES;
}

- (void)releaseFileAtPath:(NSString *)path userData:(void *)userData
{
    NSLog(@"Closing file: %@", path);
    CFBridgingRelease(userData);
}

- (int)readFileAtPath:(NSString *)path
             userData:(id)userData
               buffer:(char *)buffer
                 size:(size_t)size
               offset:(off_t)offset
                error:(NSError **)error
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[userData uri]]];
    NSString *range = [NSString stringWithFormat:@"bytes=%zd-%zd", offset, (offset + size - 1)];
    [request addValue:range forHTTPHeaderField:@"Range"];
    NSLog(@"Requesting file data using URI: %@", [userData uri]);
    
    NSHTTPURLResponse *response;
    [request setCachePolicy:NSURLRequestReloadRevalidatingCacheData];
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:error];
    
    if (!data) {
        NSLog(@"Failed to retrieve data, error: %@", *error);
        return -1;
    }
    
    NSLog(@"Requested range: %@", range);
    NSLog(@"Received range: %@", [[response allHeaderFields] objectForKey:@"Content-Range"]);
    
    size_t result = [data length];
    result = result > size ? size : result;
    if (data) {
        memcpy(buffer, [data bytes], result);
    }
    
    return (int)result;
}

#endif /* VDFS_SIMPLE_FILE_CONTENTS */

#pragma mark Symbolic Links (Optional)

- (NSString *)destinationOfSymbolicLinkAtPath:(NSString *)path
                                        error:(NSError **)error {
  *error = [NSError errorWithPOSIXCode:ENOENT];
  return NO;
}

#pragma mark Extended Attributes (Optional)

- (NSArray *)extendedAttributesOfItemAtPath:(NSString *)path error:(NSError **)error {
  return [NSArray array];  // No extended attributes.
}

- (NSData *)valueOfExtendedAttribute:(NSString *)name
                        ofItemAtPath:(NSString *)path
                            position:(off_t)position
                               error:(NSError **)error {
  *error = [NSError errorWithPOSIXCode:ENOATTR];
  return nil;
}

#pragma mark FinderInfo and ResourceFork (Optional)

- (NSDictionary *)finderAttributesAtPath:(NSString *)path
                                   error:(NSError **)error {
  return [NSDictionary dictionary];
}

- (NSDictionary *)resourceAttributesAtPath:(NSString *)path
                                     error:(NSError **)error {
  return [NSDictionary dictionary];
}

@end

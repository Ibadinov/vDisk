#import "VDFilesystemDelegate.h"

#import <OAuth2Client/NXOAuth2.h>
#import <Fuse4X/Fuse4X.h>
#import <sys/xattr.h>
#import <sys/stat.h>

#import "VDAudioTrack.h"
#import "NSData+MD5.h"

NSString *const VDAccountType = @"VDAccountType";

// NOTE: It is fine to remove the below sections that are marked as 'Optional'.

// The core set of file system operations. This class will serve as the delegate
// for GMUserFileSystemFilesystem. For more details, see the section on
// GMUserFileSystemOperations found in the documentation at:
// http://macfuse.googlecode.com/svn/trunk/core/sdk-objc/Documentation/index.html
@implementation VDFilesystemDelegate

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
    [request release];
    
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
    NSData *data = [self performMethod:@"audio.get" usingParameters:nil error:error];
    if (!data) {
        return NSLog(@"Failed to retrive list of tracks, error: %@", *error);
    }
    @synchronized(self) {
        NSString *dataChecksum = [data md5];
        if ([checksum isEqualToString:dataChecksum]) {
            return;
        }
        [tracks release];
        NSXMLDocument *document = [[NSXMLDocument alloc] initWithData:data options:0 error:nil];
        tracks = [[NSMutableDictionary alloc] initWithCapacity:[[document rootElement] childCount]];
        
        for (NSXMLElement *audio in [[document rootElement] children]) {
            VDAudioTrack *track = [[[VDAudioTrack alloc] initWithXMLElement:audio] autorelease];
            [tracks setObject:track forKey:[@"/" stringByAppendingPathComponent:[track filename]]];
        }
        [document release];
        [checksum release];
        checksum = [dataChecksum retain];
    }
}

- (NSDictionary *)tracks
{
    return tracks
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
    VDAudioTrack *track;
    @synchronized(self) {
        track = [[tracks objectForKey:path] retain];
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
            [track release];
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
    [track release];
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
    VDAudioTrack *track;
    @synchronized(self) {
        track = [[tracks objectForKey:path] retain];
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
              userData:(id *)userData
                 error:(NSError **)error
{
    NSLog(@"Opening file: %@", path);
    @synchronized(self) {
        *userData = [[tracks objectForKey:path] retain];
    }
    if (!*userData) {
        *error = [NSError errorWithPOSIXCode:ENOENT];
        return NO;
    } else
        return YES;
}

- (void)releaseFileAtPath:(NSString *)path userData:(id)userData
{
    NSLog(@"Closing file: %@", path);
    [userData release];
}

- (int)readFileAtPath:(NSString *)path
             userData:(id)userData
               buffer:(char *)buffer
                 size:(size_t)size
               offset:(off_t)offset
                error:(NSError **)error
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[userData uri]]];
    NSString *range = [NSString stringWithFormat:@"bytes=%lu-%lu", offset, (offset + size - 1)];
    [request addValue:range forHTTPHeaderField:@"Range"];
    NSLog(@"Requesting file data using URI: %@", [userData uri]);
    
    NSHTTPURLResponse *response;
    [request setCachePolicy:NSURLRequestReloadRevalidatingCacheData];
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:error];
    
    if (!data) {
        NSLog(@"Failed to retrieve data, error: %@", error);
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

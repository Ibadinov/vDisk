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

#import <OSXFUSE/OSXFUSE.h>
#import <sys/xattr.h>
#import <sys/stat.h>

#import "NSError+POSIX.h"
#import "VDFile.h"
#import "VDRootDirectory.h"


NS_INLINE void
SetError(NSError **error, NSError *value)
{
    if (error) {
        *error = value;
    }
}


@implementation VDFilesystemDelegate

- (id)init
{
    if (self = [super init]) {
        root = [VDRootDirectory new];
    }
    return self;
}

- (id)getFileSystemNodeAtPath:(NSString *)path
{
    NSArray *components = [path pathComponents];
    NSUInteger count = [components count];
    if (!count) {
        return nil;
    }
    id node = root;
    for (NSUInteger index = 1; index < count; ++index) {
        if (![node isKindOfClass:[VDDirectory class]]) {
            return nil;
        }
        node = [[node getContentsAllowingCache:YES] objectForKey:components[index]];
        if (!node) {
            return nil;
        }
    }
    return node;
}

#pragma mark Directory Contents

- (NSArray *)contentsOfDirectoryAtPath:(NSString *)path error:(NSError **)error
{
    NSLog(@"listdir: %@", path);
    VDNode *node = [self getFileSystemNodeAtPath:path];
    NSLog(@"Node: %@", node);
    if (!node) {
        SetError(error, [NSError errorWithPOSIXCode:ENOENT]);
        return nil;
    }
    if (![node isKindOfClass:[VDDirectory class]]) {
        SetError(error, [NSError errorWithPOSIXCode:ENOTDIR]);
        return nil;
    }
    /* reload contents and update cache */
    return [[(VDDirectory *)node getContentsAllowingCache:NO] allKeys];
}

#pragma mark Getting Attributes

- (NSDictionary *)attributesOfItemAtPath:(NSString *)path
                                userData:(id)userData
                                   error:(NSError **)error
{
    NSLog(@"getattrs: %@", path);
    VDNode *node = [self getFileSystemNodeAtPath:path];
    NSLog(@"Node: %@", node);
    if (!node) {
        NSLog(@"No entry at path: %@", path);
        SetError(error, [NSError errorWithPOSIXCode:ENOENT]);
        return nil;
    }
    return [node getAttributes];
}

- (NSDictionary *)attributesOfFileSystemForPath:(NSString *)path
                                          error:(NSError **)error {
  return [NSDictionary dictionary];  /* Default file system attributes */
}

#pragma mark File Contents

- (BOOL)openFileAtPath:(NSString *)path
                  mode:(int)mode
              userData:(const void **)userData
                 error:(NSError **)error
{
    NSLog(@"Opening file: %@", path);
    VDNode *node = [self getFileSystemNodeAtPath:path];
    if (!node) {
        SetError(error, [NSError errorWithPOSIXCode:ENOENT]);
        return NO;
    }
    if (![node isKindOfClass:[VDFile class]]) {
        SetError(error, [NSError errorWithPOSIXCode:EISDIR]);
        return NO;
    }
    *userData = CFBridgingRetain(node);
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
    return (int)[(VDFile *)userData readDataIntoBuffer:buffer size:size offset:offset error:error];
}

#pragma mark Symbolic Links (Optional)

- (NSString *)destinationOfSymbolicLinkAtPath:(NSString *)path error:(NSError **)error
{
    /* There is no symlink. We don't support them */
    SetError(error, [NSError errorWithPOSIXCode:ENOENT]);
    return nil;
}

#pragma mark Extended Attributes (Optional)

- (NSArray *)extendedAttributesOfItemAtPath:(NSString *)path error:(NSError **)error
{
    return [NSArray array]; /* No extended attributes */
}

- (NSData *)valueOfExtendedAttribute:(NSString *)name
                        ofItemAtPath:(NSString *)path
                            position:(off_t)position
                               error:(NSError **)error
{
    SetError(error, [NSError errorWithPOSIXCode:ENOENT]);
    return nil;
}

#pragma mark FinderInfo and ResourceFork (Optional)

- (NSDictionary *)finderAttributesAtPath:(NSString *)path error:(NSError **)error
{
    return [NSDictionary dictionary];
}

- (NSDictionary *)resourceAttributesAtPath:(NSString *)path error:(NSError **)error
{
    return [NSDictionary dictionary];
}

@end

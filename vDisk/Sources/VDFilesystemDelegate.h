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

#import <Foundation/Foundation.h>

#define VDFS_SIMPLE_FILE_CONTENTS 0


extern NSString *const VDAccountType;


@interface VDFilesystemDelegate : NSObject  {
    __strong NSMutableDictionary *tracks;
    __strong NSString            *checksum;
}

- (id)init;

#pragma mark Properties

@property (readonly) NSDictionary *tracks;

#pragma mark Directory Contents

- (NSArray *)contentsOfDirectoryAtPath:(NSString *)path error:(NSError **)error;

#pragma mark Getting Attributes

- (NSDictionary *)attributesOfItemAtPath:(NSString *)path
                                userData:(id)userData
                                   error:(NSError **)error;

- (NSDictionary *)attributesOfFileSystemForPath:(NSString *)path
                                          error:(NSError **)error;

#pragma mark File Contents


#if VDFS_SIMPLE_FILE_CONTENTS

- (NSData *)contentsAtPath:(NSString *)path;

#else /* VDFS_SIMPLE_FILE_CONTENTS */

- (BOOL)openFileAtPath:(NSString *)path
                  mode:(int)mode
              userData:(const void **)userData
                 error:(NSError **)error;

- (void)releaseFileAtPath:(NSString *)path userData:(void *)userData;

- (int)readFileAtPath:(NSString *)path
             userData:(id)userData
               buffer:(char *)buffer
                 size:(size_t)size
               offset:(off_t)offset
                error:(NSError **)error;

#endif  /* VDFS_SIMPLE_FILE_CONTENTS */

#pragma mark Symbolic Links (Optional)

- (NSString *)destinationOfSymbolicLinkAtPath:(NSString *)path
                                        error:(NSError **)error;

#pragma mark Extended Attributes (Optional)

- (NSArray *)extendedAttributesOfItemAtPath:(NSString *)path error:(NSError **)error;

- (NSData *)valueOfExtendedAttribute:(NSString *)name
                        ofItemAtPath:(NSString *)path
                            position:(off_t)position
                               error:(NSError **)error;

#pragma mark FinderInfo and ResourceFork (Optional)

- (NSDictionary *)finderAttributesAtPath:(NSString *)path
                                   error:(NSError **)error;

- (NSDictionary *)resourceAttributesAtPath:(NSString *)path
                                     error:(NSError **)error;

@end

#import <Foundation/Foundation.h>

extern NSString *const VDAccountType;

#define VDFS_SIMPLE_FILE_CONTENTS 0

@interface VDFilesystemDelegate : NSObject  {
    NSMutableDictionary *tracks;
    NSString            *checksum;
}

- (id)init;

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
              userData:(id *)userData
                 error:(NSError **)error;

- (void)releaseFileAtPath:(NSString *)path userData:(id)userData;

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

// Category on NSError to  simplify creating an NSError based on posix errno.
@interface NSError (POSIX)

+ (NSError *)errorWithPOSIXCode:(int)code;

@end
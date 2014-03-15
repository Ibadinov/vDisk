//
//  NSError+POSIX.m
//  VK Audio Disk
//
//  Created by Ibadinov Marat on 11/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSError+POSIX.h"

@implementation NSError (POSIX)

+ (NSError *)errorWithPOSIXCode:(int)code {
    return [NSError errorWithDomain:NSPOSIXErrorDomain code:code userInfo:nil];
}

@end
//
//  NSError+POSIX.h
//  VK Audio Disk
//
//  Created by Ibadinov Marat on 11/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSError (POSIX)

+ (NSError *)errorWithPOSIXCode:(int)code;

@end
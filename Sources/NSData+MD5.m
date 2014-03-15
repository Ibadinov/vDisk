//
//  NSData+MD5.m
//  VK Audio Disk
//
//  Created by Ibadinov Marat on 11/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSData+MD5.h"
#import <Foundation/NSString.h>
#import <CommonCrypto/CommonDigest.h>

@implementation NSData (MD5)

- (NSString *)md5
{
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5([self bytes], (CC_LONG)[self length], digest);
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int index = 0; index < CC_MD5_DIGEST_LENGTH; ++index) {
        [output appendFormat:@"%02x", digest[index]];
    }
    
    return output;
}

@end
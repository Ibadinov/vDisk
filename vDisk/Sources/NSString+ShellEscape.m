//
//  NSString+ShellEscape.m
//  VK Audio Disk
//
//  Created by Ibadinov Marat on 11/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSString+ShellEscape.h"

@implementation NSString (ShellEscape)

- (NSString *)stringByEscapingCharactersInSet:(NSCharacterSet *)aCharset
{
    NSMutableString *result = [[NSMutableString alloc] initWithCapacity:[self length]];
    for (NSUInteger index = 0; index < [self length]; ++index) {
        unichar character = [self characterAtIndex:index];
        if ([aCharset characterIsMember:character]) {
            [result appendString:@"\\"];
        }
        [result appendString:[NSString stringWithCharacters:&character length:1]];
    }
    return result;
}

- (NSString *)stringForUsingAsPathComponent
{
    NSString *result = [self stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
    return [result stringByEscapingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@":?%|<>\""]];
}

@end
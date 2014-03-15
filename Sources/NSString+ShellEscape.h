//
//  NSString+ShellEscape.h
//  VK Audio Disk
//
//  Created by Ibadinov Marat on 11/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/NSString.h>

@interface NSString (ShellEscape)

- (NSString *)stringByEscapingCharactersInSet:(NSCharacterSet *)aCharset;
- (NSString *)stringForUsingAsPathComponent;

@end
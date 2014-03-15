//
//  VDAudioTrack.m
//  VK Audio Disk
//
//  Created by Ibadinov Marat on 11/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VDAudioTrack.h"
#import "NSXMLElement+FastAccess.h"


static inline NSString *
VDPrepareName(NSString *name)
{
    NSString *result = (__bridge NSString *)CFXMLCreateStringByUnescapingEntities(kCFAllocatorDefault, (__bridge CFStringRef)name, NULL);
    result = [result stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
    return [result decomposedStringWithCanonicalMapping];
}


@implementation VDAudioTrack

@synthesize uri;
@synthesize size;
@synthesize modificationDate;

- (id)initWithXMLElement:(NSXMLElement *)anElement
{
    if (self = [super init]) {
        artist = VDPrepareName([anElement contentOfElementWithName:@"artist"]);
        title = VDPrepareName([anElement contentOfElementWithName:@"title"]);
        uri = [anElement contentOfElementWithName:@"url"];
        identifier = [[anElement contentOfElementWithName:@"aid"] integerValue];
        duration = [[anElement contentOfElementWithName:@"duration"] integerValue];
        size = 0;
        modificationDate = nil;
    }
    return self;
}

- (NSString *)filename
{
    NSString *filename = [NSString stringWithFormat:@"%@ - %@.mp3", artist, title];
    /* replace “colon” (0x003A) with “modifier letter colon” (0xA789)   */
    /* replace “slash” with “colon” (Finder displays it as “slash”)     */
    return [[filename stringByReplacingOccurrencesOfString:@":" withString:@"꞉"] stringByReplacingOccurrencesOfString:@"/" withString:@":"];
}

@end

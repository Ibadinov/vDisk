//
//  VDAudioTrack.m
//  VK Audio Disk
//
//  Created by Ibadinov Marat on 11/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VDAudioTrack.h"
#import "NSXMLElement+FastAccess.h"

@implementation VDAudioTrack

static inline NSString *
VDPrepareName(NSString *name)
{
    NSString *result = (NSString *)CFXMLCreateStringByUnescapingEntities(kCFAllocatorDefault, (CFStringRef)name, NULL);
    result = [result stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
    return [result decomposedStringWithCanonicalMapping];
}

- (id)initWithXMLElement:(NSXMLElement *)anElement
{
    if (self = [super init]) {
        artist = [VDPrepareName([anElement contentOfElementWithName:@"artist"]) retain];
        title = [VDPrepareName([anElement contentOfElementWithName:@"title"]) retain];
        uri = [[anElement contentOfElementWithName:@"url"] retain];
        identifier = [[anElement contentOfElementWithName:@"aid"] integerValue];
        duration = [[anElement contentOfElementWithName:@"duration"] integerValue];
        size = 0;
        modificationDate = nil;
    }
    return self;
}

- (void)dealloc
{
    [artist release];
    [title release];
    [uri release];
}

- (NSString *)filename
{
    NSString *filename = [NSString stringWithFormat:@"%@ - %@.mp3", artist, title];
    /* replace “colon” (0x003A) with “modifier letter colon” (0xA789)   */
    /* replace “slash” with “colon” (Finder displays it as “slash”)     */
    return [[filename stringByReplacingOccurrencesOfString:@":" withString:@"꞉"] stringByReplacingOccurrencesOfString:@"/" withString:@":"];
}

- (NSString *)uri
{
    return uri;
}

- (NSInteger)size
{
    return size;
}

- (NSDate *)modificationDate
{
    return modificationDate;
}

- (void)setSize:(NSInteger)aSize
{
    size = aSize;
}

- (void)setModificationDate:(NSDate *)aDate
{
    id previousDate = modificationDate;
    modificationDate = [aDate retain];
    [previousDate release];
}

@end
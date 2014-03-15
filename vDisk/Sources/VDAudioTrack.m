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

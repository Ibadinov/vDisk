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

#import "VDNode.h"
#import "NSObject+Abstract.h"


NSString *
VDGetFinderFriendlyFilename(NSString *filename)
{
    /* nobody needs those spaces */
    filename = [filename stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
    /* replace “colon” (0x003A) with “modifier letter colon” (0xA789) */
    filename = [filename stringByReplacingOccurrencesOfString:@":" withString:@"꞉"];
    /* replace “slash” with “colon” (Finder displays it as “slash”) */
    filename = [filename stringByReplacingOccurrencesOfString:@"/" withString:@":"];
    /* Finder demands this form of Unicode normalization */
    filename = [filename decomposedStringWithCanonicalMapping];
    return filename;
}


@implementation VDNode

- (id)initWithName:(NSString *)aName
{
    if (self = [super init]) {
        name = VDGetFinderFriendlyFilename(aName);
    }
    return self;
}

- (NSString *)name
{
    return name;
}

- (NSDictionary *)retrieveAttributes
{
    return [self subclassResponsibility:_cmd];
}

- (NSDictionary *)getAttributes
{
    if (!attributes) {
        NSLog(@"Requesting attributes of node: %@\nName: %@", self, name);
        NSMutableDictionary *retrieved = [[self retrieveAttributes] mutableCopy];
        @synchronized (self) {
            [retrieved setObject:[NSNumber numberWithInt:geteuid()] forKey:NSFileOwnerAccountID];
            [retrieved setObject:[NSNumber numberWithInt:getegid()] forKey:NSFileGroupOwnerAccountID];
            if (![retrieved objectForKey:NSFileCreationDate] || ![retrieved objectForKey:NSFileModificationDate]) {
                NSDate *date = [NSDate date];
                [retrieved setObject:date forKey:NSFileCreationDate];
                [retrieved setObject:date forKey:NSFileModificationDate];
            }
            return attributes = retrieved;
        }
    }
    return attributes;
}

@end

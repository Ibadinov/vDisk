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
    /* Finder demands this form of Unicode normalization */
    filename = [filename decomposedStringWithCanonicalMapping];
    /* replace “colon” (0x003A) with “modifier letter colon” (0xA789) */
    filename = [filename stringByReplacingOccurrencesOfString:@":" withString:@"꞉"];
    /* replace “slash” with “colon” (Finder displays it as “slash”) */
    filename = [filename stringByReplacingOccurrencesOfString:@"/" withString:@":"];
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

- (NSString *)type
{
    return [self subclassResponsibility:_cmd];
}

- (NSDictionary *)retrieveAttributes
{
    return [NSDictionary dictionary];
}

- (NSDictionary *)getAttributes
{
    if (!attributes) {
        NSLog(@"Requesting attributes of node: %@", self);
        NSDictionary *retrieved = [self retrieveAttributes];
        @synchronized (self) {
            attributes = [retrieved mutableCopy];
            [(NSMutableDictionary *)attributes setObject:[NSNumber numberWithLong:0444] forKey:NSFilePosixPermissions];
            [(NSMutableDictionary *)attributes setObject:[self type] forKey:NSFileType];
            return attributes;
        }
    }
    return attributes;
}

@end

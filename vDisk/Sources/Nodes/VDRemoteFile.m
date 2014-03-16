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

#import "VDRemoteFile.h"
#import "VDAPI.h"


@implementation VDRemoteFile

@synthesize url;

- (id)initWithName:(NSString *)aName URL:(NSString *)anURL
{
    if (self = [super initWithName:aName]) {
        url = anURL;
    }
    return self;
}

- (NSDictionary *)retrieveAttributes
{
    return VDAttributesOfFileAtURL(url, nil);
}

- (size_t)readDataIntoBuffer:(char *)buffer
                        size:(size_t)size
                      offset:(off_t)offset
                       error:(NSError *__autoreleasing *)error
{
    return VDReadFileAtURL(url, buffer, size, offset, error);
}

- (BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:[VDRemoteFile class]]) {
        return NO;
    }
    return [[object name] isEqual:name] && [[object url] isEqual:url];
}

- (NSUInteger)hash
{
    return [url hash];
}

@end
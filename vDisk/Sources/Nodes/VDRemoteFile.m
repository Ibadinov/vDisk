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
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"HEAD"];

    NSHTTPURLResponse *response = nil;
    NSError *underlyingError = nil;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&underlyingError];
    if (!response) {
        NSLog(@"Failed to retrieve attribtes, error: %@", underlyingError);
        return nil;
    }

    NSNumber *size = [NSNumber numberWithLongLong:[response expectedContentLength]];
    NSDate *lastModified = [NSDate dateWithNaturalLanguageString:[[response allHeaderFields] objectForKey:@"Last-Modified"]];
    lastModified = lastModified ? lastModified : [NSDate date];

    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   size, NSFileSize,
                                   lastModified, NSFileCreationDate,
                                   lastModified, NSFileModificationDate,
                                   nil];
    [result addEntriesFromDictionary:[super retrieveAttributes]];
    return result;
}

- (size_t)readDataIntoBuffer:(char *)buffer
                        size:(size_t)size
                      offset:(off_t)offset
                       error:(NSError *__autoreleasing *)error
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    NSString *range = [NSString stringWithFormat:@"bytes=%zd-%zd", offset, (offset + size - 1)];
    [request addValue:range forHTTPHeaderField:@"Range"];
    NSLog(@"Requesting file data using URI: %@", url);

    NSHTTPURLResponse *response;
    [request setCachePolicy:NSURLRequestReloadRevalidatingCacheData];
    NSError *underlyingError = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&underlyingError];

    if (!data) {
        NSLog(@"Failed to retrieve data, error: %@", underlyingError);
        if (error) {
            *error = underlyingError;
        }
        return -1;
    }

    NSLog(@"Requested range: %@/%@", range, [[self getAttributes] objectForKey:NSFileSize]);
    NSString *receivedRange = [[response allHeaderFields] objectForKey:@"Content-Range"];
    NSLog(@"Received range: %@", receivedRange);
    NSLog(@"Data length: %tu <=> %tu", [data length], size);

    NSUInteger shift = 0;
    NSUInteger received = [data length];
    if (!receivedRange) {
        /* we received file from the start */
        shift = offset;
        if (shift + size > received) {
            received = shift < received ? received - shift : 0;
        } else
            received = size;
    }
    if (data) {
        memcpy(buffer, [data bytes] + shift, received);
    }
    return received;
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

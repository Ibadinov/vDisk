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

#import "VDAPI.h"

#import <OAuth2Client/NXOAuth2.h>

NSString *const VDAccountType = @"VDAccountType";


NXOAuth2Account*
VDAPIAccountGet()
{
    return [[[NXOAuth2AccountStore sharedStore] accountsWithAccountType:VDAccountType] lastObject];
}


NSData *
VDAPIPerformMethod(NSString *method, NSDictionary *parameters, NSError **error)
{
    NSString *uri = [NSString stringWithFormat:@"https://api.vk.com/method/%@.xml", method];

    NSMutableDictionary *allParams;
    if (parameters) {
        allParams = [NSMutableDictionary dictionaryWithDictionary:parameters];
    } else {
        allParams = [NSMutableDictionary dictionary];
    }
    NXOAuth2Account *account = VDAPIAccountGet();
    [allParams setValue:account.accessToken.accessToken forKey:@"access_token"];

    NXOAuth2Request *request = [[NXOAuth2Request alloc] initWithResource:[NSURL URLWithString:uri] method:@"GET" parameters:allParams];
    [request setAccount:account];

    NSURLRequest *signedRequest = [request signedURLRequest];

    return [NSURLConnection sendSynchronousRequest:signedRequest returningResponse:nil error:error];
}


NSString *
VDDecodeXMLEntities(NSString *string)
{
    return (__bridge NSString *)CFXMLCreateStringByUnescapingEntities(kCFAllocatorDefault, (__bridge CFStringRef)string, NULL);
}


NSDictionary *
VDAttributesOfFileAtURL(NSString *url, NSError **error)
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"HEAD"];

    NSHTTPURLResponse *response = nil;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:error];
    if (!response) {
        NSLog(@"Failed to retrieve attribtes, error: %@", *error);
        return nil;
    }

    NSNumber *size = [NSNumber numberWithLongLong:[response expectedContentLength]];
    NSDate *lastModified = [NSDate dateWithNaturalLanguageString:[[response allHeaderFields] objectForKey:@"Last-Modified"]];
    lastModified = lastModified ? lastModified : [NSDate date];

    return [NSDictionary dictionaryWithObjectsAndKeys:
            size, NSFileSize,
            lastModified, NSFileCreationDate,
            lastModified, NSFileModificationDate,
            nil];
}


size_t
VDReadFileAtURL(NSString *url, char *buffer, size_t size, off_t offset, NSError **error)
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

    NSLog(@"Requested range: %@", range);
    NSLog(@"Received range: %@", [[response allHeaderFields] objectForKey:@"Content-Range"]);

    size_t result = [data length];
    result = result > size ? size : result;
    if (data) {
        memcpy(buffer, [data bytes], result);
    }

    return result;
}

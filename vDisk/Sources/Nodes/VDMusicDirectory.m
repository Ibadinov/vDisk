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

#import "VDMusicDirectory.h"
#import "VDRemoteFile.h"
#import "VDAPI.h"
#import "NSXMLElement+FastAccess.h"


@implementation VDMusicDirectory

- (NSDictionary *)retrieveContents
{
    NSError *error = nil;
    NSData *data = VDAPIPerformMethod(@"audio.get", nil, &error);
    if (!data) {
        NSLog(@"Failed to retrive list of tracks, error: %@", error);
        return nil;
    }
    NSXMLDocument *document = [[NSXMLDocument alloc] initWithData:data options:0 error:&error];
    if (!document) {
        NSLog(@"Failed to parse XML response, error: %@", error);
        return nil;
    }

    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:[[document rootElement] childCount]];
    for (NSXMLElement *audio in [[document rootElement] children]) {
        NSString *artist    = [audio contentOfElementWithName:@"artist"];
        NSString *title     = [audio contentOfElementWithName:@"title"];
        NSString *url       = [audio contentOfElementWithName:@"url"];

        NSString *filename = [NSString stringWithFormat:@"%@ - %@.mp3", artist, title];
        VDRemoteFile *file = [[VDRemoteFile alloc] initWithName:filename URL:url];
        [result setObject:file forKey:[file name]]; /* use cleaned name instead of raw */
    }
    return result;
}

@end

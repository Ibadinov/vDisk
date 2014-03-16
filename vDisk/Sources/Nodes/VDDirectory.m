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

#import "VDDirectory.h"
#import "NSObject+Abstract.h"


@implementation VDDirectory

- (NSString *)type
{
    return NSFileTypeDirectory;
}

- (NSDictionary *)getContentsAllowingCache:(BOOL)isCacheAllowed
{
    if (!contents || !isCacheAllowed) {
        NSMutableDictionary *retrieved = [[self retrieveContents] mutableCopy];
        @synchronized (self) {
            for (id filename in retrieved) {
                VDNode *cached = [contents objectForKey:filename];
                /* preserve cached elements if possible, for they have their own caches */
                if ([[retrieved objectForKey:filename] isEqual:cached]) {
                    [retrieved setObject:cached forKey:filename];
                }
            }
            return contents = retrieved;
        }
    }
    return contents;
}

- (NSDictionary *)retrieveContents
{
    return [self subclassResponsibility:_cmd];
}

- (BOOL)isEqual:(id)object
{
    /* different types of folders can not be equal */
    if (![object isKindOfClass:[self class]]) {
        return NO;
    }
    return [[object name] isEqual:name];
}

- (NSUInteger)hash
{
    return [name hash];
}

@end

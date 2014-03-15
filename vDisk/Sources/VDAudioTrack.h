//
//  VDAudioTrack.h
//  VK Audio Disk
//
//  Created by Ibadinov Marat on 11/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VDAudioTrack : NSObject {
@private
    NSString    *artist;
    NSString    *title;
    NSString    *uri;
    NSUInteger  identifier;
    NSUInteger  duration;
    NSInteger   size;
    NSDate      *modificationDate;
}

- (id)initWithXMLElement:(NSXMLElement *)anElement;
- (NSString *)filename;
- (NSString *)uri;

- (NSInteger)size;
- (NSDate *)modificationDate;

- (void)setSize:(NSInteger)aSize;
- (void)setModificationDate:(NSDate *)aDate;

@end
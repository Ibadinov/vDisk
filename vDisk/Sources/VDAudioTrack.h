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
    __strong NSString   *artist;
    __strong NSString   *title;
    __strong NSString   *uri;
    NSUInteger          identifier;
    NSUInteger          duration;
    NSInteger           size;
    __strong NSDate     *modificationDate;
}

- (id)initWithXMLElement:(NSXMLElement *)anElement;

@property (readonly) NSString *filename;
@property (readonly) NSString *uri;

@property NSInteger size;
@property NSDate    *modificationDate;

@end

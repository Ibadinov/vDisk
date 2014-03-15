//
//  NSXMLElement+FastAccess.h
//  VK Audio Disk
//
//  Created by Ibadinov Marat on 11/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/NSXMLElement.h>

@interface NSXMLElement (FastAccess)

- (NSXMLElement *)firstChild;
- (NSXMLElement *)elementForName:(NSString *)name;
- (NSString *)contentOfElementWithName:(NSString *)name;

@end
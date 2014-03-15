//
//  NSXMLElement+FastAccess.m
//  VK Audio Disk
//
//  Created by Ibadinov Marat on 11/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSXMLElement+FastAccess.h"

@implementation NSXMLElement (FastAccess)

- (NSXMLElement *)firstChild
{
    return (NSXMLElement *)[self childAtIndex:0];
}

- (NSXMLElement *)elementForName:(NSString *)name
{
    return [[self elementsForName:name] objectAtIndex:0];
}

- (NSString *)contentOfElementWithName:(NSString *)name
{
    return [[self elementForName:name] stringValue];
}

@end
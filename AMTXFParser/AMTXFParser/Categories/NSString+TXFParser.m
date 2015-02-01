//
//  NSString+TXFParser.m
//  AMDTXFParser
//
//  Created by Anoop Mohandas on 28/01/15.
//  Copyright (c) 2015 Anoop Mohandas. All rights reserved.
//

#import "NSString+TXFParser.h"
#import "TXFParser.h"

@implementation NSString (TXFParser)

- (id)TXFObject{
    return [[TXFParser new] objectFromString:self];
}

@end

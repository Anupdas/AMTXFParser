//
//  NSObject+TXFWriter.m
//  AMDTXFParser
//
//  Created by Anoop Mohandas on 28/01/15.
//  Copyright (c) 2015 Anoop Mohandas. All rights reserved.
//

#import "NSObject+TXFWriter.h"
#import "TXFWriter.h"

@implementation NSObject(TXFWriter)

- (NSString *)TXFString{
    if ([self isKindOfClass:[NSDictionary class]]||
        [self isKindOfClass:[NSArray class]]) {
        return [[TXFWriter new] stringFromObject:self];
    }else{
        return [self description];
    }
}

- (NSString *)JSONString{
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    
    if (error) {
        NSLog(@"JSON Serialization Error : %@",error.localizedDescription);
    }
    
    NSString *json = [[NSString alloc] initWithData:jsonData
                                           encoding:NSUTF8StringEncoding];
    return json;
}
@end

//
//  TXFWriter.m
//  AMDTXFParser
//
//  Created by Anoop Mohandas on 28/01/15.
//  Copyright (c) 2015 Anoop Mohandas. All rights reserved.
//

#import "TXFWriter.h"

static NSString *const kTXFText  = @"TXFText";
static NSString *const kArray    = @"TXFArray";
static NSString *const kTXFNull  = @"$#!";

@implementation TXFWriter

#pragma mark - Getters

- (NSString *)stringFromObject:(id)object{
    if ([object isKindOfClass:[NSDictionary class]]) {
        return [self stringFromDictionary:object withKey:nil];
    }else{
        return [self stringFromArray:object withKey:nil];
    }
}

-  (NSString *)stringFromDictionary:(NSDictionary *)dictionary withKey:(NSString *)aKey{
    NSMutableString *string = [@"" mutableCopy];
    
    //Sort keys so that Id and Dates are serialized before any other values
    NSArray *allKeys = [dictionary allKeys];//[self sortedKeysForDictionary:dictionary];
    
    [allKeys enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop) {
        id obj = dictionary[key];
        if ([obj isKindOfClass:[NSArray class]]) {
            [string appendString:[self stringFromArray:obj withKey:key]];
        }else if([obj isKindOfClass:[NSDictionary class]]){
            [string appendString:[self stringFromDictionary:obj withKey:key]];
        }else if([obj isKindOfClass:[NSString class]]||[obj isKindOfClass:[NSNumber class]]){
            NSString *str = obj;
            if ([key isEqualToString:kTXFText]){
                if ([obj hasPrefix:@"@"]) {
                    [string appendFormat:@"%@\n",str];
                }else{
                    /*This is optional, remove to improve writing speed*/
                    if ([obj isEqualToString:kTXFNull]) {
                        [string appendString:@"&0\n\n"];
                    }else{
                        [string appendFormat:@"&%ld\n%@\n",(unsigned long)str.length,str];
                    }
                }
            }else{
                [string appendFormat:@"$%@=%@\n",key,obj];
            }
        }
    }];
    
    if (aKey) {
        return [NSString stringWithFormat:@"#%@\n%@/%@\n",aKey,string,aKey];
    }else{
        return string;
    }
}

- (NSString *)stringFromArray:(NSArray *)array withKey:(NSString *)aKey{
    NSMutableString *string = [@"" mutableCopy];
    [array enumerateObjectsUsingBlock:^(NSDictionary *dict, NSUInteger idx, BOOL *stop) {
        [string appendString:[self stringFromDictionary:dict withKey:nil]];
    }];
    
    //If key is TXFArray donot write that key but only the body content
    if (![aKey isEqualToString:kArray]) {
        return [NSString stringWithFormat:@"#%@\n%@/%@\n",aKey,string,aKey];
    }else{
        return string;
    }
}

@end

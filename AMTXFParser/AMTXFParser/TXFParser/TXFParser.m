//
//  AMTXFParser.m
//  AMDTXFParser
//
//  Created by Anoop Mohandas on 24/01/15.
//  Copyright (c) 2015 Anoop Mohandas. All rights reserved.
//

#import "TXFParser.h"
#import <OrderedDictionary/OrderedDictionary.h>

static NSString *const kBodyText = @"TXFText";
static NSString *const kArray    = @"TXFArray";
static NSString *const kTXFNull    = @"$#!";

typedef enum {
    TXFParsingTypeObject = 0,
    TXFParsingTypeArray,
    TXFParsingTypeArrayObject,
    TXFParsingTypeChunk
}TXFParsingType;

@interface TXFParser ()

/*Temporary variable to hold values of an object*/
@property (nonatomic, strong) MutableOrderedDictionary *dict;

/*An array to hold the hierarchial data of all nodes encountered while parsing*/
@property (nonatomic, strong) NSMutableArray *stack;

@end

@implementation TXFParser

#pragma mark - Getters

- (NSMutableArray *)stack{
    if (!_stack) {
        _stack = [NSMutableArray new];
    }return _stack;
}

#pragma mark -

/*Parses the txf string by newline seperators and emit events on finding object values*/
//- (id)objectFromString:(NSString *)txfString{
//    NSCharacterSet *newlineCharacterSet = [NSCharacterSet newlineCharacterSet];
//    NSArray *components = [txfString componentsSeparatedByCharactersInSet:newlineCharacterSet];
//    [components enumerateObjectsUsingBlock:^(NSString * string, NSUInteger idx, BOOL *stop) {
//        if ([string hasPrefix:@"#"]) {
//            [self didStartParsingTag:[string substringFromIndex:1]];
//        }else if([string hasPrefix:@"$"]){
//            [self didFindKeyValuePair:[string substringFromIndex:1]];
//        }else if([string hasPrefix:@"/"]){
//            [self didEndParsingTag:[string substringFromIndex:1]];
//        }else{
//            [self didFindBodyValue:string];
//        }
//    }];
//    return self.dict;
//}

- (id)objectFromString:(NSString *)txfString{
    NSScanner *scanner = [[NSScanner alloc] initWithString:txfString];
    NSString *matchedNewlines = nil;
    while (![scanner isAtEnd]) {
        [scanner scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet]
                                intoString:&matchedNewlines];
        if ([matchedNewlines hasPrefix:@"#"]){
            [self didStartParsingTag:[matchedNewlines substringFromIndex:1]];
        }else if([matchedNewlines hasPrefix:@"$"]){
            [self didFindKeyValuePair:[matchedNewlines substringFromIndex:1]];
        }else if([matchedNewlines hasPrefix:@"/"]){
            [self didEndParsingTag:[matchedNewlines substringFromIndex:1]];
        }else{
            [self didFindBodyValue:matchedNewlines];
        }
    }return self.dict;
}

#pragma mark -

- (void)didStartParsingTag:(NSString *)tag{
    [self parserFoundObjectStartForKey:tag];
}

- (void)didFindKeyValuePair:(NSString *)tag{
    NSArray *components = [tag componentsSeparatedByString:@"="];
    NSString *key = [components firstObject];
    NSString *value = [components lastObject];
    
    if (key.length) {
        self.dict[key] = value?:@"";
    }
}

- (void)didFindBodyValue:(NSString *)bodyString{
    if (!bodyString.length) return;
    bodyString = [bodyString stringByTrimmingCharactersInSet:[NSCharacterSet illegalCharacterSet]];
    if (!bodyString.length) return;
    
    //A workaround for removing stray notes what might appear in models Viz. Member Notes
    if ([bodyString isEqualToString:@"&0"]) {
        bodyString = kTXFNull;
    }
    self.dict[kBodyText] = bodyString;
}

- (void)didEndParsingTag:(NSString *)tag{
    [self parserFoundObjectEndForKey:tag];
}

#pragma mark -

- (void)parserFoundObjectStartForKey:(NSString *)key{
    self.dict = [MutableOrderedDictionary new];
    [self.stack addObject:self.dict];
}

- (void)parserFoundObjectEndForKey:(NSString *)key{
    id value = self.dict;
    [self pop];
    /*
     If keystack has contents, then we need to append objects
     */
    /*
    Else this key is going to be the root object
    So Wrap the object with key and assign to the dictionary
    */
    if ([self.stack count]) {
        [self addObject:value forKey:key];
    }else{
        self.dict = [self wrapObject:value withKey:key];
    }
}

#pragma mark -
/*
 Clear the temporary variables and clear stacks
 */
- (void)pop {
    [self.stack removeLastObject];
    self.dict = [self.stack lastObject];
}


#pragma mark - Add Objects after finding end tag

- (void)addArrayObject:(id)value forKey:(NSString *)key{
    id array = self.dict[kArray];
    if (!array) {
        array = [NSMutableArray array];
    }
    
    NSDictionary *dict = [self wrapObject:value withKey:key];
    [array addObject:dict];
    self.dict[kArray] = array;
}

- (void)addObject:(id)value forKey:(NSString *)key{
    /*If there is no value, bailout*/
    if (!value) return;
    
    BOOL isArray = NO;//[self isAnArrayKey:key];
    if (isArray) {
        [self addArrayObject:value forKey:key];
        return;
    }
    
    /*Checks if it is an array or dictionary*/
    
    
    /*
     Check if the dict already has a value for key array.
     */
    id prev =  self.dict[kArray];// self.dict[key];
    
    /*
     If array key is not found look for another object with same key
     */
    if (!prev) {
        prev = self.dict[key];
    }else{
        isArray = YES;
    }
    
    /*
     There is a prev value for the same key. That means we need to wrap that object in a collection.
     1. Remove the object from dictionary,
     2. Wrap it with its key
     3. Add to array
     4. Save the array back to dict
     */
    if (prev && !isArray) {
        [self.dict removeObjectForKey:key];
        NSMutableArray *array = [NSMutableArray new];
        id obj = [self wrapObject:prev withKey:key];
        [array addObject:obj];
        self.dict[kArray] = array;
        prev = array;
        isArray = YES;
    }
    
    /*
     If Array flat is set, means we found an array
     1. Add the object after wrapping it with key
     2. Save the array back to the dict
     */
    if (isArray) {
        NSMutableArray *array = (NSMutableArray *)prev;
        id obj = [self wrapObject:value withKey:key];
        [array addObject:obj];
        self.dict[kArray] = array;
    }else{
        self.dict[key] = value;
    }
}

/*Wraps Object with a key for the serializer to generate txf tag*/
- (MutableOrderedDictionary *)wrapObject:(id)value withKey:(NSString *)key{
//    if (!key ||!value) {
//        return [@{} mutableCopy];
//    }
    return [@{key:value} mutableCopy];
}

@end

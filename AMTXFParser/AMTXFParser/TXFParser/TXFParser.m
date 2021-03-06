//
//  ViewController.m
//  AMTXFParser
//
//  Created by Anoop Mohandas on 01/02/15.
//  Copyright (c) 2015 Anoop Mohandas. All rights reserved.
//


#import "TXFParser.h"

static NSString *const kBodyText = @"TXFText";
static NSString *const kArray    = @"TXFArray";

@interface TXFParser ()

/*Temporary variable to hold values of an object*/
@property (nonatomic, strong) NSMutableDictionary *dict;

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

//- (id)objectFromString:(NSString *)txfString{
//    NSScanner *scanner = [[NSScanner alloc] initWithString:txfString];
//    NSString *matchedNewlines = nil;
//    while (![scanner isAtEnd]) {
//        [scanner scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet]
//                                intoString:&matchedNewlines];
//        if ([matchedNewlines hasPrefix:@"#"]){
//            [self didStartParsingTag:[matchedNewlines substringFromIndex:1]];
//        }else if([matchedNewlines hasPrefix:@"$"]){
//            [self didFindKeyValuePair:[matchedNewlines substringFromIndex:1]];
//        }else if([matchedNewlines hasPrefix:@"/"]){
//            [self didEndParsingTag:[matchedNewlines substringFromIndex:1]];
//        }else{
//            [self didFindBodyValue:matchedNewlines];
//        }
//    }return self.dict;
//}

- (id)objectFromString:(NSString *)txfString{
    [txfString enumerateLinesUsingBlock:^(NSString *string, BOOL *stop) {
        if ([string hasPrefix:@"#"]) {
            [self didStartParsingTag:[string substringFromIndex:1]];
        }else if([string hasPrefix:@"$"]){
            [self didFindKeyValuePair:[string substringFromIndex:1]];
        }else if([string hasPrefix:@"/"]){
            [self didEndParsingTag:[string substringFromIndex:1]];
        }else{
            //[self didFindBodyValue:string];
        }
    }]; return self.dict;
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
    
    self.dict[kBodyText] = bodyString;
}

- (void)didEndParsingTag:(NSString *)tag{
    [self parserFoundObjectEndForKey:tag];
}

#pragma mark -

- (void)parserFoundObjectStartForKey:(NSString *)key{
    self.dict = [NSMutableDictionary new];
    [self.stack addObject:self.dict];
}

- (void)parserFoundObjectEndForKey:(NSString *)key{
    NSDictionary *dict = self.dict;
    
    //Remove the last value of stack
    [self.stack removeLastObject];
    
    //Load the previous object as dict
    self.dict = [self.stack lastObject];
    
    //The stack has contents, then we need to append objects
    if ([self.stack count]) {
        [self addObject:dict forKey:key];
    }else{
        //This is root object,wrap with key and assign output
        self.dict = (NSMutableDictionary *)[self wrapObject:dict withKey:key];
    }
}

#pragma mark - Add Objects after finding end tag

- (void)addObject:(id)dict forKey:(NSString *)key{
    //If there is no value, bailout
    if (!dict) return;
    
    //Check if the dict already has a value for key array.
    NSMutableArray *array =  self.dict[kArray];
    
    //If array key is not found look for another object with same key
    if (array) {
        //Array found add current object after wrapping with key
        NSDictionary *currentDict = [self wrapObject:dict withKey:key];
        [array addObject:currentDict];
    }else{
        id prevObj = self.dict[key];
        if (prevObj) {
            /*
             There is a prev value for the same key. That means we need to wrap that object in a collection.
             1. Remove the object from dictionary,
             2. Wrap it with its key
             3. Add the prev and current value to array
             4. Save the array back to dict
             */
            [self.dict removeObjectForKey:key];
            NSDictionary *prevDict = [self wrapObject:prevObj withKey:key];
            NSDictionary *currentDict = [self wrapObject:dict withKey:key];
            self.dict[kArray] = [@[prevDict,currentDict] mutableCopy];
            
        }else{
            //Simply add object to dict
            self.dict[key] = dict;
        }
    }
}

/*Wraps Object with a key for the serializer to generate txf tag*/
- (NSDictionary *)wrapObject:(id)obj withKey:(NSString *)key{
    if (!key ||!obj) {
        return @{};
    }
    return @{key:obj};
}

@end

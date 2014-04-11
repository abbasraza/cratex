//
//  NSString+Additions.m
//  cratex
//
//  Created by Christian Bader on 10/04/14.
//  Copyright (c) 2014 CRATE Technology GmbH. All rights reserved.
//

#import "NSString+Additions.h"

@implementation NSString (Additions)


- (BOOL)endsWithWhitespaceOrNewlineCharacter {
    NSUInteger stringLength = [self length];
    if (stringLength == 0) {
        return NO;
    }
    unichar lastChar = [self characterAtIndex:stringLength-1];
    return [[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:lastChar];
}

- (BOOL)endsWithSemicolon {
    NSString *trimmedString = [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSUInteger stringLength = [trimmedString length];
    if (stringLength == 0) {
        return NO;
    }
    unichar lastChar = [self characterAtIndex:stringLength-1];
    return [[NSCharacterSet characterSetWithCharactersInString:@";"] characterIsMember:lastChar];
}

- (NSString *)formatForSQLQuery {
    return[[self stringByReplacingOccurrencesOfString:@"\n" withString:@" "]
           stringByReplacingOccurrencesOfString:@";" withString:@""];
}

@end

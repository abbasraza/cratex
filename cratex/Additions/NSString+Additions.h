//
//  NSString+Additions.h
//  cratex
//
//  Created by Christian Bader on 10/04/14.
//  Copyright (c) 2014 CRATE Technology GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Additions)

- (BOOL)endsWithWhitespaceOrNewlineCharacter;
- (BOOL)endsWithSemicolon;
- (NSString *)formatForSQLQuery;

@end

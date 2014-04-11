//
//  History.h
//  cratex
//
//  Created by Christian Bader on 11/04/14.
//  Copyright (c) 2014 CRATE Technology GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Query.h"

@interface History : NSObject

- (Query *)next;
- (Query *)previous;

- (void)addQuery:(Query *)query;

@end

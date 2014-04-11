//
//  Query.h
//  cratex
//
//  Created by Christian Bader on 11/04/14.
//  Copyright (c) 2014 CRATE Technology GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Query : NSObject

@property (nonatomic, copy) NSString *queryString;
@property (nonatomic, copy) NSString *log;
@property (nonatomic, assign) BOOL successful;

@end

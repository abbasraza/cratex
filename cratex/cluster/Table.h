//
//  Table.h
//  cratex
//
//  Created by Philipp Bogensberger on 10.04.14.
//  Copyright (c) 2014 CRATE Technology GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Table : NSObject

+(id)tableWithShards:(NSArray*)shards;
-(int)totalRecords;
-(NSInteger)underreplicatedRecords;
-(NSInteger)unavailableRecords;

@property(nonatomic, copy)NSArray* shards;
@property(assign)NSInteger shards_configured;

@end

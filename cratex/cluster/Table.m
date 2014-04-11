//  Copyright (c) 2014 CRATE Technology GmbH. All rights reserved.
//

#import "Table.h"

@interface Table()

-(NSArray*)primaryShards;
-(NSInteger)missingShards;
-(NSArray*)activePrimaryShards;
-(NSArray*)startedShards;
-(NSInteger)numActivePrimaryShards;
-(NSInteger)underreplicatedShards;

@end

@implementation Table

+(id)tableWithShards:(NSArray*)shards {
    Table* table = [[Table alloc] init];
    [table setShards:shards];
    return table;
}

-(id)init {
    self = [super init];
    if(self){
        self.shards_configured = 0;
    }
    return self;
}

-(int)totalRecords {
    int __block records = 0;
    [[self primaryShards] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if([obj objectForKey:@"sum_docs"]){
            records += [[obj objectForKey:@"sum_docs"] integerValue];
        }
    }];
    return records;
}

-(NSArray*)primaryShards {
    NSMutableArray* primary = [[NSMutableArray alloc] init];
    [self.shards enumerateObjectsUsingBlock:^(id shard, NSUInteger idx, BOOL *stop) {
        if([[shard objectForKey:@"primary"] isEqualToString:@"primary"]){
            [primary addObject:shard];
        }
    }];
    return primary;
}

-(NSArray*)unassignedShards {
    NSMutableArray* unassigned;
    [self.shards enumerateObjectsUsingBlock:^(id shard, NSUInteger idx, BOOL *stop) {
        if([[[shard objectForKey:@"state"] lowercaseString] isEqualToString:@"unassigend"]){
            [unassigned addObject:shard];
        }
    }];
    return unassigned;
}

-(NSArray*)startedShards {
    NSMutableArray* started;
    [self.shards enumerateObjectsUsingBlock:^(id shard, NSUInteger idx, BOOL *stop) {
        if([[[shard objectForKey:@"state"] lowercaseString] isEqualToString:@"started"]){
            [started addObject:shard];
        }
    }];
    return started;
}

-(NSInteger)missingShards {
    return MAX(0, self.shards_configured - self.numActivePrimaryShards);
}

-(NSArray*)activePrimaryShards {
    NSMutableArray* activePrimary = [[NSMutableArray alloc] init];
    [[self primaryShards] enumerateObjectsUsingBlock:^(id shard, NSUInteger idx, BOOL *stop) {
        if([@[@"started", @"relocating"] containsObject:[[shard objectForKey:@"state"] lowercaseString]]){
            [activePrimary addObject:shard];
        }
    }];
    return activePrimary;
}

-(NSInteger)numActivePrimaryShards {
    NSInteger __block num = 0;
    [[self activePrimaryShards] enumerateObjectsUsingBlock:^(id shard, NSUInteger idx, BOOL *stop) {
        if([shard objectForKey:@"count"]){
            num += [[shard objectForKey:@"count"] integerValue];
        }
    }];
    return num;
}

-(NSInteger)underreplicatedRecords {
    if([[self primaryShards] count] >0){
        if([[[self primaryShards] objectAtIndex:0] objectForKey:@"avg_docs"]){
            return [[[[self primaryShards] objectAtIndex:0] objectForKey:@"avg_docs"] integerValue] * [self underreplicatedShards];
        }
    }
    return 0;
}

-(NSInteger)underreplicatedShards {
    return [[self unassignedShards] count] * [self missingShards];
}

-(NSInteger)unavailableRecords {
    if([[self startedShards] count] > 0){
        if([[[self primaryShards] objectAtIndex:0] objectForKey:@"avg_docs"]){
            return [[[[self startedShards] objectAtIndex:0] objectForKey:@"avg_docs"] integerValue] * [self missingShards];
        }
    }
    return 0;
    
}


@end

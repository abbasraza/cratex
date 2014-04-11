//
//  History.m
//  cratex
//
//  Created by Christian Bader on 11/04/14.
//  Copyright (c) 2014 CRATE Technology GmbH. All rights reserved.
//

#import "History.h"

@interface History ()

@property (nonatomic, strong) NSMutableArray *history;
@property (nonatomic, assign) long index;
@property (nonatomic, assign) long lastIndex;

@end

@implementation History

- (id)init {
    if (self = [super init]) {
        self.history = [NSMutableArray array];
        _index = 0;
        _lastIndex = 0;
    }
    return self;
}

- (void)addQuery:(Query *)query {
    [_history addObject:query];
    _index = [_history count]-1;
}

- (Query *)next {
    if ([_history count] > _index) {
        Query *q = [_history objectAtIndex:_index];
        _index++;
        return q;
    }
    return nil;
}

- (Query *)previous {
    if ([_history count] > _index-1) {
        Query *q = [_history objectAtIndex:_index-1];
        _index--;
        return q;
    }
    return nil;
}

@end

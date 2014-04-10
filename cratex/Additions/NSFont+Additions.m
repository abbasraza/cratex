//
//  NSFont+Additions.m
//  cratex
//
//  Created by Christian Bader on 10/04/14.
//  Copyright (c) 2014 CRATE Technology GmbH. All rights reserved.
//

#import "NSFont+Additions.h"

@implementation NSFont (Additions)

+ (NSFont *)defaultTableViewFontWithSize:(CGFloat)size {
    return [NSFont systemFontOfSize:size];
}

@end

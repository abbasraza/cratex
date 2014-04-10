//
//  Cluster.h
//  cratex
//
//  Created by Philipp Bogensberger on 09.04.14.
//  Copyright (c) 2014 CRATE Technology GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Cluster : NSObject <NSCoding>

@property(copy)NSString* title;
@property(copy)NSString* url;
@property(readonly)BOOL isLeaf;

+(Cluster*)clusterWithTitle:(NSString*)title andURL:(NSString*)url;

typedef void (^CompletionBlock)(BOOL success, NSDictionary *response, NSError *error);

- (void)sql:(NSString *)query withCallback:(CompletionBlock)callback;

@end

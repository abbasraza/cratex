//
//  QueryViewController.m
//  cratex
//
//  Created by Christian Bader on 09/04/14.
//  Copyright (c) 2014 CRATE Technology GmbH. All rights reserved.
//

#import "QueryViewController.h"

@interface QueryViewController ()

@end

@implementation QueryViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (IBAction)executeQuery:(id)sender {
    [self sql:_queryTextView.string];
}

- (void)sql:(NSString *)query {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:@"http://localhost:4200/_sql"]];
    [request setHTTPMethod:@"POST"];
    [request addValue:[NSString stringWithFormat:@"application/json"] forHTTPHeaderField: @"Content-Type"];
    
    NSMutableData *postBody = [NSMutableData data];
    [postBody appendData:[[NSString stringWithFormat:@"{\"stmt\":\"%@\"}", query] dataUsingEncoding:NSUTF8StringEncoding]];
    [request setHTTPBody:postBody];
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:queue completionHandler:^(NSURLResponse *response,
                                                                       NSData *data,
                                                                       NSError *connectionError) {
                                           NSError *error = nil;
                                           NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
                                           [dict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                                               if ([key isEqualToString:@"cols"]) {
                                                   NSLog(@"%@", obj);
                                               }
                                               else if ([key isEqualToString:@"rows"]) {
                                                   NSLog(@"%@", obj);
                                               }
                                               else if ([key isEqualToString:@"rowcount"]) {
                                                   NSLog(@"%@", obj);
                                               }
                                               else if ([key isEqualToString:@"duration"]) {
                                                   NSLog(@"%@", obj);
                                               }
                                           }];
                                       }];
}

@end

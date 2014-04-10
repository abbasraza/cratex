//
//  QueryViewController.m
//  cratex
//
//  Created by Christian Bader on 09/04/14.
//  Copyright (c) 2014 CRATE Technology GmbH. All rights reserved.
//

#define kMinCellHeight 40
#define kQueryResultFontSize 12

#import "QueryViewController.h"
#import "NSFont+Additions.h"

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

- (void)awakeFromNib {
    _resultTableView.delegate = self;
    _resultTableView.dataSource = self;
}

- (IBAction)executeQuery:(id)sender {
    [self sql:_queryTextView.string];
}

- (void)sql:(NSString *)query {
    if ([query length] == 0) {
        return;
    }
    
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
                                           if (!data) {
                                               return;
                                           };
                                           
                                           NSError *error = nil;
                                           self.results = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
                                           
                                           [_results enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                                               if ([key isEqualToString:@"cols"]) {
                                                   [self updateTableColumns:obj];
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
                                               else if ([key isEqualToString:@"error"]) {
                                               }
                                           }];
                                       }];
}

- (void)updateTableColumns:(NSArray *)cols {
    dispatch_async(dispatch_get_main_queue(), ^{
        // Remove all columns from the table view
        [[_resultTableView tableColumns] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [_resultTableView removeTableColumn:obj];
        }];
       
        // Add columns depending on the fetch result
        [cols enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:@"obj"];
            [column setWidth:[self maxWidthForIndex:idx forColumn:column]];
            [[column headerCell] setStringValue:obj];
            [column setIdentifier:[NSString stringWithFormat:@"%lu", (unsigned long)idx]];
            [_resultTableView addTableColumn:column];
        }];
        [_resultTableView reloadData];
    });
}

- (CGFloat)maxWidthForIndex:(NSUInteger)index forColumn:(NSTableColumn *)column {
    // Calculate the width for the column at the given index
    CGFloat __block width = column.width;
    [[_results objectForKey:@"rows"] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *text = [obj[index] description];
        NSDictionary *attributes = @{NSFontAttributeName:[NSFont defaultTableViewFontWithSize:kQueryResultFontSize]};
        CGSize size = [text sizeWithAttributes:attributes];
        if (size.width > width) {
            width = size.width + 10.0;
        }
    }];
    return width;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [[_results objectForKey:@"rows"] count];
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    // Calculate the height for the given row
    CGFloat __block height = kMinCellHeight;
    [[[_results objectForKey:@"rows"] objectAtIndex:row] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSDictionary *attributes = @{NSFontAttributeName:[NSFont defaultTableViewFontWithSize:kQueryResultFontSize]};
        CGSize size = [[obj description] sizeWithAttributes:attributes];
        if (size.height > height) {
            height = size.height + 10.0;
        }
    }];
    return height;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSTextField *result = [tableView makeViewWithIdentifier:@"ResultView" owner:self];
    if (result == nil) {
        result = [[NSTextField alloc] initWithFrame:CGRectMake(0.0, 0.0, tableColumn.width, 0.0)];
        result.identifier = @"ResultView";
        [result setFont:[NSFont defaultTableViewFontWithSize:kQueryResultFontSize]];
    }
    result.stringValue = [[[[_results objectForKey:@"rows"]
                            objectAtIndex:row]
                           objectAtIndex:[[tableColumn identifier] intValue]]
                          description];
    return result;
}

@end

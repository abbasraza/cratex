//
//  QueryViewController.m
//  cratex
//
//  Created by Christian Bader on 09/04/14.
//  Copyright (c) 2014 CRATE Technology GmbH. All rights reserved.
//

#define kMinCellHeight 40
#define kQueryResultFontSize 16

#import "QueryViewController.h"
#import "NSFont+Additions.h"
#import "NSString+Additions.h"

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
    _queryTextView.delegate = self;
    _resultTableView.dataSource = self;
    _logTextField.font = [NSFont defaultLightFontWithSize:14];
    [_queryTextView setFont:[NSFont defaultLightFontWithSize:20]];
}

- (BOOL)textView:(NSTextView *)aTextView doCommandBySelector:(SEL)aSelector {
    BOOL result = NO;
    
    if (aSelector == @selector(insertNewline:))
    {
        //[aTextView insertNewlineIgnoringFieldEditor:self];
        if ([_queryTextView.string endsWithSemicolon]) {
            [self executeQuery:nil];
            return YES;
        }
    }
    return result;
}


- (IBAction)executeQuery:(id)sender {
    
    [self resetUI];
    
    NSString *queryString = [_queryTextView.string formatForSQLQuery];
    [_document.selectedCluster sql:queryString withCallback:^(BOOL success, NSDictionary *response, NSError *error) {
        if (success) {
           [response enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
               if ([key isEqualToString:@"cols"]) {
                   self.results = response;
                   [self updateTableColumns:obj];
               }
           }];
        } else if (error) {
            [self showErrorInLog:error.description];
        } else {
            [self showErrorInLog:[response objectForKey:@"error"]];
        }
    }];
}

- (void)showErrorInLog:(NSString *)text {
    dispatch_async(dispatch_get_main_queue(), ^{
        _logTextField.stringValue = text;
    });
}

- (void)resetUI {
    dispatch_async(dispatch_get_main_queue(), ^{
        // Remove all columns from the table view
        [[[_resultTableView tableColumns] copy] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [_resultTableView removeTableColumn:obj];
        }];
        [_resultTableView reloadData];
        
        _logTextField.stringValue = @"";
    });
}

- (void)updateTableColumns:(NSArray *)cols {
    dispatch_async(dispatch_get_main_queue(), ^{
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

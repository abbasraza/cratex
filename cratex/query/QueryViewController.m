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
#import "Query.h"

@interface QueryViewController ()

@end

@implementation QueryViewController

- (void)awakeFromNib {
    self.history = [[History alloc] init];
    
    _resultTableView.delegate = self;
    _queryTextView.delegate = self;
    _resultTableView.dataSource = self;
    
    _logTextField.font = [NSFont defaultLightFontWithSize:14];
    _statusLabel.font = [NSFont defaultBoldFontWithSize:14];
    _rowcountLabel.font = [NSFont defaultLightFontWithSize:14];
    _rowcountPrefixLabel.font = [NSFont defaultLightFontWithSize:14];
    _durationLabel.font = [NSFont defaultLightFontWithSize:14];
    _durationPrefixLabel.font = [NSFont defaultLightFontWithSize:14];
    _queryTextView.font = [NSFont defaultLightFontWithSize:20];
    
    [self resetUI];
}

- (BOOL)textView:(NSTextView *)aTextView doCommandBySelector:(SEL)aSelector {
    BOOL result = NO;
    
   if (aSelector == @selector(insertNewline:)) {
        //[aTextView insertNewlineIgnoringFieldEditor:self];
        if ([_queryTextView.string endsWithSemicolon]) {
            [self executeQuery:nil];
            return YES;
        }
    } else if (aSelector == @selector(moveUp:)) {
        [self showQuery:[_history previous]];
    } else if (aSelector == @selector(moveDown:)) {
        [self showQuery:[_history next]];
    }
    return result;
}

- (void)showQuery:(Query *)query {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (query) {
            if (!query.successful) {
                _queryTextView.textColor = [NSColor redColor];
            } else {
                _queryTextView.textColor = [NSColor blackColor];
            }
            _queryTextView.string = [query queryString];
        }
    });
}

- (IBAction)executeQuery:(id)sender {
    
    [self resetUI];
    
    Query *query = [[Query alloc] init];
    query.queryString = _queryTextView.string;
    query.successful = NO;
    
    [_history addQuery:query];
    [_document.selectedCluster sql:[query.queryString formatForSQLQuery] withCallback:^(BOOL success, NSDictionary *response, NSError *error) {
        if (success) {
           [response enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
               if ([key isEqualToString:@"cols"]) {
                   self.results = response;
                   query.successful = YES;
                   [self updateTableColumns:obj];
               }
           }];
        } else if (error) {
            query.log = error.description;
            [self showErrorInLog:error.description];
        } else {
            query.log = [response objectForKey:@"error"];
            [self showErrorInLog:[response objectForKey:@"error"]];
        }
        [self showQuery:query];
    }];
}

- (void)showErrorInLog:(NSString *)text {
    dispatch_async(dispatch_get_main_queue(), ^{
        _logTextField.stringValue = text;
        [self updateStatusLabel:NO];
    });
}

- (void)resetUI {
    dispatch_async(dispatch_get_main_queue(), ^{
        // Remove all columns from the table view
        [[[_resultTableView tableColumns] copy] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [_resultTableView removeTableColumn:obj];
        }];
        self.results = @{};
        [_resultTableView reloadData];
        
        _logTextField.stringValue = @"";
        _statusLabel.stringValue = @"";
        _statusLabel.stringValue = @"";
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
        [self updateStatusLabel:YES];
        [_resultTableView reloadData];
    });
}

- (void)updateStatusLabel:(BOOL)success {
    if (success) {
        _statusLabel.stringValue = @"OK";
        _statusLabel.textColor = [NSColor greenColor];
    } else {
        _statusLabel.stringValue = @"Failure";
        _statusLabel.textColor = [NSColor redColor];
    }
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

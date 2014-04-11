//
//  QueryViewController.h
//  cratex
//
//  Created by Christian Bader on 09/04/14.
//  Copyright (c) 2014 CRATE Technology GmbH. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Document.h"
#import "History.h"

@interface QueryViewController : NSViewController <NSTableViewDataSource, NSTableViewDelegate, NSTextViewDelegate>

@property IBOutlet NSTextView *queryTextView;
@property IBOutlet NSTableView *resultTableView;
@property IBOutlet NSButton *queryButton;
@property IBOutlet NSTextField *logTextField;
@property IBOutlet Document *document;
@property IBOutlet NSTextField *statusLabel;
@property IBOutlet NSTextField *rowcountLabel;
@property IBOutlet NSTextField *durationLabel;

@property (strong, nonatomic) NSDictionary *results;
@property (strong, nonatomic) History *history;

- (IBAction)executeQuery:(id)sender;

@end

//
//  QueryViewController.h
//  cratex
//
//  Created by Christian Bader on 09/04/14.
//  Copyright (c) 2014 CRATE Technology GmbH. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface QueryViewController : NSViewController

@property (assign) IBOutlet NSTextView *queryTextView;

- (IBAction)executeQuery:(id)sender;

@end

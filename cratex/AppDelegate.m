//
//  AppDelegate.m
//  cratex
//
//  Created by Christian Bader on 09/04/14.
//  Copyright (c) 2014 CRATE Technology GmbH. All rights reserved.
//

#import "AppDelegate.h"
#import "Cluster.h"

@interface AppDelegate()

@property (weak) IBOutlet NSOutlineView *clusterOutlineView;
@property (weak) IBOutlet NSTreeController *clusterController;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    self.clusterOutlineView.delegate = self;
    self.clusterOutlineView.dataSource = self;
    self.clusterOutlineView.floatsGroupRows = NO; // Prevent a sticky header

    [self addData];
    
    // Expand the first group and select the first item in the list
    [self.clusterOutlineView expandItem:[self.clusterOutlineView itemAtRow:0]];
    [self.clusterOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:1] byExtendingSelection:NO];
}

-(void)awakeFromNib {
    _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [_statusItem setMenu:_statusMenu];
    [_statusItem setImage:[NSImage imageNamed:@"tray_icon"]];
    [_statusItem setHighlightMode:YES];
}

- (IBAction)showDetail:(id)sender {
    [_window makeKeyAndOrderFront:nil];
}


- (BOOL) isHeader:(id)item{
    
    if([item isKindOfClass:[NSTreeNode class]]){
        return ![((NSTreeNode *)item).representedObject isKindOfClass:[Cluster class]];
    } else {
        return ![item isKindOfClass:[Cluster class]];
    }
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    
    if ([self isHeader:item]) {
        return [outlineView makeViewWithIdentifier:@"HeaderCell" owner:self];
    } else {
        return [outlineView makeViewWithIdentifier:@"DataCell" owner:self];
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item{
    return ![self isHeader:item];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item{
    // This converts a group to a header which influences its style
    return [self isHeader:item];
}



- (void) addData{
    
    // `children` and `isLeaf` have to be configured for the Tree Controller in IB
    NSMutableDictionary *root = @{@"title": @"CLUSTER",
                                  @"isLeaf": @(NO),
                                  @"children":@[
                                          [Cluster clusterWithTitle:@"Localhost" andURL:@"http://localhost:4200/"],
                                          [Cluster clusterWithTitle:@"Crate Demo Cluster" andURL:@"http://demo.crate.io:4200/"]
                                          ].mutableCopy
                                  }.mutableCopy;
    
    [self.clusterController addObject:root];
}


@end

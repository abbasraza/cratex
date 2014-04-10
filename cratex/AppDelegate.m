//
//  AppDelegate.m
//  cratex
//
//  Created by Christian Bader on 09/04/14.
//  Copyright (c) 2014 CRATE Technology GmbH. All rights reserved.
//

#import "AppDelegate.h"
#import "Cluster.h"
#import "ClusterSettingsViewController.h"

@interface AppDelegate()

-(void)clustersUpdated:(NSNotification*)notification;

@end

@implementation AppDelegate

- (id)init {
    self = [super init];
    if(self){
        self.clusters = @{@"title": @"CLUSTER",
                          @"isLeaf": @(NO),
                          @"children":@[
                                  [Cluster clusterWithTitle:@"Localhost" andURL:@"http://localhost:4200/"],
                                  [Cluster clusterWithTitle:@"Crate Demo Cluster" andURL:@"http://demo.crate.io:4200/"]
                                  ].mutableCopy
                          }.mutableCopy;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(clustersUpdated:)
                                                     name:@"clustersUpdated"
                                                   object:nil];
        

    }
    return self;
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Add status bar item
    _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [_statusItem setMenu:_statusMenu];
    [_statusItem setImage:[NSImage imageNamed:@"tray_icon"]];
    [_statusItem setHighlightMode:YES];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag {
    [self showDetail:nil];
    return YES;
}

# pragma mark - Action handling

- (IBAction)showDetail:(id)sender {
    [_window setIsVisible:YES];
    [NSApp activateIgnoringOtherApps:YES];
}


- (IBAction)showWebsite:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kCrateUrl]];
}

- (void)clustersUpdated:(NSNotification *)notification {
    
}


@end

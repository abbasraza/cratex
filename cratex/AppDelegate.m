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
-(NSString*)pathForArchive:(NSString *)archiveName;
-(NSURL *)applicationDocumentsDirectory;

@end

@implementation AppDelegate

- (id)init {
    self = [super init];
    if(self){
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(clustersUpdated:)
                                                     name:@"clustersUpdated"
                                                   object:nil];
        id archivedClusters = [NSKeyedUnarchiver unarchiveObjectWithFile:[self pathForArchive:@"clusters"]];
        if(archivedClusters){
            self.clusters = archivedClusters;
        }else {
            self.clusters = @{@"title": @"CLUSTER",
                              @"isLeaf": @(NO),
                              @"children":@[
                                      [Cluster clusterWithTitle:@"Localhost" andURL:@"http://localhost:4200/"]
                                      ].mutableCopy
                              }.mutableCopy;
        }
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
    [NSKeyedArchiver archiveRootObject:self.clusters toFile:[self pathForArchive:@"clusters"]];
}

#pragma mark - Application's Documents directory

- (NSString*)pathForArchive:(NSString *)archiveName {
    NSString* pathComponent = [NSString stringWithFormat:@"%@.archive", archiveName];
    return [[self applicationDocumentsDirectory].path stringByAppendingPathComponent:pathComponent];
}

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                   inDomains:NSUserDomainMask] lastObject];
}


@end

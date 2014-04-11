//
//  ClusterSettingsViewController.m
//  cratex
//
//  Created by Philipp Bogensberger on 09.04.14.
//  Copyright (c) 2014 CRATE Technology GmbH. All rights reserved.
//

#import "ClusterSettingsViewController.h"

@interface ClusterSettingsViewController ()

@property(nonatomic)IBOutlet NSTextField* nameField;
-(void)sendUpdateNotification;

@end

@implementation ClusterSettingsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    return self;
}


-(void)controlTextDidEndEditing:(NSNotification *)obj {
    [self sendUpdateNotification];
}

-(IBAction)updatedSettings:(id)sender {
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"statusUpdated"
     object:nil
     userInfo:nil];
    [self sendUpdateNotification];
}

-(void)sendUpdateNotification {
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"clustersUpdated"
     object:nil
     userInfo:nil];
}

@end

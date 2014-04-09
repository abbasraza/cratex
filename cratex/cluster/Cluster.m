//  Copyright (c) 2014 CRATE Technology GmbH. All rights reserved.
//

#import "Cluster.h"

@implementation Cluster

+(Cluster *)clusterWithTitle:(NSString *)title andURL:(NSString *)url {
    Cluster* cluster = [[Cluster alloc] init];
    if(cluster){
        cluster.title = title;
        cluster.url = url;
    }
    return cluster;
}

-(BOOL)isLeaf {
    return YES;
}

@end

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

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.title = [aDecoder decodeObjectForKey:@"title"];
        self.url = [aDecoder decodeObjectForKey:@"url"];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.title forKey:@"title"];
    [aCoder encodeObject:self.url forKey:@"url"];
}

-(BOOL)isLeaf {
    return YES;
}

@end

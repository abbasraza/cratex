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

- (void)sql:(NSString *)query withCallback:(CompletionBlock)callback {
    if ([query length] == 0) {
        return;
    }
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/_sql", _url]]];
    [request setHTTPMethod:@"POST"];
    [request addValue:[NSString stringWithFormat:@"application/json"] forHTTPHeaderField: @"Content-Type"];
    
    NSMutableData *postBody = [NSMutableData data];
    [postBody appendData:[[NSString stringWithFormat:@"{\"stmt\":\"%@\"}", query] dataUsingEncoding:NSUTF8StringEncoding]];
    [request setHTTPBody:postBody];
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:queue completionHandler:^(NSURLResponse *response,
                                                                       NSData *data,
                                                                       NSError *connectionError) {
                                           if (!data) {
                                               return;
                                           };
                                           
                                           NSError *error = nil;
                                           NSDictionary *results = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
                                           callback(YES, results, error);
                                       }];
    
}

@end

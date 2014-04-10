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
    [cluster fetchOverView];
    return cluster;
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.title = [aDecoder decodeObjectForKey:@"title"];
        self.url = [aDecoder decodeObjectForKey:@"url"];
        [self fetchOverView];
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

- (void)fetchOverView {
    [self fetchHealth];
}

- (NSArray*)convertSQLResult:(NSDictionary *)result fields:(NSArray *)fields {
    NSArray* rows = [result objectForKey:@"rows"];
    NSMutableArray* converted = [[NSMutableArray alloc] init];
    [rows enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSDictionary* row = [NSDictionary dictionaryWithObjects:obj forKeys:fields];
        [converted addObject:row];
    }];
    return converted;
}

- (void)fetchHealth {
    NSString* tableQuery = @"select table_name, sum(number_of_shards), number_of_replicas \
                                from information_schema.tables \
                                where schema_name in ('doc', 'blob') \
                                group by table_name, number_of_replicas";
    [self sql:tableQuery withCallback:^(BOOL success, NSDictionary *response, NSError *error) {
        
        self.tables = [self convertSQLResult:response fields:@[@"table_name", @"number_of_shards", @"number_of_replicas"]];
        NSString* shardQuery = @"select table_name, count(*), 'primary', state, sum(num_docs), \
                                    avg(num_docs), sum(size) \
                                    from sys.shards group by table_name, 'primary', state";
        
        [self sql:shardQuery withCallback:^(BOOL success, NSDictionary *response, NSError *error) {
            NSArray* shardInfo = [self convertSQLResult:response fields:@[@"name", @"count", @"primary", @"state", @"sum_docs", @"avg_docs", @"size"]];
            NSLog(@"shard info %@", shardInfo);
            self.shardInfo = shardInfo;
            
            // Calculate Active Primary
            int __block active = 0;
            int __block unassigend = 0;
            int __block configured = 0;
            [self.shardInfo enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                NSString* state = [[obj objectForKey:@"state"] lowercaseString];
                BOOL isPrimary = [[obj objectForKey:@"primary"] isEqualToString:@"primary"];
                
                if([@[@"started", @"relocating"] containsObject:state] && isPrimary){
                    active+=1;
                } else if([state isEqualToString:@"unassigned"]){
                    unassigend += 1;
                }
                configured += [[obj objectForKey:@"number_of_shards"] integerValue];
                
            }];
            self.activePrimary = [NSNumber numberWithInt:active];
            self.unassigned = [NSNumber numberWithInt:unassigend];
            self.configured = [NSNumber numberWithInt:configured];
            if(active < configured){
                self.state = @"red";
            } else if (unassigend > 0){
                self.state = @"warning";
            } else {
                self.state = @"good";
            }
            NSLog(@"active primary %@", self.activePrimary);
        }];
    }];
}

@end

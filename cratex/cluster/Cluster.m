//  Copyright (c) 2014 CRATE Technology GmbH. All rights reserved.
//

#import "Cluster.h"
#import "Table.h"

@interface Cluster ()

- (void)setDefaults;
@property(nonatomic)NSTimer* fetchHealthTimer;

@end

@implementation Cluster

+(Cluster *)clusterWithTitle:(NSString *)title andURL:(NSString *)url {
    Cluster* cluster = [[Cluster alloc] init];
    if(cluster){
        cluster.title = title;
        cluster.url = url;
    }
    [cluster fetchOverView];
    [cluster setDefaults];
    return cluster;
}

-(void)setDefaults {
    self.state = @"-";
    self.available_data = @"100%";
    self.records_unavailable = @"0";
    self.replicated_data = @"100%";
    self.records_total = @"0";
    self.records_underreplicated = @"0";
    self.statusImage = [NSImage imageNamed:@"tray_icon"];

}

-(id)init {
    self = [super init];
    if(self){
        [self setDefaults];
        [self fetchOverView];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.title = [aDecoder decodeObjectForKey:@"title"];
        self.url = [aDecoder decodeObjectForKey:@"url"];
        [self setDefaults];
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
                                               if (connectionError) {
                                                   callback(NO, nil, connectionError);
                                               }
                                               return;
                                           };
                                           
                                           NSError *error = nil;
                                           NSDictionary *results = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
                                           
                                           BOOL success = YES;
                                           if ([results objectForKey:@"error"]) {
                                               success = NO;
                                           }
                                           callback(success, results, error);
                                       }];
}

- (void)fetchOverView {
    self.fetchHealthTimer = [NSTimer scheduledTimerWithTimeInterval:5.0
                                                             target:self
                                                           selector:@selector(fetchHealth)
                                                           userInfo:nil
                                                            repeats:YES];
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
            if(error){
                [self setDefaults];
                return;
            }
            NSArray* shardInfo = [self convertSQLResult:response fields:@[@"name", @"count", @"primary", @"state", @"sum_docs", @"avg_docs", @"size"]];
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
                self.state = @"Red";
                self.statusImage = [NSImage imageNamed:@"tray_icon_r"];
            } else if (unassigend > 0){
                self.state = @"Warning";
                self.statusImage = [NSImage imageNamed:@"tray_icon_y"];
            } else {
                self.state = @"Good";
                self.statusImage = [NSImage imageNamed:@"tray_icon_g"];
            }
            
            NSMutableArray* tableInfos = [[NSMutableArray alloc] init];
            [self.tables enumerateObjectsUsingBlock:^(id table, NSUInteger idx, BOOL *stop) {
                NSMutableArray* tableShards = [[NSMutableArray alloc] init];
                [self.shardInfo enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    NSString* tableName = [table objectForKey:@"table_name"];
                    NSString* shardName = [obj objectForKey:@"name"];
                    if([tableName isEqualToString:shardName]){
                        [tableShards addObject:obj];
                    }
                }];
                Table* tableInfo = [Table tableWithShards:tableShards];
                [tableInfo setShards_configured:[[table objectForKey:@"number_of_shards"] integerValue]];
                [tableInfos addObject:tableInfo];
                
            }];
            
            int __block records_unavailable = 0;
            float __block records_total = 0;
            int __block records_underreplicated = 0;
            [tableInfos enumerateObjectsUsingBlock:^(Table *table, NSUInteger idx, BOOL *stop) {
                records_total += [table totalRecords];
                records_underreplicated += [table underreplicatedRecords];
                records_underreplicated += [table unavailableRecords];
            }];

            self.records_total = [NSString stringWithFormat:@"%.f", records_total];
            self.records_underreplicated = [NSString stringWithFormat:@"%i", records_underreplicated];
            self.records_unavailable = [NSString stringWithFormat:@"%i", records_unavailable];
            
            float available_data = 100;
            float replicated_data = 100;
            if(records_total > 0){
                available_data = 100.0 * (records_total - records_unavailable ) / records_total;
                replicated_data = 100.0 * (records_total - records_underreplicated) / records_total;
            }
            
            self.replicated_data = [NSString stringWithFormat:@"%.f%%", replicated_data];
            self.available_data = [NSString stringWithFormat:@"%.f%%", available_data];
            
        }];
    }];
}

@end

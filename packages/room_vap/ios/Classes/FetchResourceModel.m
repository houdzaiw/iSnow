#import <Foundation/Foundation.h>

@interface FetchResourceModel : NSObject

@property (nonatomic, strong, readonly) NSString *tag;
@property (nonatomic, strong, readonly) NSString *resource;

- (instancetype)initWithTag:(NSString *)tag resource:(NSString *)resource;
- (NSDictionary<NSString *, NSString *> *)toMap;
+ (instancetype)fromRawJson:(NSString *)jsonString;

@end

@implementation FetchResourceModel

- (instancetype)initWithTag:(NSString *)tag resource:(NSString *)resource {
    self = [super init];
    if (self) {
        _tag = tag;
        _resource = resource;
    }
    return self;
}

- (NSDictionary<NSString *, NSString *> *)toMap {
    return @{
        @"tag": self.tag,
        @"resource": self.resource
    };
}

+ (instancetype)fromRawJson:(NSString *)jsonString {
    NSError *error;
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    
    if (error) {
        NSLog(@"Error parsing JSON: %@", error.localizedDescription);
        return nil;
    }
    
    NSString *tag = jsonDict[@"tag"];
    NSString *resource = jsonDict[@"resource"];
    
    return [[self alloc] initWithTag:tag resource:resource];
}


+ (NSArray<FetchResourceModel *> *)fromRawJsonArray:(NSString *)jsonArrayString {
    NSError *error;
    NSData *jsonData = [jsonArrayString dataUsingEncoding:NSUTF8StringEncoding];
    NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    
    if (error) {
        NSLog(@"Error parsing JSON array: %@", error.localizedDescription);
        return nil;
    }
    
    NSMutableArray<FetchResourceModel *> *models = [NSMutableArray array];
    for (NSDictionary *jsonDict in jsonArray) {
        NSString *tag = jsonDict[@"tag"];
        NSString *resource = jsonDict[@"resource"];
        FetchResourceModel *model = [[self alloc] initWithTag:tag resource:resource];
        [models addObject:model];
    }
    
    return [models copy];
}


@end

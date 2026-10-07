#import <Foundation/Foundation.h>

@interface FetchResourceModel : NSObject

@property (nonatomic, strong, readonly) NSString *tag;
@property (nonatomic, strong, readonly) NSString *resource;

- (instancetype)initWithTag:(NSString *)tag resource:(NSString *)resource;
- (NSDictionary<NSString *, NSString *> *)toMap;

+ (instancetype)fromRawJson:(NSString *)jsonString;

+ (NSArray<FetchResourceModel *> *)fromRawJsonArray:(NSString *)jsonArrayString;
@end

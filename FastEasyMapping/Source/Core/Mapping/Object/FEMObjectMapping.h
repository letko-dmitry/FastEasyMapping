// For License please refer to LICENSE file in the root of FastEasyMapping project

#import <Foundation/Foundation.h>
#import "FEMMapping.h"

@compatibility_alias FEMObjectMapping FEMMapping;

@interface FEMMapping (FEMObjectMapping_Deprecated)

+ (instancetype)mappingForClass:(Class)objectClass
                  configuration:(void (^)(FEMObjectMapping *mapping))configuration;

+ (instancetype)mappingForClass:(Class)objectClass
                       rootPath:(NSString *)rootPath
                  configuration:(void (^)(FEMObjectMapping *mapping))configuration;

@end

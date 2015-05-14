//
// Created by zen on 14/05/15.
// Copyright (c) 2015 Yalantis. All rights reserved.
//

#import "FEMMappingUtility.h"
#import "FEMMapping.h"

void FEMMappingApply(FEMMapping *mapping, void (^apply)(FEMMapping *object)) {
    apply(mapping);

    for (FEMRelationship *relationship in mapping.relationships) {
        FEMMappingApply(relationship.objectMapping, apply);
    }
}

NSSet * FEMMappingCollectUsedEntityNames(FEMMapping *mapping) {
    NSMutableSet *output = [[NSMutableSet alloc] init];
    FEMMappingApply(mapping, ^(FEMMapping *object) {
        NSCParameterAssert(mapping.entityName != nil);

        [output addObject:mapping.entityName];
    });

    return output;
}
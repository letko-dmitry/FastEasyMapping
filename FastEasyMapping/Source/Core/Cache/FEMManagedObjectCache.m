// For License please refer to LICENSE file in the root of FastEasyMapping project

#import "FEMManagedObjectCache.h"

#import <CoreData/CoreData.h>

#import "FEMMapping.h"
#import "FEMRepresentationUtility.h"

@implementation FEMManagedObjectCache {
	NSManagedObjectContext *_context;

	NSDictionary<NSString *, NSSet<id> *> *_lookupKeysMap;
	NSMutableDictionary<NSString *, NSMutableDictionary<id, __kindof NSManagedObject *> *> *_lookupObjectsMap;
}

#pragma mark - Init


- (instancetype)initWithMapping:(FEMMapping *)mapping representation:(id)representation context:(NSManagedObjectContext *)context {
	NSParameterAssert(mapping);
    NSParameterAssert(representation);
	NSParameterAssert(context);

	self = [self init];
	if (self) {
        NSDictionary<NSString *, NSSet<id> *> *primaryKeys = FEMRepresentationCollectPresentedPrimaryKeys(representation, mapping);
        
		_context = context;
        
		_lookupKeysMap = [primaryKeys copy];
		_lookupObjectsMap = [[NSMutableDictionary alloc] initWithCapacity:primaryKeys.count];
	}

	return self;
}

#pragma mark - Inspection

- (NSMutableDictionary<id, __kindof NSManagedObject *> *)fetchExistingObjectsForMapping:(FEMMapping *)mapping {
	NSSet<id> *lookupValues = _lookupKeysMap[mapping.entityName];
	if (lookupValues.count == 0) return nil;

    NSExpression *leftExpression = [NSExpression expressionForKeyPath:mapping.primaryKey];
    NSExpression *rightExpression = [NSExpression expressionForConstantValue:lookupValues];
    NSPredicate *predicate = [[NSComparisonPredicate alloc] initWithLeftExpression: leftExpression
                                                                   rightExpression: rightExpression
                                                                          modifier: NSAllPredicateModifier
                                                                              type: NSInPredicateOperatorType
                                                                           options: NSNormalizedPredicateOption];
    
	NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:mapping.entityName];
    fetchRequest.predicate = predicate;
    fetchRequest.fetchLimit = lookupValues.count;

	NSArray<__kindof NSManagedObject *> *existingObjects = [_context executeFetchRequest:fetchRequest error:nil];
    NSArray<id> *primaryValues = [existingObjects valueForKey:mapping.primaryKey];
    
    return [[NSMutableDictionary alloc] initWithObjects: existingObjects
                                                forKeys: primaryValues];
}

- (NSMutableDictionary<id, __kindof NSManagedObject *> *)cachedObjectsForMapping:(FEMMapping *)mapping {
	NSMutableDictionary<id, __kindof NSManagedObject *> *entityObjectsMap = _lookupObjectsMap[mapping.entityName];
	if (!entityObjectsMap) {
		entityObjectsMap = [self fetchExistingObjectsForMapping:mapping];
        
        if (entityObjectsMap == nil) {
            entityObjectsMap = [NSMutableDictionary new];
        }
        
		_lookupObjectsMap[mapping.entityName] = entityObjectsMap;
	}

	return entityObjectsMap;
}

- (id)existingObjectForRepresentation:(id)representation mapping:(FEMMapping *)mapping {
	NSDictionary *entityObjectsMap = [self cachedObjectsForMapping:mapping];

	id primaryKeyValue = FEMRepresentationValueForAttribute(representation, mapping.primaryKeyAttribute);
	if (primaryKeyValue == nil || primaryKeyValue == NSNull.null) return nil;

	return entityObjectsMap[primaryKeyValue];
}

- (id)existingObjectForPrimaryKey:(id)primaryKey mapping:(FEMMapping *)mapping {
    NSDictionary *entityObjectsMap = [self cachedObjectsForMapping:mapping];

    return entityObjectsMap[primaryKey];
}

- (void)addExistingObject:(id)object mapping:(FEMMapping *)mapping {
	NSParameterAssert(mapping.primaryKey);
	NSParameterAssert(object);

	id primaryKeyValue = [object valueForKey:mapping.primaryKey];
	NSAssert(primaryKeyValue, @"No value for key (%@) on object (%@) found", mapping.primaryKey, object);

	NSMutableDictionary *entityObjectsMap = [self cachedObjectsForMapping:mapping];
    entityObjectsMap[primaryKeyValue] = object;
}

- (NSDictionary *)existingObjectsForMapping:(FEMMapping *)mapping {
    return [[self cachedObjectsForMapping:mapping] copy];
}

@end

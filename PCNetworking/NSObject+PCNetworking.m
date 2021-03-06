//
//  NSObject+PCNetworking.m
//  PCNetworking
//
//  Created by Paul Carpenter on 5/16/14.
//  Copyright (c) 2014 Paul Carpenter. All rights reserved.
//

#import "NSObject+PCNetworking.h"
#import <objc/runtime.h>
#import "PCNetworkProperty.h"
#import "NSString+PCNetworking.h"
#import <BlocksKit/BlocksKit.h>
#import <CoreData/CoreData.h>
#import <MagicalRecord/MagicalRecord.h>
#import <Mantle/MTLModel.h>
#import <Mantle/MTLJSONAdapter.h>

static char kPCNetworkPropertiesDictionaryKey;
static NSMutableArray* kPCNetworkProtocolNameList;
BOOL PCClassDescendsFromClass(Class classA, Class classB);

@implementation NSObject (PCNetworking)

////////////////////////////////////////////////////
#pragma mark - Public
////////////////////////////////////////////////////

+ (instancetype)objectFromDictionary:(NSDictionary *)dictionary
{
    return [self objectFromDictionary:dictionary inContext:nil];
}

+ (instancetype)objectFromDictionary:(NSDictionary *)dictionary inContext:(NSManagedObjectContext *)context
{
    if (![self propertiesDictionary])
    {
        [self pcNetwork_loadProperties];
    }
    
    id object;
    if (PCClassDescendsFromClass(self, [NSManagedObject class]))
    {
        Class managedObjectClass = self; // Avoid class method warning, we know it's a subclass already
        if (context)
        {
            object = [managedObjectClass MR_createEntityInContext:context];
        }
        else
        {
            object = [managedObjectClass MR_createEntity];
        }
    }
    else if (PCClassDescendsFromClass(self, [MTLModel class]))
    {
        NSError *error;
        object = [MTLJSONAdapter modelOfClass:[self class] fromJSONDictionary:dictionary error:&error];
        return object;
    }
    else
    {
        object = [[self alloc] init];
    }
    
    NSDictionary *networkPropertyNameMappings = [self networkPropertyNameMappings];
    
    [[dictionary allKeys] enumerateObjectsUsingBlock:^(NSString* key, NSUInteger idx, BOOL *stop) {
        if (![dictionary[key] isEqual:[NSNull null]])
        {
            if (networkPropertyNameMappings[key])
            {
                [object assignValue:dictionary[key] toProperty:[self propertiesDictionary][networkPropertyNameMappings[key]]];
            }
            else if ([self propertyNameFromNetworkName:key])
            {
                [object assignValue:dictionary[key] toProperty:[self propertiesDictionary][[self propertyNameFromNetworkName:key]]];
            }
            else if ([self shouldCamelCaseIncomingDict] && [[self propertiesDictionary] objectForKey:[key naiveCamelCaseString]])
            {
                [object assignValue:dictionary[key] toProperty:[self propertiesDictionary][[key naiveCamelCaseString]]];
            }
            else if ([[self propertiesDictionary] objectForKey:key])
            {
                [object assignValue:dictionary[key] toProperty:[self propertiesDictionary][key]];
            }
        }
    }];
    
    SEL callbackSel = NSSelectorFromString(@"pc_didCreateFromDictionary:");
    if ([object respondsToSelector:callbackSel])
    {
        IMP imp = [object methodForSelector:callbackSel];
        void (*func)(id, SEL, NSDictionary *) = (void *)imp;
        func(object, callbackSel, dictionary);
    }
    
    return object;
}

- (NSDictionary *)dictionaryFromProperties:(NSArray *)propertyNames
{
    if (![[self class] propertiesDictionary])
    {
        [[self class] pcNetwork_loadProperties];
    }
    
    NSMutableDictionary *dictionaryRepresentation;
    
    NSDictionary *propertiesDictionary = [[self class] propertiesDictionary];
    
    [propertyNames bk_each:^(NSString* propertyName) {
        PCNetworkProperty* property = propertiesDictionary[propertyName];
        if (property)
        {
            id object;
            IMP imp = [self methodForSelector:property.getterSel];
            if (property.type == PCNetworkPropertyTypeInt) {
                int(*func)(id, SEL) = (void*)imp;
                object = @(func(self, property.getterSel));
            } else if (property.type == PCNetworkPropertyTypeBool) {
                BOOL(*func)(id, SEL) = (void*)imp;
                object = @(func(self, property.getterSel));
            } else if (property.type == PCNetworkPropertyTypeUnsignedInt) {
                unsigned(*func)(id, SEL) = (void*)imp;
                object = @(func(self, property.getterSel));
            } else if (property.type == PCNetworkPropertyTypeShort) {
                short(*func)(id, SEL) = (void*)imp;
                object = @(func(self, property.getterSel));
            } else if (property.type == PCNetworkPropertyTypeLong) {
                NSInteger(*func)(id, SEL) = (void*)imp;
                object = @(func(self, property.getterSel));
            } else if (property.type == PCNetworkPropertyTypeUnsignedLong) {
                NSUInteger(*func)(id, SEL) = (void*)imp;
                object = @(func(self, property.getterSel));
            } else if (property.type == PCNetworkPropertyTypeFloat) {
                float(*func)(id, SEL) = (void*)imp;
                object = @(func(self, property.getterSel));
            } else if (property.type == PCNetworkPropertyTypeDouble) {
                double(*func)(id, SEL) = (void*)imp;
                object = @(func(self, property.getterSel));
            } else if (property.type == PCNetworkPropertyTypeId) {
                id(*func)(id, SEL) = (void*)imp;
                object = func(self, property.getterSel);
            }
            
            if (object != nil)
            {
                // Check for different network name!
                
                [dictionaryRepresentation setObject:object forKey:propertyName];
            }
        }
    }];
    return dictionaryRepresentation;
}

////////////////////////////////////////////////////
#pragma mark - Discover properties
////////////////////////////////////////////////////

+ (void)pcNetwork_loadProperties;
{
    [self pcNetwork_associateProperties:[self pcNetwork_getPropertiesWithClass:self]];
}

+ (NSDictionary*)pcNetwork_getPropertiesWithClass:(Class)klass
{
    NSMutableDictionary* propertiesDictionary = [[NSMutableDictionary alloc] init];
    
    // Class properties
    unsigned numberOfProperties, i;
    objc_property_t *properties = class_copyPropertyList(klass, &numberOfProperties);
    for (i = 0; i < numberOfProperties; i++)
    {
        objc_property_t property = properties[i];
        
        [propertiesDictionary setObject:[[PCNetworkProperty alloc] initWithPropertyName:[NSString stringWithFormat:@"%s", property_getName(property)] attributes:[NSString stringWithFormat:@"%s", property_getAttributes(property)]] forKey:[NSString stringWithFormat:@"%s", property_getName(property)]];
    }
    free(properties);
    
    // Protocol properties
    kPCNetworkProtocolNameList = [[NSMutableArray alloc] init];
    unsigned numberOfRootProtocols;
    __unsafe_unretained Protocol **classProtocols = class_copyProtocolList(klass, &numberOfRootProtocols);
    [propertiesDictionary addEntriesFromDictionary:[klass propertiesForProtocolList:classProtocols ofLength:numberOfRootProtocols]];
    
    if ([self includePropertiesFromSuperClass])
    {
        Class superKlass = [klass superclass];
        
        [propertiesDictionary addEntriesFromDictionary:[klass pcNetwork_getPropertiesWithClass:superKlass]];
    }
    
    // Clear out all of that nonsense
    kPCNetworkProtocolNameList = nil;
    
    // Phew send it all back
    return propertiesDictionary;
}

+ (NSDictionary*)propertiesForProtocolList:(__unsafe_unretained Protocol **)protocolList ofLength:(unsigned)length
{
    NSMutableDictionary* propertiesDictionary = [[NSMutableDictionary alloc] init];
    
    unsigned i, j, numberOfProtocolProperties;
    for (i = 0; i < length; i++)
    {
        // Get this protocol, but only if we haven't already gotten it
        NSString* protocolName = [NSString stringWithFormat:@"%s", protocol_getName(protocolList[i])];
        if ([kPCNetworkProtocolNameList containsObject:protocolName])
        {
            return @{};
        }
        [kPCNetworkProtocolNameList addObject:protocolName];
        
        // Get its properties
        objc_property_t *protocolProperties = protocol_copyPropertyList(protocolList[i], &numberOfProtocolProperties);
        for (j = 0; j < numberOfProtocolProperties; j++)
        {
            objc_property_t property = protocolProperties[j];
            
            [propertiesDictionary setObject:[[PCNetworkProperty alloc] initWithPropertyName:[NSString stringWithFormat:@"%s", property_getName(property)] attributes:[NSString stringWithFormat:@"%s", property_getAttributes(property)]] forKey:[NSString stringWithFormat:@"%s", property_getName(property)]];
        }
        
        // Get this protocol's protocols if necessary
        SEL inheritanceSelector = NSSelectorFromString([NSString stringWithFormat:@"includePropertiesFrom%@ProtocolParents", protocolName]);
        if ([self respondsToSelector:inheritanceSelector])
        {
            IMP imp = [self methodForSelector:inheritanceSelector];
            BOOL (*func)(id, SEL) = (void *)imp;
            if(func(self, inheritanceSelector))
            {
                unsigned numberOfProtocols;
                __unsafe_unretained Protocol **parentProtocols = class_copyProtocolList([self class], &numberOfProtocols);
                [propertiesDictionary addEntriesFromDictionary:[self propertiesForProtocolList:parentProtocols ofLength:numberOfProtocols]];
            }
        }
    }
    
    free(protocolList);
    
    return propertiesDictionary;
}

+ (void)pcNetwork_associateProperties:(NSDictionary*)properties
{
    objc_setAssociatedObject(self, &kPCNetworkPropertiesDictionaryKey, properties, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (BOOL)includePropertiesFromSuperClass
{
    return NO;
}

+ (NSMutableDictionary*)propertiesDictionary
{
    return objc_getAssociatedObject(self, &kPCNetworkPropertiesDictionaryKey);
}

+ (NSString*)propertyNameFromNetworkName:(NSString *)networkName
{
    return nil;
}

+ (NSDictionary*)networkPropertyNameMappings
{
    return nil;
}

////////////////////////////////////////////////////
#pragma mark - Assigning properties
////////////////////////////////////////////////////

- (void)assignValue:(id)value toProperty:(PCNetworkProperty*)property
{
    if (property.networkSetterSel)
    {
        SEL selector;
        BOOL strict = YES;
        if ([self respondsToSelector:property.networkSetterSel])
        {
            selector = property.networkSetterSel;
            strict = NO;
        }
        else
        {
            selector = [self respondsToSelector:property.setterSel] ? property.setterSel : nil;
        }
        
        if (selector && [self pcNetwork_validMethodForSetterSelector:selector property:property value:value strict:strict])
        {
            if ([self pcNetwork_propertyWantsCollection:property])
            {
                value = [self pcNetwork_formatValue:value forCollectionProperty:property];
            }
            [self callSelector:selector withValue:value forType:property.type];
        }
    }
}

+ (BOOL)shouldCamelCaseIncomingDict
{
    return YES;
}

- (void)callSelector:(SEL)selector withValue:(id)value forType:(PCNetworkPropertyType)type
{
    IMP imp = [self methodForSelector:selector];
    
    if (type == PCNetworkPropertyTypeInt) {
        void (*func)(id, SEL, int) = (void *)imp;
        func(self, selector, [self formatValueForInt:value]);
    } else if (type == PCNetworkPropertyTypeBool) {
        void (*func)(id, SEL, unsigned) = (void *)imp;
        func(self, selector, [self formatValueForBool:value]);
    } else if (type == PCNetworkPropertyTypeUnsignedInt) {
        void (*func)(id, SEL, unsigned) = (void *)imp;
        func(self, selector, [self formatValueForUnsignedInt:value]);
    } else if (type == PCNetworkPropertyTypeShort) {
        void (*func)(id, SEL, short) = (void *)imp;
        func(self, selector, [self formatValueForShort:value]);
    } else if (type == PCNetworkPropertyTypeLong) {
        void (*func)(id, SEL, SInt64) = (void *)imp;
        func(self, selector, [self formatValueForLong:value]);
    } else if (type == PCNetworkPropertyTypeUnsignedLong) {
        void (*func)(id, SEL, UInt64) = (void *)imp;
        func(self, selector, [self formatValueForUnsignedLong:value]);
    } else if (type == PCNetworkPropertyTypeFloat) {
        void (*func)(id, SEL, float) = (void *)imp;
        func(self, selector, [self formatValueForFloat:value]);
    } else if (type == PCNetworkPropertyTypeDouble) {
        void (*func)(id, SEL, double) = (void *)imp;
        func(self, selector, [self formatValueForDouble:value]);
    } else if (type == PCNetworkPropertyTypeId) {
        void (*func)(id, SEL, id) = (void *)imp;
        func(self, selector, value);
    }
}

- (BOOL)pcNetwork_validMethodForSetterSelector:(SEL)selector property:(PCNetworkProperty*)property value:(id)value strict:(BOOL)strict
{
    
    NSMethodSignature* signature = [self methodSignatureForSelector:selector];
    if ([signature numberOfArguments] == 3)
    {
        // Skip the first 2 arguments for obj-c internals
        NSString* signatureType = [NSString stringWithFormat:@"%s", [signature getArgumentTypeAtIndex:2]];
        
        if ([signatureType isEqualToString:property.typeString])
        {
            if ([signatureType isEqualToString:@"@"] && strict)
            {
                if ([self pcNetwork_propertyWantsCollection:property])
                {
                    return YES;
                }
                BOOL sameClass = [value isKindOfClass:NSClassFromString(property.className)];
                return sameClass;
            }
            return YES;
        }
    }
    return NO;
}

////////////////////////////////////////////////////
#pragma mark - Collections
////////////////////////////////////////////////////

- (BOOL)pcNetwork_propertyWantsCollection:(PCNetworkProperty*)property
{
    if (property.type == PCNetworkPropertyTypeId)
    {
        Class propertyClass = NSClassFromString(property.className);
        if (PCClassDescendsFromClass(propertyClass, [NSArray class]) || PCClassDescendsFromClass(propertyClass, [NSDictionary class]) || PCClassDescendsFromClass(propertyClass, [NSSet class]) || PCClassDescendsFromClass(propertyClass, [NSOrderedSet class]))
        {
            if ([self respondsToSelector:NSSelectorFromString([NSString stringWithFormat:@"%@ContainedClass", property.name])])
            {
                return YES;
            }
        }
    }
    return NO;
}

- (id)pcNetwork_formatValue:(id)value forCollectionProperty:(PCNetworkProperty*)property
{
    SEL selector = NSSelectorFromString([NSString stringWithFormat:@"%@ContainedClass", property.name]);
    IMP imp = [self methodForSelector:selector];
    Class (*func)(id, SEL) = (void *)imp;
    Class collectionClass = func(self, selector);
    if (PCClassDescendsFromClass([value class], [NSMutableArray class]))
    {
        return [[(NSArray*)value bk_map:^id(NSDictionary* dict) {
            return [[collectionClass class] objectFromDictionary:dict];
        }] mutableCopy];
    }
    if (PCClassDescendsFromClass([value class], [NSArray class]))
    {
        return [(NSArray*)value bk_map:^id(NSDictionary* dict) {
            return [[collectionClass class] objectFromDictionary:dict];
        }];
    }
    if (PCClassDescendsFromClass([value class], [NSMutableDictionary class]))
    {
        return [[(NSDictionary*)value bk_map:^id(id key, NSDictionary* dict) {
            return [[collectionClass class] objectFromDictionary:dict];
        }] mutableCopy];
    }
    if (PCClassDescendsFromClass([value class], [NSMutableDictionary class]))
    {
        return [(NSDictionary*)value bk_map:^id(id key, NSDictionary* dict) {
            return [[collectionClass class] objectFromDictionary:dict];
        }];
    }
    if (PCClassDescendsFromClass([value class], [NSMutableSet class]))
    {
        return [[(NSSet*)value bk_map:^id(NSDictionary* dict) {
            return [[collectionClass class] objectFromDictionary:dict];
        }] mutableCopy];
    }
    if (PCClassDescendsFromClass([value class], [NSSet class]))
    {
        return [(NSSet*)value bk_map:^id(NSDictionary* dict) {
            return [[collectionClass class] objectFromDictionary:dict];
        }];
    }
    if (PCClassDescendsFromClass([value class], [NSMutableOrderedSet class]))
    {
        return [[(NSArray*)value bk_map:^id(NSDictionary* dict) {
            return [[collectionClass class] objectFromDictionary:dict];
        }] mutableCopy];
    }
    if (PCClassDescendsFromClass([value class], [NSOrderedSet class]))
    {
        return [(NSArray*)value bk_map:^id(NSDictionary* dict) {
            return [[collectionClass class] objectFromDictionary:dict];
        }];
    }
    return value;
}

////////////////////////////////////////////////////
#pragma mark - Formatting
////////////////////////////////////////////////////

- (int)formatValueForInt:(id)aNum
{
    if ([aNum respondsToSelector:@selector(intValue)])
    {
        return [aNum intValue];
    }
    // raise exception
    return 0;
}

- (int)formatValueForBool:(id)aNum
{
    if ([aNum respondsToSelector:@selector(boolValue)])
    {
        return [aNum boolValue];
    }
    // raise exception
    return 0;
}

- (unsigned)formatValueForUnsignedInt:(id)aNum
{
    if ([aNum respondsToSelector:@selector(unsignedIntValue)])
    {
        return [aNum unsignedIntValue];
    }
    // raise exception
    return 0;
}
- (short)formatValueForShort:(id)aNum
{
    if ([aNum respondsToSelector:@selector(shortValue)])
    {
        return [aNum shortValue];
    }
    // raise exception
    return 0;
}

- (SInt64)formatValueForLong:(id)aNum
{
    if ([aNum respondsToSelector:@selector(longValue)])
    {
        return [aNum longValue];
    }
    // raise exception
    return 0;
}

- (UInt64)formatValueForUnsignedLong:(id)aNum
{
    if ([aNum respondsToSelector:@selector(unsignedLongValue)])
    {
        return [aNum unsignedLongValue];
    }
    // raise exception
    return 0;
}

- (float)formatValueForFloat:(id)aNum
{
    if ([aNum respondsToSelector:@selector(floatValue)])
    {
        return [aNum floatValue];
    }
    // raise exception
    return 0.0;
}

- (double)formatValueForDouble:(id)aNum
{
    if ([aNum respondsToSelector:@selector(doubleValue)])
    {
        return [aNum doubleValue];
    }
    // raise exception
    return 0.0;
}

@end

////////////////////////////////////////////////////
#pragma mark - C Code
////////////////////////////////////////////////////

// http://stackoverflow.com/questions/4251286/how-to-tell-if-a-class-inherits-from-nsobject-objective-c
BOOL PCClassDescendsFromClass(Class classA, Class classB)
{
    while(classA)
    {
        if(classA == classB) return YES;
        classA = class_getSuperclass(classA);
    }
    
    return NO;
}


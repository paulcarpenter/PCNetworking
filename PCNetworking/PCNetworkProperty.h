//
//  PCNetworkProperty.h
//  PCNetworking
//
//  Created by Paul Carpenter on 5/27/14.
//  Copyright (c) 2014 Paul Carpenter. All rights reserved.
//

#import <Foundation/Foundation.h>

// q -> long (NSInteger)
// Q -> unsigned long (NSUInteger)
// c -> char
// d -> double (CGFloat)
// i -> int, signed
// I -> uint, unsigned
// f -> float
// s -> short
// {...} -> struct
// (...) -> union
// ^i -> int pointer
// ^v -> void pointer
// ^* -> some kind of pointer

typedef NS_ENUM(NSUInteger, PCNetworkPropertyRetainType)
{
    PCNetworkPropertyRetainTypeNone,
    PCNetworkPropertyRetainTypeStrong,
    PCNetworkPropertyRetainTypeAssign,
    PCNetworkPropertyRetainTypeWeak,
    PCNetworkPropertyRetainTypeDynamic,
    PCNetworkPropertyRetainTypeCopy
};

typedef NS_ENUM(NSUInteger, PCNetworkPropertyType)
{
    PCNetworkPropertyTypeNone,
    PCNetworkPropertyTypeInt,
    PCNetworkPropertyTypeUnsignedInt,
    PCNetworkPropertyTypeShort,
    PCNetworkPropertyTypeLong,
    PCNetworkPropertyTypeUnsignedLong,
    PCNetworkPropertyTypeFloat,
    PCNetworkPropertyTypeDouble,
    PCNetworkPropertyTypeId,
    PCNetworkPropertyTypeInvalid
};

@interface PCNetworkProperty : NSObject

@property(nonatomic, strong) NSString* name;
@property(nonatomic, strong) NSString* attributes;

// Property properties

@property(nonatomic, assign) PCNetworkPropertyType type;
@property(nonatomic, strong) NSString* typeString;
@property(nonatomic, strong) NSString* className;
@property(nonatomic, strong) NSString* ivarName;
@property(nonatomic, assign, getter = isAtomic) BOOL atomic;
@property(nonatomic, assign, getter = isReadonly) BOOL readonly;
@property(nonatomic, assign) PCNetworkPropertyRetainType retainType;

@property(nonatomic, assign, readwrite) SEL getterSel;
@property(nonatomic, assign, readwrite) SEL setterSel;
@property(nonatomic, readonly) SEL networkSetterSel;

- (instancetype)initWithPropertyName:(NSString*)name attributes:(NSString*)attributes;

- (SEL)networkSetterSel;

@end

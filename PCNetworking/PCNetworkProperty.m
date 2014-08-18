//
//  PCNetworkProperty.m
//  PCNetworking
//
//  Created by Paul Carpenter on 5/27/14.
//  Copyright (c) 2014 Paul Carpenter. All rights reserved.
//

#import "PCNetworkProperty.h"

@implementation PCNetworkProperty

- (instancetype)initWithPropertyName:(NSString *)name attributes:(NSString *)attributes
{
    self = [super init];
    if (self)
    {
        self.name = name;
        self.attributes = attributes;
        
        [self parseAttributes];
    }
    return self;
}

- (SEL)setterSel
{
    if (!_setterSel)
    {
        return NSSelectorFromString([NSString stringWithFormat:@"set%@%@:", [[self.name substringWithRange:NSMakeRange(0, 1)] uppercaseString], [self.name substringFromIndex:1]]);
    }
    return _setterSel;
}

- (SEL)networkSetterSel
{
    NSString* selString = NSStringFromSelector(self.setterSel);
    
    selString = [NSString stringWithFormat:@"network%@%@", [[selString substringWithRange:NSMakeRange(0, 1)] uppercaseString], [selString substringFromIndex:1]];
    
    return NSSelectorFromString(selString);
}

- (void)parseAttributes
{
    // Set some defaults
    self.retainType = PCNetworkPropertyRetainTypeAssign;
    self.atomic = YES;
    
    NSArray* components = [self.attributes componentsSeparatedByString:@","];
    [components enumerateObjectsUsingBlock:^(NSString* str, NSUInteger idx, BOOL *stop) {
        switch ([str characterAtIndex:0])
        {
            case 'T':
                self.typeString = [str substringFromIndex:1];
                if ([self.typeString hasPrefix:@"@"])
                {
                    self.className = [[self.typeString substringFromIndex:1] stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                    self.typeString = @"@";
                }
                break;
                
            case 'V':
                self.ivarName = [str substringFromIndex:1];
                break;
                
            case 'N':
                self.atomic = NO;
                break;
                
            case 'R':
                self.readonly = YES;
                break;
                
            case '&':
                self.retainType = PCNetworkPropertyRetainTypeStrong;
                break;
                
            case 'C':
                self.retainType = PCNetworkPropertyRetainTypeCopy;
                break;
                
            case 'W':
                self.retainType = PCNetworkPropertyRetainTypeWeak;
                break;
                
            case 'D':
                self.retainType = PCNetworkPropertyRetainTypeDynamic;
                break;
                
            case 'S':
                self.setterSel = NSSelectorFromString([str substringFromIndex:1]);
                break;
                
            case 'G':
                self.getterSel = NSSelectorFromString([str substringFromIndex:1]);
                break;
                
            default:
                break;
        }
    }];
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"<%@: %p, name=%@, type=%@, retain=%u, readonly=%d>", NSStringFromClass([self class]), self, self.name, self.typeString, self.retainType, self.readonly];
}

- (PCNetworkPropertyType)type
{
    if (_type == PCNetworkPropertyTypeNone) {
        if ([self.typeString isEqualToString:@"i"]) {
            _type = PCNetworkPropertyTypeInt;
        } else if([self.typeString isEqualToString:@"I"]) {
            _type = PCNetworkPropertyTypeUnsignedInt;
        } else if([self.typeString isEqualToString:@"I"]) {
            _type = PCNetworkPropertyTypeUnsignedInt;
        } else if([self.typeString isEqualToString:@"s"]) {
            _type = PCNetworkPropertyTypeShort;
        } else if([self.typeString isEqualToString:@"q"]) {
            _type = PCNetworkPropertyTypeLong;
        } else if([self.typeString isEqualToString:@"Q"]) {
            _type = PCNetworkPropertyTypeUnsignedLong;
        } else if([self.typeString isEqualToString:@"f"]) {
            _type = PCNetworkPropertyTypeFloat;
        } else if([self.typeString isEqualToString:@"d"]) {
            _type = PCNetworkPropertyTypeDouble;
        } else if([self.typeString isEqualToString:@"@"]) {
            _type = PCNetworkPropertyTypeId;
        } else {
            _type = PCNetworkPropertyTypeInvalid;
        }
    }
    return _type;
}

@end


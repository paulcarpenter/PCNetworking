//
//  PCTestModel.h
//  PCNetworking
//
//  Created by Paul Carpenter on 5/27/14.
//  Copyright (c) 2014 Paul Carpenter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSObject+PCNetworking.h"

struct MyStruct {int pot; char tea;};

@interface PCTestModel : NSObject

@property(nonatomic) NSDictionary* dictionary;
@property(nonatomic, strong) NSNumber* number;
@property(nonatomic, strong, readonly) NSNumber* readonlyNumber;
@property(nonatomic, assign) NSInteger nsInteger;
@property(nonatomic, assign) NSUInteger nsuInteger;
@property(nonatomic, assign) int anInt;
@property(nonatomic, assign) long aLong;
@property(nonatomic, assign) float aFloat;
@property(nonatomic, assign) double aDouble;
@property(nonatomic, assign) struct MyStruct aStruct;
@property(nonatomic, strong) NSString* string;

@end

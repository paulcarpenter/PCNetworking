//
//  PCNetworkRequest.h
//  PCNetworking
//
//  Created by Paul Carpenter on 7/1/14.
//  Copyright (c) 2014 Paul Carpenter. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PCNetworkRequest : NSObject

@property (nonatomic, strong) NSString* httpVerb;
@property (nonatomic, strong) NSString* urlString;
@property (nonatomic, strong) NSDictionary* params;
@property (nonatomic, strong) Class objectClass;
@property (nonatomic) NSArray* responseKeys;
@property (nonatomic) NSDictionary* headerDict;

// Convenience methods
+ (instancetype)getRequestWithURLString:(NSString*)urlString params:(NSDictionary*)params klass:(Class)klass responseKeys:(NSArray*)responseKeys;

+ (instancetype)postRequestWithURLString:(NSString*)urlString params:(NSDictionary*)params klass:(Class)klass responseKeys:(NSArray*)responseKeys;

+ (instancetype)putRequestWithURLString:(NSString*)urlString params:(NSDictionary*)params klass:(Class)klass responseKeys:(NSArray*)responseKeys;

+ (instancetype)deleteRequestWithURLString:(NSString*)urlString params:(NSDictionary*)params klass:(Class)klass responseKeys:(NSArray*)responseKeys;

@end

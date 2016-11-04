//
//  PCNetworkRequest.h
//  PCNetworking
//
//  Created by Paul Carpenter on 7/1/14.
//  Copyright (c) 2014 Paul Carpenter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFURLRequestSerialization.h>

@interface PCNetworkRequest : NSObject

@property (nonatomic, strong) NSString* httpVerb;
@property (nonatomic, strong) NSString* urlString;
@property (nonatomic, strong) NSMutableDictionary* mutableParams;
@property (nonatomic, copy) NSDictionary *params;
@property (nonatomic, strong) Class objectClass;
@property (nonatomic, readwrite) BOOL useGzip;
@property (nonatomic, readwrite) BOOL extendedDuration;
@property (nonatomic) NSArray* responseKeys;
@property (nonatomic) NSDictionary* headerDict;
@property (nonatomic) dispatch_queue_t completionQueue;

// Convenience methods
+ (instancetype)getRequestWithURLString:(NSString*)urlString params:(NSDictionary*)params klass:(Class)klass responseKeys:(NSArray*)responseKeys completionQueue:(dispatch_queue_t)queue;

+ (instancetype)postRequestWithURLString:(NSString*)urlString params:(NSDictionary*)params klass:(Class)klass responseKeys:(NSArray*)responseKeys completionQueue:(dispatch_queue_t)queue;

+ (instancetype)putRequestWithURLString:(NSString*)urlString params:(NSDictionary*)params klass:(Class)klass responseKeys:(NSArray*)responseKeys completionQueue:(dispatch_queue_t)queue;

+ (instancetype)deleteRequestWithURLString:(NSString*)urlString params:(NSDictionary*)params klass:(Class)klass responseKeys:(NSArray*)responseKeys completionQueue:(dispatch_queue_t)queue;

@end

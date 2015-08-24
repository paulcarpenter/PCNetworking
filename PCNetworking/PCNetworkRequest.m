//
//  PCNetworkRequest.m
//  PCNetworking
//
//  Created by Paul Carpenter on 7/1/14.
//  Copyright (c) 2014 Paul Carpenter. All rights reserved.
//

#import "PCNetworkRequest.h"

@implementation PCNetworkRequest

+ (instancetype)getRequestWithURLString:(NSString*)urlString params:(NSDictionary*)params klass:(Class)klass responseKeys:(NSArray *)responseKeys
{
    return [[PCNetworkRequest alloc] initWithHTTPVerb:@"GET" urlString:urlString params:params objectClass:klass responseKeys:responseKeys];
}

+ (instancetype)postRequestWithURLString:(NSString*)urlString params:(NSDictionary*)params klass:(Class)klass responseKeys:(NSArray *)responseKeys
{
    return [[PCNetworkRequest alloc] initWithHTTPVerb:@"POST" urlString:urlString params:params objectClass:klass responseKeys:responseKeys];
}

+ (instancetype)putRequestWithURLString:(NSString*)urlString params:(NSDictionary*)params klass:(Class)klass responseKeys:(NSArray *)responseKeys
{
    return [[PCNetworkRequest alloc] initWithHTTPVerb:@"PUT" urlString:urlString params:params objectClass:klass responseKeys:responseKeys];
}

+ (instancetype)deleteRequestWithURLString:(NSString*)urlString params:(NSDictionary*)params klass:(Class)klass responseKeys:(NSArray *)responseKeys
{
    return [[PCNetworkRequest alloc] initWithHTTPVerb:@"DELETE" urlString:urlString params:params objectClass:klass responseKeys:responseKeys];
}

- (void)setParams:(NSMutableDictionary *)params
{
    if (params)
    {
        self.mutableParams = [params mutableCopy];
    }
    else
    {
        self.mutableParams = [NSMutableDictionary dictionary];
    }
}

////////////////////////////////////////////////////
#pragma mark - Private
////////////////////////////////////////////////////

- (instancetype)initWithHTTPVerb:(NSString*)httpVerb urlString:(NSString*)urlString params:(NSDictionary*)params objectClass:(Class)objectClass responseKeys:(NSArray*)responseKeys
{
    self = [super init];
    if (self)
    {
        self.httpVerb = httpVerb;
        self.urlString = urlString;
        self.params = params;
        self.objectClass = objectClass;
        self.responseKeys = responseKeys;
    }
    return self;
}



@end

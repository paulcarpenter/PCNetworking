//
//  PCNetworkManager.h
//  PCNetworking
//
//  Created by Paul Carpenter on 6/25/14.
//  Copyright (c) 2014 Paul Carpenter. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PCNetworkRequest;

@interface PCNetworkManager : NSObject

- (instancetype)initWithBaseURL:(NSURL*)url;
- (instancetype)initWithBaseURL:(NSURL*)url sessionConfiguration:(NSURLSessionConfiguration *)sessionConfiguration;
- (RACSignal*)loadObjectFromJSONNetworkRequest:(PCNetworkRequest*)request;
- (RACSignal*)loadObjectFromJSONNetworkRequest:(PCNetworkRequest*)request multipart:(NSDictionary*)multipart;
//- (RACSignal*)sendNewObject:(id)object;
//- (RACSignal*)sendUpdateObject:(id)object updatePaths:(NSArray*)paths;
//- (RACSignal*)sendDeleteObject:(id)object;

@end

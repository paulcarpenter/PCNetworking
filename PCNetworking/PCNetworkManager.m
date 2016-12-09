//
//  PCNetworkManager.m
//  PCNetworking
//
//  Created by Paul Carpenter on 6/25/14.
//  Copyright (c) 2014 Paul Carpenter. All rights reserved.
//

#import "PCNetworkManager.h"
#import <AFNetworking/AFHTTPSessionManager.h>
#import <AFgzipRequestSerializer/AFgzipRequestSerializer.h>
#import "PCNetworkRequest.h"
#import "NSObject+PCNetworking.h"
#import <BlocksKit/BlocksKit.h>

@interface PCNetworkManager ()

@property (nonatomic, strong) AFHTTPSessionManager* sessionManager;
@property (nonatomic, strong) NSString* baseURLString;

@end

@implementation PCNetworkManager

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.sessionManager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        self.sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
    }
    return self;
}

- (instancetype)initWithBaseURL:(NSURL*)url
{
    return [self initWithBaseURL:url sessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
}

- (instancetype)initWithBaseURL:(NSURL*)url sessionConfiguration:(NSURLSessionConfiguration *)sessionConfiguration;
{
    self = [super init];
    if (self)
    {
        self.sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:url sessionConfiguration:sessionConfiguration];
        self.sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
        [self.sessionManager.requestSerializer setTimeoutInterval:sessionConfiguration.timeoutIntervalForRequest];
        self.baseURLString = [url absoluteString];
    }
    return self;
}

- (RACSignal*)loadObjectFromJSONNetworkRequest:(PCNetworkRequest*)request
{
    return [self loadObjectFromJSONNetworkRequest:request multipart:nil];
}

- (RACSignal*)loadObjectFromJSONNetworkRequest:(PCNetworkRequest*)request multipart:(NSDictionary*)multipart
{
    return [self loadObjectFromJSONNetworkRequest:request multipart:multipart files:nil];
}

- (RACSignal*)loadObjectFromJSONNetworkRequest:(PCNetworkRequest*)request multipart:(NSDictionary*)multipart files:(NSDictionary *)multipartFiles;
{
    NSError* error;
    NSMutableURLRequest* serializedRequest;
    if (multipart || multipartFiles)
    {
        serializedRequest = [[AFJSONRequestSerializer serializer] multipartFormRequestWithMethod:request.httpVerb URLString:[NSString stringWithFormat:@"%@%@", self.baseURLString, request.urlString] parameters:request.mutableParams constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
            
            if (multipartFiles)
            {
                [formData appendPartWithFileData:multipartFiles[@"data"] name:multipartFiles[@"name"] fileName:multipartFiles[@"fileName"] mimeType:multipartFiles[@"mimeType"]];
            }
            if (multipart)
            {
                [multipart bk_each:^(NSString* key, NSData* data) {
                    [formData appendPartWithFormData:data name:key];
                }];
            }
        } error:&error];
    }
    else
    {
        if (request.useGzip)
        {
            serializedRequest = [[AFgzipRequestSerializer serializerWithSerializer:[AFJSONRequestSerializer serializer]] requestWithMethod:request.httpVerb URLString:[NSString stringWithFormat:@"%@%@", self.baseURLString, request.urlString] parameters:request.mutableParams error:&error];
        }
        else
        {
            serializedRequest = [[AFJSONRequestSerializer serializer] requestWithMethod:request.httpVerb URLString:[NSString stringWithFormat:@"%@%@", self.baseURLString, request.urlString] parameters:request.mutableParams error:&error];
        }
        
    }
    [request.headerDict bk_each:^(NSString* key, NSString* value) {
        [serializedRequest setValue:value forHTTPHeaderField:key];
    }];
    
    if (request.extendedDuration)
    {
        serializedRequest.timeoutInterval = 5.f * 60.f;
    }
    
    RACSignal* signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber)
    {
        NSURLSessionTask* task = [self.sessionManager dataTaskWithRequest:serializedRequest completionHandler:^(NSURLResponse *response, id json, NSError *error) {
            
            void (^responseBlock)() = ^void {
                if (!error)
                {
                    id __block keyedJson = json;
                    if (request.responseKeys)
                    {
                        [request.responseKeys enumerateObjectsUsingBlock:^(NSString* key, NSUInteger idx, BOOL *stop) {
                            keyedJson = keyedJson[key];
                        }];
                    }
                    
                    id obj;
                    if(request.objectClass)
                    {
                        if ([keyedJson isKindOfClass:[NSArray class]])
                        {
                            obj = [keyedJson bk_map:^(NSDictionary* elem) {
                                return [request.objectClass objectFromDictionary:elem];
                            }];
                        }
                        else
                        {
                            obj = [request.objectClass objectFromDictionary:keyedJson];
                        }
                    }
                    else
                    {
                        obj = keyedJson;
                    }
                    if (obj)
                    {
                        [subscriber sendNext:obj];
                    }
                    else
                    {
                        [subscriber sendError:error];
                    }
                }
                else
                {
                    [subscriber sendError:error];
                }
            };
            
            dispatch_queue_t queue = request.completionQueue ?: dispatch_get_main_queue();
            if (queue == dispatch_get_main_queue())
            {
                responseBlock();
            }
            else
            {
                dispatch_async(queue, responseBlock);
            }
        }];
        
        [task resume];
        
        return [RACDisposable disposableWithBlock:^{
            [task cancel];
        }];
    }];
    
    // Start executing the request
    
    return signal;
}

- (void)cancelAll
{
    for (NSURLSessionTask *task in self.sessionManager.tasks)
    {
        [task cancel];
    }
}

@end

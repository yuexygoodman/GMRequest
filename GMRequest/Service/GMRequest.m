//
//  GMRequest.m
//  GMNetworkService
//
//  Created by Good Man on 2017/5/16.
//  Copyright © 2017年 Good Man. All rights reserved.
//

#import "GMRequest.h"
#import "AFNetworking.h"

@interface GMRequestTask ()
+ (instancetype)taskWithSessionTask:(NSURLSessionTask *) sessionTask;
@property(nonatomic,strong) NSURLSessionTask * sessionTask;
@property(nonatomic,strong) id responseObject;
@property(nonatomic,strong) NSError * err;
@end

@implementation GMRequest
#pragma -mark internal methods
- (id)init
{
    self=[super init];
    if (self) {
        if (!_sessionManager) {
            _sessionManager=[AFHTTPSessionManager manager];
            AFHTTPResponseSerializer * responseSerializer=[AFHTTPResponseSerializer serializer];
            NSMutableSet *customContentTypes = [responseSerializer.acceptableContentTypes mutableCopy];
            [customContentTypes addObject:@"text/html"];
            [customContentTypes addObject:@"text/plain"];
            [customContentTypes addObject:@"text/json"];
            [customContentTypes addObject:@"image/*"];
            [customContentTypes addObject:@"application/octet-stream"];
            [customContentTypes addObject:@"application/json"];
            responseSerializer.acceptableContentTypes = [customContentTypes copy];
            _sessionManager.responseSerializer=responseSerializer;
        }
    }
    return self;
}
- (void)setTimeOut:(NSTimeInterval)timeOut
{
    _timeOut=timeOut;
    _sessionManager.requestSerializer.timeoutInterval=_timeOut;
}
- (void)setAllowInvalidCertificates:(BOOL)allowInvalidCertificates
{
    _allowInvalidCertificates=allowInvalidCertificates;
    _sessionManager.securityPolicy.allowInvalidCertificates=_allowInvalidCertificates;
}
- (void)setAllowInvalidDomain:(BOOL)allowInvalidDomain {
    _allowInvalidDomain=allowInvalidDomain;
    _sessionManager.securityPolicy.validatesDomainName=!_allowInvalidDomain;
}
- (void)setStringEncoding:(NSStringEncoding)stringEncoding
{
    _stringEncoding=stringEncoding;
    _sessionManager.requestSerializer.stringEncoding=stringEncoding;
    _sessionManager.responseSerializer.stringEncoding=stringEncoding;
}
- (void)setContentType:(GMRequestContentType)contentType {
    _contentType=contentType;
    switch (contentType) {
        case 0:
        self.sessionManager.requestSerializer=[AFHTTPRequestSerializer serializer];
        break;
        case 1:
        self.sessionManager.requestSerializer=[AFJSONRequestSerializer serializer];
        break;
        case 2:
        self.sessionManager.requestSerializer=[AFPropertyListRequestSerializer serializer];
        break;
        default:
        self.sessionManager.requestSerializer=[AFHTTPRequestSerializer serializer];
        break;
    }
}
- (void)setRequestHeaders:(NSDictionary *) headers
{
    if ([headers isKindOfClass:[NSDictionary class]]) {
        for (NSString * key in headers.allKeys) {
            [self.sessionManager.requestSerializer setValue:[headers objectForKey:key] forHTTPHeaderField:key];
        }
    }
}
#pragma -mark Get request
- (GMRequestTask *)getWithUrl:(NSString *) url finish:(GMRequestFinishBlock) finish
{
    return [self getWithUrl:url parameters:nil finish:finish];
}
- (GMRequestTask *)getWithUrl:(NSString *) url parameters:(NSDictionary *) params finish:(GMRequestFinishBlock) finish
{
    return [self getWithUrl:url headers:nil parameters:params finish:finish];
}
- (GMRequestTask *)getWithUrl:(NSString *)url headers:(NSDictionary *)heads parameters:(NSDictionary *)params finish:(GMRequestFinishBlock)finish
{
    return [self requestWithUrl:url method:GMRequestMethodGet headers:heads parameters:params progress:nil finish:finish];
}

#pragma -mark Post request
- (GMRequestTask *)postWithUrl:(NSString *) url parameters:(NSDictionary *) params finish:(GMRequestFinishBlock) finish
{
    return  [self postWithUrl:url headers:nil parameters:params finish:finish];
}
- (GMRequestTask *)postWithUrl:(NSString *)url headers:(NSDictionary *)heads parameters:(NSDictionary *)params finish:(GMRequestFinishBlock)finish
{
    return [self requestWithUrl:url method:GMRequestMethodPost headers:heads parameters:params progress:nil finish:finish];
}

- (GMRequestTask *)postWithUrl:(NSString *) url headers:(NSDictionary *) heads body:(NSData *)body progress:(GMRequestProgressBlock) progress finish:(GMRequestFinishBlock) finish {
    dispatch_semaphore_t semaphore;
    if (self.synchronous) {
        semaphore=dispatch_semaphore_create(1);
        dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        });
    }
    
    GMRequestTask *requestTask=[GMRequestTask new];
    
    void(^complete)(id responseObject,NSError *err)=^(id responseObject,NSError * err){
        requestTask.responseObject=responseObject;
        requestTask.err=err;
        if (semaphore) {
            dispatch_semaphore_signal(semaphore);
            return;
        }
        finish(responseObject,err);
    };
    
    NSMutableURLRequest * request=[[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    request.HTTPMethod=@"POST";
    for (NSString * key in heads.allKeys) {
        [request setValue:[heads objectForKey:key] forHTTPHeaderField:key];
    }
    request.HTTPBody=body;
    NSURLSessionTask * sessionTask=[self.sessionManager dataTaskWithRequest:request uploadProgress:progress downloadProgress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        complete(responseObject,error);
    }];
    [sessionTask resume];
    requestTask.sessionTask=sessionTask;
    if (semaphore) {
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        finish(requestTask.responseObject,requestTask.err);
        dispatch_semaphore_signal(semaphore);
    }
    return requestTask;
}

#pragma -mark upload a file to server
- (GMRequestTask *)uploadWithUrl:(NSString *) url parameters:(NSDictionary *) params fileName:(NSString *) fileName fileData:(id) data miniType:(NSString * ) mini finish:(GMRequestFinishBlock) finish
{
    NSArray * sepera=[fileName componentsSeparatedByString:@"."];
    NSString * keyName=sepera.count>0?sepera[0]:fileName;
    return [self uploadWithUrl:url parameters:params fileName:fileName keyName:keyName fileData:data miniType:mini progress:nil finish:finish];
}
- (GMRequestTask *)uploadWithUrl:(NSString *) url parameters:(NSDictionary *) params fileName:(NSString *) fileName keyName:(NSString *)keyName fileData:(id)data miniType:(NSString * ) mini progress:(GMRequestProgressBlock)progress finish:(GMRequestFinishBlock)finish
{
    return [self uploadWithUrl:url headers:nil parameters:params fileName:fileName keyName:keyName fileData:data miniType:mini progress:progress finish:finish];
}

#pragma -mark download a file from server
- (GMRequestTask *)downloadWithUrl:(NSString *) url parameters:(NSDictionary *) params finish:(GMRequestFinishBlock) finish
{
    return [self downloadWithUrl:url parameters:params progress:nil finish:finish];
}
- (GMRequestTask *)downloadWithUrl:(NSString *) url parameters:(NSDictionary *) params progress:(GMRequestProgressBlock) progress finish:(GMRequestFinishBlock) finish
{
    return [self downloadWithUrl:url headers:nil parameters:params progress:progress finish:finish];
}
- (GMRequestTask *)downloadWithUrl:(NSString *)url headers:(NSDictionary *)heads parameters:(NSDictionary *)params progress:(GMRequestProgressBlock)progress finish:(GMRequestFinishBlock)finish
{
    return [self requestWithUrl:url method:GMRequestMethodGet headers:heads parameters:params progress:progress finish:finish];
}

#pragma -mark Head request
- (GMRequestTask *)headWithUrl:(NSString *) url parameters:(NSDictionary *) params finishWithHeader:(GMRequestFinishWithHeaderBlock) finish
{
    return [self headWithUrl:url headers:nil parameters:params finishWithHeader:finish];
}
- (GMRequestTask *)headWithUrl:(NSString *) url headers:(NSDictionary *) heads parameters:(NSDictionary *) params finishWithHeader:(GMRequestFinishWithHeaderBlock) finish
{
    return [self requestWithUrl:url method:GMRequestMethodHead headers:heads parameters:params progress:nil finishWithHeader:finish];
}

#pragma -mark final request
- (GMRequestTask *)requestWithUrl:(NSString *) url method:(GMRequestMethod) method headers:(NSDictionary *) heads parameters:(NSDictionary *) params progress:(GMRequestProgressBlock) progress finish:(GMRequestFinishBlock) finish
{
    return [self requestWithUrl:url method:method headers:heads parameters:params progress:progress finishWithHeader:^(id resHeader, id resData, NSError *error) {
        finish(resData,error);
    }];
}
- (GMRequestTask *)requestWithUrl:(NSString *) url method:(GMRequestMethod) method headers:(NSDictionary *) heads parameters:(NSDictionary *) params progress:(GMRequestProgressBlock) progress finishWithHeader:(GMRequestFinishWithHeaderBlock) finish
{
    dispatch_semaphore_t semaphore;
    if (self.synchronous) {
        semaphore=dispatch_semaphore_create(1);
        dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        });
    }
    NSDictionary *(^headerOfTask)(NSURLSessionTask *);
    headerOfTask= ^(NSURLSessionTask * task){
        NSDictionary * headers=nil;
        NSHTTPURLResponse * response=(NSHTTPURLResponse *)task.response;
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            headers=response.allHeaderFields;
        }
        return headers;
    };
    
    [self setRequestHeaders:heads];
    NSURLSessionTask * sessionTask;
    GMRequestTask * requestTask=[GMRequestTask new];
    
    void(^complete)(NSURLSessionTask *task,id responseObject,NSError *err)=^(NSURLSessionTask * task,id responseObject,NSError * err){
        requestTask.responseObject=responseObject;
        requestTask.err=err;
        if (semaphore) {
            dispatch_semaphore_signal(semaphore);
            return;
        }
        finish(headerOfTask(task),responseObject,err);
    };
    
    switch (method) {
        case GMRequestMethodGet:
        {
            sessionTask=[self.sessionManager GET:url parameters:params progress:progress success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                complete(task,responseObject,nil);
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                complete(task,nil,error);
            }];
            break;
        }
        case GMRequestMethodPost:
        {
            sessionTask=[self.sessionManager POST:url parameters:params progress:progress success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                complete(task,responseObject,nil);
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                complete(task,nil,error);
            }];
            break;
        }
        case GMRequestMethodHead:
        {
            sessionTask=[self.sessionManager HEAD:url parameters:params success:^(NSURLSessionDataTask * _Nonnull task) {
                complete(task,nil,nil);
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                complete(task,nil,error);
            }];
            break;
        }
        case GMRequestMethodPut:
        {
            sessionTask=[self.sessionManager PUT:url parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                complete(task,responseObject,nil);
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                complete(task,nil,error);
            }];
            break;
        }
        case GMRequestMethodDelete:
        {
            sessionTask=[self.sessionManager DELETE:url parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                complete(task,responseObject,nil);
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                complete(task,nil,error);
            }];
            break;
        }
        case GMRequestMethodPatch:
        {
            sessionTask=[self.sessionManager PATCH:url parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                complete(task,responseObject,nil);
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                complete(task,nil,error);
            }];
            break;
        }
        default:
            break;
    }
    requestTask.sessionTask=sessionTask;
    if (semaphore) {
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        finish(headerOfTask(requestTask.sessionTask),requestTask.responseObject,requestTask.err);
        dispatch_semaphore_signal(semaphore);
    }
    return requestTask;
}
- (GMRequestTask *)uploadWithUrl:(NSString *)url headers:(NSDictionary *)heads parameters:(NSDictionary *)params fileName:(NSString *)fileName keyName:(NSString *)keyName fileData:(id)data miniType:(NSString * ) mini progress:(GMRequestProgressBlock)progress finish:(GMRequestFinishBlock)finish
{
    GMRequestFile * file=[[GMRequestFile alloc] initWithFileName:fileName keyName:keyName data:data miniType:mini];
    return [self uploadWithUrl:url headers:heads parameters:params files:@[file] progress:progress finish:finish];
}

- (GMRequestTask *)uploadWithUrl:(NSString *) url headers:(NSDictionary *) heads parameters:(NSDictionary *) params files:(NSArray<GMRequestFile *> *) files progress:(GMRequestProgressBlock) progress finish:(GMRequestFinishBlock) finish
{
    dispatch_semaphore_t semaphore;
    if (self.synchronous) {
        semaphore=dispatch_semaphore_create(1);
        dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        });
    }
    GMRequestTask *requestTask=[GMRequestTask new];
    
    void(^complete)(NSURLSessionTask *task,id responseObject,NSError *err)=^(NSURLSessionTask * task,id responseObject,NSError * err){
        requestTask.responseObject=responseObject;
        requestTask.err=err;
        if (semaphore) {
            dispatch_semaphore_signal(semaphore);
            return;
        }
        finish(responseObject,err);
    };
    
    NSURLSessionTask * sessionTask=[self.sessionManager POST:url parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        for (GMRequestFile * file in files) {
            [formData appendPartWithFileData:file.data name:file.keyName fileName:file.fileName mimeType:file.miniType];
        }
    } progress:progress success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        complete(task,responseObject,nil);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        complete(task,nil,error);
    }];
    requestTask.sessionTask=sessionTask;
    if (semaphore) {
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        finish(requestTask.responseObject,requestTask.err);
        dispatch_semaphore_signal(semaphore);
    }
    return requestTask;
}

#pragma -mark init methods
+ (instancetype)request
{
    return [self requestWithOptions:nil];
}

+ (instancetype)jsonRequest
{
    return [self requestWithOptions:@{kGMRequestContentType:@(GMRequestContentTypeJson)}];
}

+ (instancetype)xmlRequest
{
    return [self requestWithOptions:@{kGMRequestContentType:@(GMRequestContentTypeXplist)}];
}

+ (instancetype)requestWithOptions:(NSDictionary *) options
{
    GMRequest * request=[[GMRequest alloc] init];
    if ([options isKindOfClass:[NSDictionary class]]) {
        for (NSString * key in options.allKeys) {
            if ([key isEqualToString:kGMRequestContentType]){
                request.contentType=[[options objectForKey:key] integerValue];
            }
            else if ([key isEqualToString:kGMRequestAllowInvalidCertificates]){
                request.allowInvalidCertificates= [[options objectForKey:key] boolValue];
            }
            else if ([key isEqualToString:kGMRequestAllowInvalidDomain]){
                request.allowInvalidDomain=[[options objectForKey:key] boolValue];
            }
            else if ([key isEqualToString:kGMRequestTimeOut]) {
                request.timeOut=[[options objectForKey:key] doubleValue];
            }
            else if ([key isEqualToString:kGMRequestSynchronous]){
                request.synchronous=[[options objectForKey:key] boolValue];
            }
            else if ([key isEqualToString:kGMRequestStringEncoding]){
                request.stringEncoding=[[options objectForKey:key] longValue];
            }
        }
    }
    return request;
}

#pragma -mark getter and setter

- (BOOL)synchronous {
    if ([NSThread currentThread].isMainThread) {
        return NO;
    }
    return _synchronous;
}

@end

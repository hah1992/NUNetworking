//
//  NUNetworkingAgent.m
//  NUNetworkingDemo
//
//  Created by nuclear on 16/9/5.
//  Copyright © 2016年 nuclear. All rights reserved.
//

#import "NUNetworkAgent.h"
#import "NUNetworkAPI.h"
#import "NUBatchRequestAPI.h"
#import "NUNetworkConfig.h"
#import "NUJSONValidator.h"
#import <AFNetworking/AFNetworking.h>
#import <pthread.h>

#define NU_DISPATCH_MAIN_SYNC(block)\
if ([NSThread isMainThread]) {\
    block();\
} else {\
    dispatch_sync(dispatch_get_main_queue(), block);\
}

static NUNetworkAgent *sharedNetworkAgent = nil;

static dispatch_queue_t api_task_single_queue() {
    static dispatch_queue_t api_task_single_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        api_task_single_queue = dispatch_queue_create("com.nuclear.networking.single.task", DISPATCH_QUEUE_SERIAL);
    });
    return api_task_single_queue;
}

@interface NUNetworkAgent () {
    AFURLSessionManager* downloadSessionManager;
}

@property (nonatomic, strong) NSCache *sessionManagerCache;  //AFHTTPSessionManager cache 避免重复创建
@property (nonatomic, strong) NSCache *sessionTasksCache;
@property (nonatomic, strong) AFURLSessionManager *sessionManager;
@property (nonatomic, strong) NSURLSessionConfiguration *defaultSessionCofig;
@property (nonatomic, strong) NSURLSessionConfiguration *backgroundSessionCofig;

@property (nonatomic, strong) NSOperationQueue *downloadQueue;
@property (nonatomic, strong) NSCache *runningDownlodCache;

@end

@implementation NUNetworkAgent

#pragma mark - Init
+ (NUNetworkAgent *)sharedNetworkAgent {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedNetworkAgent = [[self alloc] init];
    });
    return sharedNetworkAgent;
}

- (instancetype)init {
    if (!sharedNetworkAgent) {
        
        sharedNetworkAgent = [super init];
        sharedNetworkAgent.configuration = [[NUNetworkConfig alloc] init];
        
        self.defaultSessionCofig = [NSURLSessionConfiguration defaultSessionConfiguration];
        self.defaultSessionCofig.HTTPMaximumConnectionsPerHost = MAX_HTTP_CONNECTION_PER_HOST;
        self.defaultSessionCofig.timeoutIntervalForRequest = NU_API_REQUEST_TIME_OUT;
        self.sessionManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:self.defaultSessionCofig];
        self.downloadQueue = [[NSOperationQueue alloc] init];
        self.downloadQueue.maxConcurrentOperationCount = 6;
        self.downloadQueue.name = @"com.nuclear.NUNetworking";
        self.configuration = [NUNetworkConfig sharedInstance];
    }
    return sharedNetworkAgent;
}

+ (void)jsonValidatorDebugOpen:(BOOL)isOpen {
    [NUJSONValidator debugOpen:isOpen];
}

#pragma mark - Lazy load

- (NSCache *)sessionManagerCache {
    if (!_sessionManagerCache) {
        _sessionManagerCache = [[NSCache alloc] init];
    }
    return _sessionManagerCache;
}

- (NSCache *)sessionTasksCache {
    if (!_sessionTasksCache) {
        _sessionTasksCache = [[NSCache alloc] init];
    }
    return _sessionTasksCache;
}

- (NSCache *)runningDownlodCache {
    if (!_runningDownlodCache) {
        _runningDownlodCache = [[NSCache alloc] init];
    }
    return _runningDownlodCache;
}

#pragma mark - Serializer
- (AFHTTPRequestSerializer *)requestSerializerForAPI:(NUNetworkAPI *)api {
    NSParameterAssert(api);
    
    if (![api isKindOfClass:[NUNetworkAPI class]]) return nil;
    
    AFHTTPRequestSerializer *requestSerializer;
    switch ([api requestSerializerType]) {
        case NURequestSerializerTypeJSON:
            requestSerializer = [AFJSONRequestSerializer serializer];
            break;
        case NURequestSerializerTypePLIST:
            requestSerializer = [AFPropertyListRequestSerializer serializer];
            break;
        case NURequestSerializerTypeHTTP:
            requestSerializer = [AFHTTPRequestSerializer serializer];
            break;
    }

    requestSerializer.cachePolicy = [api requestCachePolicy];
    [requestSerializer willChangeValueForKey:@"timeoutInterval"];
    requestSerializer.timeoutInterval = [api timeoutInterval];
    [requestSerializer didChangeValueForKey:@"timeoutInterval"];
    
    NSDictionary* requestHeaderFieldParams = [api requestHTTPHeaderField];
    
    if (![[requestHeaderFieldParams allKeys] containsObject:@"User-Agent"] && self.configuration.userAgent) {
        [requestSerializer setValue:self.configuration.userAgent forHTTPHeaderField:@"User-Agent"];
    }

    if (requestHeaderFieldParams) {
        [requestHeaderFieldParams enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL* stop) {
            [requestSerializer setValue:obj forHTTPHeaderField:key];
        }];
    }
    requestSerializer.HTTPShouldUsePipelining = YES;
    return requestSerializer;
}

- (AFHTTPResponseSerializer *)responseSerializerForAPI:(NUNetworkAPI *)api {
    NSParameterAssert(api);
    if (![api isKindOfClass:[NUNetworkAPI class]]) return nil;
    
    AFHTTPResponseSerializer *responseSerializer;
    NUResponseSerializerType responseSerializerType = [api responseSerializerType];
    switch (responseSerializerType) {
        case NUResponseSerializerTypeJSON:
            responseSerializer = [AFJSONResponseSerializer serializer];
            responseSerializer.acceptableContentTypes = [api responseAcceptableContentTypes];
            [(AFJSONResponseSerializer *)responseSerializer setRemovesKeysWithNullValues:YES];
            break;
        case NUResponseSerializerTypePLIST:
            responseSerializer = [AFPropertyListResponseSerializer serializer];
            break;
        case NUResponseSerializerTypeIMAGE:
            responseSerializer = [AFImageResponseSerializer serializer];
            break;
        case NUResponseSerializerTypeXML:
            responseSerializer = [AFXMLParserResponseSerializer serializer];
            break;
        case NUResponseSerializerTypeHTTP:
            responseSerializer = [AFHTTPResponseSerializer serializer];
            responseSerializer.acceptableContentTypes = [api responseAcceptableContentTypes];
            break;
    }
    return responseSerializer;
}

#pragma mark - Request

// 请求开始
- (NSString *)requestUrlStringWithAPI:(NUNetworkAPI *)api {
    NSParameterAssert(api);
    NSString *baseURL = [api baseUrl];
    NSAssert(baseURL != nil || self.configuration.hostStr != nil,
             @"api baseURL or self.configuration.hostStr can't be nil together");
    if (![api isKindOfClass:[NUNetworkAPI class]]) return nil;
    
    NSString *requestUrl;

    if (baseURL.length>0) {
        requestUrl = baseURL;
    }
    else{
        requestUrl = [NSString stringWithFormat:@"%@%@",self.configuration.hostStr,[api requestPathUrl]];
    }

    return requestUrl;
}

- (id)requestParamsWithAPI:(NUNetworkAPI *)api {
    NSParameterAssert(api);
    
    return [api parameters];
}

#pragma mark -  AFHTTPSessionManager

- (AFHTTPSessionManager *)sessionManagerWithAPI:(NUNetworkAPI *)api {
    NSParameterAssert(api);
    
    // Request
    AFHTTPRequestSerializer *requestSerializer = [self requestSerializerForAPI:api];
    if (!requestSerializer) {
        // Serializer Error, just return;
        return nil;
    }
    
    // Response
    AFHTTPResponseSerializer *responseSerializer = [self responseSerializerForAPI:api];
    
    NSString *baseUrlStr = [self requestUrlStringWithAPI:api];
    if (baseUrlStr.length == 0) return nil;
    
    // AFHTTPSession
    NSString *key = [NSString stringWithFormat:@"%d", [api hash]];
    AFHTTPSessionManager *sessionManager;
    sessionManager = [self.sessionManagerCache objectForKey:api];
    if (!sessionManager) {
        NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        if (self.configuration) {
            sessionConfig.HTTPMaximumConnectionsPerHost = self.configuration.maxHttpConnectionPerHost;
        }
        else
        {
            sessionConfig.HTTPMaximumConnectionsPerHost = MAX_HTTP_CONNECTION_PER_HOST;
        }
        sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:baseUrlStr]
                                                  sessionConfiguration:sessionConfig];
        [self.sessionManagerCache setObject:sessionManager forKey:baseUrlStr];
    }
    
    sessionManager.requestSerializer     = requestSerializer;
    sessionManager.responseSerializer    = responseSerializer;
    sessionManager.securityPolicy        = [self securityPolicyWithAPI:api];
    
    return sessionManager;
}

- (AFSecurityPolicy *)securityPolicyWithAPI:(NUNetworkAPI *)api {
    NUSecurityPolicy *NU_securityPolicy = api.apiSecurityPolicy;
    NSUInteger pinningMode                  = NU_securityPolicy.SSLPinningMode;
    AFSecurityPolicy *af_securityPolicy        = [AFSecurityPolicy policyWithPinningMode:pinningMode];
    af_securityPolicy.allowInvalidCertificates = NU_securityPolicy.allowInvalidCertificates;
    af_securityPolicy.validatesDomainName      = NU_securityPolicy.validatesDomainName;
    af_securityPolicy.pinnedCertificates       = NU_securityPolicy.pinnedCertificates;
    
    return af_securityPolicy;
}

#pragma mark - Response
// 成功回调
- (void)handleSuccWithResponse:(id)responseObject andAPI:(NUNetworkAPI *)api {
    [self callAPICompletion:api obj:responseObject error:nil];
    
    [api preHandleSuccessReponse];
}
// 错误回调
- (void)handleFailureWithError:(NSError *)error andAPI:(NUNetworkAPI *)api {
    
    [api preHandleFailedReponse];
    
    if ([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorCancelled) {
        [self callAPICompletion:api obj:nil error:error];
        return;
    }
    
    [self callAPICompletion:api obj:nil error:error];
}

- (void)callAPICompletion:(NUNetworkAPI *)api
                      obj:(id)obj
                    error:(NSError *)error{
    
    if (error) {
        
        NU_DISPATCH_MAIN_SYNC(^{
            !api.failureBlock ?: api.failureBlock(error);
        });

        return;
    }
    
    obj = [api apiResponseObjReformer:obj andError:error];
    NSDictionary *validator = [api jsonValiator];
    if (validator) {
        BOOL isJsonValiat = [NUJSONValidator checkJSON:obj withValidator:validator];
        if (!isJsonValiat) {
            NSError *jsonError = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:-100 userInfo:@{@"message":@"jsondata is illegal"}];
            NU_DISPATCH_MAIN_SYNC(^{
                !api.failureBlock ?: api.failureBlock(jsonError);
            });
            return;
        }
    }
    
    if (![obj isKindOfClass:[NSError class]]) {
        NU_DISPATCH_MAIN_SYNC(^{
            !api.successBlock ?: api.successBlock(obj);
        });
    }
    else{
        NUNetworkLog(@"api request fail,\n api:%@,error=%@", api,obj);
        NU_DISPATCH_MAIN_SYNC(^{
            !api.failureBlock ?: api.failureBlock(obj);
        });
    }
    [api clearCompletionBlock];
}

#pragma mark - Send Batch Requests
- (void)sendBatchAPIRequests:(nonnull NUBatchRequestAPI *)apis {
    NSParameterAssert(apis);

    self.configuration = [NUNetworkConfig sharedInstance];
    
    dispatch_group_t batch_api_group = dispatch_group_create();
    __weak typeof(self) weakSelf = self;
    [apis.apiRequestsSet enumerateObjectsUsingBlock:^(id api, BOOL * stop) {
        dispatch_group_enter(batch_api_group);
        
        __strong typeof (weakSelf) strongSelf = weakSelf;
        AFHTTPSessionManager *sessionManager = [strongSelf sessionManagerWithAPI:api];
        if (!sessionManager) {
            *stop = YES;
            dispatch_group_leave(batch_api_group);
        }
        sessionManager.completionGroup = batch_api_group;
        
        [strongSelf _sendSingleAPIRequest:api
                       withSessionManager:sessionManager
                       andCompletionGroup:batch_api_group];
    }];
    dispatch_group_notify(batch_api_group, dispatch_get_main_queue(), ^{
        if (apis.delegate && [apis.delegate respondsToSelector:@selector(batchAPIRequestsDidFinished:)]) {
            [apis.delegate batchAPIRequestsDidFinished:apis];
        }
    });
}

#pragma mark - Send Request
- (void)sendAPIRequest:(nonnull NUNetworkAPI *)api {
    NSParameterAssert(api);

    NSAssert(self.configuration, @"Configuration Can not be nil");
    
    //此处使用串行队列，避免同时请求api导致竞争
    dispatch_async(api_task_single_queue(), ^{
        AFHTTPSessionManager *sessionManager = [self sessionManagerWithAPI:api];
        if (!sessionManager) {
            return;
        }
        [self _sendSingleAPIRequest:api withSessionManager:sessionManager];
    });
}

- (void)cancelAPIRequest:(nonnull NUNetworkAPI *)api {
    dispatch_async(api_task_single_queue(), ^{

        [self deleteAPICache:api];
        [self deleteRunningDownloadOperationForAPI:api];
        [api.sessionTask cancel];
        [api clearCompletionBlock];
    });
}

- (void)_sendSingleAPIRequest:(NUNetworkAPI *)api withSessionManager:(AFHTTPSessionManager *)sessionManager {
    [self _sendSingleAPIRequest:api withSessionManager:sessionManager andCompletionGroup:nil];
}

- (void)_sendSingleAPIRequest:(NUNetworkAPI *)api
           withSessionManager:(AFHTTPSessionManager *)sessionManager
           andCompletionGroup:(dispatch_group_t)completionGroup {
    
    NSParameterAssert(api);
    NSParameterAssert(sessionManager);
    
    
    NSString *requestUrlStr = [self requestUrlStringWithAPI:api];
    id requestParams        = [self requestParamsWithAPI:api];
    
    if ([self.sessionTasksCache objectForKey:@([api hash])]) {
        NSDictionary *userInfo = @{NSLocalizedFailureReasonErrorKey : @(NUErrorTypeFrequentRequest)};
        NSError *cancelError = [NSError errorWithDomain:NSURLErrorDomain
                                                   code:NSURLErrorCancelled
                                               userInfo:userInfo];
        
        NUNetworkLog(@"request error, frequenct reqeust, \n api:%@,\n url:%@", api, api.baseUrl);
        [self callAPICompletion:api obj:nil error:cancelError];
        if (completionGroup) {
            dispatch_group_leave(completionGroup);
        }
        return;
    }
	//网络是否连接
    BOOL isReachable = [self isNetworkRechabilityInHost:sessionManager.baseURL.host];
    if (!isReachable) {
        NUNetworkLog(@"network is unreachable");
        NSDictionary *userInfo = @{
                                   NSLocalizedFailureReasonErrorKey : @(NUErrorTypeNetworkUnReachable)
                                   };
        NSError *networkUnreachableError = [NSError errorWithDomain:NSURLErrorDomain
                                                               code:NSURLErrorCannotConnectToHost
                                                           userInfo:userInfo];
        [self callAPICompletion:api obj:nil error:networkUnreachableError];
        if (completionGroup) {
            dispatch_group_leave(completionGroup);
        }
        return;
    }
    
    
    //成功回调
    void (^successBlock)(NSURLSessionDataTask *task, id responseObject)
    = ^(NSURLSessionDataTask * task, id responseObject) {
        if (self.configuration.isNetworkingActivityIndicatorEnabled) {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        }
        
        [self handleSuccWithResponse:responseObject andAPI:api];
        
        [self deleteAPICache:api];
        
        if (completionGroup) {
            dispatch_group_leave(completionGroup);
        }
        
    };
    //失败回调
    void (^failureBlock)(NSURLSessionDataTask * task, NSError * error)
    = ^(NSURLSessionDataTask * task, NSError * error) {

        if (self.configuration.isNetworkingActivityIndicatorEnabled) {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        }
        
        
        [self handleFailureWithError:error andAPI:api];
        [self deleteAPICache:api];
        
        if (completionGroup) {
            dispatch_group_leave(completionGroup);
        }
    };
    //进度回调
    void (^apiProgressBlock)(NSProgress* progress) = ^(NSProgress* progress) {
        if (progress.totalUnitCount <= 0) {
            return;
        }
        !api.progressBlock ?: api.progressBlock(progress);
    };
    
    //    void (^apiProgressBlock)(NSProgress* progress)
    //        = api.apiProgressBlock ? ^(NSProgress* progress) {
    //              if (progress.totalUnitCount <= 0) {
    //                  return;
    //              }
    //            // crash#78修复，避免block执行时已被释放
    //            !api.apiProgressBlock ?: api.apiProgressBlock(progress);
    //          }
    //                               : nil;


//    NUNetworkLog(@"api request will be sent,\n api:%@", api);
    if ([[NSThread currentThread] isMainThread]) {
        [api requestWillBeSent];
    }
    else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [api requestWillBeSent];
        });
    }

    if (self.configuration.isNetworkingActivityIndicatorEnabled) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    }

    NSURLSessionDataTask* dataTask;
    switch ([api requestMethodType]) {
    case NURequestMethodTypeGET: {
        dataTask = [sessionManager GET:requestUrlStr
                            parameters:requestParams
                              progress:apiProgressBlock
                               success:successBlock
                               failure:failureBlock];
    } break;
    case NURequestMethodTypeDELETE: {
        dataTask = [sessionManager DELETE:requestUrlStr parameters:requestParams success:successBlock failure:failureBlock];
    } break;
    case NURequestMethodTypePATCH: {
        dataTask = [sessionManager PATCH:requestUrlStr parameters:requestParams success:successBlock failure:failureBlock];
    } break;
    case NURequestMethodTypePUT: {
        dataTask = [sessionManager PUT:requestUrlStr parameters:requestParams success:successBlock failure:failureBlock];
    } break;
    case NURequestMethodTypeHEAD: {
        dataTask = [sessionManager HEAD:requestUrlStr
                             parameters:requestParams
                                success:^(NSURLSessionDataTask* _Nonnull task) {
                                    if (successBlock) {
                                        successBlock(task, nil);
                                    }
                                }
                                failure:failureBlock];
    } break;
    case NURequestMethodTypePOST: {
        if (![api apiRequestConstructingBodyBlock]) {
            dataTask =
                [sessionManager POST:requestUrlStr
                          parameters:requestParams
                            progress:apiProgressBlock
                             success:successBlock
                             failure:failureBlock];
        }
        else {
            void (^block)(id<AFMultipartFormData> formData)
                = ^(id<AFMultipartFormData> formData) {
                      api.apiRequestConstructingBodyBlock((id<NUMultipartFormData>)formData);
                  };
            dataTask =
                [sessionManager POST:requestUrlStr
                                   parameters:requestParams
                    constructingBodyWithBlock:block
                                     progress:apiProgressBlock
                                      success:successBlock
                                      failure:failureBlock];
        }

    } break;
    default:
        dataTask = [sessionManager GET:requestUrlStr
                            parameters:requestParams
                              progress:apiProgressBlock
                               success:successBlock
                               failure:failureBlock];
        break;
    }
    if (dataTask) {
        api.sessionTask = dataTask;
        [self recordAPICache:api];
    }

   // NUNetworkLog(@"api request did sent,\n api:%@", api);
    if ([[NSThread currentThread] isMainThread]) {
        [api requestDidSent];
    }
    else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [api requestDidSent];
        });
    }
}

#pragma mark - download

- (void)sendDownloadAPIRequest:(NUNetworkAPI *)api {
    
    if (api.sessionTask && api.sessionTask.state == NSURLSessionTaskStateRunning) {
        NUNetworkLog(@"api task is still running");
        return;
    }
    
    dispatch_async(api_task_single_queue(), ^{
    
        //TODO: 需要设定缓存时间
        //指定路径下文件已存在不下载，直接回调
        NSFileManager *manager = [NSFileManager defaultManager];
        if ([manager fileExistsAtPath:api.downloadPath]) {
            
            NUNetworkLog(@"have a same file in local, file path:%@",api.downloadPath);
            
            api.successBlock ? api.successBlock([[NSURL alloc] initFileURLWithPath:api.downloadPath]) : nil;
            [api clearCompletionBlock];
            return;
        }
        
        NSString *method = [self methodNameWithType:api.requestMethodType];
        [self sessionConfigurationWithAPI:api];
        AFHTTPRequestSerializer *requestSerializer = [self requestSerializerForAPI:api];
        if (!requestSerializer) return;
        
        NSError *serializerError;
        NSMutableURLRequest *downloadReq = [requestSerializer requestWithMethod:method URLString:api.baseUrl parameters:api.parameters error:&serializerError];
        downloadReq.HTTPShouldUsePipelining = YES;
        if (serializerError) {
            NUNetworkLog(@"download requestserializer error: %@",serializerError);
            api.failureBlock ? api.failureBlock(serializerError) : nil;
            [api clearCompletionBlock];
            return;
        }
        
        NUNetworkLog(@"download url: %@",downloadReq.URL.absoluteString);
        NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
            [self p_resumeDownloadTaskForAPI:api withSessionManager:self.sessionManager request:downloadReq.mutableCopy resumeData:nil];
        }];
        [self.downloadQueue addOperation:operation];
        [self recordRunningDownloadOperation:operation forAPI:api];
    });
    
    /*
    dispatch_async(api_task_single_queue(), ^{
        //TODO: 需要设定缓存时间
        //指定路径下文件已存在不下载，直接回调
        NSFileManager* manager = [NSFileManager defaultManager];
        if ([manager fileExistsAtPath:api.apiDownloadPath]) {
            NUNetworkLog(@"have a same file in local, file path:%@", api.apiDownloadPath);
            api.successCompletionBlock ? api.successCompletionBlock([NSURL URLWithString:api.apiDownloadPath]) : nil;
            return;
        }

        NSString* method = [self methodNameWithType:api.apiRequestMethodType];

        NSURLSessionConfiguration* sessionConfiguration = [self sessionConfigurationWithAPI:api];
        //[self invalidateSessionManager];
        downloadSessionManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:sessionConfiguration];
        AFHTTPRequestSerializer* requestSerializer = [self requestSerializerForAPI:api];

        NSError* serializerError;
        NSMutableURLRequest* downloadReq = [requestSerializer requestWithMethod:method URLString:api.baseUrl parameters:api.requestParameters error:&serializerError];
        if (serializerError) {
            NUNetworkLog(@"download requestserializer error: %@", serializerError);
            api.failureCompletionBlock ? api.failureCompletionBlock(serializerError) : nil;
            return;
        }

        NUNetworkLog(@"download url: %@", downloadReq.URL.absoluteString);
        [self p_resumeDownloadTaskForAPI:api withSessionManager:downloadSessionManager request:downloadReq resumeData:nil];
    });
    */
}

- (void)suspendDownloadAPIRequest:(NUNetworkAPI *)api {
    
    if (api.sessionTask.state != NSURLSessionTaskStateRunning) {
        NUNetworkLog(@"task is not running");
        return;
    }
    
    [self deleteAPICache:api];
    NSURLSessionDownloadTask* task = (NSURLSessionDownloadTask*)api.sessionTask;
    [task cancelByProducingResumeData:^(NSData* _Nullable resumeData) {

        NSString *tempPath = [self tempDownloadPathForRequestAPI:api];
        NSFileManager* manager = [NSFileManager defaultManager];
        if ([manager fileExistsAtPath:tempPath]) {
            [manager removeItemAtPath:tempPath error:nil];
        }
        [resumeData writeToFile:tempPath atomically:YES];
    }];
}

- (void)resumeDownloadAPIRequest:(NUNetworkAPI *)api {
    
    if (api.sessionTask.state == NSURLSessionTaskStateRunning) {
         NUNetworkLog(@"api task is still running");
        return;
    }
    
    NSError *error;
    NSData *data = [NSData dataWithContentsOfFile:[self tempDownloadPathForRequestAPI:api] options:0 error:&error];
    [[NSFileManager defaultManager] removeItemAtPath:[self tempDownloadPathForRequestAPI:api]  error:nil];
    if (error) {
         NUNetworkLog(@"fetch resume data failed");
        api.failureBlock ? api.failureBlock(error) : nil;
        return;
    }
    NUNetworkLog(@"fetch resume data success, filepath : %@",[self tempDownloadPathForRequestAPI:api]);
    [self p_resumeDownloadWithAPI:api resumeData:data];
}

#pragma mark private download method
- (void)p_resumeDownloadWithAPI:(NUNetworkAPI *)api resumeData:(NSData *)data {
    
    [self sessionConfigurationWithAPI:api];
    if (self.backgroundSessionCofig) {
        self.sessionManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:self.backgroundSessionCofig];
    }
    
    [self p_resumeDownloadTaskForAPI:api withSessionManager:self.sessionManager request:nil resumeData:data];
}

- (void)p_resumeDownloadTaskForAPI:(NUNetworkAPI *)api
                withSessionManager:(AFURLSessionManager *)sessionManager
                           request:(NSURLRequest *)request
                        resumeData:(NSData *)data {
    NUNetworkLog(@"current thrad: %@", [NSThread currentThread]);
    NSString *urlString = [self requestUrlStringWithAPI:api];
    BOOL isReachable = [self isNetworkRechabilityInHost:[NSURL URLWithString:urlString].host];
    if (!isReachable) {
        NUNetworkLog(@"network is unreachable");
        NSDictionary *userInfo = @{
                                   NSLocalizedFailureReasonErrorKey : @(NUErrorTypeNetworkUnReachable)
                                   };
        NSError *networkUnreachableError = [NSError errorWithDomain:NSURLErrorDomain
                                                               code:NSURLErrorCannotConnectToHost
                                                           userInfo:userInfo];
        [self callAPICompletion:api obj:nil error:networkUnreachableError];
        return;
    }
    
    void (^downloadProgressBlock)(NSProgress *downloadProgress) = ^(NSProgress *downloadProgress) {
        
        if (api.progressBlock) { api.progressBlock(downloadProgress); }
    };
    NSURL *(^destination)(NSURL *, NSURLResponse *) = ^(NSURL * targetPath, NSURLResponse * response) {
        
        return [NSURL fileURLWithPath:api.downloadPath];
    };
    void (^completionHandler)(NSURLResponse* response, NSURL* filePath, NSError* error) = ^(NSURLResponse* response, NSURL* filePath, NSError* error) {
        if ([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorCancelled) {
            api.failureBlock ? api.failureBlock(error) : nil;
            //[self invalidateSessionManager];
            return;
        }
        [self handleSuccWithResponse:filePath andAPI:api];
        [self deleteAPICache:api];
        [self deleteRunningDownloadOperationForAPI:api];
        
        //[self invalidateSessionManager];
    };
    
    NSURLSessionDownloadTask *downloadTask;
    if (request) {
        NUNetworkLog(@"start download");
        downloadTask = [sessionManager downloadTaskWithRequest:request
                                                      progress:downloadProgressBlock
                                                   destination:destination
                                             completionHandler:completionHandler];
    }
    else if (data) {
        NUNetworkLog(@"resume download");
        downloadTask = [sessionManager downloadTaskWithResumeData:data
                                                         progress:downloadProgressBlock
                                                      destination:destination
                                                completionHandler:completionHandler];
    }

    api.sessionTask = downloadTask;
    [self recordAPICache:api];
    [downloadTask resume];
    sessionManager = nil;
    if ([[NSThread currentThread] isMainThread]) {
        [api requestDidSent];
    }
    else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [api requestDidSent];
        });
    }
}

- (NSString *)tempDownloadPathForRequestAPI:(NUNetworkAPI *)api {
    NSString *tempPath = [NSString stringWithFormat:@"%@.temp",api.downloadPath];
    return tempPath;
}

- (void)invalidateSessionManager {
    /*
     *  fix bug by nuclear
     *  https://github.com/AFNetworking/AFNetworking/issues/3546
     *  As discussed in the NSURLSession docs:
     *  The session object keeps a strong reference to the delegate until your app exits or explicitly invalidates the session. If you do not invalidate the session, your app leaks memory until it exits.
     *  You must call invalidateSessionCancelingTasks: in order to properly release the session manager, since NSURLSession maintains a strong reference to its delegate.
     **/
//    dispatch_async(api_task_single_queue(), ^{
//    pthread_mutex_lock(&mutex);
        if (downloadSessionManager) {
            [downloadSessionManager invalidateSessionCancelingTasks:YES];
            //downloadSessionManager = nil;
        }
//    pthread_mutex_unlock(&mutex);
//    });
}

#pragma mark - upload

- (void)sendUploadAPIRequest:(NUNetworkAPI *)api {
    NSAssert(api.apiRequestConstructingBodyBlock, @"\n %s line:%d apiRequestConstructingBodyBlock must not be nil",__PRETTY_FUNCTION__ , __LINE__);
    
    NSString *urlString = [self requestUrlStringWithAPI:api];
    BOOL isReachable = [self isNetworkRechabilityInHost:urlString];
    if (!isReachable) {
        NUNetworkLog(@"network is unreachable");
        NSDictionary *userInfo = @{
                                   NSLocalizedFailureReasonErrorKey : @(NUErrorTypeNetworkUnReachable)
                                   };
        NSError *networkUnreachableError = [NSError errorWithDomain:NSURLErrorDomain
                                                               code:NSURLErrorCannotConnectToHost
                                                           userInfo:userInfo];
        [self callAPICompletion:api obj:nil error:networkUnreachableError];
        return;
    }
    
    NSString *method = [self methodNameWithType:api.requestMethodType];
    
    [self sessionConfigurationWithAPI:api];
    if (self.backgroundSessionCofig) {
        self.sessionManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:self.backgroundSessionCofig];
    }
    AFHTTPRequestSerializer *requestSerializer = [self requestSerializerForAPI:api];
    if (!requestSerializer) return;
    
    __autoreleasing NSError *serializerError;
    
    void (^constructingDataBodyBlock)(id <AFMultipartFormData> formData)
    = ^(id <AFMultipartFormData> formData) {
        api.apiRequestConstructingBodyBlock ? api.apiRequestConstructingBodyBlock((id<NUMultipartFormData>)formData) : nil;
    };
    NSMutableURLRequest *uploadReq = [requestSerializer multipartFormRequestWithMethod:method URLString:api.baseUrl parameters:api.parameters constructingBodyWithBlock:constructingDataBodyBlock error:&serializerError];
    if (serializerError) {
        NUNetworkLog(@"serializerError failed, \n error: %@",serializerError);
        api.failureBlock ? api.failureBlock(serializerError) : nil;
        return;
    }
    
    NSURLSessionUploadTask *task = [self.sessionManager uploadTaskWithStreamedRequest:uploadReq progress:^(NSProgress * _Nonnull uploadProgress) {

        api.progressBlock ? api.progressBlock(uploadProgress) : nil;
    }
        completionHandler:^(NSURLResponse* _Nonnull response, id _Nullable responseObject, NSError* _Nullable error) {
            if (error) {
                NUNetworkLog(@"upload task failed, \n error: %@", error);
                api.failureBlock ? api.failureBlock(error) : nil;
                return;
            }
//            NUNetworkLog(@"upload task succeess");
            api.successBlock ? api.successBlock(responseObject) : nil;
        }];

    api.sessionTask = task;
    [self recordAPICache:api];
    NUNetworkLog(@"start upload task");
    [task resume];

    if ([[NSThread currentThread] isMainThread]) {
        [api requestDidSent];
    }
    else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [api requestDidSent];
        });
    }
}

#pragma mark - configure

- (BOOL)isNetworkRechabilityInHost:(NSString *)host {
    //网络是否连接
    SCNetworkReachabilityRef hostReachable = SCNetworkReachabilityCreateWithName(NULL, [host UTF8String]);
    SCNetworkReachabilityFlags flags;
    BOOL success = SCNetworkReachabilityGetFlags(hostReachable, &flags);

    bool isReachable = success && (flags & kSCNetworkFlagsReachable) && !(flags & kSCNetworkFlagsConnectionRequired);

    if (hostReachable) {
        CFRelease(hostReachable);
    }
    
    return isReachable;
}

- (void)sessionConfigurationWithAPI:(NUNetworkAPI *)api {
    if ([api supportBackgroundTask]) {
        NSString *identifier = [self requestAPIHashKey:api];
        self.backgroundSessionCofig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:identifier];
        self.backgroundSessionCofig.sessionSendsLaunchEvents = YES;
        self.backgroundSessionCofig.discretionary = YES;
    }
    if (self.configuration) {
        self.defaultSessionCofig.HTTPMaximumConnectionsPerHost = self.configuration.maxHttpConnectionPerHost;
        self.backgroundSessionCofig.HTTPMaximumConnectionsPerHost = self.configuration.maxHttpConnectionPerHost;
    } else {
        self.defaultSessionCofig.HTTPMaximumConnectionsPerHost = MAX_HTTP_CONNECTION_PER_HOST;
        self.backgroundSessionCofig.HTTPMaximumConnectionsPerHost = MAX_HTTP_CONNECTION_PER_HOST;
    }
}

- (NSString *)requestAPIHashKey:(NUNetworkAPI *)api {
    NSString *hashKey = [NSString stringWithFormat:@"com.NUNetworking.%lu",(unsigned long)[api hash]];
     NUNetworkLog(@"request hash key : %@", hashKey);
    return hashKey;
}

#pragma mark - record data

- (void)removeSessionManagerForAPI:(NUNetworkAPI *)api {
    
    NSString *key = [self requestUrlStringWithAPI:api];
    AFHTTPSessionManager *sessionManager = [self.sessionManagerCache objectForKey:key];
    if (!sessionManager) return;
    
    [sessionManager invalidateSessionCancelingTasks:YES];
    [self.sessionManagerCache removeObjectForKey:key];
}

- (void)recordAPICache:(NUNetworkAPI *)api {
     //NUNetworkLog(@"taskidentifer : %lu",(unsigned long)api.hash);
    [self.sessionTasksCache setObject:api.sessionTask forKey:@(api.hash)];
}

- (void)deleteAPICache:(NUNetworkAPI *)api  {
    if (!api) return;
    [self.sessionTasksCache removeObjectForKey:@(api.hash)];
}

- (void)recordRunningDownloadOperation:(NSOperation *)operation forAPI:(NUNetworkAPI *)api {
    [self.runningDownlodCache setObject:operation forKey:@(api.hash)];
}

- (void)deleteRunningDownloadOperationForAPI:(NUNetworkAPI *)api  {
    NSOperation *operation = [self.runningDownlodCache objectForKey:@(api.hash)];
    if (!operation) { return; }
    [operation cancel];
    [self.runningDownlodCache removeObjectForKey:@(api.hash)];
}

- (NSString *)methodNameWithType:(NURequestMethodType)type {
    NSString *method;
    switch (type) {
        case NURequestMethodTypeGET:
            method = @"GET";
            break;
        case NURequestMethodTypePOST:
            method = @"POST";
            break;
        case NURequestMethodTypeHEAD:
            method = @"HEAD";
            break;
        case NURequestMethodTypePUT:
            method = @"PUT";
            break;
        case NURequestMethodTypePATCH:
            method = @"PATCH";
            break;
        case NURequestMethodTypeDELETE:
            method = @"DELETE";
            break;
            
        default:
            method = @"GET";
            break;
    }
    
    return method;
}

@end

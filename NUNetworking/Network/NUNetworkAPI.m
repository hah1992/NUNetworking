//
//  NUNetworkBaseAPI.m
//  NUNetworkingDemo
//
//  Created by nuclear on 16/9/5.
//  Copyright © 2016年 nuclear. All rights reserved.
//

#import "NUNetworkAPI.h"
#import "NUNetworkAgent.h"

@interface NUNetworkAPI()
    
    @end

@implementation NUNetworkAPI
    
- (instancetype)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}
    
- (nullable NSString *)baseUrl{
    return @"";
}
    
- (nullable NSString *)requestPathUrl{
    return @"";
}
    
- (nullable id)parameters {
    return nil;
}
    
- (id)jsonValiator {
    return nil;
}
    
- (NURequestMethodType)requestMethodType{
    return NURequestMethodTypePOST;
}
    
- (NURequestSerializerType)requestSerializerType{
    return NURequestSerializerTypeJSON;
}
    
- (NUResponseSerializerType)responseSerializerType{
    return NUResponseSerializerTypeJSON;
}
    
- (NSURLRequestCachePolicy)requestCachePolicy{
    return NSURLRequestUseProtocolCachePolicy;
}
    
- (NSTimeInterval)timeoutInterval {
    return NU_API_REQUEST_TIME_OUT;
}
    
- (BOOL)supportBackgroundTask {
    return  NO;
}
    
- (id)uploadData {
    return nil;
}
    
- (NSString *)downloadPath {
    return @"";
}
    
- (nullable NSDictionary *)requestHTTPHeaderField {
    return @{
             @"Content-Type" : @"application/json; charset=utf-8",
             };
}
    
- (nullable NSSet *)responseAcceptableContentTypes {
    return [NSSet setWithObjects:
            @"text/json",
            @"text/html",
            @"application/json",
            @"text/javascript",
            @"application/javascript",nil];
}
    
- (NURequestNetworkAllowType)allowRequestInReachableCondition{
    return NURequestNetworkAllowTypeAll;
}
    
#pragma mark - prehandle
- (void)preHandleSuccessReponse {
    
}
    
- (void)preHandleFailedReponse {
    
}
    
#pragma mark - Security
    
- (nullable NSArray *)certificateName{
    return @[];
}
    
- (nonnull NUSecurityPolicy *)apiSecurityPolicy {
    NUSecurityPolicy *securityPolicy;
    if ([self certificateName].count>0) {
        securityPolicy = [NUSecurityPolicy policyWithCertificateName:[self certificateName]];
    }
    else{
#ifdef DEBUG
        securityPolicy = [NUSecurityPolicy policyWithPinningMode:NUSSLPinningModeNone];
#else
        securityPolicy = [NUSecurityPolicy policyWithPinningMode:NUSSLPinningModePublicKey];
#endif
        
    }
    return securityPolicy;
}
    
#pragma mark - Process
    
- (void)requestWillBeSent {
    
}
    
- (void)requestDidSent {
    self.beginRequestTime = CFAbsoluteTimeGetCurrent();
}
    
- (void)startWithSuccess:(NUAPISuccessHandler)success failure:(NUAPIFailHandler)failure {
    [self startWithSuccess:success failure:failure progress:nil];
}
    
- (void)startWithSuccess:(_Nonnull NUAPISuccessHandler)success
                 failure:(_Nonnull NUAPIFailHandler)failure
                progress:(_Nullable NUAPIProgressHandler)progress {
    self.successBlock = success;
    self.failureBlock = failure;
    self.progressBlock = progress;
    [[NUNetworkAgent sharedNetworkAgent] sendAPIRequest:self];
}
    
- (void)clearCompletionBlock {
    // nil out to break the retain cycle.
    self.successBlock = nil;
    self.failureBlock = nil;
    self.progressBlock = nil;
    self.apiRequestConstructingBodyBlock = nil;
}
    
    
- (void)startDownloadTaskWithSuccessHandler:(NUAPISuccessHandler)downloadSuccess
                              failedHandler:(NUAPIFailHandler)downloadFailed
                                   progress:(NUAPIProgressHandler)progress {
    
    self.successBlock = downloadSuccess;
    self.failureBlock = downloadFailed;
    self.progressBlock = progress;
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [[NUNetworkAgent sharedNetworkAgent] sendDownloadAPIRequest:self];
    });
    
}
    
- (void)suspendDownload {
    [[NUNetworkAgent sharedNetworkAgent] suspendDownloadAPIRequest:self];
}
    
- (void)resumeDownload {
    [[NUNetworkAgent sharedNetworkAgent] resumeDownloadAPIRequest:self];
}
    
- (void)startUploadTaskWithSuccessHandler:(NUAPISuccessHandler)downloadSuccess
                            failedHandler:(NUAPIFailHandler)downloadFailed
                                 progress:(NUAPIProgressHandler)progress {
    
    self.successBlock = downloadSuccess;
    self.failureBlock = downloadFailed;
    self.progressBlock = progress;
    
    [[NUNetworkAgent sharedNetworkAgent] sendUploadAPIRequest:self];
}
    
- (void)cancel {
    [[NUNetworkAgent sharedNetworkAgent] cancelAPIRequest:((NUNetworkAPI *)self)];
}
    
    
#pragma mark - Transfrom
- (nullable id)apiResponseObjReformer:(id)responseObject andError:(NSError * _Nullable)error{
    
    if (error) { return error;}
    return responseObject;
}
    
#pragma mark - private
- (NSUInteger)hash {
    NURequestSerializerType reqeustSerializer = [self requestSerializerType];
    NUResponseSerializerType reponseSerializer = [self responseSerializerType];
    
    NSString *hashStr = [NSString stringWithFormat:@"%lu, %lu , %lf", (unsigned long)reqeustSerializer, (unsigned long)reponseSerializer, [self timeoutInterval]];
    
    return [hashStr hash];
}
    
-(BOOL)isEqualToAPI:(NUNetworkAPI *)api {
    return [self hash] == [api hash];
}
    
- (BOOL)isEqual:(id)object {
    if (self == object) return YES;
    if (![object isKindOfClass:[NUNetworkAPI class]]) return NO;
    return [self isEqualToAPI:(NUNetworkAPI *) object];
}
    
- (NSString *)description {
    return [NSString stringWithFormat:@" --->\r %p claseeName: %@ \r BaseUrl:%@ \r request method:%@ \r requestParameters:%@ ",self,
            [self class],
            [self baseUrl],
            [self p_methodNameWithType:[self requestMethodType]],
            [self parameters]];
}
    
- (NSString *)p_methodNameWithType:(NURequestMethodType)type {
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

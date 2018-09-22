//
//  NUNetworkBaseAPI.h
//  NUNetworkingDemo
//
//  Created by nuclear on 16/9/5.
//  Copyright © 2016年 nuclear. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NUNetworkDefines.h"
#import "NUSecurityPolicy.h"
#import "NUNetworkConfig.h"

#pragma mark - NUMultipartFormData

@protocol NUMultipartFormData

- (BOOL)appendPartWithFileURL:(NSURL  * _Nonnull )fileURL
                         name:(NSString * _Nonnull)name
                        error:(NSError * _Nullable)error;

- (BOOL)appendPartWithFileURL:(NSURL * _Nonnull)fileURL
                         name:(NSString * _Nonnull)name
                     fileName:(NSString * _Nonnull)fileName
                     mimeType:(NSString * _Nonnull)mimeType
                        error:(NSError * _Nullable)error;
- (void)appendPartWithInputStream:(nullable NSInputStream *)inputStream
                             name:(NSString * _Nonnull)name
                         fileName:(NSString * _Nonnull)fileName
                           length:(int64_t)length
                         mimeType:(NSString * _Nonnull)mimeType;
- (void)appendPartWithFileData:(NSData * _Nonnull)data
                          name:(NSString * _Nonnull)name
                      fileName:(NSString * _Nonnull)fileName
                      mimeType:(NSString * _Nonnull)mimeType;

- (void)appendPartWithFormData:(NSData * _Nonnull)data
                          name:(NSString * _Nonnull)name;

- (void)appendPartWithHeaders:(nullable NSDictionary *)headers
                         body:(NSData * _Nonnull)body;

- (void)throttleBandwidthWithPacketSize:(NSUInteger)numberOfBytes
                                  delay:(NSTimeInterval)delay;

@end

@interface NUNetworkAPI : NSObject

/**
 *  请求成功回调
 *  responseObject: api 返回的数据结构
 */
typedef void (^NUAPISuccessHandler)(_Nonnull id responseObject);

@property (nonatomic, copy, nullable) NUAPISuccessHandler successBlock;

/**
 *  请求失败回调
 *  error:  api 返回的错误信息
 */
typedef void (^NUAPIFailHandler)(NSError * _Nonnull  error);

@property (nonatomic, copy, nullable) NUAPIFailHandler failureBlock;

/**
 *  下载进度回调
 *
 *  @param progress 当前下载进度百分比
 */
typedef void (^NUAPIProgressHandler)(NSProgress * _Nullable progress);

@property (nonatomic, copy, nullable) NUAPIProgressHandler progressBlock;

/**
 *  用于组织MultipartFormData POST的block，不能与 -apiDownloadPath 同时存在
 */
@property (nonatomic, copy, nullable) void (^apiRequestConstructingBodyBlock)(id<NUMultipartFormData> _Nonnull formData);

/**
 *  当前正在执行的 sessionTask
 */
@property (nonatomic, strong, nonnull) NSURLSessionTask *sessionTask;

/**
 *  开始请求时的时间
 */
@property (nonatomic, assign) CFAbsoluteTime beginRequestTime;



#pragma mark - URL and Parameters
/**
 *  baseURL
 *  @warning 如果API子类有设定baseURL, 则Config里的hostStr不起作用
 *  需要覆盖（need override）
 */
- (nullable NSString *)baseUrl;

/**
 *  requestPathUrl用于和NUNetworkConfig中的hostStr一起使用，完整整个请求链接的拼接
 *  即URL ＝ hostStr ＋requestPathUrl，如果NUNetworkBaseAPI的子类覆盖baseUrl，则请求链接以baseUrl为准
 *
 *  @return 请求链接的拼接路径
 */
- (nullable NSString *)requestPathUrl;

/**
 *  用户api请求中的参数列表
 *  需要覆盖（need override）
 *  @return 一般来说是NSDictionary
 */
- (nullable id)parameters;

/**
 *  JSON格式校验
 *
 *  @return 标准JSON格式
 */
- (nullable id)jsonValiator;

#pragma mark - Request and Response
/**
 *  网络请求的类型
 *  @default NURequestMethodTypePOST
 *
 *  @return NURequestMethodType
 */
- (NURequestMethodType)requestMethodType;

/**
 *  Request 序列化类型
 *  @default NUResponseSerializerTypeJSON
 *
 *  @return NURequestSerializerType
 */
- (NURequestSerializerType)requestSerializerType;


/**
 *  HTTP 请求的Cache策略
 *  @default NSURLRequestUseProtocolCachePolicy
 *
 *  @return NSURLRequestCachePolicy
 */
- (NSURLRequestCachePolicy)requestCachePolicy;


/**
 *  HTTP 请求超时的时间
 *  @default NU_API_REQUEST_TIME_OUT
 *
 *  @return 超时时间
 */
- (NSTimeInterval)timeoutInterval;

/**
 *  HTTP 请求的头部区域自定义
 *  @default
 *   默认为：@{
 *               @"Content-Type" : @"application/json; charset=utf-8"
 *           }
 *
 *  @return NSDictionary
 */
- (nullable NSDictionary *)requestHTTPHeaderField;

/**
 *  HTTP 请求的返回可接受的内容类型
 *  @default
 *   默认为：[NSSet setWithObjects:
 *            @"text/json",
 *            @"text/html",
 *            @"application/json",
 *            @"text/javascript", nil];
 *
 *  @return NSSet
 */
- (nullable NSSet *)responseAcceptableContentTypes;

/**
 *  Response 序列化类型
 *  @default NUResponseSerializerTypeJSON
 *
 *  @return NUResponseSerializerType
 */
- (NUResponseSerializerType)responseSerializerType;

#pragma mark - download & upload

/**
 *  是否支持后台上传下载
 */
- (BOOL)supportBackgroundTask;

/**
 *  下载数据存放的路径，
 *
 *  @warning 不能与 apiRequestConstructingBodyBlock 同时存在，如果都存在默认下载，不执行上传
 *
 *  @return 存放路径
 */
- (nonnull NSString *)downloadPath;

/**
 *  HTTP 请求网络允许状态类型，某些操作消耗流量较大，只希望在WiFi下请求
 *
 *  @return 允许网络请求的状态
 */
- (NURequestNetworkAllowType)allowRequestInReachableCondition;

#pragma mark - Security

/**
 *  本地证书名称，需要将cer文件放在主Bundle中
 *
 *  @return 证书名称
 */
- (nullable NSArray *)certificateName;


/**
 *  HTTPS 请求的Security策略
 *
 *  @return HTTPS证书验证策略
 */
- (nonnull NUSecurityPolicy *)apiSecurityPolicy;

#pragma mark - Process

/**
 *  API 即将被Sent
 */
- (void)requestWillBeSent;

/**
 *  API 已经被Sent
 */
- (void)requestDidSent;

/**
 *  开始网络请求，并传入成功和失败回调方法
 *
 *  @param success  请求成功回调
 *  @param failure  请求失败回调
 *
 */
- (void)startWithSuccess:(_Nonnull NUAPISuccessHandler)success
                             failure:(_Nonnull NUAPIFailHandler)failure;

/**
 *  开始网络请求，并传入成功和失败回调方法
 *
 *  @param success  请求成功回调
 *  @param failure  请求失败回调
 *  @param progress 请求进度回调
 *
 */
- (void)startWithSuccess:(_Nonnull NUAPISuccessHandler)success
                             failure:(_Nonnull NUAPIFailHandler)failure
                            progress:(_Nullable NUAPIProgressHandler)progress;

/**
 *  取消网络请求
 */
- (void)cancel;

/**
 *  暂停下载，支持断点下载，需要重写 -downloadPath 方法，指定下载路径
 */
- (void)suspendDownload;

/**
 *  继续下载，支持断点下载，需要重写 -apiDownloadPath 方法，指定下载路径
 */
- (void)resumeDownload;

/**
 *  清除complettionHandle & errorHandle
 */
- (void)clearCompletionBlock;

/**
 *  开启下载任务的简便方法
 *
 *  @param downloadCompletion 下载成功回调block
 *  @param downloadfailed     下载失败回调block
 *  @param progress           下载进度回调block
 */
- (void)startDownloadTaskWithSuccessHandler:(nullable NUAPISuccessHandler)downloadSuccess
                              failedHandler:(nullable NUAPIFailHandler)downloadFailed
                                   progress:(nullable NUAPIProgressHandler)progress;

/**
 *  开启上传任务的简便方法
 *
 *  @param downloadCompletion 上传成功回调block
 *  @param downloadfailed     上传失败回调block
 *  @param progress           上传进度回调block
 */
- (void)startUploadTaskWithSuccessHandler:(nullable NUAPISuccessHandler)downloadSuccess
                            failedHandler:(nullable NUAPIFailHandler)downloadFailed
                                 progress:(nullable NUAPIProgressHandler)progress;
								 
#pragma mark - Transform
/**
 *  从网络获得的原始数据转换成符合UI/Model层需要的数据结构
 *
 *  @param responseObject 原始数据
 *  @param error  错误信息
 *
 *  @return 转换完成的数据对象
 */
- (nullable id)apiResponseObjReformer:(id _Nullable)responseObject andError:(NSError * _Nullable)error;


/**
 子类覆写，用于请求成功后回调还没有返回之前的逻辑处理
 */
- (void)preHandleSuccessReponse;

/**
 子类覆写，用于请求失败后回调还没有返回之前的逻辑处理
 */
- (void)preHandleFailedReponse;

@end

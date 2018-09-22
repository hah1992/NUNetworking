//
//  NUNetworkingAgent.h
//  NUNetworkingDemo
//
//  Created by nuclear on 16/9/5.
//  Copyright © 2016年 nuclear. All rights reserved.
//


/**
 *  Agent 中负责调用AFNetworking 对象，未来如果需要替换底层网络库只需修改此文件
 */

#import <Foundation/Foundation.h>

@class NUNetworkAPI;
@class NUNetworkConfig;
@class NUBatchRequestAPI;

@interface NUNetworkAgent : NSObject

@property (nonatomic, strong, nonnull) NUNetworkConfig *configuration;

+ (nullable NUNetworkAgent *)sharedNetworkAgent;

+ (void)jsonValidatorDebugOpen:(BOOL)isOpen;

/**
 *  发送API请求
 *
 *  @param api 要发送的api
 */
- (void)sendAPIRequest:(nonnull NUNetworkAPI  *)api;

/**
 *  取消API请求
 *
 *  @description
 *      如果该请求已经发送或者正在发送，则无法取消
 *
 *  @param api 要取消的api
 */
- (void)cancelAPIRequest:(nonnull NUNetworkAPI  *)api;

/**
 *  发送一系列API请求
 *
 *  @param apis 待发送的API请求集合
 */
- (void)sendBatchAPIRequests:(nonnull NUBatchRequestAPI *)apis;

/**
 *  发送下载请求
 *
 *  @param api 需要重写 - apiDownloadPath
 */
- (void)sendDownloadAPIRequest:(nonnull __kindof NUNetworkAPI *)api;

/**
 *  暂停下载
 *
 *  @param api 需要重写 - apiDownloadPath
 */
- (void)suspendDownloadAPIRequest:(nonnull __kindof NUNetworkAPI *)api;

/**
 *  继续下载
 *
 *  @param api 需要重写 - apiDownloadPath
 */
- (void)resumeDownloadAPIRequest:(nonnull __kindof NUNetworkAPI *)api;

/**
 *  上传请求
 *
 *  @param api 重写 - constructingUploadDataBodyBlock 方法，构建上传参数
 */
- (void)sendUploadAPIRequest:(nonnull __kindof NUNetworkAPI *)api;

@end

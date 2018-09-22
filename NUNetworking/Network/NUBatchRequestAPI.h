//
//  NUBatchRequestAPI.h
//  NUNetworkingDemo
//
//  Created by 黄安华 on 16/9/7.
//  Copyright © 2016年 nuclear. All rights reserved.
//

#import <Foundation/Foundation.h>
@class NUNetworkAPI;
@class NUBatchRequestAPI;

@protocol NUBatchAPIRequestsProtocol <NSObject>

/**
 *  Batch Requests 全部调用完成之后调用
 *
 *  @param batchApis batchApis
 */
- (void)batchAPIRequestsDidFinished:(nonnull NUBatchRequestAPI *)batchApis;

@end

@interface NUBatchRequestAPI : NSObject

@property (nonatomic, strong,readonly,nullable) NSMutableSet *apiRequestsSet;

/**
 *  Batch Requests 执行完成之后调用的delegate
 */
@property (nonatomic, weak, nullable) id<NUBatchAPIRequestsProtocol> delegate;

/**
 *  将API 加入到BatchRequest Set 集合中
 *
 *  @param api
 */
- (void)addAPIRequest:(nonnull NUNetworkAPI *)api;

/**
 *  将带有API集合的Sets 赋值
 *
 *  @param apis
 */
- (void)addBatchAPIRequests:(nonnull NSSet *)apis;

/**
 *  开启API 请求
 */
- (void)start;
@end

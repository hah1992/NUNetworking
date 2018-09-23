//
//  NUNetworkConfig.h
//  NUNetworkingDemo
//
//  Created by 黄安华 on 16/9/5.
//  Copyright © 2016年 nuclear. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NUNetworkConfig : NSObject

/**
 *  统一设置请求的Host
 */
@property (nonatomic, copy, nullable) NSString *hostStr;

/**
 *  UserAgent
 */
@property (nonatomic, copy, nullable) NSString *userAgent;

/**
 *  每个Host的最大连接数
 */
@property (nonatomic, assign) NSUInteger maxHttpConnectionPerHost;

/**
 *  NetworkingActivityIndicator
 *  默认 NO
 */
@property (nonatomic, assign) BOOL isNetworkingActivityIndicatorEnabled;

+ ( NUNetworkConfig * _Nonnull )sharedInstance;

@end

//
//  NUSecurityPolicy.h
//  NUNetworkingDemo
//
//  Created by nuclear on 16/9/5.
//  Copyright © 2016年 nuclear. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NUNetworkDefines.h"

@interface NUSecurityPolicy : NSObject

/**
 *  SSL Pinning证书的校验模式
 *  默认为 NUSSLPinningModeNone
 */
@property (readonly, nonatomic, assign) NUSSLPinningMode SSLPinningMode;

/**
 *  是否允许使用Invalid 证书
 *  默认为 NO
 */
@property (nonatomic, assign) BOOL allowInvalidCertificates;

/**
 *  是否校验在证书 CN 字段中的 domain name
 *  默认为 YES
 */
@property (nonatomic, assign) BOOL validatesDomainName;

/**
 *  使用SSL pinning mode时，校验本地证书
 */
@property (nonatomic, copy, nullable) NSSet <NSData *> *pinnedCertificates;

/**
 *  创建新的SecurityPolicy
 *
 *  @param pinningMode 证书校验模式
 *
 *  @return 新的SecurityPolicy
 */
+ (instancetype _Nonnull)policyWithPinningMode:(NUSSLPinningMode)pinningMode;

/**
 *  使用NUSSLPinningModeCertificate模式，在主Bundle中获取cer对比校验服务器证书和本地证书一致性
 *
 *  @param nameArray 本地服务器证书
 *
 *  @return 新的SecurityPolicy
 */
+ (instancetype _Nonnull)policyWithCertificateName:(NSArray *_Nullable)nameArray;

@end

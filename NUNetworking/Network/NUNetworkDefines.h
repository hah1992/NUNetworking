//
//  NUNetworkDefines.h
//  NUNetworkingDemo
//
//  Created by nuclear on 16/9/5.
//  Copyright © 2016年 nuclear. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "NUNetworkLog.h"

// 网络请求类型
typedef NS_ENUM(NSUInteger, NURequestMethodType) {
    NURequestMethodTypeGET     = 0,
    NURequestMethodTypePOST    = 1,
    NURequestMethodTypeHEAD    = 2,
    NURequestMethodTypePUT     = 3,
    NURequestMethodTypePATCH   = 4,
    NURequestMethodTypeDELETE  = 5
};

// 请求的序列化格式
typedef NS_ENUM(NSUInteger, NURequestSerializerType) {
    NURequestSerializerTypeHTTP    ,
    NURequestSerializerTypeJSON    ,
    NURequestSerializerTypePLIST
};

// 请求返回的序列化格式
typedef NS_ENUM(NSUInteger, NUResponseSerializerType) {
    NUResponseSerializerTypeHTTP    ,
    NUResponseSerializerTypeJSON    ,
    NUResponseSerializerTypeXML     ,
    NUResponseSerializerTypeIMAGE   ,
    NUResponseSerializerTypePLIST
};

// 错误类型
typedef NS_ENUM(NSUInteger, NUErrorType) {
    NUErrorTypeFrequentRequest = 0,    //频繁发送同一个请求
    NUErrorTypeNetworkUnReachable,     //网络无法访问
    NUErrorTypeReponseJSONFormat,      //返回JSON数据格式错误
};

// 网络请求允许访问类型
typedef NS_ENUM(NSUInteger, NURequestNetworkAllowType) {
    NURequestNetworkAllowTypeAll  = 1<<0,      //所有网络类型都允许访问
    NURequestNetworkAllowTypeWiFi = 1<<1,      //WiFi
    NURequestNetworkAllowType4G   = 1<<2,     //4G
    NURequestNetworkAllowType3G   = 1<<3     //3G
    
};


/**
 *  SSL Pinning
 */
typedef NS_ENUM(NSUInteger, NUSSLPinningMode) {
    /**
     *  不校验Pinning证书
     */
    NUSSLPinningModeNone,
    /**
     *  校验Pinning证书中的PublicKey.
     *  知识点可以参考
     *  https://en.wikipedia.org/wiki/HTTP_Public_Key_Pinning
     */
    NUSSLPinningModePublicKey,
    /**
     *  校验整个Pinning证书
     */
    NUSSLPinningModeCertificate,
};

// 默认的请求超时时间
#define NU_API_REQUEST_TIME_OUT 30
#define MAX_HTTP_CONNECTION_PER_HOST 5




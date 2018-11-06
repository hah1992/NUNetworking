//
//  TestAPI2.m
//  NUNetworking
//
//  Created by Huang,Anhua on 2018/11/6.
//  Copyright © 2018年 nuclear. All rights reserved.
//

#import "TestAPI2.h"

@implementation TestAPI2

- (NSString *)requestPathUrl {
    return @"weatherApi";
}

- (id)parameters {
    return @{
             @"city": _city ?: @""
             };
}

- (NURequestMethodType)requestMethodType {
    return NURequestMethodTypeGET;
}

- (id)jsonValiator {
    return @{
             @"data": @{
                     @"aqi": [NSString class],
                     @"city": [NSString class],
                     @"forecast": @[
                             @{
                                 @"date": [NSString class],
                                 @"fengxiang": [NSString class]
                                 }
                             ]
                     }
             };
}

@end

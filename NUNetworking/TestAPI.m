//
//  TestAPI.m
//  NUNetworking
//
//  Created by 黄安华 on 23/9/18.
//  Copyright © 2018年 nuclear. All rights reserved.
//

#import "TestAPI.h"

@implementation TestAPI {}

- (NSString *)baseUrl {
    return @"https://www.apiopen.top/weatherApi";
}

- (id)parameters {
    return @{
             @"city": _city ?: @""
             };
}

- (NURequestMethodType)requestMethodType {
    return NURequestMethodTypeGET;
}

@end

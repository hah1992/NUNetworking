//
//  NUNetworkConfig.m
//  NUNetworkingDemo
//
//  Created by nuclear on 16/9/5.
//  Copyright © 2016年 nuclear. All rights reserved.
//

#import "NUNetworkConfig.h"
#import "NUNetworkDefines.h"

@implementation NUNetworkConfig


+ (NUNetworkConfig *)sharedInstance {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.isNetworkingActivityIndicatorEnabled = NO;
        self.maxHttpConnectionPerHost             = MAX_HTTP_CONNECTION_PER_HOST;
    }
    return self;
}


@end

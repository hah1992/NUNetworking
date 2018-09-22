//
//  NUBatchRequestAPI.m
//  NUNetworkingDemo
//
//  Created by 黄安华 on 16/9/7.
//  Copyright © 2016年 nuclear. All rights reserved.
//

#import "NUBatchRequestAPI.h"
#import "NUNetworkAPI.h"
#import "NUNetworkAgent.h"

static  NSString * const hint = @"API should be kind of NUNetworkBaseAPI";

@interface NUBatchRequestAPI ()

@property (nonatomic, strong, readwrite) NSMutableSet *apiRequestsSet;

@end

@implementation NUBatchRequestAPI

#pragma mark - Init
- (instancetype)init {
    self = [super init];
    if (self) {
        self.apiRequestsSet = [NSMutableSet set];
    }
    return self;
}

#pragma mark - Add Requests
- (void)addAPIRequest:(NUNetworkAPI *)api {
    NSParameterAssert(api);
    NSAssert([api isKindOfClass:[NUNetworkAPI class]],hint);
    if ([self.apiRequestsSet containsObject:api]) {
        NUNetworkLog(@"Add SAME API into BatchRequest set");
    }
    
    [self.apiRequestsSet addObject:api];
}

- (void)addBatchAPIRequests:(NSSet *)apis {
    NSParameterAssert(apis);
    NSAssert([apis count] > 0, @"Apis amounts should greater than ZERO");
    [apis enumerateObjectsUsingBlock:^(id  obj, BOOL *stop) {
        if ([obj isKindOfClass:[NUNetworkAPI class]]) {
            [self.apiRequestsSet addObject:obj];
        } else {
            __unused NSString *hintStr = [NSString stringWithFormat:@"%@ %@",
                                          [[obj class] description],
                                          hint];
            NSAssert(NO, hintStr);
            return ;
        }
    }];
}

- (void)start {
    NSAssert([self.apiRequestsSet count] != 0, @"Batch API Amount can't be 0");
    [[NUNetworkAgent sharedNetworkAgent] sendBatchAPIRequests:self];
}

@end

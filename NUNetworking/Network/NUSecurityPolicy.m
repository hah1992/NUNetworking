//
//  NUSecurityPolicy.m
//  NUNetworkingDemo
//
//  Created by nuclear on 16/9/5.
//  Copyright © 2016年 nuclear. All rights reserved.
//

#import "NUSecurityPolicy.h"

static NSSet *certSetArray;

@interface NUSecurityPolicy ()

@property (readwrite, nonatomic, assign) NUSSLPinningMode SSLPinningMode;

@end


@implementation NUSecurityPolicy


- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    self.validatesDomainName = NO;
    
    return self;
}

+ (instancetype)policyWithPinningMode:(NUSSLPinningMode)pinningMode {
    NUSecurityPolicy *securityPolicy = [[self alloc] init];
    if (securityPolicy) {
        securityPolicy.SSLPinningMode           = pinningMode;
#ifdef DEBUG
        securityPolicy.allowInvalidCertificates = YES;
#else
        securityPolicy.allowInvalidCertificates = NO;
#endif
        securityPolicy.validatesDomainName      = NO;
    }
    return securityPolicy;
}

+ (instancetype)policyWithCertificateName:(NSArray *)nameArray{
    NUSecurityPolicy *securityPolicy = [[self alloc] init];
    if (securityPolicy) {
        securityPolicy.SSLPinningMode           = NUSSLPinningModeCertificate;
#ifdef DEBUG
        securityPolicy.allowInvalidCertificates = YES;
#else
        securityPolicy.allowInvalidCertificates = NO;
#endif
        securityPolicy.validatesDomainName      = NO;
        
        if (!certSetArray) {
            NSMutableSet *certSet = [[NSMutableSet alloc] init];
            if (nameArray && nameArray.count>0) {
                for (NSString *cerName in nameArray) {
                    NSString *certFilePath = [[NSBundle mainBundle] pathForResource:cerName ofType:@"der"];
                    NSData *certData = [NSData dataWithContentsOfFile:certFilePath];
                    if (!certData) continue;
                    [certSet addObject:certData];
                }
            }
            certSetArray = certSet.copy;
        }
        securityPolicy.pinnedCertificates = certSetArray;
    }
    return securityPolicy;
}

@end

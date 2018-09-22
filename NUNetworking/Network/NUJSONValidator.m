//
//  NUJSONValidator.m
//  iPhoneNews
//
//  Created by 黄安华 on 16/10/14.
//  Copyright © 2016年 nuclear. All rights reserved.
//

#import "NUJSONValidator.h"
#import "NUNetworkLog.h"
#import <UIKit/UIKit.h>

static NSString *const NUNetworkJSONErrorDomain = @"com.NUNetworking.jsonerrordomain";

static BOOL jsonDEBUG;
@implementation NUJSONValidator

+ (void)debugOpen:(BOOL)isAllow {
    jsonDEBUG = isAllow;
}

+ (BOOL)checkJSON:(id)json withValidator:(id)validatorJson {
    
    //只有字典和数组才需要遍历判断，如果是无包裹的数据类型（NSString， NSValue等）直接判断，遍历一层后递归操作。
    if ([json isKindOfClass:[NSDictionary class]] &&
        [validatorJson isKindOfClass:[NSDictionary class]]) {
        NSDictionary * dict = json;
        NSDictionary * validator = validatorJson;
        BOOL result = YES;
        NSEnumerator * enumerator = [validator keyEnumerator];
        NSString * key;
        while ((key = [enumerator nextObject]) != nil) {
            id value = dict[key];
            id format = validator[key];
            if ([value isKindOfClass:[NSDictionary class]]
                || [value isKindOfClass:[NSArray class]]) {
                result = [self checkJSON:value withValidator:format];
                if (!result) {
                    break;
                }
            }
            else {
                if ([value isKindOfClass:format] == NO &&
                    [value isKindOfClass:[NSNull class]] == NO) {
                    result = NO;
                    
                    // JSON DEBUG
                    if (jsonDEBUG) {
                        [self showDEBUGAlertWithDict:dict key:key format:format];
                    }
                    
                    break;
                }
            }
        }
        return result;
    }
    else if ([json isKindOfClass:[NSArray class]] &&
             [validatorJson isKindOfClass:[NSArray class]]) {
        
        NSArray* validatorArray = (NSArray*)validatorJson;
        if (validatorArray.count > 0) {
            NSArray * array = json;
            id validator = validatorJson[0];
            for (id item in array) {
                BOOL result = [self checkJSON:item withValidator:validator];
                if (!result) {
                    return NO;
                }
            }
        }
        return YES;
    }
    else if ([json isKindOfClass:validatorJson]) {
        return YES;
    }
    else {
        return NO;
    }
}



#pragma mark - private

+ (void)showDEBUGAlertWithDict:(NSDictionary *)dict key:(NSString *)key format:(id)format {
    NSString *msg;
    
    id value = dict[key];
    NSArray *jsonKeys = dict.allKeys;
    
    if (![jsonKeys containsObject:key])
    {
        NUNetworkLog(@"======== json validate failed， rason： key %@ in json not found =========", key);
        
        msg = [NSString stringWithFormat:@"找不到key：%@", key];
    }
    else if ([value isKindOfClass:format] == NO)
    {
        NUNetworkLog(@"======== json validate failed， rason： 类型错误: key: %@, 正确：%@, 实际：%@  =========", key, NSStringFromClass((Class)format), [value class]);
        
        msg = [NSString stringWithFormat:@"类型错误: key: %@, 正确：%@, 实际：%@", key, NSStringFromClass((Class)format), [value class]];
    }
    
    [self showDEBUGAlertWithMessage:msg];
}

+ (void)showDEBUGAlertWithMessage:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"json格式错误" message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *confirm = [UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:confirm];
    
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
}


@end

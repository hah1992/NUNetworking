//
//  NUJSONValidator.h
//  iPhoneNews
//
//  Created by 黄安华 on 16/10/14.
//  Copyright © 2016年 nuclear. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NUJSONValidator : NSObject
id NUJSONObjectNormalizingNullStringValues(id JSONObject, NSJSONReadingOptions readingOptions);

+ (void)debugOpen:(BOOL)isAllow;
+ (BOOL)checkJSON:(id)json withValidator:(id)validatorJson;

@end

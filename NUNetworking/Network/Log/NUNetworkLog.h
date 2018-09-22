//
//  NUNetworkLog.h
//  iPhoneNews
//
//  Created by nuclear on 16/9/21.
//  Copyright © 2016年 nuclear. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef DEBUG
    #define NUNetworkLog(f, ...)                            \
    do                                        \
    {                                        \
        if([[NUNetworkLog sharedInstance] isLogNeeded])                            \
            [[NUNetworkLog sharedInstance]logWithFile:[[NSString stringWithUTF8String:__FILE__] lastPathComponent] line:__LINE__ params:(f), ##__VA_ARGS__];    \
        else                                    \
            NSLog((f), ##__VA_ARGS__);                \
    }while(0)
#else
    #define NUNetworkLog(f, ...)
#endif

#define kMaxLogTimesToFlush 10

@interface NUNetworkLog : NSObject

@property (nonatomic,assign) NSUInteger logTimes;

+ (NUNetworkLog*)sharedInstance;
- (NSString*)filePath;
- (BOOL)isLogNeeded;
- (BOOL)openFile;
- (void)closeFile;
- (void)logWithFile:(NSString *)file line:(NSUInteger)line params:(NSString *)format, ... ;

@end

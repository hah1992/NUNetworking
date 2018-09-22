//
//  NUNetworkLog.m
//  iPhoneNews
//
//  Created by nuclear on 16/9/21.
//  Copyright © 2016年 nuclear. All rights reserved.
//

#import "NUNetworkLog.h"
#import <UIKit/UIKit.h>

static NUNetworkLog *SharedLog = nil;
FILE *sn_Logfile = nil;
static dispatch_queue_t api_task_single_queue;

@implementation NUNetworkLog

+ (NUNetworkLog *)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SharedLog = [[self alloc] init];
    });
    return SharedLog;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _logTimes = 0;
        api_task_single_queue=dispatch_queue_create("com.nuclear.log.single.task", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (NSString *)filePath {
    NSString *path = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask, YES);
    if (paths.count > 0) {
        path = [paths objectAtIndex:0];
    }
    return [NSString stringWithFormat:@"%@/log.txt", path];
}

- (BOOL)isLogNeeded {
    return ![[UIDevice currentDevice].model isEqualToString:@"iPad Simulator"];
}

- (void)logWithFile:(NSString *)file line:(NSUInteger)line params:(NSString *)format, ... {
    
    va_list ap;
    NSString *logStr;
    va_start(ap, format);
    logStr = [[NSString alloc] initWithFormat:format arguments:ap];
    va_end(ap);

    fprintf(stderr,"%s:%ld\t%s\n",[file UTF8String], line, [logStr UTF8String]);
    
    if (![[NUNetworkLog sharedInstance] openFile]) {
        return;
    }
    fprintf(sn_Logfile, "%s\n", [logStr UTF8String]);
    
    dispatch_async(api_task_single_queue, ^{
        self->_logTimes++;
        if (self->_logTimes == kMaxLogTimesToFlush) {
            fflush(sn_Logfile);
            self->_logTimes = 0;
        }
    });
}

- (BOOL)openFile {
    if (sn_Logfile == nil) {
        sn_Logfile = fopen([[[NUNetworkLog sharedInstance] filePath] UTF8String], "a＋");
    }
    return sn_Logfile != nil;
}

- (void)closeFile {
    if (sn_Logfile) {
        fflush(sn_Logfile);
        fclose(sn_Logfile);
        sn_Logfile = nil;
    }
}

- (void)dealloc {
    [[NUNetworkLog sharedInstance] closeFile];
}
@end

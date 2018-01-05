//
//  GMRequestFile.m
//  GMNetworkService
//
//  Created by Good Man on 2017/6/7.
//  Copyright © 2017年 Good Man. All rights reserved.
//

#import "GMRequestFile.h"

@implementation GMRequestFile
- (id)initWithFileName:(NSString *) fileName keyName:(NSString *) keyName data:(NSData *) data miniType:(NSString *) mini
{
    self=[self init];
    if (self) {
        self.fileName=fileName;
        self.keyName=keyName;
        self.data=data;
        self.miniType=mini;
    }
    return self;
}

- (id)initWithFileName:(NSString *)fileName keyName:(NSString *)keyName filePath:(NSString *)filePath miniType:(NSString *)mini {
    self=[self init];
    if (self) {
        self.fileName=fileName;
        self.keyName=keyName;
        self.filePath=filePath;
        self.miniType=mini;
    }
    return self;
}

- (NSData *)data {
    if (!_data && self.filePath.length>0) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.filePath]) {
            _data=[NSData dataWithContentsOfFile:self.filePath];
        }
    }
    return _data;
}

@end

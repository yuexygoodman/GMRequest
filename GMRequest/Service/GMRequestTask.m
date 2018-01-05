//
//  GMRequestTask.m
//  GMRequestService
//
//  Created by 岳潇洋 on 2017/5/17.
//  Copyright © 2017年 岳潇洋. All rights reserved.
//

#import "GMRequestTask.h"
@interface GMRequestTask ()
@property(nonatomic,strong) NSURLSessionTask * sessionTask;
@property(nonatomic,strong) id responseObject;
@property(nonatomic,strong) NSError * err;
@end

@implementation GMRequestTask
- (void) cancel
{
    return [self.sessionTask cancel];
}
- (void) resume
{
    return [self.sessionTask resume];
}
+ (instancetype)taskWithSessionTask:(NSURLSessionTask *) sessionTask
{
    GMRequestTask * task=[[GMRequestTask alloc] init];
    task.sessionTask=sessionTask;
    return task;
}
@end

//
//  GMRequestFile.h
//  GMNetworkService
//
//  Created by Good Man on 2017/6/7.
//  Copyright © 2017年 Good Man. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GMRequestFile : NSObject

@property(copy,nonatomic) NSString * fileName;
@property(copy,nonatomic) NSString * keyName;
@property(strong,nonatomic) NSData * data;
@property(strong,nonatomic) NSString * filePath;
@property(copy,nonatomic) NSString * miniType;

- (id)initWithFileName:(NSString *) fileName keyName:(NSString *) keyName data:(NSData *) data miniType:(NSString *) mini;

- (id)initWithFileName:(NSString *)fileName keyName:(NSString *)keyName filePath:(NSString *)filePath miniType:(NSString *)mini;

@end

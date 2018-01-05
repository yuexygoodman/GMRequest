//
//  GMRequestTask.h
//  GMRequestService
//
//  Created by Good Man on 2017/5/17.
//  Copyright © 2017年 Good Man. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 `GMRequestTask` is a task that handle a request for you,you can cancel or resume a request by it.
 */

@interface GMRequestTask : NSObject
- (void)cancel;
- (void)resume;
@end

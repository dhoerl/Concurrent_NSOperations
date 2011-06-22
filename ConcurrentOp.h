//
//  ConcurrentOp.h
//  Concurrent_NSOperation
//
//  Created by David Hoerl on 6/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ConcurrentOp : NSOperation
{}
@property (assign) BOOL failInSetup;
@property (assign) NSThread *thread;
@property (retain) NSMutableData *webData;

- (void)wakeUp;
- (void)runConnection;

@end

//
//  ConcurrentOp.h
//  Concurrent_NSOperation
//
//  Created by David Hoerl on 6/13/11.
//  Copyright 2011 David Hoerl. All rights reserved.
//

@interface ConcurrentOp : NSOperation
@property (assign) BOOL failInSetup;
@property (nonatomic, strong) NSThread *thread;			// only exposed to demonstrate that users of this can message it on its own thread.
@property (nonatomic, strong) NSMutableData *webData;	// when the operation is over, fetch the data - no contention

- (void)wakeUp;				// should be run on the operation's thread - could create a convenience method that does this then hide thread
- (void)finish;				// should be run on the operation's thread - could create a convenience method that does this then hide thread
- (void)runConnection;		// convenience method - messages using proper thread
- (void)cancel;				// subclassed convenience method

@end

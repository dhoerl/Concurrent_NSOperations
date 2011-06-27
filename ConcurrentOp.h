//
//  ConcurrentOp.h
//  Concurrent_NSOperation
//
//  Created by David Hoerl on 6/13/11.
//  Copyright 2011 David Hoerl. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ConcurrentOp : NSOperation
{}
@property (assign) BOOL failInSetup;
@property (assign) NSThread *thread;	// only exposed to demonstrate that users of this can message it on its own thread. Create public convenience methods then you can remove it.
@property (retain) NSMutableData *webData;

- (void)wakeUp;				// should be run on the operation's thread - could create a convenience method that does this then hide thread
- (void)finish;				// should be run on the operation's thread - could create a convenience method that does this then hide thread
- (void)runConnection;		// convenience method - messages using proper thread
- (void)cancel;				// subclassed convenience method

@end

//
//  Concurrent_NSOperations_MacAppDelegate.m
//  Concurrent_NSOperations_Mac
//
//  Created by David Hoerl on 6/16/11.
//  Copyright 2011 David Hoerl. All rights reserved.
//

#import "Concurrent_NSOperations_MacAppDelegate.h"

#import "ConcurrentOp.h"

static char *runnerContext = "runnerContext";

@interface Concurrent_NSOperations_MacAppDelegate ()
@property (nonatomic, strong) NSOperationQueue *queue;
@property (nonatomic, strong) NSMutableSet *operations;

- (void)operationDidFinish:(ConcurrentOp *)operation;

@end

@implementation Concurrent_NSOperations_MacAppDelegate
@synthesize window;
@synthesize finishOp;
@synthesize messageOp;
@synthesize connectionOp;
@synthesize preCancel;
@synthesize run;
@synthesize cancel;
@synthesize failSwitch;
@synthesize spinner;
@synthesize queue;
@synthesize operations;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	self.operations = [NSMutableSet setWithCapacity:1];
	self.queue = [NSOperationQueue new];
	
	[cancel setEnabled:NO];
	[messageOp setEnabled:NO];
	[finishOp setEnabled:NO];
	[connectionOp setEnabled:NO];
	[spinner stopAnimation:self];
}

- (IBAction)runNow:(id)sender
{
	ConcurrentOp *runner = [ConcurrentOp new];
	runner.failInSetup = [failSwitch state];

	[run setEnabled:NO];
	[cancel setEnabled:YES];
	[messageOp setEnabled:YES];
	[finishOp setEnabled:YES];
	[connectionOp setEnabled:YES];
	[spinner startAnimation:self];
	
	// Mimics a cancel that occurrs when the operation is queued but not executing
	if([preCancel state]) [runner cancel];
	
	// Order is important here
	[runner addObserver:self forKeyPath:@"isFinished" options:0 context:runnerContext];	// First, observe isFinished
	[operations addObject:runner];	// Second we retain and save a reference to the operation
	[queue addOperation:runner];	// Lastly, lets get going!
}

- (IBAction)cancelNow:(id)sender
{
	[queue cancelAllOperations];
	[queue waitUntilAllOperationsAreFinished];
	
	// note that all the operationDidFinish: messages are now queued in the main runLoop.
	[operations enumerateObjectsUsingBlock:^(id obj, BOOL *stop) { [obj removeObserver:self forKeyPath:@"isFinished"]; }];
    [self.operations removeAllObjects];
}

// These three methods are how we can safely message the Operation directly without a "convenience" method in the operation class itself
- (IBAction)messageNow:(id)sender
{
	for(ConcurrentOp *op in operations)
		[op performSelector:@selector(wakeUp) onThread:op.thread withObject:nil waitUntilDone:NO];
}

- (IBAction)finishNow:(id)sender
{
	for(ConcurrentOp *op in operations)
		[op performSelector:@selector(finish) onThread:op.thread withObject:nil waitUntilDone:NO];
}

- (IBAction)connectNow:(id)sender
{
	for(ConcurrentOp *op in operations)
		[op performSelector:@selector(runConnection) onThread:op.thread withObject:nil waitUntilDone:NO];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	ConcurrentOp *op = object;
	if(context == runnerContext) {
		if(op.isFinished == YES) {
			// we get this on the operation's thread
			[self performSelectorOnMainThread:@selector(operationDidFinish:) withObject:op waitUntilDone:NO];
		} else {
			//NSLog(@"NSOperation starting to RUN!!!");
		}
	} else {
		if([object respondsToSelector:@selector(observeValueForKeyPath:ofObject:change:context:)])
			[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (void)operationDidFinish:(ConcurrentOp *)operation
{
	// Test Code
	[run setEnabled:YES];
	[cancel setEnabled:NO];
	[messageOp setEnabled:NO];
	[finishOp setEnabled:NO];
	[connectionOp setEnabled:NO];
	[spinner stopAnimation:self];

	// what you would want in real world situations below

	// if you cancel the operation when its in the set, will hit this case
	// since observeValueForKeyPath: queues this message on the main thread
	if(![self.operations containsObject:operation]) return;
	
	// If we are in the queue, then we have to both remove our observation and queue membership
	[operation removeObserver:self forKeyPath:@"isFinished"];
	[operations removeObject:operation];
	
	// This would be the case if cancelled before we start running.
	if(operation.isCancelled) return;
	
	// We either failed in setup or succeeded doing something.
	NSLog(@"Operation Succeeded: webData = %lx", (unsigned long)operation.webData);
}


@end

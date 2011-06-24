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
@property (nonatomic, retain) NSOperationQueue *queue;
@property (nonatomic, retain) NSMutableSet *operations;

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

- (id)init
{
	if((self = [super init])) {
		self.operations = [NSMutableSet setWithCapacity:1];
	}
	return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	self.queue = [[NSOperationQueue new] autorelease];
	[cancel setEnabled:NO];
	[messageOp setEnabled:NO];
	[finishOp setEnabled:NO];
	[connectionOp setEnabled:NO];
	[spinner stopAnimation:self];
}

- (IBAction)runNow:(id)sender
{
	ConcurrentOp *runner = [[ConcurrentOp new] autorelease];
	runner.failInSetup = [failSwitch state];

	[run setEnabled:NO];
	[cancel setEnabled:YES];
	[messageOp setEnabled:YES];
	[finishOp setEnabled:YES];
	[connectionOp setEnabled:YES];
	[spinner startAnimation:self];
	
	[runner addObserver:self forKeyPath:@"isFinished" options:0 context:runnerContext];
	// Have to be observing to get finished which happens when this case is hit
	if([preCancel state]) [runner cancel];
	NSLog(@"isCancelled = %d", [runner isCancelled]);
	[queue addOperation:runner];
}

- (IBAction)cancelNow:(id)sender
{
	[queue cancelAllOperations];
	[queue waitUntilAllOperationsAreFinished];
	
	for (id object in operations)
	{
		[object removeObserver:self forKeyPath:@"isFinished"];
	}
    
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
			NSLog(@"NSOperation starting to RUN!!!");
		}
	} else {
		if([object respondsToSelector:@selector(observeValueForKeyPath:ofObject:change:context:)])
			[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (void)operationDidFinish:(ConcurrentOp *)operation
{
	[run setEnabled:YES];
	[cancel setEnabled:NO];
	[messageOp setEnabled:NO];
	[finishOp setEnabled:NO];
	[connectionOp setEnabled:NO];
	[spinner stopAnimation:self];

	// what you would want in real world situations below

	// if you cancel the operation when it's in the set, will hit this case
	if(![self.operations containsObject:operation]) return;
	
	// or we get called here when canceled but not yet removed from the set,
	// when we cancel, we remove when we get control back at that time
	if(operation.isCancelled) return;
	
	// Success path: should remove self as an observer
	[operation removeObserver:self forKeyPath:@"isFinished"]; // race condition - do this first
	[self.operations removeObject:operation];	
	// Runner still valid since performSelector retains the object til this method returns

	NSLog(@"Operation Did End: webData = %lx", (unsigned long)operation.webData);
}

- (void)dealloc
{
    [run release];
    [cancel release];
    [spinner release];
	[queue release];
	[operations release];
	[failSwitch release];
	[finishOp release];
	[messageOp release];
    [connectionOp release];
	[preCancel release];

    [super dealloc];
}

@end

//
//  Concurrent_NSOperationViewController.m
//  Concurrent_NSOperation
//
//  Created by David Hoerl on 6/13/11.
//  Copyright 2011 David Hoerl. All rights reserved.
//

#import "Concurrent_NSOperationViewController.h"

#import "ConcurrentOp.h"

static char *runnerContext = "runnerContext";

@interface Concurrent_NSOperationViewController ()
@property (nonatomic, retain) NSOperationQueue *queue;
@property (nonatomic, retain) NSMutableSet *operations;

- (void)operationDidFinish:(ConcurrentOp *)operation;

@end

@implementation Concurrent_NSOperationViewController
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

- (IBAction)runNow:(id)sender
{
	ConcurrentOp *runner = [[ConcurrentOp new] autorelease];
	runner.failInSetup = failSwitch.on;

	run.enabled = NO, run.alpha = 0.5f;
	cancel.enabled = YES, cancel.alpha = 1.0f;
	messageOp.enabled = YES, messageOp.alpha = 1.0f;
	finishOp.enabled = YES, finishOp.alpha = 1.0f;
	connectionOp.enabled = YES, connectionOp.alpha = 1.0f;
	[spinner startAnimating];
	
	// Mimics a cancel that occurrs when the operation is queued but not executing
	if(preCancel.on) [runner cancel];
	
	// Order is important here
	[runner addObserver:self forKeyPath:@"isFinished" options:0 context:runnerContext];	// First, observe isFinished
	[operations addObject:runner];	// Second we retain and save a reference to the operation
	[queue addOperation:runner];	// Lastly, lets get going!
}

- (IBAction)cancelNow:(id)sender
{
	[queue cancelAllOperations];
	[queue waitUntilAllOperationsAreFinished];
	
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
		[op runConnection]; // convenience method - call directly
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.operations = [NSMutableSet setWithCapacity:1];
	self.queue = [[NSOperationQueue new] autorelease];

	cancel.enabled = NO, cancel.alpha = 0.5f;
	messageOp.enabled = NO, messageOp.alpha = 0.5f;
	finishOp.enabled = NO, finishOp.alpha = 0.5f;
	connectionOp.enabled = NO, connectionOp.alpha = 0.5f;
	[spinner stopAnimating];
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
	// in support of test code
	run.enabled = YES, run.alpha = 1.0f;
	cancel.enabled = NO, cancel.alpha = 0.5f;
	messageOp.enabled = NO, messageOp.alpha = 0.5f;
	finishOp.enabled = NO, finishOp.alpha = 0.5f;
	connectionOp.enabled = NO, connectionOp.alpha = 0.5f;
	[spinner stopAnimating];

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

- (void)viewDidUnload
{
    [self setRun:nil];
    [self setCancel:nil];
    [self setSpinner:nil];
    [self setQueue:nil];

	[self setFailSwitch:nil];
	[self setFinishOp:nil];
	[self setMessageOp:nil];
    [self setConnectionOp:nil];
	[self setPreCancel:nil];

    [super viewDidUnload];
}

- (void)dealloc
{
    [run release];
    [cancel release];
    [spinner release];
	[queue release];
	[failSwitch release];
	[finishOp release];
	[messageOp release];
    [connectionOp release];
	[preCancel release];

    [super dealloc];
}


#pragma mark - View lifecycle

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
*/

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end

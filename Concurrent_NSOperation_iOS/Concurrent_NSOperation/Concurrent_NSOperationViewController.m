//
//  Concurrent_NSOperationViewController.m
//  Concurrent_NSOperation
//
//  Created by David Hoerl on 6/13/11.
//  Copyright 2011 David Hoerl. All rights reserved.
//

#import "Concurrent_NSOperationViewController.h"

#import "ConcurrentOp.h"

#if ! __has_feature(objc_arc)
#error THIS CODE MUST BE COMPILED WITH ARC ENABLED!
#endif

static char *runnerContext = "runnerContext";

@interface Concurrent_NSOperationViewController ()
@property (nonatomic, strong) IBOutlet UIButton *run;
@property (nonatomic, strong) IBOutlet UIButton *cancel;
@property (nonatomic, strong) IBOutlet UISwitch *failSwitch;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic, strong) IBOutlet UIButton *finishOp;
@property (nonatomic, strong) IBOutlet UIButton *messageOp;
@property (nonatomic, strong) IBOutlet UIButton *connectionOp;
@property (nonatomic, strong) IBOutlet UISwitch *preCancel;

@property (nonatomic, strong) NSOperationQueue *queue;
@property (nonatomic, strong) NSMutableSet *operations;
@property (nonatomic, assign) dispatch_queue_t operationsQueue;

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
@synthesize operationsQueue;

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.operations = [NSMutableSet setWithCapacity:1];
	self.queue = [NSOperationQueue new];
	self.operationsQueue = dispatch_queue_create("com.dfh.operationsQueue", DISPATCH_QUEUE_CONCURRENT);

	cancel.enabled = NO, cancel.alpha = 0.5f;
	messageOp.enabled = NO, messageOp.alpha = 0.5f;
	finishOp.enabled = NO, finishOp.alpha = 0.5f;
	connectionOp.enabled = NO, connectionOp.alpha = 0.5f;
	[spinner stopAnimating];
}

- (IBAction)runNow:(id)sender
{
	ConcurrentOp *runner = [ConcurrentOp new];
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
	dispatch_barrier_async(operationsQueue, ^
		{
			[operations addObject:runner];	// Second we retain and save a reference to the operation
		} );
	[queue addOperation:runner];	// Lastly, lets get going!
}

- (IBAction)cancelNow:(id)sender
{
	// Stop listening first
	dispatch_sync(operationsQueue, ^
		{
			[operations enumerateObjectsUsingBlock:^(id obj, BOOL *stop) { [obj removeObserver:self forKeyPath:@"isFinished"]; }];   
		} );
	dispatch_barrier_sync(operationsQueue, ^
		{
			[operations removeAllObjects];
		} );

	[queue cancelAllOperations];
	[queue waitUntilAllOperationsAreFinished];
}

// These three methods are how we can safely message the Operation directly without a "convenience" method in the operation class itself
- (IBAction)messageNow:(id)sender
{
	dispatch_barrier_sync(operationsQueue, ^
		{
			for(ConcurrentOp *op in operations)
				[op performSelector:@selector(wakeUp) onThread:op.thread withObject:nil waitUntilDone:NO];
		} );
}

- (IBAction)finishNow:(id)sender
{
	dispatch_barrier_sync(operationsQueue, ^
		{
			for(ConcurrentOp *op in operations)
				[op performSelector:@selector(finish) onThread:op.thread withObject:nil waitUntilDone:NO];
		} );
}

- (IBAction)connectNow:(id)sender
{
	dispatch_barrier_sync(operationsQueue, ^
		{
			for(ConcurrentOp *op in operations)
				[op runConnection]; // convenience method - call directly
		} );
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	ConcurrentOp *op = object;
	if(context == runnerContext) {
		if(op.isFinished == YES) {
			// we get this on the operation's thread
			//[self performSelectorOnMainThread:@selector(operationDidFinish:) withObject:op waitUntilDone:NO];
			dispatch_async(dispatch_get_main_queue(), ^{ [self operationDidFinish:op]; } );
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
	__block BOOL containsObject;
	dispatch_sync(operationsQueue, ^
		{
            containsObject = [self.operations containsObject:operation];
        } );
	if(!containsObject) return;
	
	// If we are in the queue, then we have to both remove our observation and queue membership
	[operation removeObserver:self forKeyPath:@"isFinished"];
	dispatch_barrier_async(operationsQueue, ^
		{
			[operations removeObject:operation];
		} );
	
	// This would be the case if cancelled before we start running.
	if(operation.isCancelled) return;
	
	// We either failed in setup or succeeded doing something.
	NSLog(@"Operation Succeeded: webData = %lx", (unsigned long)operation.webData);
}

- (NSSet *)operationsSet
{
	__block NSSet *set;
	dispatch_sync(operationsQueue, ^
		{
            set = [NSSet setWithSet:operations];
        } );
	return set;
}
- (NSUInteger)operationsCount
{
	__block NSUInteger count;
	dispatch_sync(operationsQueue, ^
		{
            count = [operations count];
        } );
	return count;
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

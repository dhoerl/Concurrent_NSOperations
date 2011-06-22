//
//  Concurrent_NSOperations_MacAppDelegate.m
//  Concurrent_NSOperations_Mac
//
//  Created by David Hoerl on 6/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Concurrent_NSOperations_MacAppDelegate.h"

#import "ConcurrentOp.h"

static char *runnerContext = "runnerContext";

@interface Concurrent_NSOperations_MacAppDelegate ()
@property (nonatomic, retain) NSOperationQueue *queue;
@property (nonatomic, retain) ConcurrentOp *runner;

- (void)operationDidFinish;

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
@synthesize runner;

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
	self.runner = [[ConcurrentOp new] autorelease];
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
	//[runner cancel];
}

- (IBAction)messageNow:(id)sender
{
	[runner performSelector:@selector(wakeUp) onThread:runner.thread withObject:nil waitUntilDone:NO];
}

- (IBAction)finishNow:(id)sender
{
	[runner performSelector:@selector(finish) onThread:runner.thread withObject:nil waitUntilDone:NO];
}

- (IBAction)connectNow:(id)sender
{
	[runner performSelector:@selector(runConnection) onThread:runner.thread withObject:nil waitUntilDone:NO];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if(context == runnerContext) {
		if(runner.isFinished == YES) {
			// we get this on the operation's thread
			[self performSelectorOnMainThread:@selector(operationDidFinish) withObject:nil waitUntilDone:NO];
		} else {
			NSLog(@"NSOperation starting to RUN!!!");
		}
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (void)operationDidFinish
{
	[run setEnabled:YES];
	[cancel setEnabled:NO];
	[messageOp setEnabled:NO];
	[finishOp setEnabled:NO];
	[connectionOp setEnabled:NO];
	[spinner stopAnimation:self];

	NSLog(@"Operation Did End: webData = %lx", (unsigned long)runner.webData);
	self.runner = nil;
}

- (void)dealloc
{
    [run release];
    [cancel release];
    [spinner release];
	[queue release];
	[runner release];
	[failSwitch release];
	[finishOp release];
	[messageOp release];
    [connectionOp release];
	[preCancel release];

    [super dealloc];
}

@end

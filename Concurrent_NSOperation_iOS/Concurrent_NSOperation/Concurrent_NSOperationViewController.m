//
//  Concurrent_NSOperationViewController.m
//  Concurrent_NSOperation
//
//  Created by David Hoerl on 6/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Concurrent_NSOperationViewController.h"

#import "ConcurrentOp.h"

static char *runnerContext = "runnerContext";

@interface Concurrent_NSOperationViewController ()

@property (nonatomic, retain) NSOperationQueue *queue;
@property (nonatomic, retain) ConcurrentOp *runner;

- (void)operationDidFinish;

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
@synthesize runner;

- (IBAction)runNow:(id)sender
{
	self.runner = [[ConcurrentOp new] autorelease];
	runner.failInSetup = failSwitch.on;

	run.enabled = NO, run.alpha = 0.5f;
	cancel.enabled = YES, cancel.alpha = 1.0f;
	messageOp.enabled = YES, messageOp.alpha = 1.0f;
	finishOp.enabled = YES, finishOp.alpha = 1.0f;
	connectionOp.enabled = YES, connectionOp.alpha = 1.0f;
	[spinner startAnimating];
	
	[runner addObserver:self forKeyPath:@"isFinished" options:0 context:runnerContext];
	// Have to be observing to get finished which happens when this case is hit
	if(preCancel.on) [runner cancel];
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

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.queue = [[NSOperationQueue new] autorelease];
	cancel.enabled = NO, cancel.alpha = 0.5f;
	messageOp.enabled = NO, messageOp.alpha = 0.5f;
	finishOp.enabled = NO, finishOp.alpha = 0.5f;
	connectionOp.enabled = NO, connectionOp.alpha = 0.5f;
	[spinner stopAnimating];
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
	run.enabled = YES, run.alpha = 1.0f;
	cancel.enabled = NO, cancel.alpha = 0.5f;
	messageOp.enabled = NO, messageOp.alpha = 0.5f;
	finishOp.enabled = NO, finishOp.alpha = 0.5f;
	connectionOp.enabled = NO, connectionOp.alpha = 0.5f;
	[spinner stopAnimating];

	NSLog(@"Operation Did End: webData = %lx", (unsigned long)runner.webData);
	self.runner = nil;
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
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
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

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
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

//
//  MyClass.m
//  Concurrent_NSOperation
//
//  Created by David Hoerl on 6/13/11.
//  Copyright 2011 David Hoerl. All rights reserved.
//

#import "ConcurrentOp.h"


@interface ConcurrentOp ()
@property (nonatomic, assign) BOOL executing, finished;
@property (nonatomic, assign) int loops;
@property (nonatomic, retain) NSTimer *timer;
@property (nonatomic, retain) NSURLConnection *connection;

- (BOOL)setup;
- (void)timer:(NSTimer *)timer;

@end

@interface ConcurrentOp (NSURLConnectionDelegate)
@end

@implementation ConcurrentOp
@synthesize failInSetup;
@synthesize thread;
@synthesize executing, finished;
@synthesize loops;
@synthesize timer;
@synthesize connection;
@synthesize webData;

- (BOOL)isConcurrent { return YES; }
- (BOOL)isExecuting { return executing; }
- (BOOL)isFinished { return finished; }

- (void)start
{
	if([self isCancelled]) {
		NSLog(@"OP: cancelled before I even started!");
		[self willChangeValueForKey:@"isFinished"];
		finished = YES;
		[self didChangeValueForKey:@"isFinished"];
		return;
	}

	NSLog(@"OP: start");
	NSAutoreleasePool *pool = [NSAutoreleasePool new];

	loops = 1;	// testing
	self.thread	= [NSThread currentThread];	// do this first, to enable future messaging
	self.timer	= [NSTimer scheduledTimerWithTimeInterval:60*60 target:self selector:@selector(timer:) userInfo:nil repeats:NO];	// makes runloop functional
	
    [self willChangeValueForKey:@"isExecuting"];
    executing = YES;
    [self didChangeValueForKey:@"isExecuting"];
	
    BOOL allOK = [self setup];

	if(allOK) {
		while(![self isFinished]) {
			//NSLog(@"main: sitting in loop (loops=%d)", loops);
			BOOL ret = [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
			assert(ret && "first assert"); // could remove this - its here to convince myself all is well
		}
		NSLog(@"OP: finished - %@", [self isCancelled] ? @"was canceled" : @"normal completion");
	} else {
		[self finish];

		NSLog(@"OP: finished - setup failed");
		[timer invalidate], self.timer = nil;
		[connection cancel], self.connection = nil;
	}
	// Objects retaining us
	[timer invalidate], self.timer = nil;
	[connection cancel], self.connection = nil;
	[pool drain];
}

- (BOOL)setup
{
	NSLog(@"OP: setup");
	NSURLRequest *request = [NSURLRequest requestWithURL: [NSURL URLWithString: @"http://images.apple.com/home/images/icloud_title.png"]];
	self.connection =  [[[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO] autorelease];

#if !TARGET_OS_IPHONE // Apple bug in OSX (still in Snow Leopard)
	[connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
#endif

	return !failInSetup;	// testing
}

- (void)wakeUp
{
	NSLog(@"OP: was messaged!!!");
	if(loops++ >= 4)
		[self performSelector:@selector(finish) onThread:thread withObject:nil waitUntilDone:NO];
}

- (void)runConnection
{
	[connection performSelector:@selector(start) onThread:thread withObject:nil waitUntilDone:NO];
}

- (void)cancel
{
	[super cancel];
	
	if([self isExecuting]) {
		[self performSelector:@selector(finish) onThread:thread withObject:nil waitUntilDone:NO];
	}
}

- (void)finish
{
	// This order per the Concurrency Guide - some authors switch the didChangeValueForKey order.
	[self willChangeValueForKey:@"isFinished"];
	[self willChangeValueForKey:@"isExecuting"];

	executing = NO;
	finished = YES;

	[self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

- (void)timer:(NSTimer *)timer
{
}

- (void)dealloc
{
	NSLog(@"OP: dealloc"); // didn't always see this message :-)

	[timer invalidate], [timer release];
	[connection cancel], [connection release];
	[webData release];

	[super dealloc];
}

@end

@implementation ConcurrentOp (NSURLConnectionDelegate)

- (void)connection:(NSURLConnection *)conn didReceiveResponse:(NSURLResponse *)response
{
	if([super isCancelled]) {
		[connection cancel];
		return;
	}

	NSUInteger responseLength = response.expectedContentLength == NSURLResponseUnknownLength ? 1024 : response.expectedContentLength;
#ifndef NDEBUG
	//NSLog(@"ConcurrentOp: response=%@ len=%lu", response, (unsigned long)responseLength);
#endif
	self.webData = [NSMutableData dataWithCapacity:responseLength]; 
}

- (void)connection:(NSURLConnection *)conn didReceiveData:(NSData *)data
{
#ifndef NDEBUG
	//NSLog(@"WEB SERVICE: got Data len=%lu", [data length]);
#endif
	if([super isCancelled]) {
		[connection cancel];
		return;
	}
	[webData appendData:data];
}

- (void)connection:(NSURLConnection *)conn didFailWithError:(NSError *)error
{
#ifndef NDEBUG
	NSLog(@"ConcurrentOp: error: %@", [error description]);
#endif
	self.webData = nil;
    [connection cancel];

	[self finish];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)conn
{
	if([super isCancelled]) {
		[connection cancel];
		return;
	}
#ifndef NDEBUG
	//NSLog(@"ConcurrentOp FINISHED LOADING WITH Received Bytes: %u", [webData length]);
#endif
	// could use a NSXMLParser here too.
	[self finish];
}

@end

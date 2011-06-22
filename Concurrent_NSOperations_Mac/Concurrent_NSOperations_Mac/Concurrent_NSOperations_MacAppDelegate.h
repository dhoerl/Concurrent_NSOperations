//
//  Concurrent_NSOperations_MacAppDelegate.h
//  Concurrent_NSOperations_Mac
//
//  Created by David Hoerl on 6/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface Concurrent_NSOperations_MacAppDelegate : NSObject <NSApplicationDelegate>
{}
@property (nonatomic, assign) IBOutlet NSWindow *window;
@property (nonatomic, assign) IBOutlet NSButton *run;
@property (nonatomic, assign) IBOutlet NSButton *cancel;
@property (nonatomic, assign) IBOutlet NSButton *failSwitch;
@property (nonatomic, assign) IBOutlet NSProgressIndicator *spinner;
@property (nonatomic, assign) IBOutlet NSButton *finishOp;
@property (nonatomic, assign) IBOutlet NSButton *messageOp;
@property (nonatomic, assign) IBOutlet NSButton *connectionOp;
@property (nonatomic, assign) IBOutlet NSButton *preCancel;

- (IBAction)runNow:(id)sender;
- (IBAction)cancelNow:(id)sender;
- (IBAction)messageNow:(id)sender;
- (IBAction)finishNow:(id)sender;
- (IBAction)connectNow:(id)sender;

@end

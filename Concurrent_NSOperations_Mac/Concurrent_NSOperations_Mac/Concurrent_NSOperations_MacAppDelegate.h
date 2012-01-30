//
//  Concurrent_NSOperations_MacAppDelegate.h
//  Concurrent_NSOperations_Mac
//
//  Created by David Hoerl on 6/16/11.
//  Copyright 2011 David Hoerl. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface Concurrent_NSOperations_MacAppDelegate : NSObject <NSApplicationDelegate>
{}
@property (nonatomic, unsafe_unretained) IBOutlet NSWindow *window;
@property (nonatomic, weak) IBOutlet NSButton *run;
@property (nonatomic, weak) IBOutlet NSButton *cancel;
@property (nonatomic, weak) IBOutlet NSButton *failSwitch;
@property (nonatomic, weak) IBOutlet NSProgressIndicator *spinner;
@property (nonatomic, weak) IBOutlet NSButton *finishOp;
@property (nonatomic, weak) IBOutlet NSButton *messageOp;
@property (nonatomic, weak) IBOutlet NSButton *connectionOp;
@property (nonatomic, weak) IBOutlet NSButton *preCancel;

- (IBAction)runNow:(id)sender;
- (IBAction)cancelNow:(id)sender;
- (IBAction)messageNow:(id)sender;
- (IBAction)finishNow:(id)sender;
- (IBAction)connectNow:(id)sender;

@end

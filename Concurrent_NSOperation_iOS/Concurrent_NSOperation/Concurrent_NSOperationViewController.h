//
//  Concurrent_NSOperationViewController.h
//  Concurrent_NSOperation
//
//  Created by David Hoerl on 6/13/11.
//  Copyright 2011 David Hoerl. All rights reserved.
//

@interface Concurrent_NSOperationViewController : UIViewController

- (IBAction)runNow:(id)sender;
- (IBAction)cancelNow:(id)sender;
- (IBAction)messageNow:(id)sender;
- (IBAction)finishNow:(id)sender;
- (IBAction)connectNow:(id)sender;

// utility commands
- (NSSet *)operationsSet;
- (NSUInteger)operationsCount;

@end

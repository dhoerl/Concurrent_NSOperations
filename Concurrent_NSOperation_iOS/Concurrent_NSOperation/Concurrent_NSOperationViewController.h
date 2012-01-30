//
//  Concurrent_NSOperationViewController.h
//  Concurrent_NSOperation
//
//  Created by David Hoerl on 6/13/11.
//  Copyright 2011 David Hoerl. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Concurrent_NSOperationViewController : UIViewController
{
/*
	UIButton *run;
	UIButton *cancel;
	UISwitch *failSwitch;
	UIActivityIndicatorView *spinner;
	UIButton *finishOp;
	UIButton *messageOp;
	UIButton *connectionOp;
	UISwitch *preCancel;
*/
}
@property (nonatomic, strong) IBOutlet UIButton *run;
@property (nonatomic, strong) IBOutlet UIButton *cancel;
@property (nonatomic, strong) IBOutlet UISwitch *failSwitch;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic, strong) IBOutlet UIButton *finishOp;
@property (nonatomic, strong) IBOutlet UIButton *messageOp;
@property (nonatomic, strong) IBOutlet UIButton *connectionOp;
@property (nonatomic, strong) IBOutlet UISwitch *preCancel;

- (IBAction)runNow:(id)sender;
- (IBAction)cancelNow:(id)sender;
- (IBAction)messageNow:(id)sender;
- (IBAction)finishNow:(id)sender;
- (IBAction)connectNow:(id)sender;

@end

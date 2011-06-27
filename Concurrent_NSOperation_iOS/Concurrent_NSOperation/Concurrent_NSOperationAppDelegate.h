//
//  Concurrent_NSOperationAppDelegate.h
//  Concurrent_NSOperation
//
//  Created by David Hoerl on 6/13/11.
//  Copyright 2011 David Hoerl. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Concurrent_NSOperationViewController;

@interface Concurrent_NSOperationAppDelegate : NSObject <UIApplicationDelegate>
{}
@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet Concurrent_NSOperationViewController *viewController;

@end

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
@property (nonatomic, strong) IBOutlet UIWindow *window;
@property (nonatomic, strong) IBOutlet Concurrent_NSOperationViewController *viewController;

@end

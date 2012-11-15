//
//  EasyGraphAppDelegate.h
//  EasyGraph
//
//  Created by Oren Shklarsky on 12-07-19.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol EasyGraphDropboxDelegate <NSObject>

@required
- (void)dropboxWasLinked;
@end

// Constants used for OAuth 2.0 authorization.
static NSString *const kKeychainItemName = @"EasyGraph: Google Drive";
static NSString *const kClientId = @"363193959323.apps.googleusercontent.com";
static NSString *const kClientSecret = @"CWopZmMpnndrw-RcJwbB6gxt";

@interface EasyGraphAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) UISplitViewController *splitViewController;

@property id <EasyGraphDropboxDelegate> delegate;

@end

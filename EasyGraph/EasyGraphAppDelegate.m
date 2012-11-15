//
//  EasyGraphAppDelegate.m
//  EasyGraph
//
//  Created by Oren Shklarsky on 12-07-19.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EasyGraphAppDelegate.h"
#import "EasyGraphMasterViewController.h"
#import "EasyGraphDetailViewController.h"
#import <DropboxSDK/DropboxSDK.h>

@implementation EasyGraphAppDelegate

@synthesize window = _window;
@synthesize splitViewController = _splitViewController;
@synthesize delegate = _delegate;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.

    EasyGraphMasterViewController *masterViewController = [[EasyGraphMasterViewController alloc] initWithNibName:@"EasyGraphMasterViewController" bundle:nil];
    UINavigationController *masterNavigationController = [[UINavigationController alloc] initWithRootViewController:masterViewController];

    NSFileManager *filemgr = [NSFileManager defaultManager];
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [dirPaths objectAtIndex:0];
    NSString *fileListPath = [[NSString alloc] initWithString:
                    [docsDir stringByAppendingPathComponent:@"fileList.archive"]];
    
    if ([filemgr fileExistsAtPath:fileListPath]) {
        [masterViewController reloadFileList];
    } else {
        masterViewController.fileList = [[NSMutableArray alloc] initWithObjects:@"Untitled_1", nil];
    }
    EasyGraphDetailViewController *newDetailView;
    for (NSString *name in masterViewController.fileList) {
        newDetailView = [[EasyGraphDetailViewController alloc]
                        initWithNibName:@"EasyGraphDetailViewController" title:name];
        [newDetailView setMasterViewController:masterViewController];
        [newDetailView setMyAppDelegate:self];
        [masterViewController.easyGraphDetailViewControllers addObject:newDetailView];

    }
    
    EasyGraphDetailViewController *detailViewController =
                        [masterViewController.easyGraphDetailViewControllers objectAtIndex:0];
    detailViewController.title = [masterViewController.fileList objectAtIndex:0];
    UINavigationController *detailNavigationController = [[UINavigationController alloc] initWithRootViewController:detailViewController];

    masterViewController.detailViewController = detailViewController;

    self.splitViewController = [[UISplitViewController alloc] init];
    self.splitViewController.delegate = detailViewController;
    self.splitViewController.viewControllers = [NSArray arrayWithObjects:masterNavigationController, detailNavigationController, nil];
    self.splitViewController.presentsWithGesture = NO;
    
    self.window.rootViewController = self.splitViewController;
    [self.window makeKeyAndVisible];
    
    //Setup NSUserDefaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *defaultValues = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSNumber numberWithFloat:70], @"vertexSize",
                                   [NSNumber numberWithBool:NO], @"hidingLabels",
                                   [NSNumber numberWithFloat:18.0], @"vertexLetterSize",
                                   [NSKeyedArchiver archivedDataWithRootObject:[UIColor blackColor]], @"vertexColour",
                                   [NSNumber numberWithFloat:3.0], @"edgeWidth",
                                   [NSKeyedArchiver archivedDataWithRootObject:[UIColor blackColor]], @"edgeColour",
                                   [NSNumber numberWithInt:0], @"defaultLanguage",
                                   [NSNumber numberWithBool:YES], @"exportColours",
                                   [NSNumber numberWithFloat:10.0], @"tikzScale",
                                   [NSNumber numberWithFloat:5.0], @"tikzVertexSize",
                                   [NSNumber numberWithFloat:1.0], @"tikzEdgeWidth",
                                   [NSNumber numberWithFloat:10.0], @"pstricksScale",
                                   [NSNumber numberWithFloat:3.0], @"pstricksVertexSize",
                                   [NSNumber numberWithFloat:1.0], @"pstricksEdgeWidth",
                                   [NSNumber numberWithInt:0], @"storageDefaultService",
                                   nil];
    
    [defaults registerDefaults:defaultValues];
    
    //Add dropbox support
    DBSession* dbSession =
    [[DBSession alloc]
     initWithAppKey:@"gltrsjotofeak0p"
     appSecret:@"nw8e4urd39rnvxj"
     root:kDBRootAppFolder];
    [DBSession setSharedSession:dbSession];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL) application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    if ([[DBSession sharedSession] handleOpenURL:url]) {
        if ([[DBSession sharedSession] isLinked]) {
            NSLog(@"App linked successfully!");
            // At this point you can start making API calls
            if (_delegate) {
                [[self delegate] dropboxWasLinked];
            }
        }
        return YES;
    }
    // Add whatever other url handling code your app requires here
    return NO;
}

@end

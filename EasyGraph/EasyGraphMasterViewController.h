//
//  GraphMakerMasterViewController.h
//  GraphMaker
//
//  Created by Oren Shklarsky on 12-07-19.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@protocol EasyGraphInsertOptionsDelegate <NSObject>
@required
- (void) insertNewObject:(int)row;
@end

@interface EasyGraphInsertOptions : UITableViewController
@property (nonatomic, retain) NSArray *options;
@property (nonatomic, assign) id <EasyGraphInsertOptionsDelegate> delegate;
@end


@class EasyGraphDetailViewController;


@interface EasyGraphMasterViewController : UITableViewController <UITextFieldDelegate,
                                                                EasyGraphInsertOptionsDelegate>

@property (strong, nonatomic) IBOutlet UIPopoverController *graphChoiceController;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *addButton;

@property (nonatomic, retain) NSMutableArray *fileList;
@property (nonatomic, retain) NSMutableArray *graphCanvases;

@property (strong, nonatomic) EasyGraphDetailViewController *detailViewController;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (strong, nonatomic) NSString *fileListPath;
@property (strong, nonatomic) UIAlertView *renameDialouge;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *renameButton;
@property (strong, nonatomic) NSIndexPath *currentSelection;
@property (strong, nonatomic) NSString *saveDataPath;

// Save the the names of all existing graphs for reloading.
- (void) saveFileList;

// Reload the list of files.
- (void) reloadFileList;

// Display a dialouge allowing the user to rename the current detailViewController
// instance.
- (void) renameGraphDialouge;

// Replace the old name of the current detailViewController in |self.fileList|
// and update the tableView.
- (void) updateFileName:(NSString *)newName;

- (void) tableView:(UITableView *)tableView deleteGraphAtIndexPath:(NSIndexPath *)indexPath;

- (void) showChooseGraphTypeView;
@end
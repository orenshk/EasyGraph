//
//  EasyGraphMasterViewController.m
//  EasyGraph
//
//  Created by Oren Shklarsky on 12-07-19.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//



#import "EasyGraphMasterViewController.h"

#import "EasyGraphDetailViewController.h"


@implementation EasyGraphInsertOptions
@synthesize options;
@synthesize delegate;

- (void) viewDidLoad {
    [super viewDidLoad];
    
    self.options = [[NSArray alloc] initWithObjects:@"Graph", @"Digraph", nil];
    self.contentSizeForViewInPopover = CGSizeMake(150.0, 88.0);
}

- (void) viewDidUnload {
    [super viewDidUnload];
    self.options = nil;
    self.delegate = nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.options count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.textLabel.text = [self.options objectAtIndex:[indexPath row]];
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.delegate != nil) {
        [self.delegate insertNewObject:[indexPath row]];
    }
}


@end

@interface EasyGraphMasterViewController () {
    NSMutableArray *_objects;
}
@end

@implementation EasyGraphMasterViewController

@synthesize detailViewController = _detailViewController;
@synthesize fetchedResultsController = __fetchedResultsController;
@synthesize managedObjectContext = __managedObjectContext;
@synthesize fileList, graphCanvases, fileListPath, renameDialouge;
@synthesize renameButton, currentSelection, saveDataPath;
@synthesize graphChoiceController, addButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Graphs", @"Graphs");
        self.clearsSelectionOnViewWillAppear = NO;
        self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
        
        self.graphCanvases = [[NSMutableArray alloc] initWithObjects:nil];
        
        NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *docsDir = [dirPaths objectAtIndex:0];
        
        [self setFileListPath:[[NSString alloc] initWithString:[docsDir stringByAppendingPathComponent:@"fileList.archive"]]];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.leftBarButtonItem = self.editButtonItem;

    self.addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(showChooseGraphTypeView)];
    
    UIBarButtonItem *removeAllButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(removeAllAlert)];

    [self.navigationItem setRightBarButtonItems:[NSArray arrayWithObjects:self.addButton, removeAllButton, nil]];
    
    
    
    self.renameButton = [[UIBarButtonItem alloc] initWithTitle:@"Rename"
                                        style:UIBarButtonItemStylePlain target:
                                            self action:@selector(renameGraphDialouge)];
    
    self.detailViewController.navigationItem.rightBarButtonItem = self.renameButton;
    
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [dirPaths objectAtIndex:0];
    self.saveDataPath = [[NSString alloc] initWithString:[docsDir stringByAppendingPathComponent:@"currentSelection.archive"]];
    
    //Check if file exists and set self.vertexSet
    NSFileManager *filemgr = [NSFileManager defaultManager];
    if ([filemgr fileExistsAtPath:self.saveDataPath]) {
        self.currentSelection = [NSKeyedUnarchiver unarchiveObjectWithFile:self.saveDataPath];
        [self.tableView selectRowAtIndexPath:self.currentSelection animated:NO
                              scrollPosition:UITableViewScrollPositionMiddle];
        [self tableView:self.tableView didSelectRowAtIndexPath:self.currentSelection];
    } else {
        self.currentSelection = [[NSIndexPath alloc] init];
    }
}

- (void) saveFileList {
    [NSKeyedArchiver archiveRootObject:self.fileList toFile:self.fileListPath];
}

- (void) reloadFileList {
    [self setFileList:[[NSMutableArray alloc] initWithArray:
                        [NSKeyedUnarchiver unarchiveObjectWithFile:self.fileListPath]]];
}

- (void) removeAllAlert {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Remove All!"
                                                    message:@"This will remove all graphs.\n Are you sure you wish to proceed?" delegate:self cancelButtonTitle:@"Clear List" otherButtonTitles:@"Cancel",nil];
    [alert setTag:0];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if ([alertView tag] == 0) {
        if (buttonIndex == 0) {
            int count = [self.fileList count];
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
            while (count > 0) {
                [self tableView:self.tableView deleteGraphAtIndexPath:indexPath];
                --count;
            }
        }
    } else if (alertView.tag == 1) {
        if (buttonIndex == 1) {
            [self updateFileName:[alertView textFieldAtIndex:0].text];
        }
    }
}

- (void) showChooseGraphTypeView {
    if (self.graphChoiceController == nil) {
        EasyGraphInsertOptions *graphOptions = [[EasyGraphInsertOptions alloc] init];
        [graphOptions setDelegate:self];
        self.graphChoiceController = [[UIPopoverController alloc] initWithContentViewController:graphOptions];
    }
    if ([self.graphChoiceController isPopoverVisible]) {
        [self.graphChoiceController dismissPopoverAnimated:YES];
    } else {
        [self.graphChoiceController presentPopoverFromBarButtonItem:self.addButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

- (void) renameGraphDialouge {
    self.renameDialouge = [[UIAlertView alloc] initWithTitle:@"Rename"
                                                     message:nil
                                                    delegate:self
                                           cancelButtonTitle:@"Cancel"
                                           otherButtonTitles:@"OK", nil];
    [self.renameDialouge setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [self.renameDialouge setTag:1];
    [[self.renameDialouge textFieldAtIndex:0] setDelegate:self];
    [self.renameDialouge show];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.renameDialouge dismissWithClickedButtonIndex:self.renameDialouge.firstOtherButtonIndex animated:YES];
    [self updateFileName:textField.text];
    return YES;
}

- (void) updateFileName:(NSString *)newName {

    // Remove old name
    [self.detailViewController deleteData];
    int fileNo = [self.fileList indexOfObject:[self.detailViewController title]];
    
    // Set new name
    [self.detailViewController setTitle:newName];
    [self.fileList replaceObjectAtIndex:fileNo withObject:newName];
    [self.detailViewController saveData];
    [self.detailViewController updateTitle:newName];
    [self saveFileList];
    
    // update tableView
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:fileNo inSection:0];
    [[self tableView] reloadRowsAtIndexPaths:[[NSArray alloc]
                         initWithObjects:indexPath, nil] withRowAnimation:NO];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    self.fileList = nil;
    self.graphCanvases = nil;
    self.fileListPath = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)insertNewObject:(int)row
{
    int graphCount = [self.fileList count] + 1;
    BOOL isDirected;
    [self.graphChoiceController dismissPopoverAnimated:YES];
    NSMutableString *newGraph = [NSMutableString stringWithFormat:@"Untitled_%d", graphCount];
    [self.fileList addObject:newGraph];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:graphCount - 1 inSection:0];
    [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    
    NSString *subtitle;
    if (row == 1) {
        isDirected = YES;
        subtitle = @"(Directed)";
    } else {
        isDirected = NO;
        subtitle = @"(Undirected)";
    }
    
    EasyGraphDetailViewController *newDetailViewController =
                [[EasyGraphDetailViewController alloc] initWithNibName:
                 @"EasyGraphDetailViewController" title:newGraph];
    
    [newDetailViewController.navigationItem setRightBarButtonItem:self.renameButton];
    [newDetailViewController setIsDirected:isDirected];
    [newDetailViewController setUpTitleViewWithTitle:newGraph andSubtitle:subtitle];
    [self.graphCanvases addObject:newDetailViewController];
    [self.tableView selectRowAtIndexPath:indexPath animated:YES
                          scrollPosition:UITableViewScrollPositionMiddle];
    [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
    [self saveFileList];
}

- (void) tableView:(UITableView *)tableView deleteGraphAtIndexPath:(NSIndexPath *)indexPath { 
    NSString *fileName = [self.fileList objectAtIndex:indexPath.row];
    NSString *title = [self.detailViewController title];
    [self.fileList removeObjectAtIndex:indexPath.row];
    [[self.graphCanvases objectAtIndex:indexPath.row] deleteData];
    [self.graphCanvases removeObjectAtIndex:indexPath.row];
    [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    
    // If deleted canvas is being viewed, make a switch
    if (title == fileName && [self.fileList count] > 0) {
        NSIndexPath *newIndexPath;
        if (indexPath.row == 0) {
            newIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        } else {
            newIndexPath = [NSIndexPath indexPathForRow:indexPath.row - 1 inSection:0];
        }
        [self.tableView selectRowAtIndexPath:newIndexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
        [self tableView:self.tableView didSelectRowAtIndexPath:newIndexPath];
    }
    
    if ([self.fileList count] == 0) {
        [self insertNewObject:0];
    }
    [self saveFileList];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.fileList count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.textLabel.text = [fileList objectAtIndex:[indexPath row]];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self tableView:tableView deleteGraphAtIndexPath:indexPath];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    EasyGraphDetailViewController *newDetailViewController = [self.graphCanvases objectAtIndex:indexPath.row];
    UIBarButtonItem *leftButton = self.detailViewController.navigationItem.leftBarButtonItem;
    UINavigationController *detailNavigationController = [[UINavigationController alloc] initWithRootViewController:newDetailViewController];
    [newDetailViewController.navigationItem setLeftBarButtonItem:leftButton];
    [newDetailViewController.navigationItem setRightBarButtonItem:self.renameButton];
    self.detailViewController = newDetailViewController;
    NSArray *viewControllers = [[NSArray alloc] initWithObjects:self.navigationController, detailNavigationController, nil];
    self.splitViewController.delegate = newDetailViewController;
    self.splitViewController.viewControllers = viewControllers;
    [self setCurrentSelection:indexPath];
    [NSKeyedArchiver archiveRootObject:self.currentSelection toFile:self.saveDataPath];
}

@end

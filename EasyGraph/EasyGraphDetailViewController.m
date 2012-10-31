//
//  EasyGraphDetailViewController.m
//  EasyGraph
//
//  Created by Oren Shklarsky on 12-07-19.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EasyGraphDetailViewController.h"

@implementation UIBarButtonItemWithObject
@synthesize intendedObject;

@end

@interface EasyGraphDetailViewController ()
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
//- (void)configureView;
@end

@implementation EasyGraphDetailViewController
@synthesize masterPopoverController = _masterPopoverController;
@synthesize undoButton, redoButton, subdivideButton, contractButton, nonEdgeButton;
@synthesize removeElementsButton, easyGraphCanvas;
@synthesize gridSize, vertexSet, movingVertexView, edgeStartPoint;
@synthesize inRemoveMode, undoManager, saveDataPath, inSubdivideMode;
@synthesize inContractMode, vertexFrameSize, vertexColour, edgeColour;
@synthesize colourPickerPopoverController, exportButton, pdfButton, latexPSTButton;
@synthesize isDirected, relabelDialouge;

#pragma mark - Managing the detail item


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"", @"");
    }
    return self;
}

- (id) initWithNibName:(NSString *)nibNameOrNil title:(NSString *)titleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nil];
    if (self) {
        self.title = NSLocalizedString(titleOrNil, titleOrNil);
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.vertexFrameSize = 70;
    self.vertexSet = [[NSMutableSet alloc] init];
    self.movingVertexView = nil;
    self.gridSize = 30;
    self.hidingLabels = NO;
    self.inRemoveMode = NO;
    self.inSubdivideMode = NO;
    self.changingVertexColor = NO;
    self.inSelectMode = NO;
    self.vertexColour = [UIColor blackColor];
    self.edgeColour = [UIColor blackColor];
    prevNumberOfTouches = 1;
    [self.renameView setDelegate:self];
    self.selectedElements = [[NSMutableSet alloc] init];
    
    [self configureGraphCanvasView];
    
    [self.modesButton setPossibleTitles:[NSSet setWithObjects:@"Mode: None",
                                                              @"Mode: Select",
                                                              @"Mode: Remove",
                                                              @"Mode: Subdivide",
                                                              @"Mode: Contract",
                                                              @"Mode: Non-Edge", nil]];
    
    self.undoManager = [[NSUndoManager alloc] init];
    
    [self.undoButton setEnabled:NO];
    [self.redoButton setEnabled:NO];
    
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [dirPaths objectAtIndex:0];
    NSString *fileName = [NSString stringWithFormat:@"%@.archive", self.title];
    
    [self setSaveDataPath:[[NSString alloc] initWithString:[docsDir stringByAppendingPathComponent:fileName]]];
    
    //Check if file exists and set self.vertexSet
    NSFileManager *filemgr = [NSFileManager defaultManager];
    if ([filemgr fileExistsAtPath:self.saveDataPath]) {
        [self reloadData];
    }
    
    self.vertexColourButton = [[UIBarButtonItem alloc] initWithTitle:@"Vertex" style:UIBarButtonItemStyleBordered target:self action:@selector(openColourPicker:)];
    [self.vertexColourButton setTintColor:self.vertexColour];
    [self.vertexColourButton setTag:0];
    
    self.edgeColourButton = [[UIBarButtonItem alloc] initWithTitle:@"Edge" style:UIBarButtonItemStyleBordered target:self action:@selector(openColourPicker:)];
    [self.edgeColourButton setTintColor:self.edgeColour];
    [self.edgeColourButton setTag:1];
    
    NSArray *rightButtons = [[NSArray alloc] initWithObjects:[self.navigationItem rightBarButtonItem], self.vertexColourButton, self.edgeColourButton, nil];
    [self.navigationItem setRightBarButtonItems:rightButtons animated:NO];
    
    self.exportButton = [[UIBarButtonItem alloc] initWithTitle:@"Export" style:UIBarButtonItemStyleBordered target:self action:@selector(exportDialoug:)];
    NSArray *leftButtons = [[NSArray alloc] initWithObjects:[self.navigationItem leftBarButtonItem], self.exportButton, nil];
    [self.navigationItem setLeftBarButtonItems:leftButtons];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    [self saveData];
}

- (void) setUpTitleViewWithTitle:(NSString *)title andSubtitle:(NSString *)subtitle {
    // Replace titleView
    CGRect headerTitleSubtitleFrame = CGRectMake(0, 0, 200, 44);
    UIView* _headerTitleSubtitleView = [[UILabel alloc] initWithFrame:headerTitleSubtitleFrame];
    _headerTitleSubtitleView.backgroundColor = [UIColor clearColor];
    _headerTitleSubtitleView.autoresizesSubviews = YES;
    
    CGRect titleFrame = CGRectMake(0, 2, 200, 24);
    UILabel *titleView = [[UILabel alloc] initWithFrame:titleFrame];
    titleView.backgroundColor = [UIColor clearColor];
    titleView.font = [UIFont boldSystemFontOfSize:20];
    titleView.textAlignment = UITextAlignmentCenter;
    titleView.textColor = [UIColor darkGrayColor];
    titleView.text = title;
    titleView.adjustsFontSizeToFitWidth = YES;
    [_headerTitleSubtitleView addSubview:titleView];
    
    CGRect subtitleFrame = CGRectMake(0, 24, 200, 44-24);
    UILabel *subtitleView = [[UILabel alloc] initWithFrame:subtitleFrame];
    subtitleView.backgroundColor = [UIColor clearColor];
    subtitleView.font = [UIFont boldSystemFontOfSize:13];
    subtitleView.textAlignment = UITextAlignmentCenter;
    subtitleView.textColor = [UIColor darkGrayColor];
    subtitleView.text = subtitle;
    subtitleView.adjustsFontSizeToFitWidth = YES;
    [_headerTitleSubtitleView addSubview:subtitleView];
    
    _headerTitleSubtitleView.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin |
                                                 UIViewAutoresizingFlexibleRightMargin |
                                                 UIViewAutoresizingFlexibleTopMargin |
                                                 UIViewAutoresizingFlexibleBottomMargin);
    
    self.navigationItem.titleView = _headerTitleSubtitleView;
}

- (void) updateTitle:(NSString *) title {
    UIView* headerTitleSubtitleView = self.navigationItem.titleView;
    UILabel* titleView = [headerTitleSubtitleView.subviews objectAtIndex:0];
    titleView.text = title;
    
}

- (void) updateSubtitle:(NSString *)subtitle {
    UIView* headerTitleSubtitleView = self.navigationItem.titleView;
    UILabel* subtitleView = [headerTitleSubtitleView.subviews objectAtIndex:1];
    subtitleView.text = subtitle;
}

- (void) configureGraphCanvasView {
    int mult = 1;
    int width = mult *768;
    int height = mult * 916;
    self.easyGraphCanvas = [[EasyGraphCanvas alloc] initWithFrame:CGRectMake(0, 0, width, height)];
    [self.easyGraphCanvas setGridSize:self.gridSize];
    [self.easyGraphCanvas setMultipleTouchEnabled:YES];
    [self.view addSubview:self.easyGraphCanvas];

    UIPanGestureRecognizer *panDetector =
    [[UIPanGestureRecognizer alloc]
     initWithTarget:self action:@selector(handlePanGesture:)];
    [panDetector setMaximumNumberOfTouches:2];
    [self.easyGraphCanvas addGestureRecognizer:panDetector];
    [panDetector setDelegate:self];
    
    UITapGestureRecognizer *singleTap =
    [[UITapGestureRecognizer alloc]
     initWithTarget:self action:@selector(handleSingleTap:)];
    [self.easyGraphCanvas addGestureRecognizer:singleTap];
    [singleTap setDelegate:self];

    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    [longPress setMinimumPressDuration:0.5];
    [self.easyGraphCanvas addGestureRecognizer:longPress];

    
    UIRotationGestureRecognizer *rotate = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotate:)];
    [self.easyGraphCanvas addGestureRecognizer:rotate];

}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (IBAction)handleRotate:(UIRotationGestureRecognizer *)sender {
    if (self.movingVertexView == nil && self.edgeStartPoint == nil) {
        float rotation = self.angle + sender.rotation;
        self.easyGraphCanvas.transform = CGAffineTransformMakeRotation(rotation);
        
        
        if (sender.state == UIGestureRecognizerStateEnded) {
            if (-0.2 <= rotation && rotation <= 0.2) {
                self.easyGraphCanvas.transform = CGAffineTransformMakeRotation(0);
                rotation = 0;
            }
            self.angle = rotation;
        }
        
        //snaps
        // redraw grid?
    }
}

- (void)viewDidUnload
{
    [self setMenuPopoverController:nil];
    [self setRelabelDialouge:nil];
    [self setExportButton:nil];
    [self setLabelsMenuButton:nil];
    [self setEditButton:nil];
    [self setModesButton:nil];
    [self setScrollView:nil];
    [self setRenameView:nil];
    [super viewDidUnload];
    [self setRemoveElementsButton:nil];
    [self setUndoButton:nil];
    [self setRedoButton:nil];
    [self setSubdivideButton:nil];
    [self setContractButton:nil];
    [self setNonEdgeButton:nil];
    
    // Release any retained subviews of the main view.
    [self setVertexSet:nil];
    [self setMovingVertexView:nil];
    [self setEdgeStartPoint:nil];
    [self setUndoManager:nil];
    for (UIView *view in [self.easyGraphCanvas subviews]) {
        [view removeFromSuperview];
    }
    [self.easyGraphCanvas removeFromSuperview];
    [self setEasyGraphCanvas:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (interfaceOrientation != UIInterfaceOrientationPortrait) {
        return NO;
    }
    return YES;
}

- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
        self.easyGraphCanvas.frame = CGRectMake(0, 0, 916, 660);
    } else {
        self.easyGraphCanvas.frame = CGRectMake(0, 0, 768, 916);
        [self.navigationItem setLeftBarButtonItems:[NSArray arrayWithObjects:[self.navigationItem leftBarButtonItem], self.exportButton, nil]];
     }
    [self.easyGraphCanvas setNeedsDisplay];
}
							
#pragma mark - Split view

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"Files", @"Files");
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}

/*******************************************************************************
                                    Archiving
*******************************************************************************/

- (void) reloadData {
    self.saveDataPath = [self updateFileName];
    NSArray *dataArray = [NSKeyedUnarchiver unarchiveObjectWithFile:self.saveDataPath];
    NSMutableSet *vertices = [dataArray objectAtIndex:0];
    NSMutableSet *edgeSet = [[NSMutableSet alloc] init];
    for (EasyGraphVertexView *vert in vertices) {
        [self.vertexSet addObject:vert];
        [vert setupVertexLabelAndColour:[vert colour]];
        [self.easyGraphCanvas addSubview:vert];
        [edgeSet addObjectsFromArray:[vert.inNeighbs allObjects]];
        [edgeSet addObjectsFromArray:[vert.outNeighbs allObjects]];
        [vert.inNeighbs removeAllObjects];
        [vert.outNeighbs removeAllObjects];
    }
    [self setIsDirected:[[dataArray objectAtIndex:1] boolValue]];
    for (EasyGraphEdgeView *edge in edgeSet) {
        [self.easyGraphCanvas setCurvePoints:[NSMutableArray arrayWithArray:[edge curvePoints]]];
        [self setEdgeColour:edge.colour];
        [self makeNewEdgeFromVertex:edge.startVertex toVertex:edge.endVertex isNonEdge:[edge isNonEdge]];
    }
    [self.easyGraphCanvas.curvePoints removeAllObjects];
    [self setEdgeColour:[UIColor blackColor]];
    NSString *subtitle = [self isDirected] ? @"(Directed)" : @"(Undirected)";
    [self setUpTitleViewWithTitle:[self title] andSubtitle:subtitle];
}

- (void) saveData {
    self.saveDataPath = [self updateFileName];
    NSArray *toArchive = [NSArray arrayWithObjects:self.vertexSet, [NSNumber numberWithBool:self.isDirected], nil];
    [NSKeyedArchiver archiveRootObject:toArchive toFile:self.saveDataPath];
}

- (void) deleteData {
    self.saveDataPath = [self updateFileName];
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    [fileMgr removeItemAtPath:self.saveDataPath error:nil];
}

#pragma mark - Graph Drawing

/*******************************************************************************
                                Touch Handling
*******************************************************************************/

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint locationPoint = [touch locationInView:self.easyGraphCanvas];
    UIView *touched = [self.easyGraphCanvas hitTest:locationPoint withEvent:nil];
    if ([touch tapCount] == 2) {
        if ([touched isKindOfClass:[EasyGraphVertexView class]]) {
            self.movingVertexView = (EasyGraphVertexView *)touched;
            self.edgeStartPoint = nil;
            self.easyGraphCanvas.fingerStartPoint = CGPointZero;
            self.easyGraphCanvas.fingerCurrPos = CGPointZero;
            self.easyGraphCanvas.drawingEdge = NO;
            
            [self highlightVertex:self.movingVertexView];
            
            [[self.undoManager prepareWithInvocationTarget:self]
             undoVertexMove:self.movingVertexView atOriginalPoint:movingVertexView.center];
        }
    } else {
        if (self.movingVertexView != nil) {
            [self unhighlightVertex:self.movingVertexView];
        }
        self.edgeStartPoint = [touched isKindOfClass:[EasyGraphVertexView class]] ? (EasyGraphVertexView *)touched : nil;
        self.movingVertexView = nil;
        self.easyGraphCanvas.fingerStartPoint = locationPoint;
        self.easyGraphCanvas.drawingEdge = self.edgeStartPoint != nil;
    }
}

- (IBAction)handleLongPress:(UIGestureRecognizer *)sender {
    if ([sender state] == UIGestureRecognizerStateBegan) {
        CGPoint location = [sender locationInView:self.easyGraphCanvas];
        [self showFloatingMenuAtLocation:location];
    }
}

- (IBAction)handleSingleTap:(UITapGestureRecognizer *)sender {
    CGPoint locationPoint = [sender locationOfTouch:0 inView:self.easyGraphCanvas];
    UIView *touched = [self.easyGraphCanvas hitTest:locationPoint withEvent:nil];
    if (self.inRemoveMode) {
        if ([touched isKindOfClass:[EasyGraphVertexView class]]) {
            [self removeVertex:(EasyGraphVertexView *)touched];
        } else if ([touched isKindOfClass:[EasyGraphEdgeView class]]) {
            [self removeEdgeFromVertexAt:
                ((EasyGraphEdgeView *)touched).startVertex.center
                              toVertexAt:((EasyGraphEdgeView *)touched).endVertex.center];
        }
    } else if (self.inSubdivideMode) {
        if ([touched isKindOfClass:[EasyGraphEdgeView class]]) 
            [self subdivide:(EasyGraphEdgeView *)touched atPoint:locationPoint];
        
    } else if (self.inContractMode) {
        if ([touched isKindOfClass:[EasyGraphEdgeView class]])
            [self contract:(EasyGraphEdgeView *)touched];
        
    } else if (self.inSelectMode) {
        EasyGraphElement *elt = (EasyGraphElement *)touched;
        if ([self.selectedElements containsObject:elt]) {
            [self unhighlightElement:elt];
            [self.selectedElements removeObject:elt];
            if ([self.selectedElements count] == 0) {
                [self.floatingMenuPopoverController dismissPopoverAnimated:YES];
            }
        } else {
            [self highlightElement:elt];
            [self.selectedElements addObject:elt];
            if ([self.selectedElements count] == 1) {
                [self showFloatingMenuAtLocation:locationPoint];
            }
        }
    } else if (![touched isKindOfClass:[EasyGraphVertexView class]] &&
            ![touched isKindOfClass:[EasyGraphEdgeView class]] &&
                                                self.edgeStartPoint == nil) {
            [self makeNewVertex:locationPoint];
        
    }
}

- (IBAction)handlePanGesture:(UIPanGestureRecognizer *)sender {
    if (self.movingVertexView != nil) {
        EasyGraphVertexView *vert = self.movingVertexView;


        if (sender.state == UIGestureRecognizerStateEnded) {
            CGPoint endPt = [self getClosestGridPointToPoint:self.movingVertexView.center];
            
            self.movingVertexView.frame = CGRectMake(endPt.x - self.vertexFrameSize/2.0, endPt.y - self.vertexFrameSize/2.0, self.vertexFrameSize, self.vertexFrameSize);

            [self unhighlightVertex:vert];
            [self updateEdgesFor:self.movingVertexView];

            self.movingVertexView = nil;
        } else {
            CGPoint translation = [sender translationInView:self.easyGraphCanvas];
            CGPoint vertexViewPosition = self.movingVertexView.center;
            vertexViewPosition.x += translation.x;
            vertexViewPosition.y += translation.y;
            self.movingVertexView.center = vertexViewPosition;
            [self highlightVertex:vert];
            [self updateEdgesFor:self.movingVertexView];
        }        
        [sender setTranslation:CGPointZero inView:self.easyGraphCanvas];
    } else if (self.edgeStartPoint != nil) {
        
        // draw edge
        CGPoint locationPoint = [sender locationInView:self.easyGraphCanvas];
        self.easyGraphCanvas.fingerCurrPos = locationPoint;
        if ([sender numberOfTouches] == 2) {
            if (prevNumberOfTouches == 1) {
                prevNumberOfTouches = 2;
            }
        } else if (prevNumberOfTouches == 2) {
            [self.easyGraphCanvas.curvePoints addObject:[NSValue valueWithCGPoint:[sender locationOfTouch:0 inView:self.easyGraphCanvas]]];
            prevNumberOfTouches = 1;
        } else {
            [self.easyGraphCanvas setNeedsDisplay];
        }
        UIView *touched = [self.easyGraphCanvas hitTest:locationPoint withEvent:nil];
        
            
        // If passing through another vertex make new edge to that vertex
        // and start over
        if (touched != self.edgeStartPoint && [touched isKindOfClass:[EasyGraphVertexView class]]) {
            [self makeNewEdgeFromVertex:self.edgeStartPoint toVertex:(EasyGraphVertexView *)touched
                                isNonEdge:[self.easyGraphCanvas inNonEdgeMode]];
            self.edgeStartPoint = (EasyGraphVertexView *)touched;
            self.easyGraphCanvas.fingerStartPoint = self.edgeStartPoint.center;
            [self.easyGraphCanvas.curvePoints removeAllObjects];
        }
        
        // add edge to VertexViews
        if (sender.state == UIGestureRecognizerStateEnded) {
            touched = [self.easyGraphCanvas hitTest:[self getClosestGridPointToPoint:locationPoint] withEvent:nil];
            EasyGraphVertexView *edgeEndPoint;
            if (![touched isKindOfClass:[EasyGraphVertexView class]]) { //What about edge class?
                
                edgeEndPoint = [self makeNewVertex:locationPoint];
                [self makeNewEdgeFromVertex:self.edgeStartPoint toVertex:edgeEndPoint
                                isNonEdge:[self.easyGraphCanvas inNonEdgeMode]];
            }
            self.edgeStartPoint = nil;
            [self.easyGraphCanvas setDrawingEdge:NO];
            [self.easyGraphCanvas setFingerCurrPos:CGPointZero];
            [self.easyGraphCanvas setFingerStartPoint:CGPointZero];
            [self.easyGraphCanvas.curvePoints removeAllObjects];
        }
    }
    [self.view setNeedsDisplay];
}

/*******************************************************************************
                            Vertex and Edge Manipulation
*******************************************************************************/

- (EasyGraphVertexView *) makeNewVertex:(CGPoint)fingerPos {
    CGPoint grid = [self getClosestGridPointToPoint:fingerPos];
    EasyGraphVertexView *vert = [[EasyGraphVertexView alloc]
                        initWithFrame:CGRectMake(grid.x - self.vertexFrameSize/2.0, grid.y - self.vertexFrameSize/2.0, self.vertexFrameSize, self.vertexFrameSize)];
    

    [self.easyGraphCanvas addSubview:vert];
    
    [self.vertexSet addObject:vert];
    [vert setVertexNum:[self.vertexSet count]];
    
    [vert setColour:self.vertexColour];
    if (self.hidingLabels) {
        [[vert label] removeFromSuperview];
    }
    [[self.undoManager prepareWithInvocationTarget:self] removeVertex:vert];
    [self.undoButton setEnabled:YES];
    
    [self saveData];
    return vert;
}

- (EasyGraphEdgeView *) makeNewEdgeFromVertex:(EasyGraphVertexView *)start toVertex:(EasyGraphVertexView *)end isNonEdge:(BOOL)nonEdge {
    EasyGraphEdgeView *newEdgeView = nil;
    if (![self isNeighbour:start of:end]) {
        CGRect rect;
        rect = [self makeEdgeRectForEdgeFromPoint:[NSValue valueWithCGPoint:start.center]
                                  toPoint:[NSValue valueWithCGPoint:end.center]];
        newEdgeView = [[EasyGraphEdgeView alloc] initWithFrame:rect
                                          andStartPnt:start andEndPnt:end];
        [newEdgeView setCurvePoints:[NSMutableArray arrayWithArray:[self.easyGraphCanvas curvePoints]]];
        [newEdgeView setIsNonEdge:nonEdge];
        [newEdgeView setColour:self.edgeColour];
        [newEdgeView setIsDirected:self.isDirected];
        
        [self.easyGraphCanvas addSubview:newEdgeView];
        
        [start.outNeighbs addObject:newEdgeView];
        [end.inNeighbs addObject:newEdgeView];
        
        for (UIView *view in self.easyGraphCanvas.subviews) {
            if ([view isKindOfClass:[EasyGraphVertexView class]]) {
                [self.easyGraphCanvas bringSubviewToFront:view];
            }
        }
        [[self.undoManager prepareWithInvocationTarget:self]
         removeEdgeFromVertexAt:start.center toVertexAt:end.center];
        [self.undoButton setEnabled:YES];
    }
    [self saveData];
    return newEdgeView;
}

- (void) updateEdgesFor:(EasyGraphVertexView *)vert {
    NSSet *neighbs = [[NSSet alloc] initWithSet:[vert.inNeighbs setByAddingObjectsFromSet:vert.outNeighbs]];
    CGRect newRect;
    CGPoint start, end;
    for (EasyGraphEdgeView *edge in [neighbs allObjects]) {
        [edge setOpaque:NO];
        start = edge.startVertex.center;
        end = edge.endVertex.center;
        [self.easyGraphCanvas setCurvePoints:[NSMutableArray arrayWithArray:[edge curvePoints]]];
        newRect = [self makeEdgeRectForEdgeFromPoint:[NSValue valueWithCGPoint:start]
                                     toPoint:[NSValue valueWithCGPoint:end]];
        [self.easyGraphCanvas.curvePoints removeAllObjects];
        [edge setFrame:newRect];
        [edge setNeedsDisplay];
    }
    [self saveData];
}

- (void) removeVertex:(EasyGraphVertexView *)vert {
    NSSet *outCopy = [[NSSet alloc] initWithSet:vert.outNeighbs];
    for (EasyGraphEdgeView *edge in outCopy) {
        [self removeEdgeFromVertexAt:vert.center toVertexAt:edge.endVertex.center];
    }
    
    NSSet *inCopy = [[NSSet alloc] initWithSet:vert.inNeighbs];
    for (EasyGraphEdgeView *edge in inCopy) {
        [self removeEdgeFromVertexAt:edge.startVertex.center toVertexAt:vert.center];
    }

    [[self.undoManager prepareWithInvocationTarget:self] undoVertexDelete:vert];
    [self.undoButton setEnabled:YES];
    
    [self.vertexSet removeObject:vert];
    [vert removeFromSuperview];
    
    [self saveData];
    
}

- (void) removeEdgeFromVertexAt:(CGPoint)start toVertexAt:(CGPoint)end {
    EasyGraphEdgeView *edge;
    EasyGraphVertexView *startVert, *endVert;
    
    // Find vertices at start and end points
    for (UIView *view in self.vertexSet) {
        if ([view pointInside:[self.easyGraphCanvas convertPoint:start toView:view] withEvent:nil]) {
            startVert = (EasyGraphVertexView *)view;
        } else if ([view pointInside:[self.easyGraphCanvas convertPoint:end toView:view] withEvent:nil]) {
            endVert = (EasyGraphVertexView *)view;
        }
    }
    
    // Find the edge.
    for (EasyGraphEdgeView *e in startVert.outNeighbs) {
        if (endVert == e.endVertex) {
            edge = e;
            break;
        }
    }
    
    // Remove edge
    [edge.startVertex.outNeighbs removeObject:edge];
    [edge.endVertex.inNeighbs removeObject:edge];
    [edge removeFromSuperview];
    
    [[self.undoManager prepareWithInvocationTarget:self] undoEdgeDelete:edge];

    [self.undoButton setEnabled:YES];
    [self saveData];
}

- (void) undoEdgeDelete:(EasyGraphEdgeView *)edge {
    [self.easyGraphCanvas setCurvePoints:[NSMutableArray arrayWithArray:[edge curvePoints]]];
    [self.easyGraphCanvas setEdgeColour:[edge colour]];
    EasyGraphEdgeView *tempEdge = [self makeNewEdgeFromVertex:edge.startVertex toVertex:edge.endVertex isNonEdge:edge.isNonEdge];
    [tempEdge setColour:[edge colour]];
    [self.easyGraphCanvas.curvePoints removeAllObjects];
    [self.easyGraphCanvas setEdgeColour:[self edgeColour]];
}

- (void) undoVertexDelete:(EasyGraphVertexView *)vert {
    
    [self.vertexSet addObject:vert];
    [self.easyGraphCanvas addSubview:vert];
    [self unhighlightVertex:vert];
    
    [vert.inNeighbs removeAllObjects];
    [vert.outNeighbs removeAllObjects];
    [[self.undoManager prepareWithInvocationTarget:self] removeVertex:vert];
    [self.undoButton setEnabled:YES];
    
    [self saveData];
}

- (void) undoVertexMove:(EasyGraphVertexView *)vert atOriginalPoint:(CGPoint)point {
    [[self.undoManager prepareWithInvocationTarget:self] undoVertexMove:vert atOriginalPoint:vert.center];
    vert.center = point;
    [self updateEdgesFor:vert];
    
    [self saveData];
}

- (void) subdivide:(EasyGraphEdgeView *)edge atPoint:(CGPoint)point {
    [self removeEdgeFromVertexAt:edge.startVertex.center toVertexAt:edge.endVertex.center];
    EasyGraphVertexView *new_vert = [self makeNewVertex:point];
    [self makeNewEdgeFromVertex:edge.startVertex toVertex:new_vert isNonEdge:NO]; //ignore non edges when subdividing
    [self makeNewEdgeFromVertex:new_vert toVertex:edge.endVertex isNonEdge:NO];
    
    [self saveData];
}

- (void) contract:(EasyGraphEdgeView *)edge {
    EasyGraphVertexView *endVert = edge.endVertex;
    for (EasyGraphEdgeView *oldEdge in endVert.outNeighbs) {
        [self makeNewEdgeFromVertex:edge.startVertex toVertex:oldEdge.endVertex isNonEdge:NO]; // ignore non edges when contracting
    }
    for (EasyGraphEdgeView *oldEdge in endVert.inNeighbs) {
        if (oldEdge.startVertex != edge.startVertex) {
            [self makeNewEdgeFromVertex:oldEdge.startVertex toVertex:edge.startVertex isNonEdge:NO];
        }
    }
    [self removeVertex:endVert];
    
    [self saveData];
}

/*******************************************************************************
                                Buttons and other UI
 *******************************************************************************/

#pragma mark - Buttons and other UI

- (void) showFloatingMenuAtLocation:(CGPoint) location {
    UIView *view = [self.easyGraphCanvas hitTest:location withEvent:nil];
    if ([view isKindOfClass:[EasyGraphVertexView class]] ||
        [view isKindOfClass:[EasyGraphEdgeView class]]) {
        
        int tag;
        NSMutableArray *passThrough = [[NSMutableArray alloc] init];
        if ([view isKindOfClass:[EasyGraphVertexView class]]) {
            [self.selectedElements addObject:(EasyGraphVertexView *)view];
            [self highlightVertex:(EasyGraphVertexView *)view];
            tag = 0;
            if (view.frame.origin.y <= 835) {
                location.y = view.frame.origin.y + 75;
            } else {
                location.y = view.frame.origin.y - 25;
            }
        } else {
            [self.selectedElements addObject:(EasyGraphEdgeView *)view];
            [self highlightEdge:(EasyGraphEdgeView *)view];
            tag = 1;
        }
        
        if (self.inSelectMode) {
            tag = 0;
            [passThrough addObject:self.easyGraphCanvas];
        }
        CGRect anchor = CGRectMake(location.x, location.y, 263, 30);
        
        self.floatingMenuPopoverController = [[UIPopoverController alloc] initWithContentViewController:[self makeFloatingMenuWithTag:tag]];
        [self.floatingMenuPopoverController setDelegate:self];
        [self.floatingMenuPopoverController setPopoverContentSize:CGSizeMake(263, 30)];
        [self.floatingMenuPopoverController setPassthroughViews:passThrough];
        [self.floatingMenuPopoverController setPopoverBackgroundViewClass:[EasyGraphPopoverBackgroundView class]];
        [self.floatingMenuPopoverController
         presentPopoverFromRect:anchor inView:self.easyGraphCanvas
         permittedArrowDirections:0 animated:YES];
    }
}

- (UINavigationController *) makeFloatingMenuWithTag:(int) tag {
    UIViewController *viewController = [[UIViewController alloc] init];
    
    UIBarButtonItem *delete = [[UIBarButtonItem alloc] initWithTitle:@"Delete" style:UIBarButtonItemStyleBordered target:self action:@selector(processDelete:)];
    [delete setTintColor:[UIColor grayColor]];
    
    UIBarButtonItem *rename = [[UIBarButtonItem alloc] initWithTitle:@"Rename" style:UIBarButtonItemStyleBordered target:self action:@selector(showRenamePopover:)];
    [rename setTintColor:[UIColor grayColor]];
    
    UIBarButtonItem *color = [[UIBarButtonItem alloc] initWithTitle:@"Color" style:UIBarButtonItemStyleBordered target:self action:@selector(openColourPicker:)];
    [color setTintColor:[UIColor grayColor]];
    
    [color setTag:tag];
    
    UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelSelection:)];
    
    NSArray *buttons = [NSArray arrayWithObjects:cancel, delete, rename, color, nil];
    [viewController.navigationItem setRightBarButtonItems:buttons];
    
    return [[UINavigationController alloc] initWithRootViewController:viewController];
}

- (void) cancelSelection:(UIBarButtonItem *)sender {
    if (self.inSelectMode) {
        [self toggleSelectMode];
    } else {
        [self.floatingMenuPopoverController dismissPopoverAnimated:YES];
        [self popoverControllerDidDismissPopover:self.floatingMenuPopoverController];
    }
}

-(BOOL) textFieldShouldBeginEditing:(UITextField *)textField {
    return YES;
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    if ([[textField placeholder] isEqualToString:@"Enter new label letter"]) {
        [self renameElement:textField];
    }

    [textField resignFirstResponder];
    return YES;
}

- (void)keyboardWillHide:(NSNotification *)notification {
//    NSDictionary* keyboardInfo = [notification userInfo];
//    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameBeginUserInfoKey];
//    CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
//    [self setViewMoveUp:NO withRect:keyboardFrameBeginRect];
}


- (void)keyboardWillShow:(NSNotification *)notification {
//    NSDictionary* keyboardInfo = [notification userInfo];
//    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameBeginUserInfoKey];
//    CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
//    [self setViewMoveUp:YES withRect:keyboardFrameBeginRect];
}

//method to move the view up/down whenever the keyboard is shown/dismissed
-(void)setViewMoveUp:(BOOL)moveUp withRect:(CGRect)keyRect {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3]; // if you want to slide up the view
    [UIView setAnimationBeginsFromCurrentState:YES];
    
    CGRect rect = self.view.frame;
    if (moveUp)
    {
        // 1. move the view's origin up so that the text field that will be hidden come above the keyboard
        // 2. increase the size of the view so that the area behind the keyboard is covered up.
        
        if (rect.origin.y == 0 ) {
            rect.origin.y -= keyRect.size.height;
            //rect.size.height += kOFFSET_FOR_KEYBOARD;
        }
    }
    else
    {
        rect.origin.y += keyRect.size.height;
        //rect.size.height -= kOFFSET_FOR_KEYBOARD;
    }
    self.view.frame = rect;
    [UIView commitAnimations];
}

- (void) showRenamePopover:(UIBarButtonItem *)sender {
    if (self.renamePopoverController == nil) {
        UIViewController *viewController = [[UIViewController alloc] init];
        [viewController.view addSubview:self.renameView];
        self.renamePopoverController = [[UIPopoverController alloc] initWithContentViewController:viewController];
        [self.renamePopoverController setPopoverContentSize:self.renameView.frame.size];
        [self.renamePopoverController setPopoverBackgroundViewClass:[EasyGraphPopoverBackgroundView class]];
    }
    if ([self.renamePopoverController isPopoverVisible]) {
        [self.renamePopoverController dismissPopoverAnimated:YES];
    } else {
        [self.renamePopoverController presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

- (IBAction)renameElement:(UITextField *)sender {
    for (EasyGraphElement *element in self.selectedElements) {
        [[self.undoManager prepareWithInvocationTarget:self] undoElement:element rename:[element letter]];
        [element setLetter:[sender text]];
        [self unhighlightElement:element];
        [element setOpaque:NO];
        [element setNeedsDisplay];
    }
    [self.selectedElements removeAllObjects];
    [sender setText:@""];
    [sender setPlaceholder:@"Enter new label letter"];
    [self.renamePopoverController dismissPopoverAnimated:YES];
    [self toggleSelectMode];
    [self saveData];
}

- (void) undoElement:(EasyGraphElement *)elt rename:(NSString *)letter {
    UITextField *sender = [[UITextField alloc] init];
    [sender setText:letter];
    [self.selectedElements addObject:elt];
    [self renameElement:sender];
}

- (void) processDelete:(UIBarButtonItemWithObject *)sender {
    for (UIView *view in self.selectedElements) {
        if ([view isKindOfClass:[EasyGraphEdgeView class]]) {
            EasyGraphEdgeView *edge = (EasyGraphEdgeView *)view;
            [self removeEdgeFromVertexAt:edge.startVertex.center toVertexAt:edge.endVertex.center];
        } else if ([view isKindOfClass:[EasyGraphVertexView class]]) {
            [self removeVertex:(EasyGraphVertexView *)view];
        }
    }
    [self.selectedElements removeAllObjects];
    [self toggleSelectMode];
}

- (void) popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    for (EasyGraphElement *elt in self.selectedElements) {
        [self unhighlightElement:elt];
    }
    [self.selectedElements removeAllObjects];
}

- (void) highlightElement:(EasyGraphElement *)elt {
    if ([elt isKindOfClass:[EasyGraphVertexView class]]) {
        [self highlightVertex:(EasyGraphVertexView *)elt];
    } else {
        [self highlightEdge:(EasyGraphEdgeView *)elt];
    }
}

- (void) unhighlightElement:(EasyGraphElement *)elt {
    if ([elt isKindOfClass:[EasyGraphVertexView class]]) {
        [self unhighlightVertex:(EasyGraphVertexView *)elt];
    } else {
        [self unhighlightEdge:(EasyGraphEdgeView *)elt];
    }
}

- (void) highlightEdge:(EasyGraphEdgeView *)edge {
    [edge setOpaque:NO];
    edge.layer.shadowColor = [UIColor blueColor].CGColor;
}

- (void) unhighlightEdge:(EasyGraphEdgeView *)edge {
    [edge setOpaque:NO];
    edge.layer.shadowColor = [UIColor clearColor].CGColor;
}

- (void) highlightVertex:(EasyGraphVertexView *)vert {
    vert.layer.opaque = YES;
    vert.layer.masksToBounds = NO;
    vert.layer.shadowOffset = CGSizeMake(0, 0);
    vert.layer.shadowRadius = 2.5;
    vert.layer.shadowOpacity = 0.5;
    vert.layer.shadowColor = [UIColor blueColor].CGColor;
    
    vert.layer.shadowPath = [UIBezierPath bezierPathWithArcCenter:[vert convertPoint:vert.center fromView:vert.superview] radius:vert.vertexSize/2.0 + 10 startAngle:0 endAngle:M_PI*2 clockwise:YES].CGPath;
}

- (void) unhighlightVertex:(EasyGraphVertexView *)vert {
    vert.layer.opaque = YES;
    vert.layer.masksToBounds = NO;
    vert.layer.shadowOffset = CGSizeMake(-4, 0);
    vert.layer.shadowRadius = 2.5;
    vert.layer.shadowOpacity = 0.3;
    vert.layer.shadowColor = [UIColor blackColor].CGColor;
    
    vert.layer.shadowPath = [UIBezierPath bezierPathWithArcCenter:[vert convertPoint:vert.center fromView:vert.superview] radius:vert.vertexSize/2.0 + 3 startAngle:0 endAngle:M_PI*2 clockwise:YES].CGPath;
}


- (IBAction)showMenuPopover:(UIBarButtonItem *)sender {
    if (self.menuPopoverController == nil) {
        double toolbarWidth = 0;
        double toolbarHeight = 0;
        UIViewController *toolsViewController = [[UIViewController alloc] init];
        switch ([sender tag]) {
            case 0:
                toolbarWidth = 381;
                toolbarHeight = 30;
                [toolsViewController.navigationItem setRightBarButtonItems:[self setupModesButtons]];
                break;
            case 1:
                toolbarWidth = 87;
                toolbarHeight = 30;
                [toolsViewController.navigationItem setRightBarButtonItems:[self setupToolsButtons]];
                break;
            default:
                return;
        }
        UINavigationController *nv = [[UINavigationController alloc] initWithRootViewController:toolsViewController];

        [nv.view setTag:[sender tag]];
        self.menuPopoverController = [[UIPopoverController alloc] initWithContentViewController:nv];
        [self.menuPopoverController setDelegate:self];
        [self.menuPopoverController setPassthroughViews:[NSArray arrayWithObject:self.view]];
        [self.menuPopoverController setPopoverContentSize:CGSizeMake(toolbarWidth, toolbarHeight)];
        [self.menuPopoverController setPopoverBackgroundViewClass:[EasyGraphPopoverBackgroundView class]];
    }
    
    if ([self.menuPopoverController isPopoverVisible]) {
        if ([sender tag] != [self.menuPopoverController.contentViewController.view tag]) {
            [self.menuPopoverController dismissPopoverAnimated:NO];
            [self setMenuPopoverController:nil];
            [self showMenuPopover:sender];
        } else {
            [self.menuPopoverController dismissPopoverAnimated:YES];
            [self setMenuPopoverController:nil];
        }
    } else {
        [self.menuPopoverController presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

- (NSArray *)setupModesButtons {
    if (self.removeElementsButton == nil) {
        self.selectButton = [[UIBarButtonItem alloc] initWithTitle:@"Select" style:UIBarButtonItemStyleBordered target:self action:@selector(toggleSelectMode)];
        
        self.removeElementsButton = [[UIBarButtonItem alloc] initWithTitle:@"Remove" style:UIBarButtonItemStyleBordered target:self action:@selector(toggleRemoveElementsMode:)];
        
        self.subdivideButton = [[UIBarButtonItem alloc] initWithTitle:@"Subdivide" style:UIBarButtonItemStyleBordered target:self action:@selector(toggleSubdivideMode:)];
        
        self.contractButton = [[UIBarButtonItem alloc] initWithTitle:@"Contract" style:UIBarButtonItemStyleBordered target:self action:@selector(toggleContractMode:)];
        
        self.nonEdgeButton = [[UIBarButtonItem alloc] initWithTitle:@"Non-Edge" style:UIBarButtonItemStyleBordered target:self action:@selector(toggleNonEdgeMode:)];
    }
    NSArray *result = [NSArray arrayWithObjects:self.selectButton, self.removeElementsButton, self.subdivideButton, self.contractButton, self.nonEdgeButton, nil];
    return result;
}

- (NSArray *) setupToolsButtons {
    if (self.toggleLabelsButton == nil) {
        
        self.toggleLabelsButton = [[UIBarButtonItem alloc] initWithTitle:@"Hide Labels" style:UIBarButtonItemStyleBordered target:self action:@selector(toggleLabels:)];
        [self.toggleLabelsButton setPossibleTitles:[NSSet setWithObjects:@"Hide Labels", @"Show Labels", nil]];
        
    }
    NSArray *result = [NSArray arrayWithObjects:self.toggleLabelsButton, nil];
    return result;
}

-(IBAction)toggleLabels:(UIBarButtonItem *)sender {
    if (!self.hidingLabels) {
        for (EasyGraphVertexView *vert in self.vertexSet) {
            [[vert label] removeFromSuperview];
        }
        self.hidingLabels = YES;
        [sender setTitle:@"Show Labels"];
    } else {
        for (EasyGraphVertexView *vert in self.vertexSet) {
            [vert addSubview:[vert label]];
        }
        self.hidingLabels = NO;
        [sender setTitle:@"Hide Labels"];
    }
}

- (IBAction)clearAll:(id)sender {
    for (EasyGraphVertexView * vert in [NSSet setWithSet:self.vertexSet]) {
        [self removeVertex:vert];
    }
}

-(IBAction)toggleSelectMode {
    if (self.inSelectMode) {
        self.inSelectMode = NO;
        [self.selectButton setStyle:UIBarButtonItemStyleBordered];
        for (EasyGraphElement *elt in self.selectedElements) {
            [self unhighlightElement:elt];
        }
        [self.selectedElements removeAllObjects];
        [self.floatingMenuPopoverController dismissPopoverAnimated:YES];
    } else {
        self.inSelectMode = YES;
        [self.selectButton setStyle:UIBarButtonItemStyleDone];
        if (self.inRemoveMode) {
            [self toggleRemoveElementsMode:nil];
        } else if (self.inSubdivideMode) {
            [self toggleSubdivideMode:nil];
        } else if (self.inContractMode) {
            [self toggleContractMode:nil];
        }
    }
    [self updateModesButton:@"Select" withDoneStyle:self.inSelectMode];
}

- (IBAction)toggleRemoveElementsMode:(UIBarButtonItem *)sender {
    if (self.inRemoveMode) {
        [self setInRemoveMode:NO];
        [self.removeElementsButton setStyle:UIBarButtonItemStyleBordered];
        [self.removeElementsButton setTitle:@"Remove"];
    } else {
        [self setInRemoveMode:YES];
        [self.removeElementsButton setStyle:UIBarButtonItemStyleDone];
        if (self.inSubdivideMode) {
            [self toggleSubdivideMode:sender];
        } else if (self.inContractMode) {
            [self toggleContractMode:sender];

        } else if (self.inSelectMode) {
            [self toggleSelectMode];
        }
    }
    [self updateModesButton:@"Remove" withDoneStyle:self.inRemoveMode];
}

- (IBAction)toggleSubdivideMode:(UIBarButtonItem *)sender {
    if (self.inSubdivideMode) {
        [self setInSubdivideMode:NO];
        [self.subdivideButton setStyle:UIBarButtonItemStyleBordered];
        [self.subdivideButton setTitle:@"Subdivide"];
    } else {
        [self setInSubdivideMode:YES];
        [self.subdivideButton setStyle:UIBarButtonItemStyleDone];
        if (self.inRemoveMode) {
            [self toggleRemoveElementsMode:sender];
        } else if (self.inContractMode) {
            [self toggleContractMode:sender];
        } else if ([self.easyGraphCanvas inNonEdgeMode]) {
            [self toggleNonEdgeMode:sender];
        } else if (self.inSelectMode) {
            [self toggleSelectMode];
        }
    }
    [self updateModesButton:@"Subdivide" withDoneStyle:self.inSubdivideMode];
}

- (IBAction)toggleContractMode:(UIBarButtonItem *)sender {
    if (self.inContractMode) {
        [self setInContractMode:NO];
        [self.contractButton setStyle:UIBarButtonItemStyleBordered];
        [self.contractButton setTitle:@"Contract"];
    } else {
        [self setInContractMode:YES];
        [self.contractButton setStyle:UIBarButtonItemStyleDone];
        if (self.inRemoveMode) {
            [self toggleRemoveElementsMode:sender];
        } else if (self.inSubdivideMode) {
            [self toggleSubdivideMode:sender];
        } else if ([self.easyGraphCanvas inNonEdgeMode]) {
            [self toggleNonEdgeMode:sender];
        } else if (self.inSelectMode) {
            [self toggleSelectMode];
        }
    }
    [self updateModesButton:@"Contract" withDoneStyle:self.inContractMode];
}

- (IBAction)toggleNonEdgeMode:(UIBarButtonItem *)sender {
    if ([self.easyGraphCanvas inNonEdgeMode]) {
        [self.easyGraphCanvas setInNonEdgeMode:NO];
        [self.nonEdgeButton setStyle:UIBarButtonItemStyleBordered];
        [self.nonEdgeButton setTitle:@"Non-Edge"];
    } else {
        [self.easyGraphCanvas setInNonEdgeMode:YES];
        [self.nonEdgeButton setStyle:UIBarButtonItemStyleDone];
        if (self.inRemoveMode) {
            [self toggleRemoveElementsMode:sender];
        } else if (self.inSubdivideMode) {
            [self toggleSubdivideMode:sender];
        } else if (self.inContractMode) {
            [self toggleContractMode:sender];
        }
    }
    [self updateModesButton:@"Non-Edge" withDoneStyle:[self.easyGraphCanvas inNonEdgeMode]];
}

- (void) updateModesButton:(NSString *)newTitle withDoneStyle:(BOOL)doneStyle {
    if (doneStyle) {
        [self.modesButton setStyle:UIBarButtonItemStyleDone];
        [self.modesButton setTitle:[NSString stringWithFormat:@"Mode: %@", newTitle]];
    } else {
        [self.modesButton setStyle:UIBarButtonItemStyleBordered];
        [self.modesButton setTitle:@"Mode: None"];
    }
}

- (IBAction)performUndo:(id)sender {
    [self.undoManager undo];
    if ([[self.undoManager valueForKey:@"_undoStack"] count] == 0) {
        [self.undoButton setEnabled:NO];
    }
    [self.redoButton setEnabled:YES];
}

- (IBAction)performRedo:(id)sender {
    [self.undoManager redo];
    if ([[self.undoManager valueForKey:@"_redoStack"] count] == 0) {
        [self.redoButton setEnabled:NO];
    }
    [self.undoButton setEnabled:YES];
}

- (BOOL) popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController {
    if (popoverController == self.floatingMenuPopoverController) {
        return YES;
    }
    return NO;
}

/*******************************************************************************
                                Colour Picker
*******************************************************************************/

-(void) openColourPicker:(id)sender {
    int tag = [sender tag];
    if (self.colourPickerPopoverController == nil) {
        UIViewController *colourController = [[UIViewController alloc] init];
        UINavigationController *nv;
        if (tag == 0) {
            [self setChangingVertexColor:YES];
            [colourController.navigationItem setRightBarButtonItems:[self makeColourButtonsWithWhite:YES]];

            nv = [[UINavigationController alloc] initWithRootViewController:colourController];
            
            self.colourPickerPopoverController = [[UIPopoverController alloc] initWithContentViewController:nv];
            
            [self.colourPickerPopoverController setPopoverContentSize:CGSizeMake(6*44 + 10, 30) animated:NO];
        } else {
            [colourController.navigationItem setRightBarButtonItems:[self makeColourButtonsWithWhite:NO]];
            nv = [[UINavigationController alloc] initWithRootViewController:colourController];
            
            self.colourPickerPopoverController = [[UIPopoverController alloc] initWithContentViewController:nv];
            
            [self.colourPickerPopoverController setPopoverContentSize:CGSizeMake(5*44, 30) animated:NO];
        }
        [nv.view setTag:tag];
    }
    [self.colourPickerPopoverController setPopoverBackgroundViewClass:[EasyGraphPopoverBackgroundView class]];
    [self dismissColourPickerWithTag:tag fromSender:sender];
}

- (void) dismissColourPickerWithTag:(int) tag fromSender:(id)sender {
    if ([self.colourPickerPopoverController isPopoverVisible]) {
        if (tag != [self.colourPickerPopoverController.contentViewController.view tag]) {
            [self.colourPickerPopoverController dismissPopoverAnimated:NO];
            [self setColourPickerPopoverController:nil];
            [self openColourPicker:sender];
        } else {
            [self.colourPickerPopoverController dismissPopoverAnimated:YES];
            [self setColourPickerPopoverController:nil];
        }
    } else {
        [self.colourPickerPopoverController presentPopoverFromBarButtonItem:sender
                                                   permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

- (void) setSelectedColor:(UIBarButtonItemWithObject *)sender {
    UIColor *color = [sender tintColor];
    
    if ([self.selectedElements count] == 0) {
        if (self.changingVertexColor) {
            [self setVertexColour:color];
            [self.vertexColourButton setTintColor:color];
        } else {
            [self setEdgeColour:color];
            [self.easyGraphCanvas setEdgeColour:color];
            [self.edgeColourButton setTintColor:color];
        }
    } else {
        for (EasyGraphElement *element in self.selectedElements) {
            [[self.undoManager prepareWithInvocationTarget:self] undoItem:element colourChangeForColour:[element colour]];
            [element setColour:[sender tintColor]];
            [element setOpaque:NO];
            [element setNeedsDisplay];
        }
        [self.selectedElements removeAllObjects];
    }
    [self setChangingVertexColor:NO];
    [self dismissColourPickerWithTag:[self.colourPickerPopoverController.contentViewController.view tag] fromSender:sender];
}

- (void) undoItem:(id)item colourChangeForColour:(UIColor *)col {
    [item setColour:col];
    [item setOpaque:NO];
    [item setNeedsDisplay];
}

- (NSMutableArray *) makeColourButtonsWithWhite:(BOOL)withWhite {
    
     NSArray *colours;
     if (withWhite) {
         colours = [[NSArray alloc] initWithObjects:[UIColor blackColor],[UIColor whiteColor], [UIColor redColor], [UIColor greenColor], [UIColor blueColor], nil];
     } else {
         colours = [[NSArray alloc] initWithObjects:[UIColor blackColor], [UIColor redColor], [UIColor greenColor], [UIColor blueColor], nil];
     }
     NSMutableArray *colourButtons = [[NSMutableArray alloc] init];
     UIBarButtonItem *colButton;
     for (UIColor *col in colours) {
         colButton = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStyleBordered target:self action:@selector(setSelectedColor:)];
         [colButton setTintColor:col];
         [colourButtons addObject:colButton];
     }
     return colourButtons;
}

/*******************************************************************************
                                Export Functionality
*******************************************************************************/

- (IBAction)exportDialoug:(id)sender {
    EasyGraphExporterViewController *latexController = [[EasyGraphExporterViewController alloc] initWithNibName:@"EasyGraphExporterViewController" bundle:nil];
    [latexController setVertexSet:[NSSet setWithSet:[self vertexSet]]];
    [latexController setScaleFactor:4.0];
    [latexController setIsDirected:isDirected];
    [latexController setTitle:[self title]];
    [self.navigationController pushViewController:latexController animated:YES];
}

/*******************************************************************************
                            Helper Methods
*******************************************************************************/

- (double) getToolBarWidthFromButtons:(NSArray *)buttons {
    UIView *view;
    double width = 0;
    for (int i = 0; i < [buttons count]; i++) {
        view = (UIView *)[buttons objectAtIndex:i];
        width += view.bounds.size.width + 30;
    }
    return width;
}

- (BOOL) isNeighbour:(EasyGraphVertexView *)start of:(EasyGraphVertexView *)end {
    for (EasyGraphEdgeView *outEdge in start.outNeighbs) {
        if (end == outEdge.endVertex) {
            return YES;
        }
    }
    if (!isDirected) {
        for (EasyGraphEdgeView *inEdge in start.inNeighbs) {
            if (end == inEdge.startVertex) {
                return YES;
            }
        }
    }
    return NO;
}

- (NSArray *) calcDist:(NSArray *)pnts fromPoint:(CGPoint)point {
    NSMutableArray *dists = [[NSMutableArray alloc] initWithCapacity:[pnts count]];
    double dist;
    CGPoint currPoint;
    for (int i = 0; i < [pnts count]; i++) {
        currPoint = [[pnts objectAtIndex:i] CGPointValue];
        dist = pow(point.x - currPoint.x, 2) + pow(point.y - currPoint.y, 2);
        dist = sqrt(dist);
        [dists addObject:[NSNumber numberWithDouble:dist]];
    }
    return dists;
}

- (CGPoint) getClosestGridPointToPoint:(CGPoint) p {
    int x_mult = p.x / self.gridSize;
    int y_mult = p.y / self.gridSize;
    
    NSValue *p1 = [NSValue valueWithCGPoint:CGPointMake(x_mult * self.gridSize, y_mult * self.gridSize)];
    
    NSValue *p2 = [NSValue valueWithCGPoint:CGPointMake((x_mult + 1) * self.gridSize, y_mult * self.gridSize)];
    
    NSValue *p3 = [NSValue valueWithCGPoint:CGPointMake(x_mult * self.gridSize, (y_mult + 1) * self.gridSize)];
    
    NSValue *p4 = [NSValue valueWithCGPoint:CGPointMake((x_mult + 1) * self.gridSize, (y_mult + 1) * self.gridSize)];
    NSArray *pnts = [[NSArray alloc] initWithObjects:p1, p2, p3, p4, nil];
    NSMutableArray *dists = [self calcDist:pnts fromPoint:p];
    NSNumber *min = [dists valueForKeyPath:@"@min.doubleValue"];
    return [[pnts objectAtIndex:[dists indexOfObject:min]] CGPointValue];
}

- (NSString *) updateFileName {
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [dirPaths objectAtIndex:0];
    NSString *fileName = [NSString stringWithFormat:@"%@.archive", self.title];
    
    return [[NSString alloc] initWithString:[docsDir stringByAppendingPathComponent:fileName]];
}

- (CGRect) makeEdgeRectForEdgeFromPoint:(NSValue *)start toPoint:(NSValue *)end {
    double minX = 1000;
    double minY = 1000;
    double maxX = 0;
    double maxY = 0;
    CGPoint point;
    
    NSMutableArray *p = [NSMutableArray arrayWithArray:self.easyGraphCanvas.curvePoints];
    
    [p  insertObject:start atIndex:0];
    [p insertObject:start atIndex:0];
    [p addObject:end];
    [p addObject:end];
    NSArray *splinePoints = [self.easyGraphCanvas catmullRomSpline:p segments:100];
    for (NSValue *val in splinePoints) {
        point = [val CGPointValue];
        minX = point.x < minX ? point.x : minX;
        minY = point.y < minY ? point.y : minY;
        maxX = point.x > maxX ? point.x : maxX;
        maxY = point.y > maxY ? point.y : maxY;
    }
//    double xpad = start.x == end.x ? 10
    return CGRectMake(minX - 10, minY - 10, maxX - minX + 20, maxY - minY + 20);
}

-(void) addGradient:(UIButton *) _button {
    
    // Add Border
    CALayer *layer = _button.layer;
    layer.cornerRadius = 8.0f;
    layer.masksToBounds = YES;
    layer.borderWidth = 1.0f;
    layer.borderColor = [UIColor colorWithWhite:0.5f alpha:0.2f].CGColor;
    
    // Add Shine
    CAGradientLayer *shineLayer = [CAGradientLayer layer];
    shineLayer.frame = layer.bounds;
    shineLayer.colors = [NSArray arrayWithObjects:
                         (id)[UIColor colorWithWhite:1.0f alpha:0.4f].CGColor,
                         (id)[UIColor colorWithWhite:1.0f alpha:0.2f].CGColor,
                         (id)[UIColor colorWithWhite:0.75f alpha:0.2f].CGColor,
                         (id)[UIColor colorWithWhite:0.4f alpha:0.2f].CGColor,
                         (id)[UIColor colorWithWhite:1.0f alpha:0.4f].CGColor,
                         nil];
    shineLayer.locations = [NSArray arrayWithObjects:
                            [NSNumber numberWithFloat:0.0f],
                            [NSNumber numberWithFloat:0.5f],
                            [NSNumber numberWithFloat:0.5f],
                            [NSNumber numberWithFloat:0.8f],
                            [NSNumber numberWithFloat:1.0f],
                            nil];
    [layer addSublayer:shineLayer];
}

@end
//
//  EasyGraphDetailViewController.m
//  EasyGraph
//
//  Created by Oren Shklarsky on 12-07-19.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EasyGraphDetailViewController.h"

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
    self.inRemoveMode = NO;
    self.inSubdivideMode = NO;
    self.vertexColour = [UIColor blackColor];
    self.edgeColour = [UIColor blackColor];
    self.changingVertexColor = NO;
    prevNumberOfTouches = 1;
    
    [self configureGraphCanvasView];

    [self.modesButton setPossibleTitles:[NSSet setWithObjects:@"Mode: None",
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
    self.xOffset = 200.0;
    self.yOffset = 200.0;
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

//    [self.scrollView.panGestureRecognizer setMinimumNumberOfTouches:3];
//    [self.scrollView.panGestureRecognizer setMaximumNumberOfTouches:3];
//    [self.scrollView setContentSize:CGSizeMake(width, height)];
//    [self.scrollView addSubview:self.easyGraphCanvas];
//    [self.scrollView setDelegate:self];
    
//    UILongPressGestureRecognizer *longPressOneTap = [[UILongPressGestureRecognizer alloc]    initWithTarget:self action:@selector(handleLongPress:)];
//    [longPressOneTap setMinimumPressDuration:0.0];
//    [longPressOneTap setNumberOfTapsRequired:1];
//    [self.easyGraphCanvas addGestureRecognizer:longPressOneTap];
//    
//    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]    initWithTarget:self action:@selector(handleLongPress:)];
//    [longPress setMinimumPressDuration:0.0];
//    [longPress setNumberOfTapsRequired:0];
//    [longPress setNumberOfTouchesRequired:1];
//    [longPress setDelegate:self];
//    [self.easyGraphCanvas addGestureRecognizer:longPress];

    
//    [singleTap requireGestureRecognizerToFail:[self.scrollView panGestureRecognizer]];
//    [longPressOneTap requireGestureRecognizerToFail:[self.scrollView panGestureRecognizer]];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
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
            [[self.undoManager prepareWithInvocationTarget:self]
             undoVertexMove:self.movingVertexView atOriginalPoint:movingVertexView.center];
        }
    } else {
        self.edgeStartPoint = [touched isKindOfClass:[EasyGraphVertexView class]] ? (EasyGraphVertexView *)touched : nil;
        self.movingVertexView = nil;
        self.easyGraphCanvas.fingerStartPoint = locationPoint;
        self.easyGraphCanvas.drawingEdge = self.edgeStartPoint != nil;
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
        
    } else if (![touched isKindOfClass:[EasyGraphVertexView class]] && self.edgeStartPoint == nil) {
            [self makeNewVertex:locationPoint];
    }
}

- (IBAction)handlePanGesture:(UIPanGestureRecognizer *)sender {
    if (self.movingVertexView != nil) {
        EasyGraphVertexView *vert = self.movingVertexView;


        if (sender.state == UIGestureRecognizerStateEnded) {
            CGPoint endPt = [self getClosestGridPointToPoint:self.movingVertexView.center];
            
            self.movingVertexView.frame = CGRectMake(endPt.x - self.vertexFrameSize/2.0, endPt.y - self.vertexFrameSize/2.0, self.vertexFrameSize, self.vertexFrameSize);
            vert.layer.opaque = YES;
            vert.layer.masksToBounds = NO;
            vert.layer.shadowOffset = CGSizeMake(-4, 0);
            vert.layer.shadowRadius = 2.5;
            vert.layer.shadowOpacity = 0.3;
            vert.layer.shadowColor = [UIColor blackColor].CGColor;
            
            vert.layer.shadowPath = [UIBezierPath bezierPathWithArcCenter:[vert convertPoint:vert.center fromView:vert.superview] radius:vert.vertexSize/2.0 + 3 startAngle:0 endAngle:M_PI*2 clockwise:YES].CGPath;
            [self updateEdgesFor:self.movingVertexView];

            self.movingVertexView = nil;
        } else {
            CGPoint translation = [sender translationInView:self.easyGraphCanvas];
            CGPoint vertexViewPosition = self.movingVertexView.center;
            vertexViewPosition.x += translation.x;
            vertexViewPosition.y += translation.y;
            self.movingVertexView.center = vertexViewPosition;
            vert.layer.opaque = YES;
            vert.layer.masksToBounds = NO;
            vert.layer.shadowOffset = CGSizeMake(0, 0);
            vert.layer.shadowRadius = 2.5;
            vert.layer.shadowOpacity = 0.5;
            vert.layer.shadowColor = [UIColor blueColor].CGColor;
            
            vert.layer.shadowPath = [UIBezierPath bezierPathWithArcCenter:[vert convertPoint:vert.center fromView:vert.superview] radius:vert.vertexSize/2.0 + 10 startAngle:0 endAngle:M_PI*2 clockwise:YES].CGPath;
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
    
    [vert setupVertexLabelAndColour:self.vertexColour];
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

#pragma mark - Bottom toolbar buttons

- (IBAction)showMenuPopover:(UIBarButtonItem *)sender {
    if (self.menuPopoverController == nil) {
        double toolbarWidth, toolbarHeight;
        UIViewController *toolsViewController = [[UIViewController alloc] init];
        switch ([sender tag]) {
            case 0:
                toolbarWidth = 318;
                toolbarHeight = 30;
                [toolsViewController.navigationItem setRightBarButtonItems:[self setupModesButtons]];
                break;
            case 1:
                toolbarWidth = 500;
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
        self.removeElementsButton = [[UIBarButtonItem alloc] initWithTitle:@"Remove" style:UIBarButtonItemStyleBordered target:self action:@selector(toggleRemoveElementsMode:)];
        self.subdivideButton = [[UIBarButtonItem alloc] initWithTitle:@"Subdivide" style:UIBarButtonItemStyleBordered target:self action:@selector(toggleSubdivideMode:)];
        self.contractButton = [[UIBarButtonItem alloc] initWithTitle:@"Contract" style:UIBarButtonItemStyleBordered target:self action:@selector(toggleContractMode:)];
        self.nonEdgeButton = [[UIBarButtonItem alloc] initWithTitle:@"Non-Edge" style:UIBarButtonItemStyleBordered target:self action:@selector(toggleNonEdgeMode:)];
    }
    return [NSArray arrayWithObjects:self.removeElementsButton, self.subdivideButton, self.contractButton, self.nonEdgeButton, nil];
}

- (NSArray *) setupToolsButtons {
    if (self.relabelVertexButton == nil) {
        
        self.toggleLabelsButton = [[UIBarButtonItem alloc] initWithTitle:@"Hide Labels" style:UIBarButtonItemStyleBordered target:self action:@selector(toggleLabels:)];
        [self.toggleLabelsButton setPossibleTitles:[NSSet setWithObjects:@"Hide Labels", @"Show Labels", nil]];
        
    }
    UIButton *sep = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 1, 41)];
    UIBarButtonItem *sepItem = [[UIBarButtonItem alloc] initWithCustomView:sep];
    
    UITextField *relabelField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 150, 30)];
    relabelField.borderStyle = UITextBorderStyleRoundedRect;
    relabelField.font = [UIFont systemFontOfSize:15];
    relabelField.placeholder = @"old_label:new_label";
    relabelField.autocorrectionType = UITextAutocorrectionTypeNo;
    relabelField.keyboardType = UIKeyboardTypeDefault;
    relabelField.returnKeyType = UIReturnKeyDone;
    relabelField.clearButtonMode = UITextFieldViewModeWhileEditing;
    relabelField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    relabelField.delegate = self;

    UIBarButtonItem *fieldItem = [[UIBarButtonItem alloc] initWithCustomView:relabelField];
    
    return [NSArray arrayWithObjects:self.toggleLabelsButton, self.relabelVertexButton, sepItem,fieldItem, nil];
}

-(IBAction)toggleLabels:(UIBarButtonItem *)sender {
    if ([[sender title] isEqualToString:@"Hide Labels"]) {
        for (EasyGraphVertexView *vert in self.vertexSet) {
            [[vert label] removeFromSuperview];
        }
        [sender setTitle:@"Show Labels"];
    } else {
        for (EasyGraphVertexView *vert in self.vertexSet) {
            [vert addSubview:[vert label]];
        }
        [sender setTitle:@"Hide Labels"];
    }
}

- (IBAction)clearAll:(id)sender {
    for (EasyGraphVertexView * vert in [NSSet setWithSet:self.vertexSet]) {
        [self removeVertex:vert];
    }
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
        } else if ([self.easyGraphCanvas inNonEdgeMode]) {
            [self toggleNonEdgeMode:sender];
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

- (void) setSelectedColor:(id)sender {
    UIColor *color = [sender tintColor];
    if (self.changingVertexColor) {
        [self setVertexColour:color];
        [self setChangingVertexColor:NO];
        [self.vertexColourButton setTintColor:color];
    } else {
        [self setEdgeColour:color];
        [self.easyGraphCanvas setEdgeColour:color];
        [self.edgeColourButton setTintColor:color];
    }
    [self dismissColourPickerWithTag:[self.colourPickerPopoverController.contentViewController.view tag] fromSender:sender];
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
         [colButton setWidth:44];
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


-(BOOL) textFieldShouldBeginEditing:(UITextField *)textField {
    return YES;
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)keyboardWillHide:(NSNotification *)notification {
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameBeginUserInfoKey];
    CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
    [self setViewMoveUp:NO withRect:keyboardFrameBeginRect];
}


- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameBeginUserInfoKey];
    CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
    [self setViewMoveUp:YES withRect:keyboardFrameBeginRect];
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

@end
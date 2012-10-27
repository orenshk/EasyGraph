//
//  GraphMakerDetailViewController.h
//  GraphMaker
//
//  Created by Oren Shklarsky on 12-07-19.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EasyGraphCanvas.h"
#import "EasyGraphVertexView.h"
#import "GMEdgeView.h"
#import "EasyGraphMasterViewController.h"
#import "GMPdfViewController.h"
#import "EasyGraphExporterViewController.h"

@interface EasyGraphDetailViewController : UIViewController
                                                <UISplitViewControllerDelegate,
                                                 UITextFieldDelegate>
{
    int prevNumberOfTouches;
}

/** Toolbar buttons */
@property (strong, nonatomic) IBOutlet UIBarButtonItem *removeElementsButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *undoButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *redoButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *subdivideButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *contractButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *nonEdgeButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *vertexColourButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *edgeColourButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *exportButton;

@property (strong, nonatomic) IBOutlet UIButton *pdfButton;
@property (strong, nonatomic) IBOutlet UIButton *latexPSTButton;

@property (strong, nonatomic) UIPopoverController *exportPopOverController;

@property (strong, nonatomic) UIPopoverController *colourPickerPopoverController;

/** The currently active canvas */
@property (strong, nonatomic) EasyGraphCanvas *graphMakerCanvas;

/** Size of a grid square */
@property const int gridSize;

/** The set of VertexView objects */
@property (nonatomic, strong) NSMutableSet *vertexSet;

/** The VertexView being moved, if any */
@property (nonatomic, retain) EasyGraphVertexView *movingVertexView;

/** If drawing an edge, it's start VertexView */
@property (nonatomic, retain) EasyGraphVertexView *edgeStartPoint;

/** The size of a VertexView frame */
@property int vertexFrameSize;

/** The colour of new VertexViews being drawn */
@property UIColor *vertexColour;

/** True when the color picker for vertex colours is to be shown */
@property BOOL changingVertexColor;

/** The colour of new EdgeViews being drawn */
@property UIColor *edgeColour;

@property BOOL inRemoveMode;
@property BOOL inSubdivideMode;
@property BOOL inContractMode;
@property BOOL isDirected;

/** Location of archive file holding VertexView information */
@property NSString *saveDataPath;

@property (nonatomic, retain) NSUndoManager *undoManager;

- (id) initWithNibName: (NSString *)nibNameOrNil title:(NSString *)titleOrNil;
- (void) setUpTitleViewWithTitle:(NSString *)title andSubtitle:(NSString *)subtitle;
- (void) updateTitle:(NSString *)title;
- (void) updateSubtitle:(NSString *)subtitle;
- (void) configureGraphCanvasView;

/** 
 Reload from archive the VertexView and Edge setmaintained by this
 GraphMakerDetailViewController.
 */
- (void) reloadData;

/**
 save to archive the VertexView and Edge setmaintained by this
 GraphMakerDetailViewController.
 */
- (void) saveData;

/**
 delete from archive the VertexViews and Edges setmaintained by this
 GraphMakerDetailViewController.
 */
- (void) deleteData;

/**
 Create and return a VertexView. The new VertexView
 is added as a subview of |self.graphMakerCanvas|.
 @param fingerPos The new VertexView will be centered at the grid point closest
        to fingerPos
 @returns The new VertexView.
 */
- (EasyGraphVertexView *) makeNewVertex:(CGPoint) fingerPos;

/**
 Create and return a EdgeView whose tail is in |start| and endpoint is in |end|.
 @param start the tail of the new edge.
 @param end the endpoint of the edge.
 @param isNonEdge whether or not the new edge should be drawn as a non-edge.
 */
- (GMEdgeView *) makeNewEdgeFromVertex:(EasyGraphVertexView *)start toVertex:(EasyGraphVertexView *)end isNonEdge:(BOOL)nonEdge;


/**
 Redraw all edges incident to |vert|
 @param vert the vertex being updated.
 */
- (void) updateEdgesFor:(EasyGraphVertexView *)vert;

/**
 Remove |vert| from |self.graphMakerCanvas|.
 @param vert the vertex being deleted
 */
- (void) removeVertex:(EasyGraphVertexView *)vert;

/** 
 Remove the edge connecting the VertexViews with center |start| and |end|.
 @param start the coordinates in the edge's superview of the removed edge's tail.
 @param end the coordinates in the edges' superview of the removed edges' endpoint.
 */
- (void) removeEdgeFromVertexAt:(CGPoint)start toVertexAt:(CGPoint)end;

/**
 Undo a vertex deletion. 
 This is the reciprocal of removeVertex:
 @param vert the VertexView to be restored.
 */
- (void) undoVertexDelete:(EasyGraphVertexView *)vert;

/**
 Undo an edge deletion.
 This is the reciprocal of removeEdgeFromVertexAt:toVertexAt:
 @param edge the EdgeView to be restored.
 */
- (void) undoEdgeDelete:(GMEdgeView *)edge;

/**
 Undo a vertex move.
 This is its own reciprocal.
 @param vert the VertexView whose position we wish to restore.
 @param point the original position of vert.
 */
- (void) undoVertexMove:(EasyGraphVertexView *)vert atOriginalPoint:(CGPoint)point;

/**
 Create a new vertex whose center is the grid point closest to |point|,
 and whose only neighbours are |edge.startVertex| and |edge.endVertex|, and
 remove |edge|.
 @param edge the EdgeView to be subdivided.
 @param point the After subdivision, the new VertexView will be placed at the
        grid point closest to |point|.
 */
- (void) subdivide:(GMEdgeView *)edge atPoint:(CGPoint)point;

/**
 Make edges from each neighbour of edge.endVertex to edge.startVertex
 and remove edge.endVertex.
 i.e. edge.endVertex is collapsed into edge.startVertex.
 @param edge the EdgeView to be contracted.
 */
- (void) contract:(GMEdgeView *)edge;

/**
 Remove all vertices and edges from this GraphMakerDetailViewController.
 */
- (IBAction)clearAll:(id)sender;

/**
 Toggle element removal mode. When in this mode, a tap on a vertex or
 edge will result in its removal. Edges may be created in this mode, but
 vertices cannot be moved. This mode is mutually exclusive with all other
 modes.
 */
- (IBAction)toggleRemoveElementsMode:(id)sender;

/**
 Toggle subdivide mode. In this mode, a tap on an edge will subdivide it.
 Edges may be created in this mode, and vertices may be respositioned.
 This mode is mutually exclusive with all other modes.
*/
- (IBAction)toggleSubdivideMode:(id)sender;

/**
 Toggle contract mode. In this mode, a tap on an edge will contract it.
 Edges may be created in this mode, and vertices may be repositioned.
 This mode is mutually exclusive with all other modes.
 */
- (IBAction)toggleContractMode:(id)sender;

/**
 Toggle non-edge mode. In this mode any EdgeView created is has its
 |isNonEdge| property set to |YES|, and the edge will be drawn as a non-edge
 with the default being a dashed line.
 */
- (IBAction)toggleNonEdgeMode:(id)sender;

- (IBAction)performUndo:(id)sender;
- (IBAction)performRedo:(id)sender;

/**
 Return |YES| iff there is an edge from vert to otherVert or an edge from
 otherVert to vert;
 @param vert one endpoint of a potential edge.
 @param otherVert the other endpoint of a potential edge.
 @returns YES if vert is a neighbour of edge. NO otherwise.
 */
- (BOOL) isNeighbour:(EasyGraphVertexView *)start of:(EasyGraphVertexView *)start;

/**
 Return an array of distances from each point in |pnts| to
 |point|. The ith entry of the returned array corresponds the distance of the
 ith point of |pnts| to |point|, for 0 <= i <= [pnts count]
 @param pnts the collection of points whose distance from |point| we are getting.
 @param point the point from which distance is measured.
 @returns An array containing the distances of the points in |pnts| to |point|
 */
- (NSMutableArray *) calcDist:(NSArray *) pnts fromPoint:(CGPoint) point;

/**
 Return the point closest to p, whose x and y coordinates are both multiples
 of self.gridSize.
 */
- (CGPoint) getClosestGridPointToPoint:(CGPoint) p;

/**
 Change the file name of the archive file for this detailViewController
 to reflect its title, and return the new file Name.
 @returns the new file name for the archive file.
 */
- (NSString *) updateFileName;

/**
 Open the colour picker associated with vertex colours.
 */
- (void) openColourPicker:(id)sender;

- (CGRect) makeEdgeRectForEdgeFromPoint:(NSValue *)start toPoint:(NSValue *)end;

- (void) setSelectedColor:(id)sender;

- (IBAction)exportDialoug:(id)sender;

@end
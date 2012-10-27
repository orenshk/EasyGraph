//
//  GraphMakerCanvas.h
//  GraphMaker
//
//  Created by Oren Shklarsky on 12-07-19.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GMVertexView.h"

@interface GMCanvas : UIView

/** Size of a grid square */
@property const int gridSize;

/** True when a new edge is being drawn and before a new EdgeView is created */
@property BOOL drawingEdge;

/** The starting position of a user touch when drawing an edge */
@property CGPoint fingerStartPoint;

/** The current position of a user touch when drawing an edge */
@property CGPoint fingerCurrPos;

/** True when the newly drawn edge is a non-edge */
@property BOOL inNonEdgeMode;

/** Colour of edge being drawn */
@property UIColor *edgeColour;

@property (strong, nonatomic) NSMutableArray *curvePoints;

/**
 Draw a grid of self.gridSize by self.gridSize squares
 */
- (void) drawGrid;

/**
 Return the x coordinate of the interception point of the line  L1 going through
 y and parallel to the x-axis, and the line L2 going through points (x1,y1)
 (x2,y2)
 @param y the first line goes
 @param x1 the x coordinate of the first point of L2.
 @param y2 the y coordinate of the first point of L2.
 @param x2 the x coordinate of the second point of L2.
 @param y2 the y coordinate of the second point of L2.
 @returns the x coordinate of the intersection point of L1 and L2.
 */
- (double) findXintersectOfLineWith:(double) y andlineWithX1:(double) x1
                                 Y1:(double) y1 X2:(double) x2 Y2:(double) y2;

/**
 Return and array of interpolated Catmull-Rom Spline points whose control 
 points are in |points|.
 @param points the set of control points for the spline
 @param segments the parametric equation of the spline is evaluated every
        1/segments points.
 @returns an NSArray containing the points for the spline.
 */
- (NSArray *)catmullRomSpline:(NSArray *)points segments:(int)segments;
@end
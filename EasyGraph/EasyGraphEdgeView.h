//
//  EdgeView.h
//  EasyGraph
//
//  Created by Oren Shklarsky on 12-07-22.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EasyGraphVertexView.h"
#import "EasyGraphCanvas.h"
#import "EasyGraphElement.h"

@class EasyGraphEdgeView;
@interface EasyGraphEdgeView : EasyGraphElement

/** The tail of this EdgeView */
@property (nonatomic, strong) EasyGraphVertexView *startVertex;

/** The endpoint of this EdgeView */
@property (nonatomic ,strong) EasyGraphVertexView *endVertex;

@property (nonatomic, strong) NSMutableArray *curvePoints;

@property (nonatomic, strong) NSArray *splinePoints;

/** True of this edge is a non-edge */
@property BOOL isNonEdge;

@property BOOL isDirected;

@property double arrowLength;
@property double arrowWidth;

@property CGFloat edgeWidth;

/**
 Initialize and return an EdgeView object betwen |start| and |end|
 @param start the new EdgeView's tail
 @param end the new EdgeView's endpoint
 @returns the new EdgeView
 */
- (id) initWithFrame:(CGRect)frame 
         andStartPnt:(EasyGraphVertexView *)start andEndPnt:(EasyGraphVertexView *) end;

/**
 Returns YES iff this EdgeView is at distance at most |c| from |point|.
 @param c the distance threshold.
 @param point the point checked.
 @returns YES if this EdgeView is at distance at most |c| from |point|.
 false otherwise.
 */
- (BOOL) edgeWithinDistance:(double) c ofPoint:(CGPoint)point;

/**
 Draw an edge through |points|
 @param points the set of control points for the edge.
 */
- (void) drawEdgeThroughPoints:(NSArray *)points;

- (void) drawArrowForSplinePoints:(NSArray *)points ofLength:(double)length andWidth:(double)width;

- (NSArray *) getSplinePointsForStartPoint:(CGPoint) start endPoint:(CGPoint) end controlPoints:(NSArray *)points;
@end
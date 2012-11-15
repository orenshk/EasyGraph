//
//  VertexView.h
//  EasyGraph
//
//  Created by Oren Shklarsky on 12-07-20.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "EasyGraphElement.h"

@interface EasyGraphVertexView : EasyGraphElement

/** The in neighbours of this VertexView */
@property (nonatomic, retain) NSMutableSet *inNeighbs;

/** The out neighbours if this VertexView */
@property (nonatomic, retain) NSMutableSet *outNeighbs;

@property int vertexNum;
@property BOOL hidingLabel;

/** The size of the circle representing the vertex */
@property int vertexSize;

- (void) setupVertexLabelAndColour:(UIColor *)colour;

- (void) updateVertexSize:(float)newSize;

- (void) updateLabelSize:(float)newSize;

- (void) updateLabelStatus:(BOOL)hidingLabel;
@end
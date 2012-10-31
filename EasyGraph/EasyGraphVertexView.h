//
//  VertexView.h
//  EasyGraph
//
//  Created by Oren Shklarsky on 12-07-20.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreText/CTStringAttributes.h>

@interface EasyGraphVertexView : UIView

/** The in neighbours of this VertexView */
@property (nonatomic, retain) NSMutableSet *inNeighbs;

/** The out neighbours if this VertexView */
@property (nonatomic, retain) NSMutableSet *outNeighbs;

@property int vertexNum;

/** The colour of this vertex */
@property UIColor *colour;

/** The size of the circle representing the vertex */
@property int vertexSize;

@property (strong, nonatomic) IBOutlet UIWebView *label;

@property (strong, nonatomic) NSString *letter;

- (void) setupVertexLabelAndColour:(UIColor *)colour;

@end
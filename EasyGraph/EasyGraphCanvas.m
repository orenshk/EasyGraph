//
//  EasyGraphCanvas.m
//  EasyGraph
//
//  Created by Oren Shklarsky on 12-07-19.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EasyGraphCanvas.h"

@implementation EasyGraphCanvas
@synthesize gridSize;
@synthesize fingerCurrPos;
@synthesize fingerStartPoint;
@synthesize drawingEdge;
@synthesize inNonEdgeMode;
@synthesize edgeColour;
@synthesize curvePoints;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
        self.inNonEdgeMode = NO;
        self.edgeColour = [UIColor blackColor];
        self.curvePoints = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.nextResponder touchesBegan:touches withEvent:event];
}

- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.nextResponder touchesMoved:touches withEvent:event];
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.nextResponder touchesEnded:touches withEvent:event];
}

- (double) findXintersectOfLineWith:(double)y andlineWithX1:(double)x1 Y1:(double)y1 X2:(double)x2 Y2:(double)y2 {
    double m = (y1 - y2) / (x1 - x2);
    double b = y1 - m*x1;
    return (y - b) / m;
}

- (NSArray *)catmullRomSpline:(NSArray *)points segments:(int)segments
{
    int count = [points count];
    if(count < 4) {
        return points;
    }
    
    float b[segments][4];
    {
        // precompute interpolation parameters
        float t = 0.0f;
        float dt = 1.0f/(float)segments;
        for (int i = 0; i < segments; i++, t+=dt) {
            float tt = t*t;
            float ttt = tt * t;
            b[i][0] = 0.5f * (-ttt + 2.0f*tt - t);
            b[i][1] = 0.5f * (3.0f*ttt -5.0f*tt +2.0f);
            b[i][2] = 0.5f * (-3.0f*ttt + 4.0f*tt + t);
            b[i][3] = 0.5f * (ttt - tt);
        }
    }
    
    NSMutableArray *resultArray = [NSMutableArray array];
    for (int i = 1; i < count-2; i++) {
        // the first interpolated point is always the original control point
        [resultArray addObject:[points objectAtIndex:i]];
        for (int j = 0; j < segments; j++) {
            CGPoint pointIm1 = [[points objectAtIndex:(i - 1)] CGPointValue];
            CGPoint pointI = [[points objectAtIndex:i] CGPointValue];
            CGPoint pointIp1 = [[points objectAtIndex:(i + 1)] CGPointValue];
            CGPoint pointIp2 = [[points objectAtIndex:(i + 2)] CGPointValue];
            float px = b[j][0]*pointIm1.x + b[j][1]*pointI.x + b[j][2]*pointIp1.x + b[j][3]*pointIp2.x;
            float py = b[j][0]*pointIm1.y + b[j][1]*pointI.y + b[j][2]*pointIp1.y + b[j][3]*pointIp2.y;
            [resultArray addObject:[NSValue valueWithCGPoint:CGPointMake(px, py)]];
        }
    }
    [resultArray addObject:[points objectAtIndex:count - 2]];
    return resultArray;
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (self.drawingEdge) {
        CGContextSetLineWidth(context, 3.0);
        CGContextSetStrokeColorWithColor(context, self.edgeColour.CGColor);
        if (self.inNonEdgeMode) {
            CGFloat dashArray[] = {6};
            CGContextSetLineDash(context, 3, dashArray, 1);
        }
        CGContextMoveToPoint(context, self.fingerStartPoint.x, self.fingerStartPoint.y);
        if ([curvePoints count] == 0) {
            CGContextAddLineToPoint(context, self.fingerCurrPos.x, self.fingerCurrPos.y);
            
        } else {
            NSValue *startV = [NSValue valueWithCGPoint:self.fingerStartPoint];
            NSValue *endV = [NSValue valueWithCGPoint:self.fingerCurrPos];
            NSMutableArray *points = [[NSMutableArray alloc] initWithObjects:startV, startV,  nil];
            
            [points addObjectsFromArray:self.curvePoints];
            [points addObjectsFromArray:[[NSArray alloc] initWithObjects:endV, endV, nil]];
    
            NSArray *splinePoints = [self catmullRomSpline:points segments:100];
            CGPoint point;
            for (int i = 1; i < [splinePoints count]; i++) {
                point = [[splinePoints objectAtIndex:i] CGPointValue];
                CGContextAddLineToPoint(context, point.x, point.y);
            }
        }
        CGContextStrokePath(context);
    }
}

@end

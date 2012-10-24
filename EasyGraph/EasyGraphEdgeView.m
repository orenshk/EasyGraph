//
//  EdgeView.m
//  GraphMaker
//
//  Created by Oren Shklarsky on 12-07-22.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EasyGraphEdgeView.h"

@implementation EasyGraphEdgeView
@synthesize startVertex, endVertex, isNonEdge, curvePoints, splinePoints;
@synthesize isDirected;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setBackgroundColor:[UIColor clearColor]];
    }
    return self;
}

- (id) initWithFrame:(CGRect)frame 
         andStartPnt:(EasyGraphVertexView *)start andEndPnt:(EasyGraphVertexView *) end {
    self = [super initWithFrame:frame];
    if (self) {
        [self setBackgroundColor:[UIColor clearColor]];
        self.startVertex = start;
        self.endVertex = end;
        self.isNonEdge = NO;
        self.curvePoints = [[NSMutableArray alloc] init];
    }
    return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        self.startVertex = [aDecoder decodeObjectForKey:@"start"];
        self.endVertex = [aDecoder decodeObjectForKey:@"end"];
        self.isNonEdge = [[aDecoder decodeObjectForKey:@"isNonEdge"] boolValue];
        self.colour = [aDecoder decodeObjectForKey:@"edgeColour"];
        self.curvePoints = [aDecoder decodeObjectForKey:@"curvePoints"];
        self.isDirected = [[aDecoder decodeObjectForKey:@"isDirected"] boolValue];
    }
    return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.startVertex forKey:@"start"];
    [aCoder encodeObject:self.endVertex forKey:@"end"];
    [aCoder encodeObject:[NSNumber numberWithBool:self.isNonEdge] forKey:@"isNonEdge"];
    [aCoder encodeObject:self.colour forKey:@"edgeColour"];
    [aCoder encodeObject:self.curvePoints forKey:@"curvePoints"];
    [aCoder encodeObject:[NSNumber numberWithBool:self.isDirected] forKey:@"isDirected"];
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

- (BOOL) edgeWithinDistance:(double)c ofPoint:(CGPoint)point {
    double dist;

    CGPoint curvePoint = [[self.splinePoints objectAtIndex:0] CGPointValue];
    for (int i = 1; i < [self.splinePoints count]; i++) {
        curvePoint = [[self.splinePoints objectAtIndex:i] CGPointValue];
        dist = sqrt(pow(curvePoint.x - point.x, 2) + pow(curvePoint.y - point.y, 2));
        if (dist < c) {
            return YES;
        }
    }
    return NO;
}

- (UIView *) hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *result = nil;
    if (CGRectContainsPoint([self bounds], point)) {
        result = [self edgeWithinDistance:20 ofPoint:point] ? self : nil;
    }
    return result;
}

- (NSArray *) getSplinePointsForStartPoint:(CGPoint)start endPoint:(CGPoint)end controlPoints:(NSMutableArray *)points {
    NSValue *startV = [NSValue valueWithCGPoint:start];
    NSValue *endV = [NSValue valueWithCGPoint:end];
    [points addObject:endV];
    [points addObject:endV];
    [points insertObject:startV atIndex:0];
    [points insertObject:startV atIndex:0];
    return [(EasyGraphCanvas *)self.superview catmullRomSpline:points segments:50];
}

- (void) drawEdgeThroughPoints:(NSArray *)points {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGPoint point = [[points objectAtIndex:0] CGPointValue];
    CGContextMoveToPoint(context, point.x, point.y);
    for (int i = 1; i < [points count]; i++) {
        point = [[points objectAtIndex:i] CGPointValue];
        CGContextAddLineToPoint(context, point.x, point.y);
    }
}

- (void) drawArrow {
    double slopy, cosy, siny;
    double length = 30.0;
    double width = 15.0;
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGPoint start = [[self.splinePoints objectAtIndex:[self.splinePoints count] - 4] CGPointValue];
    CGPoint end = [[self.splinePoints objectAtIndex:[self.splinePoints count] - 3] CGPointValue];
    slopy = atan2((start.y - end.y), (start.x - end.x));
    cosy = cos(slopy);
    siny = sin(slopy);
    CGContextMoveToPoint(context, end.x, end.y);
    CGContextAddLineToPoint(context,
                            end.x + (length * cosy - (width / 2.0 * siny)),
                            end.y + (length * siny + (width / 2.0 * cosy)));
    CGContextAddLineToPoint(context,
                            end.x + (length * cosy + width / 2.0 * siny),
                            end.y - (width / 2.0 * cosy - length * siny));
    CGContextClosePath(context);
    CGContextFillPath(context);
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 3.0);
    CGContextSetStrokeColorWithColor(context, self.colour.CGColor);
    if (self.isNonEdge) {
        CGFloat dashArray[] = {6};
        CGContextSetLineDash(context, 3, dashArray, 1);
    }
    CGPoint start = [self convertPoint:self.startVertex.center fromView:self.superview];
    CGPoint end = [self convertPoint:self.endVertex.center fromView:self.superview];
    
    CGPoint curvePoint;
    NSMutableArray *localCurvePoints = [[NSMutableArray alloc] init];
    for (NSValue *point in self.curvePoints) {
        curvePoint = [self convertPoint:[point CGPointValue] fromView:self.superview];
        [localCurvePoints addObject:[NSValue valueWithCGPoint:curvePoint]];
    }
    self.splinePoints = [self getSplinePointsForStartPoint:start endPoint:end controlPoints:localCurvePoints];
    [self drawEdgeThroughPoints:self.splinePoints];
    end = CGContextGetPathCurrentPoint(context);
    CGContextStrokePath(context);
    
    if (isDirected) [self drawArrow];

}
@end
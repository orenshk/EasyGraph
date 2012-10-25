//
//  VertexView.m
//  EasyGraph
//
//  Created by Oren Shklarsky on 12-07-20.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EasyGraphVertexView.h"

@implementation EasyGraphVertexView
@synthesize inNeighbs, outNeighbs, vertexNum, vertexSize, label;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        //[self setAlpha:0.0];
        self.backgroundColor = [UIColor clearColor];
        self.inNeighbs = [[NSMutableSet alloc] init];
        self.outNeighbs = [[NSMutableSet alloc] init];
        self.vertexSize = 34;
        [self setupVertexColour:[UIColor blackColor]];
        self.label = [[UILabel alloc] initWithFrame:CGRectMake(15, 15, 40, 40)];
        [label setTextAlignment:NSTextAlignmentCenter];
        [label setFont:[UIFont systemFontOfSize:20.0]];
        [label setBackgroundColor:[UIColor clearColor]];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        self.backgroundColor = [UIColor clearColor];
        self.inNeighbs = [aDecoder decodeObjectForKey:@"inNeighbs"];
        self.outNeighbs = [aDecoder decodeObjectForKey:@"outNeighbs"];
        self.vertexSize = [aDecoder decodeInt32ForKey:@"vertexSize"];
        self.vertexNum = [aDecoder decodeInt32ForKey:@"vertexNum"];
        self.colour = [aDecoder decodeObjectForKey:@"vertexColour"];
        self.label = [aDecoder decodeObjectForKey:@"label"];
    }
    return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.inNeighbs forKey:@"inNeighbs"];
    [aCoder encodeObject:self.outNeighbs forKey:@"outNeighbs"];
    [aCoder encodeInt32:self.vertexSize forKey:@"vertexSize"];
    [aCoder encodeInt32:self.vertexNum forKey:@"vertexNum"];
    [aCoder encodeObject:self.colour forKey:@"vertexColour"];
    [aCoder encodeObject:self.label forKey:@"label"];
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

- (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.nextResponder touchesCancelled:touches withEvent:event];
}

- (void) setupVertexColour:(UIColor *)col {
    [self setColour:col];
    CGFloat red, green, blue, alpha;
    red = green = blue = alpha = 0;
    if ([col isEqual:[UIColor blackColor]]) {
        [label setTextColor:[UIColor whiteColor]];
    } else if ([col isEqual:[UIColor whiteColor]]) {
        [label setTextColor:[UIColor blackColor]];
    } else {
        [col getRed:&red green:&green blue:&blue alpha:&alpha];
        [label setTextColor:[UIColor colorWithRed:1.0 - red green:1.0 - green blue:1.0 - blue alpha:alpha]];
    }
    
    [self addSubview:self.label];
}


- (void) drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    if ([self.colour isEqual:[UIColor whiteColor]]) {
        CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
        CGContextSetLineWidth(context, 2.0);
    } else {
        CGContextSetStrokeColorWithColor(context, self.colour.CGColor);
        CGContextSetLineWidth(context, 1.0);
    }
    CGContextSetFillColorWithColor(context, self.colour.CGColor);
    CGRect rectangle = CGRectMake((self.frame.size.width - self.vertexSize) / 2.0,
                                  (self.frame.size.height - self.vertexSize)/2.0, self.vertexSize, self.vertexSize);
    CGContextAddEllipseInRect(context, rectangle);
    CGContextStrokePath(context);
    CGContextFillEllipseInRect(context, rectangle);
}

@end
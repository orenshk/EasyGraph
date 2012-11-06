//
//  EasyGraphGridView.m
//  EasyGraph
//
//  Created by Oren Shklarsky on 2012-11-04.
//
//

#import "EasyGraphGridView.h"

@implementation EasyGraphGridView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setGridSize:30]; // Default
        [self setBackgroundColor:[UIColor whiteColor]];
        [self setOpaque:YES];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGRect r = self.frame;
    double thickness;
    UIColor *lineColor;
    for (int x = 0; x < r.size.width; x = x + self.gridSize) {
        thickness = x % (3*self.gridSize) ? 0.5: 2.5;
        lineColor = x % (3*self.gridSize) ? [UIColor blackColor] : [UIColor grayColor];
        CGContextSetLineWidth(context, thickness);
        CGContextSetStrokeColorWithColor(context, lineColor.CGColor);
        CGContextMoveToPoint(context, x, 0);
        CGContextAddLineToPoint(context, x, r.size.height);
        CGContextStrokePath(context);
    }
    
    for (int y = 0; y < r.size.height; y = y + self.gridSize) {
        thickness = y % (3*self.gridSize) ? 0.5: 2.5;
        lineColor = y % (3*self.gridSize) ? [UIColor blackColor] : [UIColor grayColor];
        CGContextSetLineWidth(context, thickness);
        CGContextSetStrokeColorWithColor(context, lineColor.CGColor);
        CGContextMoveToPoint(context, 0, y);
        CGContextAddLineToPoint(context, r.size.width, y);
        CGContextStrokePath(context);
    }
}


@end

//
//  VertexView.m
//  EasyGraph
//
//  Created by Oren Shklarsky on 12-07-20.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EasyGraphVertexView.h"

@implementation EasyGraphVertexView

+(Class)layerClass
{
	return [CATiledLayer class];
}

@synthesize inNeighbs, outNeighbs, vertexNum, vertexSize, label;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        //[self setAlpha:0.0];
        [self setBackgroundColor:[UIColor clearColor]];
        [self setOpaque:NO];
        self.inNeighbs = [[NSMutableSet alloc] init];
        self.outNeighbs = [[NSMutableSet alloc] init];
        self.vertexSize = 34;
        self.label = [[UIWebView alloc] initWithFrame:CGRectMake(16, 16, 40, 40)];
        [self.label setBackgroundColor:[UIColor clearColor]];
        [self.label setOpaque:NO];
        [self.label setUserInteractionEnabled:NO];
        [self.label.scrollView setScrollEnabled:NO];
        [self addSubview:self.label];
        self.letter = @"";

        [self setClipsToBounds:YES];
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
        self.letter = [aDecoder decodeObjectForKey:@"letter"];
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
    [aCoder encodeObject:self.letter forKey:@"letter"];
}

- (void) setupVertexLabelAndColour:(UIColor *)col {
    CGFloat red, green, blue, alpha;
    NSString *body, *color, *html;
    red = green = blue = alpha = 0;
    if ([col isEqual:[UIColor blackColor]]) {
        color = @"(255,255,255)";
        self.letter = [self.letter isEqualToString:@""] ? @"b" : self.letter;
    } else if ([col isEqual:[UIColor whiteColor]]) {
        color = @"(0,0,0)";
        self.letter = [self.letter isEqualToString:@""] ? @"w" : self.letter;
    } else if ([col isEqual:[UIColor blueColor]]) {
        color = @"(255,255,255)";
        self.letter = [self.letter isEqualToString:@""] ? @"x" : self.letter;
    } else if ([col isEqual:[UIColor greenColor]]) {
        color = @"(0,0,0)";
        self.letter = [self.letter isEqualToString:@""] ? @"y" : self.letter;
    } else if ([col isEqual:[UIColor redColor]]) {
        color = @"(0,0,0)";
        self.letter = [self.letter isEqualToString:@""] ? @"z" : self.letter;
    } else {
        color = @"(0,0,0)";
        self.letter = [self.letter isEqualToString:@""] ? @"u" : self.letter;
    }
    body = [NSString stringWithFormat:@"<i>%@</i><sub>%d</sub></body></html>", self.letter, self.vertexNum];
    html = [NSString stringWithFormat:@"<html> \n"
                                   "<head> \n"
                                   "<style type=\"text/css\"> \n"
                                   "body {font-size: %@; color:rgb%@}\n"
                                   "</style> \n"
                                   "</head> \n"
                                   "<body>%@</body> \n"
                                   "</html>", [NSNumber numberWithInt:18],color,  body];
    [self.label loadHTMLString:html baseURL:nil];
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
    
    [self setupVertexLabelAndColour:self.colour];
    CGContextSetFillColorWithColor(context, self.colour.CGColor);
    CGRect rectangle = CGRectMake((self.frame.size.width - self.vertexSize) / 2.0,
                                  (self.frame.size.height - self.vertexSize)/2.0, self.vertexSize, self.vertexSize);
    CGContextAddEllipseInRect(context, rectangle);
    CGContextStrokePath(context);
    CGContextFillEllipseInRect(context, rectangle);
    
    self.layer.opaque = YES;
    self.layer.masksToBounds = NO;
    self.layer.shadowOffset = CGSizeMake(-4, 0);
    self.layer.shadowRadius = 2.5;
    self.layer.shadowOpacity = 0.25;

    self.layer.shadowPath = [UIBezierPath bezierPathWithArcCenter:[self convertPoint:self.center fromView:self.superview] radius:self.vertexSize/2.0 + 3 startAngle:0 endAngle:M_PI*2 clockwise:YES].CGPath;
}

@end
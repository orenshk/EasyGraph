//
//  EasyGraphScrollView.m
//  EasyGraph
//
//  Created by Oren Shklarsky on 2012-10-26.
//
//

#import "EasyGraphScrollView.h"

@implementation EasyGraphScrollView
@synthesize EGDelegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setBackgroundColor:[UIColor clearColor]];
        [self setOpaque:NO];
        
    }
    return self;
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if ([[touches anyObject] tapCount] == 1) {
        [EGDelegate touchesBegan:touches withEvent:event];
    } else {
        [super touchesBegan:touches withEvent:event];
    }
}

- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.nextResponder touchesMoved:touches withEvent:event];
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    for (UIView *view in self.subviews) {
        [view setNeedsDisplay];
    }
}


@end

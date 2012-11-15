//
//  EasyGraphElement.m
//  EasyGraph
//
//  Created by Oren Shklarsky on 2012-10-31.
//
//

#import "EasyGraphElement.h"

@implementation EasyGraphElement
@synthesize colour, label, letterSize;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end

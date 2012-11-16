//
//  EasyGraphElement.m
//  EasyGraph
//
//  Created by Oren Shklarsky on 2012-10-31.
//
//

#import "EasyGraphElement.h"

@implementation EasyGraphElement
@synthesize colour, label, letter, letterSize;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.label = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
        self.label.center = CGPointMake(frame.size.width/2.0, frame.size.height/2.0);
        [self.label setBackgroundColor:[UIColor clearColor]];
        [self.label setOpaque:NO];
        [self.label setUserInteractionEnabled:NO];
        [self.label.scrollView setScrollEnabled:NO];
        [self addSubview:self.label];
        self.letter = @"";
        self.letterSize = 18.0;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        self.colour = [aDecoder decodeObjectForKey:@"vertexColour"];
        self.label = [aDecoder decodeObjectForKey:@"label"];
        self.letter = [aDecoder decodeObjectForKey:@"letter"];
        self.letterSize = [[aDecoder decodeObjectForKey:@"letterSize"] integerValue];
        self.hidingLabel = [[aDecoder decodeObjectForKey:@"hidingLabel"] boolValue];
        self.number = [aDecoder decodeInt32ForKey:@"elementNumber"];
    }
    return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.colour forKey:@"vertexColour"];
    [aCoder encodeObject:self.label forKey:@"label"];
    [aCoder encodeObject:self.letter forKey:@"letter"];
    [aCoder encodeObject:[NSNumber numberWithInt:self.letterSize] forKey:@"letterSize"];
    [aCoder encodeObject:[NSNumber numberWithBool:self.hidingLabel] forKey:@"hidingLabel"];
    [aCoder encodeInt32:self.number forKey:@"elementNumber"];
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

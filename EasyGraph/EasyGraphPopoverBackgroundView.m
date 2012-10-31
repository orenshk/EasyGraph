//
//  EasyGraphPopoverBackgroundView.m
//  EasyGraph
//
//  Created by Oren Shklarsky on 2012-10-29.
//
//

#import "EasyGraphPopoverBackgroundView.h"

@implementation EasyGraphPopoverBackgroundView

@synthesize arrowOffset, arrowDirection;



-(id)initWithFrame:(CGRect)frame{
    
    if (self = [super initWithFrame:frame]) {
        
        _imageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"bg-popover-grey.png"] resizableImageWithCapInsets: UIEdgeInsetsMake(40.0, 10.0, 30.0, 10.0)]];

       _arrowView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bg-popover-arrow.png"]];
        
        self.BackgroundColor =  _imageView.BackgroundColor = [UIColor clearColor];
        [self addSubview:_imageView];
        [self addSubview:_arrowView];
    
        
    }
    return self;
}



//- (void)drawRect:(CGRect)rect {
//    
//    
//    
//}



-(void)layoutSubviews{
    switch (arrowDirection) {
        case UIPopoverArrowDirectionDown:
            _imageView.frame = CGRectMake(0, 0, self.superview.frame.size.width, self.superview.frame.size.height - 20);
                        _arrowView.transform = CGAffineTransformMakeRotation(M_PI);
            _arrowView.frame = CGRectMake(self.superview.frame.size.width / 2 + arrowOffset - [EasyGraphPopoverBackgroundView arrowBase] / 2, self.superview.frame.size.height - 20, [EasyGraphPopoverBackgroundView arrowBase], [EasyGraphPopoverBackgroundView arrowHeight]);
            break;
        case UIPopoverArrowDirectionUp:
            _imageView.frame = CGRectMake(0, 20, self.superview.frame.size.width, self.superview.frame.size.height - 20);
            
            _arrowView.frame = CGRectMake(self.superview.frame.size.width / 2 + arrowOffset - [EasyGraphPopoverBackgroundView arrowBase] / 2, -1, [EasyGraphPopoverBackgroundView arrowBase], [EasyGraphPopoverBackgroundView arrowHeight]);
            break;
        case UIPopoverArrowDirectionLeft:
            _imageView.frame = CGRectMake(0, 0, self.superview.frame.size.width, self.superview.frame.size.height);
            break;
        case UIPopoverArrowDirectionRight:
            _imageView.frame = CGRectMake(0, 0, self.superview.frame.size.width - 20, self.superview.frame.size.height);
            break;
        default:
            _imageView.frame = CGRectMake(0, 0, self.superview.frame.size.width, self.superview.frame.size.height - 20);
            _arrowView.frame = CGRectMake(0, 0, 0, 0);
            break;
    }
}



+(UIEdgeInsets)contentViewInsets{
    
    return UIEdgeInsetsMake(5, 5, 5, 5);
}



+(CGFloat)arrowHeight{
    return 21.0;
}



+(CGFloat)arrowBase{
    
    return 35.0;
}

@end

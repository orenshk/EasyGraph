//
//  EasyGraphScrollView.h
//  EasyGraph
//
//  Created by Oren Shklarsky on 2012-10-26.
//
//

#import <UIKit/UIKit.h>

@protocol EasyGraphScrollViewDelegate <NSObject>
@required
- (IBAction)handlePanGesture:(UIPanGestureRecognizer *)sender;
- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;

@end
@interface EasyGraphScrollView : UIScrollView
@property (nonatomic, assign) id <EasyGraphScrollViewDelegate> EGDelegate;
@end

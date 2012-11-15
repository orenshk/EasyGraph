//
//  EasyGraphElement.h
//  EasyGraph
//
//  Created by Oren Shklarsky on 2012-10-31.
//
//

#import <UIKit/UIKit.h>

@interface EasyGraphElement : UIView

@property (strong, nonatomic) UIColor *colour;
@property (strong, nonatomic) IBOutlet UIWebView *label;
@property (strong, nonatomic) NSString *letter;
@property float letterSize;

@end

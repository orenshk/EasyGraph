//
//  GMPdfViewController.h
//  GraphMaker
//
//  Created by Oren Shklarsky on 2012-10-16.
//
//

#import <UIKit/UIKit.h>

@interface GMPdfViewController : UIViewController <UIDocumentInteractionControllerDelegate,
                                                   UIPrintInteractionControllerDelegate>
@property (strong, nonatomic) IBOutlet UIBarButtonItem *openInButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *printButton;
@property (strong, nonatomic) UIDocumentInteractionController *documentInteractionController;
@property (strong, nonatomic) NSString *filePath;

- (void) openInDialouge;

- (void) showPDF;

- (void) printItem;

@end

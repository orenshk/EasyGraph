//
//  GMLatexConstructor.h
//  GraphMaker
//
//  Created by Oren Shklarsky on 2012-10-19.
//
//

#import <UIKit/UIKit.h>
#import "GMVertexView.h"
#import "GMEdgeView.h"

@interface GMLatexConstructor : UIViewController

@property (strong, nonatomic) IBOutlet UITextView *latexField;
@property (strong, nonatomic) IBOutlet UIView *settingsView;

@property (strong, nonatomic) IBOutlet UISegmentedControl *latexPackageSwitch;
@property (strong, nonatomic) IBOutlet UIWebView *pdfView;
@property (strong, nonatomic) IBOutlet UIToolbar *vertexEdgeSizeToolBar;
@property (strong, nonatomic) IBOutlet UIToolbar *scaleFactorToolbar;
@property (strong, nonatomic) IBOutlet UIToolbar *buttonsToolBar;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *previewButton;

// scale factor
@property (strong, nonatomic) IBOutlet UISlider *scaleFactorSlider;
@property (strong, nonatomic) IBOutlet UITextField *scaleFactorTextField;

// Vertex size
@property (strong, nonatomic) IBOutlet UISlider *vertexSizeSlider;
@property (strong, nonatomic) IBOutlet UITextField *vertexSizeTextField;

// Edge width
@property (strong, nonatomic) IBOutlet UISlider *edgeWidthSlider;
@property (strong, nonatomic) IBOutlet UITextField *edgeWidthTextField;


@property double scaleFactor;
@property double vertexSize;
@property double vertexSizeMultiplier;
@property double edgeWidthMultiplier;
@property double edgeWidth;
@property NSMutableArray *colors;
@property (strong, nonatomic) NSSet *vertexSet;
@property BOOL doingPSTricks;

- (NSString *) getPathforTexFile;

- (void) processForTiKzFile;
- (NSMutableString *) processCurvedEdgeForTiKz:(GMEdgeView *)edge;
- (NSString *) processStraightEdgeForTiKz:(GMEdgeView *)edge;
- (NSString *) processVertexForTiKz:(GMVertexView *)vert;

- (void) processForPSTricksFile;
- (NSString *) makePSTricksEdgeCommandStringForEdge:(GMEdgeView *)edge;
- (NSString *) makePSTricksVertexCommandStringForVertex:(GMVertexView *)vert;

- (NSString *) makeColorStringWithColor:(UIColor* )color;



- (IBAction)scaleSliderMoved:(UISlider *)sender;
- (IBAction)scaleFieldChanged;
- (IBAction)previewPressed;
- (IBAction)vertexSizeSliderMoved:(UISlider *)sender;
- (IBAction)vertexSizeFieldChanged:(id)sender;
- (IBAction)edgeWitdhSliderMoved:(UISlider *)sender;
- (IBAction)edgeWidthFieldChanged:(UITextField *)sender;

@end
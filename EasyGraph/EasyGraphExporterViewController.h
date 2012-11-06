//
//  GMLatexConstructor.h
//  EasyGraph
//
//  Created by Oren Shklarsky on 2012-10-19.
//
//

#import <UIKit/UIKit.h>
#import <DropboxSDK/DropboxSDK.h>
#import "EasyGraphVertexView.h"
#import "EasyGraphEdgeView.h"


@interface EasyGraphExporterViewController : UIViewController
<UIDocumentInteractionControllerDelegate,
DBRestClientDelegate> {
    DBRestClient *restClient;
    NSString *extension;
}

@property (strong, nonatomic) IBOutlet UITextView *codeField;
@property (strong, nonatomic) IBOutlet UIView *settingsView;

@property (strong, nonatomic) IBOutlet UISegmentedControl *exportLanguageSelector;
@property (strong, nonatomic) IBOutlet UIWebView *pdfView;
@property (strong, nonatomic) IBOutlet UIToolbar *vertexEdgeSizeToolBar;
@property (strong, nonatomic) IBOutlet UIToolbar *scaleFactorToolbar;
@property (strong, nonatomic) IBOutlet UIToolbar *buttonsToolBar;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *saveButton;

@property (strong, nonatomic) IBOutlet UIToolbar *middleBar;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *exportPDFButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *openPDFInButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *previewButton;

@property (strong, nonatomic) UIDocumentInteractionController *documentInteractionController;

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
@property double edgeWidth;
@property (strong, nonatomic) NSMutableArray *colors;
@property (strong, nonatomic) NSSet *vertexSet;
@property BOOL isDirected;
@property BOOL doingPSTricks;


- (IBAction)exportGraph:(UISegmentedControl *)sender;

- (NSString *) getPathForFileOfType:(NSString *)type;

- (void) processForTiKzFile;
- (NSMutableString *) processCurvedEdgeForTiKz:(EasyGraphEdgeView *)edge;
- (NSString *) processStraightEdgeForTiKz:(EasyGraphEdgeView *)edge;
- (NSString *) processVertexForTiKz:(EasyGraphVertexView *)vert;

- (void) processForPSTricksFile;
- (NSString *) makePSTricksEdgeCommandStringForEdge:(EasyGraphEdgeView *)edge;
- (NSString *) makePSTricksVertexCommandStringForVertex:(EasyGraphVertexView *)vert;

- (void) processForSageFile;

- (NSString *) makeColorStringWithColor:(UIColor* )color;

- (IBAction)scaleSliderMoved:(UISlider *)sender;
- (IBAction)scaleFieldChanged;
- (IBAction)vertexSizeSliderMoved:(UISlider *)sender;
- (IBAction)vertexSizeFieldChanged:(id)sender;
- (IBAction)edgeWitdhSliderMoved:(UISlider *)sender;
- (IBAction)edgeWidthFieldChanged:(UITextField *)sender;
- (IBAction)openInDialouge:(id)sender;
- (IBAction)makePreview:(id)sender;
- (IBAction)savePressed:(UIBarButtonItem *)sender;
- (IBAction)savePDFpressed:(UIBarButtonItem *)sender;


@end
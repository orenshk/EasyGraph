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
#import "EasyGraphAppDelegate.h"
#import "EasyGraphPopoverBackgroundView.h"
#import "GTLDrive.h"
#import "GTMOAuth2ViewControllerTouch.h"

static NSString *UbiquityContainerIdentifier = @"88H38EDZM9.com.orenshk.EasyGraph";

@interface EasyGraphExporterViewController : UIViewController
<UIDocumentInteractionControllerDelegate,
DBRestClientDelegate,
EasyGraphDropboxDelegate> {
    DBRestClient *restClient;
    NSString *extension;
    BOOL googleIsAuthorized;
    BOOL usingColours;
}

@property (strong, nonatomic) NSMetadataQuery *metadataQuery;

//Settings
@property (strong, nonatomic) IBOutlet UIView *settingsView;

// scale factor
@property (strong, nonatomic) IBOutlet UIToolbar *scaleFactorToolbar;
@property (strong, nonatomic) IBOutlet UISlider *scaleFactorSlider;
@property (strong, nonatomic) IBOutlet UITextField *scaleFactorTextField;

// Vertex size
@property (strong, nonatomic) IBOutlet UIToolbar *vertexEdgeSizeToolBar;
@property (strong, nonatomic) IBOutlet UISlider *vertexSizeSlider;
@property (strong, nonatomic) IBOutlet UITextField *vertexSizeTextField;

// Edge width
@property (strong, nonatomic) IBOutlet UISlider *edgeWidthSlider;
@property (strong, nonatomic) IBOutlet UITextField *edgeWidthTextField;

// PDF toolbar and view
@property (strong, nonatomic) UIDocumentInteractionController *documentInteractionController;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *exportPDFButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *openPDFInButton;
@property (strong, nonatomic) IBOutlet UISwitch *colourSwitch;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *previewButton;
@property (strong, nonatomic) IBOutlet UIWebView *pdfView;

// Export view
@property (strong, nonatomic) IBOutlet UIToolbar *middleBar;
@property (strong, nonatomic) IBOutlet UISegmentedControl *exportLanguageSelector;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *saveButton;
@property (strong, nonatomic) UIActivityIndicatorView *uploadingView;
@property (strong, nonatomic) IBOutlet UIPopoverController *servicesPopoverController;
@property (strong, nonatomic) IBOutlet UITextView *codeField;


@property (strong, nonatomic) DBMetadata *dropboxFile;
@property GTLDriveFile *googleDriveFile;

@property (strong, nonatomic) EasyGraphAppDelegate *myAppDelegate;

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

- (IBAction)colourSwitchFlipped:(UISwitch *)sender;
- (IBAction)selectedLanguageChanged:(UISegmentedControl *)sender;
- (IBAction)scaleSliderMoved:(UISlider *)sender;
- (IBAction)vertexSizeSliderMoved:(UISlider *)sender;
- (IBAction)edgeWitdhSliderMoved:(UISlider *)sender;
- (IBAction)openInDialouge:(id)sender;
- (IBAction)makePreview;
- (IBAction)savePressed:(UIBarButtonItem *)sender;
- (IBAction)savePDFpressed:(UIBarButtonItem *)sender;


@end
//
//  EasyGraphSettings.h
//  EasyGraph
//
//  Created by Oren Shklarsky on 2012-11-06.
//
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "EasyGraphAppDelegate.h"
#import "EasyGraphDetailViewController.h"

@interface EasyGraphSettings : UIViewController <EasyGraphDropboxDelegate>
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet UIView *graphBuilderSettings;

//Vertex settings
@property (strong, nonatomic) IBOutlet UIView *vertexDemoViewBackground;
@property (strong, nonatomic) EasyGraphVertexView *vertexDemoView;
@property (strong, nonatomic) IBOutlet UISlider *vertexSizeSlider;
@property (strong, nonatomic) IBOutlet UISwitch *showingLabelsSwitch;
@property (strong, nonatomic) IBOutlet UISlider *vertexLetterSizeSlider;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *vertexBlackColor;

// Edge settings
@property (strong, nonatomic) IBOutlet EasyGraphCanvas *edgeDemoViewBackground;
@property (strong, nonatomic) IBOutlet EasyGraphEdgeView *edgeDemoView;
@property (strong, nonatomic) IBOutlet UISlider *edgeWidthSlider;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *edgeBlackColour;

// Export settings
@property (strong, nonatomic) IBOutlet UISegmentedControl *defaultLanguage;
@property (strong, nonatomic) IBOutlet UISwitch *exportingColours;

// Tikz settings
@property (strong, nonatomic) IBOutlet UISlider *tikzScaleSlider;
@property (strong, nonatomic) IBOutlet UITextField *tikzScaleTextField;
@property (strong, nonatomic) IBOutlet UISlider *tikzVertexSizeSlider;
@property (strong, nonatomic) IBOutlet UITextField *tikzVertexSizeTextField;
@property (strong, nonatomic) IBOutlet UISlider *tikzEdgeWidthSlider;
@property (strong, nonatomic) IBOutlet UITextField *tikzEdgeWidthTextField;

// PSTricks settings
@property (strong, nonatomic) IBOutlet UISlider *pstricksScaleSlider;
@property (strong, nonatomic) IBOutlet UITextField *pstricksScaleTextField;
@property (strong, nonatomic) IBOutlet UISlider *pstricksVertexSizeSlider;
@property (strong, nonatomic) IBOutlet UITextField *pstricksVertexSizeTextField;
@property (strong, nonatomic) IBOutlet UISlider *pstricksEdgeWidthSlider;
@property (strong, nonatomic) IBOutlet UITextField *pstricksEdgeWidthTextField;

// Storage settings
@property (strong, nonatomic) IBOutlet UIBarButtonItem *dropboxButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *googleDriveButton;
@property (strong, nonatomic) IBOutlet UISegmentedControl *defaultStorageService;


@property (strong, nonatomic) NSMutableArray *easyGraphDetailViewControllers;
@property (strong, nonatomic) NSUserDefaults *defaults;
@property (strong, nonatomic) EasyGraphAppDelegate *myAppDelegate;

// Vertex settings methods
- (IBAction)vertexSizeSliderMoved:(UISlider *)sender;
- (IBAction)vertexLabelsToggled:(UISwitch *)sender;
- (IBAction)labelSizeSliderMoved:(UISlider *)sender;
- (IBAction)vertexColourChosen:(UIBarButtonItem *)sender;

// Edge settings methods
- (IBAction)edgeWidthSliderMoved:(UISlider *)sender;
- (IBAction)edgeColourChosen:(UIBarButtonItem *)sender;

// Export Settings methods
- (IBAction)defaultLanguageChanged:(UISegmentedControl *)sender;
- (IBAction)exportColoursToggled:(UISwitch *)sender;

// TikZ settings methods
- (IBAction)tikzScaleSliderMoved:(UISlider *)sender;
- (IBAction)tikzVertexSizeSliderMoved:(UISlider *)sender;
- (IBAction)tikzEdgeWidthSliderMoved:(UISlider *)sender;

// PSTricks settings methods
- (IBAction)pstricksScaleSliderMoved:(UISlider *)sender;
- (IBAction)pstricksVertexSizeSliderMoved:(UISlider *)sender;
- (IBAction)pstricksEdgeWidthSliderMoved:(UISlider *)sender;

// Storage settings methods
- (IBAction)dropboxButtonPressed:(UIBarButtonItem *)sender;
- (IBAction)googleDriveButtonPressed:(UIBarButtonItem *)sender;
- (IBAction)defaultStorageServiceChanged:(UISegmentedControl *)sender;

- (IBAction)resetVertexSettings;
- (IBAction)resetEdgeSettings;
- (IBAction)resetTikZSettings;
- (IBAction)resetPSTricksSettings;
- (IBAction)resetAllSettingsPressed;

@end
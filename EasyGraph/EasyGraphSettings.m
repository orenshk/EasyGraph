//
//  EasyGraphSettings.m
//  EasyGraph
//
//  Created by Oren Shklarsky on 2012-11-06.
//
//

#import <DropboxSDK/DropboxSDK.h>
#import "EasyGraphSettings.h"
#import "GTLDrive.h"
#import "GTMOAuth2ViewControllerTouch.h"

@interface EasyGraphSettings ()


@property BOOL googleIsAuthorized;

- (void)isAuthorizedWithAuthentication:(GTMOAuth2Authentication *)auth;

@end

@implementation EasyGraphSettings

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        [self setTitle:@"Settings"];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self.myAppDelegate setDelegate:self];
    
    [self roundBorderForLayer:self.vertexDemoViewBackground.layer];
    [self roundBorderForLayer:self.graphBuilderSettings.layer];
    [self roundBorderForLayer:self.edgeDemoViewBackground.layer];
    
    
    //setup scrollview
    [self.scrollView addSubview:self.graphBuilderSettings];
    CGSize size = self.graphBuilderSettings.frame.size;
    [self.graphBuilderSettings setFrame:CGRectMake(14, 14, size.width, size.height)];
    [self.scrollView setContentSize:CGSizeMake(size.width + 14, size.height + 14)];
    
    [self setupVertexDefaults];
    [self setupEdgeDefaults];
    [self setupExportDefaults];
    [self setupTikZDefaults];
    [self setupPSTricksDefaults];
    [self setupStorageDefaults];
    
    for (UIView *view in self.graphBuilderSettings.subviews) {
        if (![view isKindOfClass:[UILabel class]]) {
            [self roundBorderForLayer:view.layer];
            for (UIView *subview in view.subviews) {
                if (![subview isKindOfClass:[UILabel class]]) {
                    [subview.layer setBorderColor:[[UIColor lightGrayColor] CGColor]];
                    [subview.layer setBorderWidth:1.0];
                }
            }
        }
    }
    
    [self.vertexDemoView.layer setBorderWidth:0];
    [self.vertexBlackColor setTintColor:[UIColor blackColor]];
    [self.edgeBlackColour setTintColor:[UIColor blackColor]];
    
    [self.dropboxButton setPossibleTitles:[NSSet setWithObjects:@"Sign in to Dropbox", @"Sign out of Dropbox", nil]];
    [self.dropboxButton setTitle:[[DBSession sharedSession] isLinked] ? @"Sign out of Dropbox" : @"Sign in to Dropbox"];
    
    [self.googleDriveButton setPossibleTitles:[NSSet setWithObjects:@"Sign in to Google Drive", @"Sign out of Google Drive", nil]];
    GTMOAuth2Authentication *auth =
    [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:kKeychainItemName
                                                          clientID:kClientId
                                                      clientSecret:kClientSecret];
    
    if ([auth canAuthorize]) {
        [self isAuthorizedWithAuthentication:auth];
        [self.googleDriveButton setTitle:@"Sign out of Google Drive"];
    } else {
        [self.googleDriveButton setTitle:@"Sign in to Google Drive"];
    }
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setVertexDemoViewBackground:nil];
    [self setGraphBuilderSettings:nil];
    [self setEdgeDemoViewBackground:nil];
    [self setVertexBlackColor:nil];
    [self setVertexSizeSlider:nil];
    [self setVertexLetterSizeSlider:nil];
    [self setScrollView:nil];
    [self setShowingLabelsSwitch:nil];
    [self setEdgeWidthSlider:nil];
    [self setEdgeBlackColour:nil];
    [self setDefaultLanguage:nil];
    [self setExportingColours:nil];
    [self setTikzScaleSlider:nil];
    [self setTikzVertexSizeSlider:nil];
    [self setTikzEdgeWidthSlider:nil];
    [self setPstricksVertexSizeSlider:nil];
    [self setPstricksEdgeWidthSlider:nil];
    [self setPstricksScaleSlider:nil];
    [self setPstricksVertexSizeSlider:nil];
    [self setPstricksEdgeWidthSlider:nil];
    [self setDropboxButton:nil];
    [self setGoogleDriveButton:nil];
    [self setDefaultStorageService:nil];
    [self setTikzScaleTextField:nil];
    [self setTikzVertexSizeTextField:nil];
    [self setTikzEdgeWidthTextField:nil];
    [self setPstricksScaleTextField:nil];
    [self setPstricksVertexSizeTextField:nil];
    [self setPstricksEdgeWidthTextField:nil];
    [super viewDidUnload];
}


- (void) viewWillDisappear:(BOOL)animated {
    [self.defaults synchronize];
}

# pragma mark - loading defaults methods

- (void) setupVertexDefaults {
    //vertex settings
    self.defaults = [NSUserDefaults standardUserDefaults];
    CGFloat vertexSize = [self.defaults floatForKey:@"vertexSize"];
    BOOL hidingLabels = [self.defaults boolForKey:@"hidingLabels"];
    CGFloat vertexLetterSize = [self.defaults floatForKey:@"vertexLetterSize"];
    NSData *colourData = [self.defaults objectForKey:@"vertexColour"];
    UIColor *vertexColour = [NSKeyedUnarchiver unarchiveObjectWithData:colourData];
    
    //setup vertex change demo
    CGSize size = self.vertexDemoViewBackground.frame.size;
    self.vertexDemoView = [[EasyGraphVertexView alloc] initWithFrame:CGRectMake((size.width - vertexSize)/2.0, (size.height - vertexSize)/2.0, vertexSize, vertexSize)];
    [self.vertexDemoView setColour:vertexColour];
    [self.vertexDemoView setupVertexLabelAndColour:vertexColour];
    [self.vertexDemoView setLetterSize:vertexLetterSize];
    [self.vertexDemoViewBackground addSubview:self.vertexDemoView];
    
    [self.vertexSizeSlider setValue:vertexSize];
    [self.showingLabelsSwitch setOn:hidingLabels];
    [self.vertexDemoView updateLabelStatus:hidingLabels];
    [self.vertexLetterSizeSlider setEnabled:!hidingLabels];
    [self.vertexLetterSizeSlider setValue:vertexLetterSize];
}

- (void) setupEdgeDefaults {
    //setup edge change demo
    CGSize size = self.edgeDemoViewBackground.frame.size;
    EasyGraphVertexView *start = [[EasyGraphVertexView alloc]
                                    initWithFrame:CGRectMake(0, 0, 0, 0)];
    EasyGraphVertexView *end = [[EasyGraphVertexView alloc]
                                    initWithFrame:CGRectMake(size.width, size.height, 0, 0)];
    self.edgeDemoView = [[EasyGraphEdgeView alloc]
                         initWithFrame:CGRectMake(0, 0, size.width, size.height) andStartPnt:start andEndPnt:end];

    [self.edgeDemoViewBackground addSubview:self.edgeDemoView];

    CGFloat edgeWidth = [self.defaults floatForKey:@"edgeWidth"];
    [self.edgeWidthSlider setValue:edgeWidth];
    [self.edgeDemoView setEdgeWidth:edgeWidth];
    
    NSData *colourData = [self.defaults objectForKey:@"edgeColour"];
    UIColor *edgeColour = [NSKeyedUnarchiver unarchiveObjectWithData:colourData];
    [self.edgeDemoView setColour:edgeColour];
}

- (void) roundBorderForLayer:(CALayer *)imageLayer {
    [imageLayer setCornerRadius:10];
    [imageLayer setBorderWidth:1];
    [imageLayer setBorderColor:[[UIColor lightGrayColor] CGColor]];
}

- (void) setupExportDefaults {
    [self.defaultLanguage setSelectedSegmentIndex:[self.defaults integerForKey:@"defaultLanguage"]];
    [self.exportingColours setOn:[self.defaults boolForKey:@"exportColours"]];
}
     
- (void) setupTikZDefaults {
    [self.tikzScaleSlider setValue:[self.defaults floatForKey:@"tikzScale"]];
    [self.tikzVertexSizeSlider setValue:[self.defaults floatForKey:@"tikzVertexSize"]];
    [self.tikzEdgeWidthSlider setValue:[self.defaults floatForKey:@"tikzEdgeWidth"]];
    
    double newVal = (int)([self.tikzScaleSlider value] * 10) / 10.0;
    newVal = 15 - newVal;
    [self.tikzScaleTextField setText:[NSString stringWithFormat:@"%.1f", newVal]];
    [self.tikzScaleTextField setText:[NSString stringWithFormat:@"%.1f", newVal]];
    [self.tikzVertexSizeTextField setText:[NSString stringWithFormat:@"%.1f", [self.tikzVertexSizeSlider value]]];
    [self.tikzEdgeWidthTextField setText:[NSString stringWithFormat:@"%.1f", [self.tikzEdgeWidthSlider value]]];
}

- (void) setupPSTricksDefaults {
    [self.pstricksScaleSlider setValue:[self.defaults floatForKey:@"pstricksScale"]];
    [self.pstricksVertexSizeSlider setValue:[self.defaults floatForKey:@"pstricksVertexSize"]];
    [self.pstricksEdgeWidthSlider setValue:[self.defaults floatForKey:@"pstricksEdgeWidth"]];
    
    double newVal = (int)([self.pstricksScaleSlider value] * 10) / 10.0;
    newVal = 15 - newVal;
    [self.pstricksScaleTextField setText:[NSString stringWithFormat:@"%.1f", newVal]];
    [self.pstricksScaleTextField setText:[NSString stringWithFormat:@"%.1f", newVal]];
    [self.pstricksVertexSizeTextField setText:[NSString stringWithFormat:@"%.1f", [self.pstricksVertexSizeSlider value]]];
    [self.pstricksEdgeWidthTextField setText:[NSString stringWithFormat:@"%.1f", [self.pstricksEdgeWidthSlider value]]];
}

- (void) setupStorageDefaults {
    [self.defaultStorageService setSelectedSegmentIndex:[self.defaults integerForKey:@"storageDefaultService"]];
}

# pragma mark - vertex settings

- (IBAction)vertexSizeSliderMoved:(UISlider *)sender {
    CGFloat newSize = [sender value];
    [self.vertexDemoView updateVertexSize:newSize];
    for (EasyGraphDetailViewController *view in self.easyGraphDetailViewControllers) {
        [view setVertexFrameSize:newSize];
    }
    [self.defaults setFloat:newSize forKey:@"vertexSize"];
}

- (IBAction)vertexLabelsToggled:(UISwitch *)sender {
    [self.vertexDemoView updateLabelStatus:[sender isOn]];
    for (EasyGraphDetailViewController *view in self.easyGraphDetailViewControllers) {
        [view setHidingLabels:[sender isOn]];
        [view.toggleLabelsButton setTitle:[sender isOn] ? @"Show Labels": @"Hide Labels"];
        for (EasyGraphVertexView *vert in view.vertexSet) {
            [vert updateLabelStatus:[sender isOn]];
        }
    }
    [self.vertexLetterSizeSlider setEnabled:![sender isOn]];
    [self.defaults setBool:[sender isOn] forKey:@"hidingLabels"];
}

- (IBAction)labelSizeSliderMoved:(UISlider *)sender {
    [self.vertexDemoView updateLabelSize:[sender value]];
    for (EasyGraphDetailViewController *view in self.easyGraphDetailViewControllers) {
        [view setLetterSize:[sender value]];
    }
    [self.defaults setFloat:[sender value] forKey:@"vertexLetterSize"];
}

- (IBAction)vertexColourChosen:(UIBarButtonItem *)sender {
    [self.vertexDemoView setColour:[sender tintColor]];
    [self.vertexDemoView setupVertexLabelAndColour:[sender tintColor]];
    [self.vertexDemoView setNeedsDisplay];
    for (EasyGraphDetailViewController *view in self.easyGraphDetailViewControllers) {
        [view setVertexColour:[sender tintColor]];
        [view.vertexColourButton setTintColor:[sender tintColor]];
    }
    NSData *colourData = [NSKeyedArchiver archivedDataWithRootObject:[sender tintColor]];
    [self.defaults setObject:colourData forKey:@"vertexColour"];
    
}

#pragma mark - edge settings

- (IBAction)edgeWidthSliderMoved:(UISlider *)sender {
    [self.edgeDemoView setEdgeWidth:[sender value]];
    [self.edgeDemoView setNeedsDisplay];
    [self.defaults setFloat:[sender value] forKey:@"edgeWidth"];
    for (EasyGraphDetailViewController *view in self.easyGraphDetailViewControllers) {
        [view setEdgeWidth:[sender value]];
    }
}

- (IBAction)edgeColourChosen:(UIBarButtonItem *)sender {
    [self.edgeDemoView setColour:[sender tintColor]];
    [self.edgeDemoView setNeedsDisplay];
    NSData *colourData = [NSKeyedArchiver archivedDataWithRootObject:[sender tintColor]];
    [self.defaults setObject:colourData forKey:@"edgeColour"];
    for (EasyGraphDetailViewController *view in self.easyGraphDetailViewControllers) {
        [view setEdgeColour:[sender tintColor]];
        [view.vertexColourButton setTintColor:[sender tintColor]];
    }
}

#pragma mark - export settings

- (IBAction)defaultLanguageChanged:(UISegmentedControl *)sender {
    [self.defaults setInteger:[sender selectedSegmentIndex] forKey:@"defaultLanguage"];
}

- (IBAction)exportColoursToggled:(UISwitch *)sender {
    [self.defaults setBool:[sender isOn] forKey:@"exportColours"];
}

#pragma mark - tikz settings

- (IBAction)tikzScaleSliderMoved:(UISlider *)sender {
    double newVal = (int)([sender value] * 10) / 10.0;
    newVal = 15 - newVal;
    [self.tikzScaleTextField setText:[NSString stringWithFormat:@"%.1f", newVal]];
    [self.defaults setFloat:[sender value] forKey:@"tikzScale"];
}

- (IBAction)tikzVertexSizeSliderMoved:(UISlider *)sender {
    [self.tikzVertexSizeTextField setText:[NSString stringWithFormat:@"%.1f", [sender value]]];
    [self.defaults setFloat:[sender value] forKey:@"tikzVertexSize"];
}

- (IBAction)tikzEdgeWidthSliderMoved:(UISlider *)sender {
    [self.tikzEdgeWidthTextField setText:[NSString stringWithFormat:@"%.1f", [sender value]]];
    [self.defaults setFloat:[sender value] forKey:@"tikzEdgeWidth"];
}

#pragma mark - pstricks settings

- (IBAction)pstricksScaleSliderMoved:(UISlider *)sender {
    double newVal = (int)([sender value] * 10) / 10.0;
    newVal = 15 - newVal;
    [self.pstricksScaleTextField setText:[NSString stringWithFormat:@"%.1f", newVal]];
    [self.defaults setFloat:[sender value] forKey:@"pstricksScale"];
}

- (IBAction)pstricksVertexSizeSliderMoved:(UISlider *)sender {
    [self.pstricksVertexSizeTextField setText:[NSString stringWithFormat:@"%.1f", [sender value]]];
    [self.defaults setFloat:[sender value] forKey:@"pstricksVertexSize"];
}

- (IBAction)pstricksEdgeWidthSliderMoved:(UISlider *)sender {
    [self.pstricksEdgeWidthTextField setText:[NSString stringWithFormat:@"%.1f", [sender value]]];
    [self.defaults setFloat:[sender value] forKey:@"pstricksEdgeWidth"];
}

#pragma mark - stroage settings

- (IBAction)defaultStorageServiceChanged:(UISegmentedControl *)sender {
    [self.defaults setInteger:[sender selectedSegmentIndex] forKey:@"storageDefaultService"];
}

- (void) showSignOutAlertViewForService:(NSString *)service {
    NSString *msg = [NSString stringWithFormat:@"You have signed out of your %@ account", service];
    [[[UIAlertView alloc]
      initWithTitle:@"Account Signed out!" message:msg
      delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]
     show];
}

#pragma mark - storage - Dropbox
- (IBAction)dropboxButtonPressed:(UIBarButtonItem *)sender {
    if (![[DBSession sharedSession] isLinked]) {
        //Sign in
        [[DBSession sharedSession] linkFromController:self];
    } else {
        //Sign out
        [[DBSession sharedSession] unlinkAll];
        [self.dropboxButton setTitle:@"Sign in to Dropbox"];
        [self showSignOutAlertViewForService:@"Dropbox"];
    }
}

- (void)dropboxWasLinked {
    [self.dropboxButton setTitle:@"Sign out of Dropbox"];
}

#pragma mark - storage - Google

- (IBAction)googleDriveButtonPressed:(UIBarButtonItem *)sender {
    if (!self.googleIsAuthorized) {
        //Sign in
        SEL finishedSelector = @selector(viewController:finishedWithAuth:error:);
        GTMOAuth2ViewControllerTouch *authViewController =
        [[GTMOAuth2ViewControllerTouch alloc] initWithScope:kGTLAuthScopeDriveFile
                                                   clientID:kClientId
                                               clientSecret:kClientSecret
                                           keychainItemName:kKeychainItemName
                                                   delegate:self
                                           finishedSelector:finishedSelector];
        
        // Add cancel button on Google's login view.
        UIToolbar *toolBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 768, 44)];
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(userCanceledGoogleSignup)];
        [toolBar setItems:[NSArray arrayWithObject:cancelButton]];
        CGSize size;
        CGPoint origin;
        for (UIView *view in authViewController.view.subviews) {
            size = view.frame.size;
            origin = view.frame.origin;
            view.frame = CGRectMake(0, origin.y + 44, size.width, size.height - 44);
        }
        [authViewController.view addSubview:toolBar];
        [self presentViewController:authViewController animated:YES completion:nil];

    } else {
        //Sign out
        [GTMOAuth2ViewControllerTouch removeAuthFromKeychainForName:kKeychainItemName];
        [[self driveService] setAuthorizer:nil];
        [self.googleDriveButton setTitle:@"Sign in to Google Drive"];
        self.googleIsAuthorized = NO;
        [self showSignOutAlertViewForService:@"Google Drive"];
    }
}

- (IBAction)userCanceledGoogleSignup {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)viewController:(GTMOAuth2ViewControllerTouch *)viewController
      finishedWithAuth:(GTMOAuth2Authentication *)auth
                 error:(NSError *)error {
    [self dismissModalViewControllerAnimated:YES];
    if (error == nil) {
        [self isAuthorizedWithAuthentication:auth];
    }
}

- (void)isAuthorizedWithAuthentication:(GTMOAuth2Authentication *)auth {
    [[self driveService] setAuthorizer:auth];
    [self.googleDriveButton setTitle:@"Sign out of Google Drive"];
    [self setGoogleIsAuthorized:YES];
}

- (GTLServiceDrive *)driveService {
    static GTLServiceDrive *service = nil;
    
    if (!service) {
        service = [[GTLServiceDrive alloc] init];
        
        // Have the service object set tickets to fetch consecutive pages
        // of the feed so we do not need to manually fetch them.
        service.shouldFetchNextPages = YES;
        
        // Have the service object set tickets to retry temporary error conditions
        // automatically.
        service.retryEnabled = YES;
    }
    return service;
}

# pragma mark - reset buttons

- (IBAction)resetVertexSettings {
    [self.vertexSizeSlider setValue:70.0];
    [self vertexSizeSliderMoved:self.vertexSizeSlider];
    [self.showingLabelsSwitch setOn:NO];
    [self vertexLabelsToggled:self.showingLabelsSwitch];
    [self.vertexLetterSizeSlider setValue:18.0];
    [self labelSizeSliderMoved:self.vertexLetterSizeSlider];
    [self vertexColourChosen:self.vertexBlackColor];
}

- (IBAction)resetEdgeSettings {
    [self.edgeWidthSlider setValue:3.0];
    [self edgeWidthSliderMoved:self.edgeWidthSlider];
    
    [self edgeColourChosen:self.edgeBlackColour];
}

- (void) resetExportSettings {
    [self.defaultLanguage setSelectedSegmentIndex:0];
    [self defaultLanguageChanged:self.defaultLanguage];
    [self.exportingColours setOn:YES];
    [self exportColoursToggled:self.exportingColours];
}

- (IBAction)resetTikZSettings {
    [self.tikzScaleSlider setValue:10.0];
    [self tikzScaleSliderMoved:self.tikzScaleSlider];
    [self.tikzVertexSizeSlider setValue:5.0];
    [self tikzVertexSizeSliderMoved:self.tikzVertexSizeSlider];
    [self.tikzEdgeWidthSlider setValue:1.0];
    [self tikzEdgeWidthSliderMoved:self.tikzEdgeWidthSlider];
}

- (IBAction)resetPSTricksSettings {
    [self.pstricksScaleSlider setValue:10.0];
    [self pstricksScaleSliderMoved:self.pstricksScaleSlider];
    [self.pstricksVertexSizeSlider setValue:3.0];
    [self pstricksVertexSizeSliderMoved:self.pstricksVertexSizeSlider];
    [self.pstricksEdgeWidthSlider setValue:1.0];
    [self pstricksEdgeWidthSliderMoved:self.pstricksEdgeWidthSlider];
}


- (IBAction)resetAllSettingsPressed {
    [self resetVertexSettings];
    [self resetEdgeSettings];
    [self resetExportSettings];
    [self resetTikZSettings];
    [self resetPSTricksSettings];
    [self.defaultStorageService setSelectedSegmentIndex:0];
    [self.defaults setInteger:0 forKey:@"storageDefaultService"];
    
}
@end

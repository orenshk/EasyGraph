//
//  GMLatexConstructor.m
//  EasyGraph
//
//  Created by Oren Shklarsky on 2012-10-19.
//
//

#import "EasyGraphExporterViewController.h"

@interface EasyGraphExporterViewController ()

@end

@implementation EasyGraphExporterViewController
@synthesize scaleFactor, vertexSize, edgeWidth, colors, vertexSet;
@synthesize doingPSTricks;
@synthesize isDirected;

#pragma mark - view management
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.colors = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self.myAppDelegate setDelegate:self];
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    [self.codeField setFont: [UIFont systemFontOfSize:15]];

    [self roundBorderForLayer:self.codeField.layer];
    [self roundBorderForLayer:self.pdfView.layer];
    [self roundBorderForLayer:self.settingsView.layer];
    [self roundBorderForLayer:self.middleBar.layer];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [self.exportLanguageSelector setSelectedSegmentIndex:[defaults integerForKey:@"defaultLanguage"]];
    [self selectedLanguageChanged:self.exportLanguageSelector];
    
    [self.colourSwitch setOn:[defaults boolForKey:@"exportColours"]];
    usingColours = [self.colourSwitch isOn];
    
    [self setDoingPSTricks:self.exportLanguageSelector.selectedSegmentIndex == 1];
    [self exportGraph:self.exportLanguageSelector];
    
    [self setupSaveButtons];
}

- (void) setupSaveButtons {
    [self.saveButton setPossibleTitles:[NSSet setWithObjects:@"Save to...", @"Save to Dropbox", @"Save to Google Drive", nil]];
    
    GTMOAuth2Authentication *auth =
    [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:kKeychainItemName
                                                          clientID:kClientId
                                                      clientSecret:kClientSecret];
    googleIsAuthorized = [auth canAuthorize];
    [[self driveService] setAuthorizer:[auth canAuthorize] ? auth : nil];
    int servicesStatus[] = {[[DBSession sharedSession] isLinked], //Dropbox
                             googleIsAuthorized};                 //Google Drive
    int servicesSum = servicesStatus[0] + servicesStatus[1];
    NSArray *serviceNames = [NSArray arrayWithObjects:@"Save to Dropbox", @"Save to Google Drive", @"Save to...", nil];
    NSArray *pdfServiceNames = [NSArray arrayWithObjects:@"Save PDF to Dropbox", @"Save PDF to Google Drive", @"Save PDF to...", nil];
    int service = [[NSUserDefaults standardUserDefaults] integerForKey:@"storageDefaultService"];
    if (servicesSum == 0) {
        service = 2;
    } else if (!servicesStatus[service]) {
        // The default service is not linked, but some service is.
        // (right now there are only two but in future might have more).
        service = (service + 1) % 2;
    }
    
    [self.saveButton setTitle:[serviceNames objectAtIndex:service]];
    [self.saveButton setTag:service];
    [self.exportPDFButton setTitle:[pdfServiceNames objectAtIndex:service]];
    [self.exportPDFButton setTag:service];
}

- (void) roundBorderForLayer:(CALayer *)imageLayer {
    [imageLayer setCornerRadius:10];
    [imageLayer setBorderWidth:1];
    imageLayer.borderColor=[[UIColor blackColor] CGColor];
}

- (void)viewDidUnload {
    [self setSaveButton:nil];
    [self setExportPDFButton:nil];
    [self setOpenPDFInButton:nil];
    [self setMiddleBar:nil];
    [self setPreviewButton:nil];
    [self setScaleFactorSlider:nil];
    [self setScaleFactorTextField:nil];
    [self setExportLanguageSelector:nil];
    [self setVertexSizeSlider:nil];
    [self setVertexSizeTextField:nil];
    [self setEdgeWidthSlider:nil];
    [self setEdgeWidthTextField:nil];
    [self setPdfView:nil];
    [self setVertexEdgeSizeToolBar:nil];
    [self setScaleFactorToolbar:nil];
    [self setSettingsView:nil];
    [self setCodeField:nil];
    [self setColors:nil];
    [self setColourSwitch:nil];
    [super viewDidUnload];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString *) getPathForFileOfType:(NSString *) type {
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [dirPaths objectAtIndex:0];
    NSString *fileName = [NSString stringWithFormat:@"%@.%@", self.title, type];
    
    return [[NSString alloc] initWithString:[docsDir stringByAppendingPathComponent:fileName]];

}

- (IBAction)exportGraph:(UISegmentedControl *)sender {
    switch ([sender selectedSegmentIndex]) {
        case 0:
            extension = @"tikz.tex";
            [self processForTiKzFile];
            [self makePDF];
            break;
        case 1:
            extension = @"pstricks.tex";
            [self processForPSTricksFile];
            [self setDoingPSTricks:YES];
            [self makePDF];
            [self setDoingPSTricks:NO];
            break;
        case 2:
            extension = @"py";
            [self processForSageFile];
            break;
        case 3:
            extension = @"m";
            [self.codeField setText:@"In the works..."];
            break;
        case 4:
            extension = @"mathematica";
            [self.codeField setText:@"In the works..."];
            break;
        case 5:
            extension = @"mpl";
            [self.codeField setText:@"In the works..."];
        default:
            break;
    }
}

#pragma mark - tikz generator methods
/*******************************************************************************
                            TikZ generator methods
 *******************************************************************************/

- (void) processForTiKzFile {
    NSMutableString *latexCode = [NSMutableString stringWithString:@"\t\\begin{tikzpicture}\n"\
                                  "\t\t\\tikzstyle{every node} = [circle, fill=black, inner sep=0pt]\n"];
    NSMutableString *colorString = [NSMutableString stringWithString:@"\n\t\t%COLORS\n"];
    NSMutableString *vertexString = [NSMutableString stringWithString:@"\n\n\t\t%VERTICES\n"];
    NSMutableString *straightEdgeString = [[NSMutableString alloc] init];
    NSMutableString *curvedEdgeString = [NSMutableString stringWithString:@"\n\n\t\t%CURVED EDGES\n"];
    int lineLength = [@"\t\t\\foreach \\from/\\to/\\col/\\type in {" length];
    NSString *straightEdge;
    for (EasyGraphVertexView *vert in self.vertexSet) {
        [colorString appendString:[self makeColorStringWithColor:[vert colour]]];
        [vertexString appendString:[self processVertexForTiKz:vert]];
        
        for (EasyGraphEdgeView *edge in vert.inNeighbs) {
            [colorString appendString:[self makeColorStringWithColor:[edge colour]]];
            if ([edge.curvePoints count] == 0) {
                straightEdge = [self processStraightEdgeForTiKz:edge];
                lineLength += [straightEdge length];
                [straightEdgeString appendString:straightEdge];
                if (lineLength > 79) {
                    [straightEdgeString appendString:@"\n\t\t\t\t"];
                    lineLength = [@"\t\t\t\t" length];
                }
            } else {
                [curvedEdgeString appendString:[self processCurvedEdgeForTiKz:edge]];
            }
        }
    }
    if ([straightEdgeString length] != 0) {
        [straightEdgeString deleteCharactersInRange:NSMakeRange([straightEdgeString length] - 2, 2)];
        
        NSMutableString *forEachCode;

        forEachCode = [NSMutableString stringWithFormat:
                       @"\n\n\t\t%%STRAIGHT EDGES\n\t\t"\
                       "\\foreach \\from/\\to/%@\\type in {", usingColours ? @"\\col/" : @""];
        [forEachCode appendString:straightEdgeString];
        [forEachCode appendFormat:@"}\n\t\t\t\\draw [-%@, line width=%.3fpt"\
                                                "%@, style=\\type](\\from) -- (\\to);",
                                                self.isDirected ? @">, >=latex" : @"",
                                                self.edgeWidth,
                                                usingColours ? @", color=\\col" : @""];
        straightEdgeString = forEachCode;
    }
    if (!usingColours) {
        colorString = [NSMutableString stringWithString:@""];
    }
    NSArray *strings = [NSArray arrayWithObjects:colorString, vertexString, straightEdgeString, curvedEdgeString, @"\t\\end{tikzpicture}", nil];
    [latexCode appendString:[strings componentsJoinedByString:@""]];
    
    [latexCode writeToFile:[self getPathForFileOfType:extension] atomically:YES encoding:NSStringEncodingConversionAllowLossy error:nil];

    [self.codeField setText:latexCode];
    [self.colors removeAllObjects];
}

- (NSMutableString *) processCurvedEdgeForTiKz:(EasyGraphEdgeView *)edge {
    NSString *colorName, *edgeType;
    NSString *directed = self.isDirected ? @"->, >=latex, " : @"";
    NSMutableString *curvedEdgeString = [[NSMutableString alloc] init];
    CGPoint point;
    if (usingColours) {
        colorName = [NSString stringWithFormat:@"color_%d, ",
                     [self.colors indexOfObject:[edge colour]]];
    } else {
        colorName = @"";
    }
    edgeType = edge.isNonEdge ? @"dashed" : @"solid";

    [curvedEdgeString appendFormat:@"\t\t\\draw [%@%@, line width=%.3f, %@]"\
                             " plot [tension=2] coordinates {",
                                                    directed,
                                                    colorName,
                                                    self.edgeWidth,
                                                    edgeType];
    NSValue *pointVal;
    int lineLength = [curvedEdgeString length];
    NSString *addedString;
    for (int i = 0; i < [edge.splinePoints count] - 8; i++) {
        pointVal = [edge.splinePoints objectAtIndex:i];
        point = [edge convertPoint:[pointVal CGPointValue] toView:edge.superview];
        addedString = [NSString stringWithFormat:@"(%.3fpt,-%.3fpt)",
                       point.x / self.scaleFactor,
                       point.y / self.scaleFactor];
        lineLength += [addedString length];
        [curvedEdgeString appendString:addedString];
        if (lineLength > 79) {
            [curvedEdgeString appendString:@"\n\t\t\t"];
            lineLength = [@"\t\t\t" length];
        }
    }
    
    [curvedEdgeString appendString:@"};\n"];
    return curvedEdgeString;
}

- (NSString *) processStraightEdgeForTiKz:(EasyGraphEdgeView *)edge {
    NSString *colorName, *edgeType;
    if (usingColours) {
        colorName = [NSString stringWithFormat:@"color_%d/",
                     [self.colors indexOfObject:[edge colour]]];
    } else {
        colorName = @"";
    }
    edgeType = edge.isNonEdge ? @"dashed" : @"solid";
    return [NSString stringWithFormat:@"%d/%d/%@%@, ", edge.startVertex.vertexNum, edge.endVertex.vertexNum, colorName, edgeType];
}

- (NSString *) processVertexForTiKz:(EasyGraphVertexView *)vert {
    NSString *colorName, *borderColor, *vertexString;
    if (usingColours) {
        colorName = [NSString stringWithFormat:@"color_%d, ",
                     [self.colors indexOfObject:[vert colour]]];
    } else {
        colorName = @"";
    }
    borderColor = [[vert colour] isEqual:[UIColor whiteColor]] ? @", draw=black" : @"";
    vertexString = [NSString stringWithFormat:@"\t\t\\node[%@minimum size=%.3fpt%@](%d)"\
                                         " at (%.3fpt, -%.3fpt){};\n",
                                         colorName,
                                         self.vertexSize,
                                         borderColor,
                                         [vert vertexNum],
                                         vert.center.x / self.scaleFactor,
                                         vert.center.y / self.scaleFactor];
    return vertexString;
}

#pragma mark - pstricks generating methods
/*******************************************************************************
                             PSTricks generating methods
 *******************************************************************************/

- (void) processForPSTricksFile {

    NSMutableString *latexCode = [NSMutableString stringWithFormat:@"\t\\begin{pspicture}(0, -%.3fpt)(%.3fpt,0)\n", 916/scaleFactor, 768/scaleFactor];
    NSMutableString *colorString = [NSMutableString stringWithString:@"\n\t\t%COLORS\n"];
    NSMutableString *vertexString = [NSMutableString stringWithString:@"\n\t\t%VERTICES\n"];
    NSMutableString *edgeString = [NSMutableString stringWithString:@"\n\t\t%EDGES\n"];
    

    for (EasyGraphVertexView *vert in self.vertexSet) {
        [colorString appendString:[self makeColorStringWithColor:vert.colour]];
        [vertexString appendString:[self makePSTricksVertexCommandStringForVertex:vert]];
        
        for (EasyGraphEdgeView *edge in vert.inNeighbs) {
            [colorString appendString:[self makeColorStringWithColor:edge.colour]];
            [edgeString appendString:[self makePSTricksEdgeCommandStringForEdge:edge]];
        }
    }
    if (!usingColours) {
        colorString = [NSMutableString stringWithString:@""];
    }
    NSArray *strings = [NSArray arrayWithObjects:colorString, edgeString, vertexString, @"\n\t\\end{pspicture}\n", nil];
    [latexCode appendString:[strings componentsJoinedByString:@""]];
    [latexCode writeToFile:[self getPathForFileOfType:extension] atomically:YES encoding:NSStringEncodingConversionAllowLossy error:nil];
    
    [self.codeField setText:latexCode];
    [self.colors removeAllObjects];
}

- (NSString *) makePSTricksVertexCommandStringForVertex:(EasyGraphVertexView *)vert {
    NSString *colorName = [NSString stringWithFormat:@"color_%d",
                                                [self.colors indexOfObject:vert.colour]];
    NSMutableString *commandString = [[NSMutableString alloc] init];
    if (usingColours) {
        if ([vert.colour isEqual:[UIColor whiteColor]]) {
            [commandString appendString:@"\t\t\\pscircle[linecolor=black, fillcolor=white, fillstyle=solid]"];
        } else {
            [commandString appendFormat:@"\t\t\\pscircle[linecolor=%@, fillcolor=%@, fillstyle=solid]",colorName, colorName];
        }
    } else {
        [commandString appendString:@"\t\t\\pscircle[fillcolor=black, fillstyle=solid]"];
    }
    [commandString appendFormat:@"(%.3fpt, -%.3fpt){%.3fpt}\n", (vert.center.x / scaleFactor), (vert.center.y/scaleFactor), vertexSize];
    
    return commandString;
}

- (NSMutableString *) makePSTricksEdgeCommandStringForEdge:(EasyGraphEdgeView *)edge {
    NSMutableString *commandString = [[NSMutableString alloc] init];
    NSString *colorName;
    NSString *directedOne = @"";
    NSString *directedTwo = @"";
    if (usingColours) {
        colorName = [NSString stringWithFormat:@", linecolor=color_%d", [self.colors indexOfObject:edge.colour]];
    } else {
        colorName = @"";
    }
    if (self.isDirected) {
        directedOne = [NSString stringWithFormat:@"arrows=->, arrowsize=%.3fpt, arrowinset=0.15, ", 1.5*self.vertexSize];
        directedTwo = @">";
    }
    if ([edge.curvePoints count] == 0) {
        [commandString appendFormat:@"\t\t\\psline[%@linewidth=%.3fpt%@]{-%@}(%.3fpt, -%.3fpt)(%.3fpt, -%.3fpt)\n",
         directedOne,
         edgeWidth,
         colorName,
         directedTwo,
         edge.startVertex.center.x/scaleFactor,
         edge.startVertex.center.y/scaleFactor,
         edge.endVertex.center.x/scaleFactor,
         edge.endVertex.center.y/scaleFactor];
    } else {
        [commandString appendFormat:@"\t\t\\psecurve[%@linewidth=%.3fpt%@]{-%@}",
         directedOne, edgeWidth, colorName, directedTwo];
        CGPoint point;
        for (NSValue *pointVal in edge.splinePoints) {
            point = [edge convertPoint:[pointVal CGPointValue] toView:edge.superview];
            [commandString appendFormat:@"(%.3fpt, -%.3fpt)",
                                        point.x/scaleFactor,
                                        point.y/scaleFactor];
        }
        [commandString appendString:@"\n"];
    }
    return commandString;
}

- (NSString *) makeColorStringWithColor:(UIColor *)color {
    NSMutableString *colorString = [NSMutableString stringWithString:@""];
    if (![self.colors containsObject:color]) {
        [self.colors addObject:color];
        CGFloat red, green, blue, alpha;
        [colorString appendFormat:@"\t\t\\definecolor{color_%d}{rgb}", [self.colors count] - 1];
        if ([color getRed:&red green:&green blue:&blue alpha:&alpha]) {
            [colorString appendFormat:@"{%.1f,%.1f,%.1f}\n", red, green, blue];
        } else if ([color isEqual:[UIColor whiteColor]]) {
            [colorString appendFormat:@"{1.0, 1.0, 1.0}\n"];
        } else {
            [colorString appendFormat:@"{0, 0, 0}\n"];
        }
    }
    return colorString;
}

#pragma mark - sage generating methods.
/*******************************************************************************
                                Sage generating methods
 *******************************************************************************/

- (void) processForSageFile {
    NSMutableString *sageCode = [NSMutableString stringWithString:@"G = "];
    if (self.isDirected) {
        [sageCode appendFormat:@"DiGraph(%d)\n", [self.vertexSet count]];
    } else {
        [sageCode appendFormat:@"Graph(%d)\n", [self.vertexSet count]];
    }
    NSMutableString *relabelString = [NSMutableString stringWithString:@"G.relabel(["];
    int i = 1;
    NSMutableString *edges = [[NSMutableString alloc] init];
    for (EasyGraphVertexView *vert in self.vertexSet) {
        [relabelString appendFormat:@"%d, ", i++];
        for (EasyGraphEdgeView *edge in vert.inNeighbs) {
            if (![edge isNonEdge]) {
                [edges appendFormat:@"(%d, %d), ", edge.startVertex.vertexNum,
                                                      edge.endVertex.vertexNum];
            }
        }
    }
    [sageCode appendString:[relabelString substringToIndex:[relabelString length] - 2]];
    [sageCode appendString:@"])\n"];
    if ([edges length] != 0) {
        [sageCode appendString:@"G.add_edges(["];
        [edges deleteCharactersInRange:NSMakeRange([edges length] - 2, 2)];
        [sageCode appendString:edges];
        [sageCode appendString:@"])"];
    }
    [sageCode writeToFile:[self getPathForFileOfType:extension] atomically:YES encoding:NSStringEncodingConversionAllowLossy error:nil];
    [self.codeField setText:sageCode];
}

/*******************************************************************************
                                PDF production
 *******************************************************************************/

- (IBAction)makePDF {
    NSString *path = [self getPathForFileOfType:@"pdf"];
    double width = 612;
    double height = 792;
    UIGraphicsBeginPDFContextToFile(path, CGRectMake(0, 0, width, height), nil);
    UIGraphicsBeginPDFPageWithInfo(CGRectMake(0, 0, width, height), nil);
    double xOffset = self.scaleFactor <= 5 ? self.scaleFactor * 50 : self.scaleFactor + 250;
    double yOffset = self.scaleFactor * 5;
    CGPoint offsets = CGPointMake(xOffset, yOffset);
    
    [self drawEdgesToPDFWithOffsets:offsets];
    [self drawVerticesToPDFWithOffsets:offsets];
    
    UIGraphicsEndPDFContext();
    
    NSURL *url = [NSURL fileURLWithPath:path];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.pdfView setScalesPageToFit:YES];
    [self.pdfView loadRequest:request];
    self.documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:url];
}

- (void) drawEdgesToPDFWithOffsets:(CGPoint) offsets {
    CGContextRef context = UIGraphicsGetCurrentContext();
    NSMutableArray *curvePoints = [[NSMutableArray alloc] init];
    CGPoint start, end;
    CGColorRef edgeColour;
    NSArray *splinePoints;
    for (EasyGraphVertexView *vert in self.vertexSet) {
        for (EasyGraphEdgeView *edge in vert.inNeighbs) {
            CGContextSetLineWidth(context, self.edgeWidth);
            edgeColour = usingColours ? edge.colour.CGColor : [UIColor blackColor].CGColor;
            CGContextSetStrokeColorWithColor(context, edgeColour);
            if (edge.isNonEdge) {
                CGFloat dashArray[] = {6};
                CGContextSetLineDash(context, 3, dashArray, 1);
            }
            start = edge.startVertex.center;
            end = edge.endVertex.center;
            start = CGPointMake(offsets.x + start.x/self.scaleFactor, offsets.y + start.y/self.scaleFactor);
            end = CGPointMake(offsets.x + end.x/self.scaleFactor, offsets.y + end.y/self.scaleFactor);
            NSMutableArray *fixedCurvePoints = [[NSMutableArray alloc] init];
            for (NSValue *val in [edge curvePoints]) {
                CGPoint p = [val CGPointValue];
                p = CGPointMake(offsets.x + p.x/self.scaleFactor, offsets.y + p.y/self.scaleFactor);
                [fixedCurvePoints addObject:[NSValue valueWithCGPoint:p]];
            }
            splinePoints = [edge getSplinePointsForStartPoint:start endPoint:end controlPoints:[NSMutableArray arrayWithArray:fixedCurvePoints]];
            [edge drawEdgeThroughPoints:splinePoints];
            CGContextStrokePath(context);
            if (isDirected) {
                double length = self.vertexSize * 2;
                double width = self.vertexSize * 1.1;
                [edge drawArrowForSplinePoints:splinePoints ofLength:length andWidth:width];
            }
            CGContextSetLineDash(context, 0, nil, 0);
            [curvePoints removeAllObjects];
        }
    }
}

- (void) drawVerticesToPDFWithOffsets:(CGPoint) offsets {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGPoint center;
    CGColorRef vertexColour;
    double vSize = self.vertexSize;
    if (self.doingPSTricks) {
        vSize *= 4.5;
    } else {
        vSize *= 3;
    }
    for (EasyGraphVertexView *vert in self.vertexSet) {
        vertexColour = usingColours ? vert.colour.CGColor : [UIColor blackColor].CGColor;
        if ([vert.colour isEqual:[UIColor whiteColor]]) {
            CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
            CGContextSetLineWidth(context, 1.0);
        } else {
            CGContextSetStrokeColorWithColor(context, vertexColour);
            CGContextSetLineWidth(context, 0.5);
        }
        CGContextSetFillColorWithColor(context, vertexColour);
        center = CGPointMake(offsets.x + vert.center.x / self.scaleFactor, offsets.y + vert.center.y / self.scaleFactor);
        CGRect rectangle = CGRectMake(center.x - vSize/4.0, center.y - vSize/4.0, vSize/2, vSize/2);
        
        CGContextAddEllipseInRect(context, rectangle);
        CGContextStrokePath(context);
        CGContextFillEllipseInRect(context, rectangle);
    }
}
#pragma mark - UI Methods
/*******************************************************************************
                            UI Elements
 *******************************************************************************/

- (IBAction)colourSwitchFlipped:(UISwitch *)sender {
    usingColours = !usingColours;
    [self makePreview];
    [self exportGraph:self.exportLanguageSelector];
}

- (IBAction)openInDialouge:(id)sender {
    if (self.documentInteractionController != nil) {
        self.documentInteractionController.delegate = self;
        [self.documentInteractionController presentOpenInMenuFromBarButtonItem:self.openPDFInButton animated:YES];
    }
}

- (IBAction)selectedLanguageChanged:(UISegmentedControl *)sender {
    self.dropboxFile = nil;
    self.googleDriveFile = nil;
    switch ([sender selectedSegmentIndex]) {
        case 0:
            [self setLatexDefaultsForPackage:@"tikz"];
            break;
        case 1:
            [self setLatexDefaultsForPackage:@"pstricks"];
            break;
        default:
            [self.scaleFactorSlider setEnabled:NO];
            [self.scaleFactorTextField setEnabled:NO];
            [self.vertexSizeSlider setEnabled:NO];
            [self.vertexSizeTextField setEnabled:NO];
            [self.edgeWidthSlider setEnabled:NO];
            [self.edgeWidthTextField setEnabled:NO];
            [self.exportPDFButton setEnabled:NO];
            break;
    }
    [self makePreview];
}

- (IBAction)makePreview {
    [self exportGraph:self.exportLanguageSelector];
}

- (IBAction)savePressed:(UIBarButtonItem *)sender {
    switch ([sender tag]) {
        case 0:
            [self saveToDropbox];
            break;
        case 1:
            [self saveToGoogleDrive];
            break;
        default:
            [self promptForServiceChoice];
            break;
    }
}

- (IBAction)savePDFpressed:(UIBarButtonItem *)sender {
    //Come up with better method!
    extension = @"pdf";
    self.dropboxFile = nil;
    [self savePressed:sender];
}

- (void) promptForServiceChoice {
    if (self.servicesPopoverController == nil) {
        UIViewController *servicesView = [[UIViewController alloc] init];
        UIBarButtonItem *dropboxButton = [[UIBarButtonItem alloc] initWithTitle:@"Dropbox" style:UIBarButtonItemStyleBordered target:self action:@selector(signInToService:)];
        [dropboxButton setTag:0];
        UIBarButtonItem *googleDriveButton = [[UIBarButtonItem alloc] initWithTitle:@"Google Drive" style:UIBarButtonItemStyleBordered target:self action:@selector(signInToService:)];
        [googleDriveButton setTag:1];

        
        [servicesView.navigationItem setLeftBarButtonItems:[NSArray arrayWithObjects:dropboxButton, googleDriveButton, nil]];
        
        UINavigationController *nv = [[UINavigationController alloc] initWithRootViewController:servicesView];
        
        self.servicesPopoverController = [[UIPopoverController alloc] initWithContentViewController:nv];
        [self.servicesPopoverController setPopoverContentSize:CGSizeMake(175, 30)];
//        [self.servicesPopoverController setPopoverBackgroundViewClass:[EasyGraphPopoverBackgroundView class]];
    }
    if ([self.servicesPopoverController isPopoverVisible]) {
        [self.servicesPopoverController dismissPopoverAnimated:YES];
        [self setServicesPopoverController:nil];
    } else {
        [self.servicesPopoverController presentPopoverFromBarButtonItem:self.saveButton permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    }
    
}

- (IBAction)signInToService:(UIBarButtonItem *)sender {
    [self.servicesPopoverController dismissPopoverAnimated:YES];
    switch ([sender tag]) {
        case 0:
            [self.saveButton setTitle:@"Save to Dropbox"];
            [self saveToDropbox];
            break;
        case 1:
            [self.saveButton setTitle:@"Save to Google Drive"];
            [self saveToGoogleDrive];
            break;
        default:
            break;
    }
    [self.saveButton setTag:[sender tag]];
}

#pragma mark - UI methods - latex settings
- (IBAction)scaleSliderMoved:(UISlider *)sender {
    double newVal = (int)([sender value] * 10) / 10.0;
    newVal = 15 - newVal;
    [self setScaleFactor:newVal];
    [self.scaleFactorTextField setText:[NSString stringWithFormat:@"%.1f", newVal]];
}

- (IBAction)scaleFieldChanged {
    CGFloat newScale = fmin([[[self scaleFactorTextField] text] floatValue], 15);
    [self setScaleFactor:newScale];
    [self.scaleFactorSlider setValue:newScale];
    [self exportGraph:self.exportLanguageSelector];
}

- (IBAction)vertexSizeSliderMoved:(UISlider *)sender {
    double newVal = (int)([sender value] * 10) / 10.0;
    [self setVertexSize:newVal];
    [self.vertexSizeTextField setText:[NSString stringWithFormat:@"%.1f", newVal]];
}

- (IBAction)vertexSizeFieldChanged:(id)sender {
    CGFloat newScale = fmin([[[self vertexSizeTextField] text] floatValue], 10.0);
    [self setVertexSize:newScale];
    [self.vertexSizeSlider setValue:newScale];
}

- (IBAction)edgeWitdhSliderMoved:(UISlider *)sender {
    double newVal = (int)([sender value] * 10) / 10.0;
    [self setEdgeWidth:newVal];
    [self.edgeWidthTextField setText:[NSString stringWithFormat:@"%.1f", newVal]];
}

- (IBAction)edgeWidthFieldChanged:(UITextField *)sender {
    CGFloat newScale = fmin([[[self edgeWidthTextField] text] floatValue], 10.0);
    [self setEdgeWidth:newScale];
    [self.edgeWidthSlider setValue:newScale];
}

- (void)setLatexDefaultsForPackage:(NSString *)package {
    NSString *scaleKey = [NSString stringWithFormat:@"%@Scale", package];
    NSString *vertexSizeKey = [NSString stringWithFormat:@"%@VertexSize", package];
    NSString *edgeWidthKey = [NSString stringWithFormat:@"%@EdgeWidth", package];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    float newVal = [defaults floatForKey:scaleKey];
    [self.scaleFactorSlider setValue:newVal];
    newVal = (int)(newVal * 10) / 10.0;
    newVal = 15 - newVal;
    [self.scaleFactorTextField setText:[NSString stringWithFormat:@"%.1f", newVal]];
    [self setScaleFactor:newVal];
    
    newVal = [defaults floatForKey:vertexSizeKey];
    [self.vertexSizeSlider setValue:newVal];
    [self.vertexSizeTextField setText:[NSString stringWithFormat:@"%.1f", newVal]];
    [self setVertexSize:newVal];
    
    newVal = [defaults floatForKey:edgeWidthKey];
    [self.edgeWidthSlider setValue:newVal];
    [self.edgeWidthTextField setText:[NSString stringWithFormat:@"%.1f", newVal]];
    [self setEdgeWidth:newVal];
    
    [self.scaleFactorSlider setEnabled:YES];
    [self.scaleFactorTextField setEnabled:YES];
    [self.vertexSizeSlider setEnabled:YES];
    [self.vertexSizeTextField setEnabled:YES];
    [self.edgeWidthSlider setEnabled:YES];
    [self.edgeWidthTextField setEnabled:YES];
    [self.exportPDFButton setEnabled:YES];
}

# pragma mark - Google Drive
- (void) saveToGoogleDrive {
    if (!googleIsAuthorized) {
        // Sign in
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
        [self googleDriveWasLinked];
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
        [[self driveService] setAuthorizer:auth];
        googleIsAuthorized = YES;
        [self googleDriveWasLinked];
    }
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

- (void) googleDriveWasLinked {
    if (self.googleDriveFile == nil) {
        [self loadGoogleDriveFiles];
    } else {
        [self uploadFileToGoogleDrive];
    }
}

- (void) loadGoogleDriveFiles {
    GTLQueryDrive *query = [GTLQueryDrive queryForFilesList];
    query.q = @"fullText contains '*'";

    
    [[self driveService] executeQuery:query completionHandler:^(GTLServiceTicket *ticket,
                                                              GTLDriveFileList *files,
                                                              NSError *error) {
        if (error == nil) {
            NSString *fileName = [NSString stringWithFormat:@"%@.%@", self.title, extension];
            for (GTLDriveFile *file in files.items) {
                if ([file.title isEqualToString:fileName] && !file.explicitlyTrashed) {
                    self.googleDriveFile = file;
                    break;
                }
            }
            if (self.googleDriveFile == nil) {
                self.googleDriveFile = [GTLDriveFile object];
            }
            [self uploadFileToGoogleDrive];
        } else {
            NSLog(@"An error occurred: %@", error);
        }
    }];
}

- (void) uploadFileToGoogleDrive {
    NSString *path = [self getPathForFileOfType:extension];
    NSData *fileContent = [NSData dataWithContentsOfFile:path];
    GTLUploadParameters *uploadParameters =
                        [GTLUploadParameters uploadParametersWithData:
                                    fileContent MIMEType:@"plain/text"];
    [self.googleDriveFile setTitle:[NSString stringWithFormat:@"%@.%@", self.title, extension]];
    GTLQueryDrive *query = nil;
    if (self.googleDriveFile.identifier == nil || self.googleDriveFile.identifier.length == 0) {
        // This is a new file, instantiate an insert query.
        query = [GTLQueryDrive queryForFilesInsertWithObject:self.googleDriveFile
                                            uploadParameters:uploadParameters];
    } else {
        // This file already exists, instantiate an update query.
        query = [GTLQueryDrive queryForFilesUpdateWithObject:self.googleDriveFile
                                                      fileId:self.googleDriveFile.identifier
                                            uploadParameters:uploadParameters];
    }
    
    [self showUploadingIndicator];
    [[self driveService] executeQuery:query completionHandler:^(GTLServiceTicket *ticket,
                                                              GTLDriveFile *updatedFile,
                                                              NSError *error) {
        [self.uploadingView stopAnimating];
        if (error == nil) {
            NSString *msg = [NSString stringWithFormat:@"File uploaded successfully"];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Google Drive" message:msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
            self.googleDriveFile = updatedFile;
        } else {
            NSLog(@"An error occurred: %@", error);
        }
    }];

}

# pragma mark - Dropbox

- (void) saveToDropbox {
    if (![[DBSession sharedSession] isLinked]) {
        [[DBSession sharedSession] linkFromController:self];
    } else {
        [self dropboxWasLinked];
    }
}

- (void)dropboxWasLinked {
    [self showUploadingIndicator];
    if (self.dropboxFile == nil) {
        [[self restClient] loadMetadata:@"/"];
    } else {
        NSString *path = [self getPathForFileOfType:extension];
        [[self restClient] uploadFile:self.dropboxFile.filename toPath:@"/" withParentRev:self.dropboxFile.rev fromPath:path];
    }
}

- (DBRestClient *)restClient {
    if (!restClient) {
        restClient =
        [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        restClient.delegate = self;
    }
    return restClient;
}

- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata {
    NSString *path = [self getPathForFileOfType:extension];
    int pathLength = [path length];
    int titleLength = [self.title length];
    int extLength = [extension length] + 1;
    int filenameStart = pathLength - titleLength - extLength;
    NSString *filename = [path substringFromIndex:filenameStart];
    NSString *rev;
    if (metadata.isDirectory) {
        for (DBMetadata *file in metadata.contents) {
            if ([filename isEqualToString:file.filename]) {
                rev = file.rev;
            }
        }
    }
    [[self restClient] uploadFile:filename toPath:@"/" withParentRev:rev fromPath:path];
}

- (void)restClient:(DBRestClient *)client
loadMetadataFailedWithError:(NSError *)error {
    NSString *msg = [NSString stringWithFormat:@"File upload failed with error - %@", error];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath
              from:(NSString*)srcPath metadata:(DBMetadata*)metadata {
    self.dropboxFile = metadata;
    [self.uploadingView stopAnimating];
    NSString *msg = [@"" stringByAppendingFormat:@"File uploaded successfully to path: /Apps/EasyGraph/%@", metadata.filename];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Dropbox" message:msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error {
    NSString *msg = [NSString stringWithFormat:@"File upload failed with error - %@", error];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    
    [self.uploadingView stopAnimating];
}

- (void)showUploadingIndicator {
    if (self.uploadingView == nil) {
        self.uploadingView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 8, 30, 30)];
        [self.uploadingView setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhite];
        [[[self.middleBar subviews] objectAtIndex:2] addSubview:self.uploadingView];
        [self.uploadingView setHidesWhenStopped:YES];
    }
    [self.uploadingView startAnimating];
}

-(void) addGradient:(UIButton *) _button {
    // Add Border
    CALayer *layer = _button.layer;
    layer.cornerRadius = 8.0f;
    layer.masksToBounds = YES;
    layer.borderWidth = 1.0f;
    layer.borderColor = [UIColor colorWithWhite:0.5f alpha:0.2f].CGColor;
    
    // Add Shine
    CAGradientLayer *shineLayer = [CAGradientLayer layer];
    shineLayer.frame = layer.bounds;
    shineLayer.colors = [NSArray arrayWithObjects:
                         (id)[UIColor colorWithWhite:1.0f alpha:0.4f].CGColor,
                         (id)[UIColor colorWithWhite:1.0f alpha:0.2f].CGColor,
                         (id)[UIColor colorWithWhite:0.75f alpha:0.2f].CGColor,
                         (id)[UIColor colorWithWhite:0.4f alpha:0.2f].CGColor,
                         (id)[UIColor colorWithWhite:1.0f alpha:0.4f].CGColor,
                         nil];
    shineLayer.locations = [NSArray arrayWithObjects:
                            [NSNumber numberWithFloat:0.0f],
                            [NSNumber numberWithFloat:0.5f],
                            [NSNumber numberWithFloat:0.5f],
                            [NSNumber numberWithFloat:0.8f],
                            [NSNumber numberWithFloat:1.0f],
                            nil];
    [layer addSublayer:shineLayer];
}

@end

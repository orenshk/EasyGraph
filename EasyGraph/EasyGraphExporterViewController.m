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
@synthesize vertexSizeMultiplier, edgeWidthMultiplier, doingPSTricks;
@synthesize isDirected;

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
    [self.view setBackgroundColor:[UIColor whiteColor]];
    [self.codeField setFont: [UIFont systemFontOfSize:15]];

    [self roundBorderForLayer:self.codeField.layer];
    [self roundBorderForLayer:self.pdfView.layer];
    [self roundBorderForLayer:self.settingsView.layer];
    [self roundBorderForLayer:self.middleBar.layer];
    
    [self setScaleFactor:5.0];
    [self setEdgeWidth:7.0 / self.scaleFactor];
    [self setVertexSizeMultiplier:1.0];
    [self setEdgeWidthMultiplier:1.0];
    
    [self setDoingPSTricks:NO];
    [self exportGraph:self.exportLanguageSelector];
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
    [super viewDidUnload];
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
    [self setButtonsToolBar:nil];
    [self setSettingsView:nil];
    [self setCodeField:nil];
    [self setColors:nil];
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
            [self processForTiKzFile];
            [self makePDF];
            break;
        case 1:
            [self processForPSTricksFile];
            [self setDoingPSTricks:YES];
            [self makePDF];
            [self setDoingPSTricks:NO];
            break;
        case 2:
            [self processForSageFile];
            break;
        case 3:
            [self.codeField setText:@"In the works..."];
            break;
        case 4:
            [self.codeField setText:@"In the works..."];
            break;
        case 5:
            [self.codeField setText:@"In the works..."];
        default:
            break;
    }
}

/*******************************************************************************
                            TikZ generator functions
 *******************************************************************************/

- (void) processForTiKzFile {
    NSMutableString *latexCode = [NSMutableString stringWithString:@"\t\\begin{tikzpicture}\n"\
                                  "\t\t\\tikzstyle{every node} = [circle, fill=black]\n"];
    NSMutableString *colorString = [NSMutableString stringWithString:@"\n\t\t%COLORS\n"];
    NSMutableString *vertexString = [NSMutableString stringWithString:@"\n\n\t\t%VERTICES\n"];
    NSMutableString *straightEdgeString = [[NSMutableString alloc] init];
    NSMutableString *curvedEdgeString = [NSMutableString stringWithString:@"\n\n\t\t%CURVED EDGES\n"];
    for (EasyGraphVertexView *vert in self.vertexSet) {
        [colorString appendString:[self makeColorStringWithColor:[vert colour]]];
        [vertexString appendString:[self processVertexForTiKz:vert]];
        
        for (EasyGraphEdgeView *edge in vert.inNeighbs) {
            [colorString appendString:[self makeColorStringWithColor:[edge colour]]];
            if ([edge.curvePoints count] == 0) {
                [straightEdgeString appendString:[self processStraightEdgeForTiKz:edge]];
            } else {
                [curvedEdgeString appendString:[self processCurvedEdgeForTiKz:edge]];
            }
        }
    }
    if ([straightEdgeString length] != 0) {
        [straightEdgeString deleteCharactersInRange:NSMakeRange([straightEdgeString length] - 2, 2)];
        
        NSMutableString *forEachCode = [NSMutableString stringWithString:
                             @"\n\n\t\t%STRAIGHT EDGES\n\t\t"\
                             "\\foreach \\from/\\to/\\col/\\type in {"];
        [forEachCode appendString:straightEdgeString];
        
        [forEachCode appendFormat:@"}\n\t\t\t\\draw [-%@, line width=%.3fpt, "\
                                                "color=\\col, style=\\type](\\from) -- (\\to);",
                                                self.isDirected? @">, >=latex" : @"",
                                                self.edgeWidth];
        straightEdgeString = forEachCode;
    }
    NSArray *strings = [NSArray arrayWithObjects:colorString, vertexString, straightEdgeString, curvedEdgeString, @"\t\\end{tikzpicture}", nil];
    [latexCode appendString:[strings componentsJoinedByString:@""]];
    
    [latexCode writeToFile:[self getPathForFileOfType:@"tex"] atomically:YES encoding:NSStringEncodingConversionAllowLossy error:nil];
    [self.codeField setText:latexCode];
    [self.colors removeAllObjects];
    NSLog(@"%@", latexCode);
}

- (NSMutableString *) processCurvedEdgeForTiKz:(EasyGraphEdgeView *)edge {
    NSString *colorName, *edgeType;
    NSString *directed = self.isDirected ? @"->, >=latex, " : @"";
    NSMutableString *curvedEdgeString = [[NSMutableString alloc] init];
    CGPoint point;
    colorName = [NSString stringWithFormat:@"color_%d",
                 [self.colors indexOfObject:[edge colour]]];
    edgeType = edge.isNonEdge ? @"dashed" : @"solid";

    [curvedEdgeString appendFormat:@"\t\t\\draw [%@, %@, line width=%.3f, %@]"\
                             " plot [tension=2] coordinates {",
                                                    directed,
                                                    colorName,
                                                    self.edgeWidth,
                                                    edgeType];
    
    NSValue *pointVal;
    for (int i = 0; i < [edge.splinePoints count] - 8; i++) {
        pointVal = [edge.splinePoints objectAtIndex:i];
        point = [edge convertPoint:[pointVal CGPointValue] toView:edge.superview];
        [curvedEdgeString appendFormat:@"(%.3fpt,-%.3fpt)",
         point.x / self.scaleFactor,
         point.y / self.scaleFactor];
    }
    
    [curvedEdgeString appendString:@"};\n"];
    return curvedEdgeString;
}

- (NSString *) processStraightEdgeForTiKz:(EasyGraphEdgeView *)edge {
    NSString *colorName, *edgeType;
    colorName = [NSString stringWithFormat:@"color_%d",
                 [self.colors indexOfObject:[edge colour]]];
    edgeType = edge.isNonEdge ? @"dashed" : @"solid";
    return [NSString stringWithFormat:@"%d/%d/%@/%@, ", edge.startVertex.vertexNum, edge.endVertex.vertexNum, colorName, edgeType];
}

- (NSString *) processVertexForTiKz:(EasyGraphVertexView *)vert {
    NSString *colorName, *borderColor, *vertexString;
    self.vertexSize = vert.vertexSize / self.scaleFactor;
    colorName = [NSString stringWithFormat:@"color_%d",
                 [self.colors indexOfObject:[vert colour]]];
    borderColor = [[vert colour] isEqual:[UIColor whiteColor]] ? @", draw=black" : @"";
    vertexString = [NSString stringWithFormat:@"\t\t\\node[%@, minimum size=%.3fpt%@](%d)"\
                                         " at (%.3fpt, -%.3fpt){};\n",
                                         colorName,
                                         self.vertexSize,
                                         borderColor,
                                         [vert vertexNum],
                                         vert.center.x / self.scaleFactor,
                                         vert.center.y / self.scaleFactor];
    return vertexString;
}

/*******************************************************************************
                             PSTricks generating functions
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
    
    NSArray *strings = [NSArray arrayWithObjects:colorString, edgeString, vertexString, @"\n\t\\end{pspicture}\n", nil];
    [latexCode appendString:[strings componentsJoinedByString:@""]];
    NSLog(@"%@", latexCode);
    [latexCode writeToFile:[self getPathForFileOfType:@"tex"] atomically:YES encoding:NSStringEncodingConversionAllowLossy error:nil];
    
    [self.codeField setText:latexCode];
    [self.colors removeAllObjects];
}

- (NSString *) makePSTricksVertexCommandStringForVertex:(EasyGraphVertexView *)vert {
    self.vertexSize = vert.vertexSize / self.scaleFactor;
    NSString *colorName = [NSString stringWithFormat:@"color_%d",
                                                [self.colors indexOfObject:vert.colour]];
    NSMutableString *commandString = [[NSMutableString alloc] init];
    if ([vert.colour isEqual:[UIColor whiteColor]]) {
        [commandString appendString:@"\t\t\\pscircle[linecolor=black, fillcolor=white, fillstyle=solid]"];
    } else {
        [commandString appendFormat:@"\t\t\\pscircle[linecolor=%@, fillcolor=%@, fillstyle=solid]",colorName, colorName];
    }
    [commandString appendFormat:@"(%.3fpt, -%.3fpt){%.3fpt}\n", (vert.center.x / scaleFactor), (vert.center.y/scaleFactor), vertexSize];
    
    return commandString;
}

- (NSMutableString *) makePSTricksEdgeCommandStringForEdge:(EasyGraphEdgeView *)edge {
    NSString *colorName = [NSString stringWithFormat:@"color_%d", [self.colors indexOfObject:edge.colour]];
    NSMutableString *commandString = [[NSMutableString alloc] init];
    NSString *directed = self.isDirected ? [NSString stringWithFormat:@"arrows=->, arrowsize=%.3fpt, arrowinset=0.15, ", 1.5*self.vertexSize] : @"";
    if ([edge.curvePoints count] ==0) {
        [commandString appendFormat:@"\t\t\\psline[%@linewidth=%.3fpt,linecolor=%@]{->}(%.3fpt, -%.3fpt)(%.3fpt, -%.3fpt)\n",
         directed,
         edgeWidth,
         colorName,
         edge.startVertex.center.x/scaleFactor,
         edge.startVertex.center.y/scaleFactor,
         edge.endVertex.center.x/scaleFactor,
         edge.endVertex.center.y/scaleFactor];
    } else {
        [commandString appendFormat:@"\t\t\\psecurve[%@linewidth=%.3fpt,linecolor=%@]{->}",
         directed, edgeWidth, colorName];
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

/*******************************************************************************
                                Sage code
 *******************************************************************************/

- (void) processForSageFile {
    NSMutableString *sageCode = [NSMutableString stringWithString:@"G = "];
    if (self.isDirected) {
        [sageCode appendFormat:@"DiGraph(%d)\n", [self.vertexSet count]];
    } else {
        [sageCode appendFormat:@"Graph(%d)\n", [self.vertexSet count]];
    }
    [sageCode appendString:@"G.add_edges(["];

    for (EasyGraphVertexView *vert in self.vertexSet) {
        for (EasyGraphEdgeView *edge in vert.inNeighbs) {
            if (![edge isNonEdge]) {
                [sageCode appendFormat:@"(%d, %d), ", edge.startVertex.vertexNum - 1,
                                                      edge.endVertex.vertexNum - 1];
            }
        }
    }
    [sageCode deleteCharactersInRange:NSMakeRange([sageCode length] - 2, 2)];
    [sageCode appendString:@"])"];
    [sageCode writeToFile:[self getPathForFileOfType:@"py"] atomically:YES encoding:NSStringEncodingConversionAllowLossy error:nil];
    [self.codeField setText:sageCode];
    NSLog(@"%@", sageCode);
}

/*******************************************************************************
                                PDF production
 *******************************************************************************/

- (IBAction)makePDF {
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [dirPaths objectAtIndex:0];
    NSString *fileName = [NSString stringWithFormat:@"%@.pdf", self.title];
    NSString *path = [[NSString alloc] initWithString:[docsDir stringByAppendingPathComponent:fileName]];
    
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
    self.documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:path]];
}

- (void) drawEdgesToPDFWithOffsets:(CGPoint) offsets {
    CGContextRef context = UIGraphicsGetCurrentContext();
    NSMutableArray *curvePoints = [[NSMutableArray alloc] init];
    CGPoint start, end;
    
    NSArray *splinePoints;
    for (EasyGraphVertexView *vert in self.vertexSet) {
        for (EasyGraphEdgeView *edge in vert.inNeighbs) {
            CGContextSetLineWidth(context, self.edgeWidth * self.edgeWidthMultiplier);
            CGContextSetStrokeColorWithColor(context, edge.colour.CGColor);
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
    double vSize = self.vertexSizeMultiplier * self.vertexSize;
    if (self.doingPSTricks) {
        vSize *= 4.5;
    } else {
        vSize *= 3;
    }
    for (EasyGraphVertexView *vert in self.vertexSet) {
        if ([vert.colour isEqual:[UIColor whiteColor]]) {
            CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
            CGContextSetLineWidth(context, 1.0);
        } else {
            CGContextSetStrokeColorWithColor(context, vert.colour.CGColor);
            CGContextSetLineWidth(context, 0.5);
        }
        CGContextSetFillColorWithColor(context, vert.colour.CGColor);
        center = CGPointMake(offsets.x + vert.center.x / self.scaleFactor, offsets.y + vert.center.y / self.scaleFactor);
        CGRect rectangle = CGRectMake(center.x - vSize/4.0, center.y - vSize/4.0, vSize/2, vSize/2);
        
        CGContextAddEllipseInRect(context, rectangle);
        CGContextStrokePath(context);
        CGContextFillEllipseInRect(context, rectangle);
    }
}

/*******************************************************************************
                            UI Elements
 *******************************************************************************/

- (IBAction)openInDialouge:(id)sender {
    if (self.documentInteractionController == nil) {
        
    } else {
        self.documentInteractionController.delegate = self;
        [self.documentInteractionController presentOpenInMenuFromBarButtonItem:self.openPDFInButton animated:YES];
    }
    
}

- (IBAction)makePreview:(id)sender {
    [self exportGraph:self.exportLanguageSelector];
}

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
    [self setVertexSizeMultiplier:newVal];
    [self.vertexSizeTextField setText:[NSString stringWithFormat:@"%.1f", newVal]];
}

- (IBAction)vertexSizeFieldChanged:(id)sender {
    CGFloat newScale = fmin([[[self vertexSizeTextField] text] floatValue], 10.0);
    [self setVertexSizeMultiplier:newScale];
    [self.vertexSizeSlider setValue:newScale];
}

- (IBAction)edgeWitdhSliderMoved:(UISlider *)sender {
    double newVal = (int)([sender value] * 10) / 10.0;
    [self setEdgeWidthMultiplier:newVal];
    [self.edgeWidthTextField setText:[NSString stringWithFormat:@"%.1f", newVal]];
}

- (IBAction)edgeWidthFieldChanged:(UITextField *)sender {
    CGFloat newScale = fmin([[[self edgeWidthTextField] text] floatValue], 10.0);
    [self setEdgeWidthMultiplier:newScale];
    [self.edgeWidthSlider setValue:newScale];
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

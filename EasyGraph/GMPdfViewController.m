//
//  GMPdfViewController.m
//  GraphMaker
//
//  Created by Oren Shklarsky on 2012-10-16.
//
//

#import "GMPdfViewController.h"

@interface GMPdfViewController ()

@end

@implementation GMPdfViewController
@synthesize filePath;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.openInButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(openInDialouge)];
    
    self.printButton = [[UIBarButtonItem alloc] initWithTitle:@"Print" style:UIBarButtonItemStyleBordered target:self action:@selector(printItem)];
    
    [self.navigationItem setRightBarButtonItems:[NSArray arrayWithObjects:self.openInButton, self.printButton, nil]];
    
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [dirPaths objectAtIndex:0];
    NSString *fileName = [NSString stringWithFormat:@"%@.pdf", self.title];
    NSString *path = [[NSString alloc] initWithString:[docsDir stringByAppendingPathComponent:fileName]];
    
    self.filePath = path;
    
    [self showPDF];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)openInDialouge {
    self.documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:self.filePath]];
    self.documentInteractionController.delegate = self;
    [self.documentInteractionController presentOpenInMenuFromBarButtonItem:self.openInButton animated:YES];
}

- (void) showPDF {
    UIWebView* webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, 768, 1024)];
    NSURL *url = [NSURL fileURLWithPath:self.filePath];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [webView setScalesPageToFit:YES];
    [webView loadRequest:request];
    [self.view addSubview:webView];
}

-(void) printItem {
    NSData *dataFromPath = [NSData dataWithContentsOfFile:self.filePath];
    
    UIPrintInteractionController *printController = [UIPrintInteractionController sharedPrintController];
    
    if(printController && [UIPrintInteractionController canPrintData:dataFromPath]) {
        
        printController.delegate = self;
        
        UIPrintInfo *printInfo = [UIPrintInfo printInfo];
        printInfo.outputType = UIPrintInfoOutputGeneral;
        printInfo.jobName = [self.filePath lastPathComponent];
        printInfo.duplex = UIPrintInfoDuplexLongEdge;
        printController.printInfo = printInfo;
        printController.showsPageRange = YES;
        printController.printingItem = dataFromPath;
        
        void (^completionHandler)(UIPrintInteractionController *, BOOL, NSError *) = ^(UIPrintInteractionController *printController, BOOL completed, NSError *error) {
            if (!completed && error) {
                NSLog(@"FAILED! due to error in domain %@ with error code %u", error.domain, error.code);
            }
        };
        [printController presentFromBarButtonItem:self.printButton animated:YES completionHandler:completionHandler];
    }
}


#pragma mark - UIDocumentInteractionControllerDelegate

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller
{
    return self;
}

- (UIView *)documentInteractionControllerViewForPreview:(UIDocumentInteractionController *)controller
{
    return self.view;
}

- (CGRect)documentInteractionControllerRectForPreview:(UIDocumentInteractionController *)controller
{
    return self.view.frame;
}

@end

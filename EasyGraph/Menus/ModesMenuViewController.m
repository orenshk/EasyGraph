//
//  ModesMenuViewController.m
//  EasyGraph
//
//  Created by Oren Shklarsky on 2012-10-24.
//
//

#import "ModesMenuViewController.h"

@interface ModesMenuViewController ()

@end

@implementation ModesMenuViewController



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
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setRemoveButton:nil];
    [super viewDidUnload];
}
@end

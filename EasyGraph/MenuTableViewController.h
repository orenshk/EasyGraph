//
//  MenuTableViewController.h
//  EasyGraph
//
//  Created by Oren Shklarsky on 2012-10-25.
//
//

#import <UIKit/UIKit.h>

@protocol MenuTableViewDelegate <NSObject>
@required
-(void)tableView:(UITableView *)tableView choseRow:(int)row;
@end

@interface MenuTableViewController : UITableViewController
@property (strong, nonatomic) NSArray *menuOptions;
@property (nonatomic, assign) id <MenuTableViewDelegate> delegate;
- (id)initWithStyle:(UITableViewStyle)style andContent:(NSArray *)content;
@end

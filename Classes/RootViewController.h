//
//  RootViewController.h
//  SuperSharer
//
//  Created by kinglong on 4/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ShareConfig.h"
#import "ShareItem.h"

@interface RootViewController : UITableViewController {
	NSArray			* tableViewDataSource_;
	ShareItem		* shareItem_;
}

@end
